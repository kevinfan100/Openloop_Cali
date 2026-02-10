%% ========================================================================
%  Vm Steady-State Spectrum Comparison (Hung / Hung No Ring / NTU)
%  觀察各實驗在 1/10/100 Hz 下的頻域表現
% ========================================================================
%
% Purpose:
%   比較三組實驗的 Vm 穩態頻譜（FFT）
%   觀察基頻尖峰、諧波結構、寬頻雜訊底
%
% Layout:
%   subplot(3,1,k) — 3 列垂直堆疊
%   子圖順序：Hung → Hung (No Ring) → NTU
%   每個子圖內疊加 3 條線（1 Hz / 10 Hz / 100 Hz）
%   共用水平圖例置於圖頂，xlabel 僅底圖
%
% Data Sources:
%   Hung:          Hung_tweezer/single_raw_data/Hung_single_{freq}.dat
%   Hung (No Ring): Hung_tweezer/single_noring_raw_data/Hung_single_noring_{freq}.dat
%   NTU:           NTU_tweezer/single_raw_data/NTU_single_{freq}.dat
%
% Output:
%   Vm_Spectrum_Comparison.png
%
% Author: Claude Code
% Date: 2026-02-06

clear; clc; close all;

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  Vm Spectrum Comparison (Hung / Hung No Ring / NTU)\n');
fprintf('========================================================================\n\n');

%% Configuration
script_root = fileparts(mfilename('fullpath'));
functions_path = fullfile(script_root, 'functions');
addpath(functions_path);

% Frequencies to plot
plot_freqs = [1, 10, 100];  % Hz
freq_labels = {'1 Hz', '10 Hz', '100 Hz'};
freq_suffixes = {'1hz', '10hz', '100hz'};

% Steady-state parameters
NUM_PERIODS = 3;
RELATIVE_THRESHOLD = 0.002;  % 0.2%

% Experiments configuration (Hung → Hung No Ring → NTU)
experiments = struct();

experiments(1).name = 'Hung';
experiments(1).folder = fullfile(script_root, 'Hung_tweezer', 'single_raw_data');
experiments(1).prefix = 'Hung_single_';

experiments(2).name = 'Hung (No Ring)';
experiments(2).folder = fullfile(script_root, 'Hung_tweezer', 'single_noring_raw_data');
experiments(2).prefix = 'Hung_single_noring_';

experiments(3).name = 'NTU';
experiments(3).folder = fullfile(script_root, 'NTU_tweezer', 'single_raw_data');
experiments(3).prefix = 'NTU_single_';

% Line colors for each frequency
colors = lines(3);

%% Create figure
fig = figure('Position', [100, 100, 1200, 1200], 'Name', 'Vm Spectrum');

%% Process each experiment (one subplot per experiment)
for exp_idx = 1:length(experiments)
    exp = experiments(exp_idx);
    subplot(3, 1, exp_idx);
    hold on;

    fprintf('Processing: %s\n', exp.name);

    for freq_idx = 1:length(plot_freqs)
        target_freq = plot_freqs(freq_idx);
        suffix = freq_suffixes{freq_idx};
        filename = fullfile(exp.folder, [exp.prefix, suffix, '.dat']);

        fprintf('  %.0f Hz: %s ... ', target_freq, [exp.prefix, suffix, '.dat']);

        if ~exist(filename, 'file')
            fprintf('NOT FOUND\n');
            continue;
        end

        try
            % Step 1: Read raw data
            data = read_hsdata(filename);
            ch = data.channel;
            fs = data.sampling_rate;

            % Step 2: Extract excitation channel Vm
            Vm_ch2 = data.Vm(:, ch);

            % Step 4: Steady-state detection
            steady_info = detect_steady_state_relative(...
                Vm_ch2, target_freq, fs, ...
                'RelativeThreshold', RELATIVE_THRESHOLD, ...
                'ConsecutivePeriods', 3, 'CheckPoints', 25, 'Verbose', false);

            if steady_info.index <= 0
                fprintf('NO STEADY STATE\n');
                continue;
            end

            % Step 5: Extract steady-state data (3 complete periods)
            ss_start = steady_info.index;
            period_samples = steady_info.period_samples;
            ss_length = NUM_PERIODS * period_samples;

            if ss_start + ss_length - 1 > length(Vm_ch2)
                ss_length = length(Vm_ch2) - ss_start + 1;
                ss_length = floor(ss_length / period_samples) * period_samples;
            end

            Vm_ss = Vm_ch2(ss_start : ss_start + ss_length - 1);

            % Step 6: FFT → single-sided amplitude spectrum
            N = length(Vm_ss);
            Vm_fft = fft(Vm_ss);
            amp = abs(Vm_fft(1:floor(N/2)+1)) / N * 2;
            amp(1) = amp(1) / 2;  % DC component
            freq_axis = (0:floor(N/2)) * fs / N;

            % Plot spectrum (loglog)
            loglog(freq_axis, amp, '-', 'LineWidth', 2, 'Color', colors(freq_idx, :), ...
                'DisplayName', freq_labels{freq_idx});

            fprintf('OK (%d samples, fs=%.0f Hz)\n', N, fs);

        catch ME
            fprintf('ERROR: %s\n', ME.message);
        end
    end

    % Format subplot
    if exp_idx == length(experiments)
        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    end
    ylabel('|Vm| (V)', 'FontWeight', 'bold', 'FontSize', 40);
    title(exp.name, 'FontWeight', 'bold', 'FontSize', 24);

    ax = gca;
    set(ax, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(ax, 'XScale', 'log', 'YScale', 'log');
    xlim([0.5, fs/2]);
    ax.XAxis.LineWidth = 3;
    ax.YAxis.LineWidth = 3;
    box on;
    grid on;

    fprintf('\n');
end

% Shared horizontal legend at the top
ax_first = subplot(3, 1, 1);
lgd = legend(ax_first, 'Orientation', 'horizontal', ...
    'FontWeight', 'bold', 'FontSize', 22);
lgd.Position = [0.25, 0.965, 0.5, 0.03];

%% Save figure
output_file = fullfile(script_root, 'Vm_Spectrum_Comparison.png');
exportgraphics(fig, output_file, 'Resolution', 150);
fprintf('Figure saved: %s\n', output_file);

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  COMPLETE\n');
fprintf('========================================================================\n\n');
