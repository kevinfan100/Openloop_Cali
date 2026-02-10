%% ========================================================================
%  Vm vs Current 比較圖 (跨實驗：Hung / NTU / Hung No Ring)
%  繪製 3 個頻率 (1, 10, 100 Hz) 的 Lissajous 橢圓
% ========================================================================
%
% Purpose:
%   比較三組實驗在不同頻率下的 Vm-Current 關係
%   低頻 → 橢圓較扁（相位差小）
%   高頻 → 橢圓較圓/寬（相位差大）
%
% Data Sources:
%   Hung:          Hung_tweezer/single_raw_data/Hung_single_{freq}.dat
%   NTU:           NTU_tweezer/single_raw_data/NTU_single_{freq}.dat
%   Hung (No Ring): Hung_tweezer/single_noring_raw_data/Hung_single_noring_{freq}.dat
%
% Author: Claude Code
% Date: 2026-02-06

clear; clc; close all;

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  Vm vs Current Comparison (Hung / NTU / Hung No Ring)\n');
fprintf('========================================================================\n\n');

%% Configuration
script_root = fileparts(mfilename('fullpath'));
functions_path = fullfile(script_root, 'functions');
addpath(functions_path);

% Amplifier gain for channel 2: k_A_diag(2) = 0.3614 A/V
k_A = 0.3614;

% DAC conversion parameters
DAC_ZERO = 32768;
DAC_RANGE_V = 20.0;
DAC_RESOLUTION = 65536;

% Frequencies to plot
plot_freqs = [1, 10, 100];  % Hz
freq_labels = {'1 Hz', '10 Hz', '100 Hz'};

% Steady-state parameters
NUM_PERIODS = 3;  % Number of periods to extract
RELATIVE_THRESHOLD = 0.002;  % 0.2%

% Experiments configuration
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

% Frequency file suffixes
freq_suffixes = {'1hz', '10hz', '100hz'};

% Line colors for each frequency
colors = lines(3);  % MATLAB default color order

%% Create figure
fig = figure('Position', [100, 100, 1800, 600], 'Name', 'Vm vs Current');

%% Process each experiment (one subplot per experiment)
for exp_idx = 1:length(experiments)
    exp = experiments(exp_idx);
    subplot(1, 3, exp_idx);
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
            ch = data.channel;  % Excitation channel (should be 2)
            fs = data.sampling_rate;

            % Step 2: Extract excitation channel
            da_raw = double(data.da(:, ch));
            Vm_ch2 = data.Vm(:, ch);

            % Step 3: DAC → Voltage → Current
            V_dac = (da_raw - DAC_ZERO) * (DAC_RANGE_V / DAC_RESOLUTION);
            I = k_A * V_dac;

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

            % Check we have enough samples
            if ss_start + ss_length - 1 > length(I)
                ss_length = length(I) - ss_start + 1;
                ss_length = floor(ss_length / period_samples) * period_samples;
            end

            I_ss = I(ss_start : ss_start + ss_length - 1);
            Vm_ss = Vm_ch2(ss_start : ss_start + ss_length - 1);

            % Step 6: Plot Vm vs Current
            plot(I_ss, Vm_ss, '-', 'LineWidth', 3, 'Color', colors(freq_idx, :), ...
                'DisplayName', freq_labels{freq_idx});

            fprintf('OK (%d samples)\n', length(I_ss));

        catch ME
            fprintf('ERROR: %s\n', ME.message);
        end
    end

    % Format subplot
    xlabel('Current (A)', 'FontWeight', 'bold', 'FontSize', 40);
    if exp_idx == 1
        ylabel('Vm (V)', 'FontWeight', 'bold', 'FontSize', 40);
    end
    title(exp.name, 'FontWeight', 'bold', 'FontSize', 24);

    ax = gca;
    set(ax, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    ax.XAxis.LineWidth = 3;
    ax.YAxis.LineWidth = 3;
    pbaspect([1 1 1]);
    box on;
    grid on;

    fprintf('\n');
end

% Shared horizontal legend at the top
ax_first = subplot(1, 3, 1);
lgd = legend(ax_first, 'Orientation', 'horizontal', ...
    'FontWeight', 'bold', 'FontSize', 22);
lgd.Position = [0.3, 0.95, 0.4, 0.04];

% Unify Y-axis limits across all subplots
all_ylim = zeros(3, 2);
for k = 1:3
    ax_k = subplot(1, 3, k);
    all_ylim(k, :) = ylim(ax_k);
end
global_ylim = [min(all_ylim(:,1)), max(all_ylim(:,2))];
for k = 1:3
    ax_k = subplot(1, 3, k);
    ylim(ax_k, global_ylim);
end

%% Save figure
output_file = fullfile(script_root, 'Vm_vs_Current_Comparison.png');
exportgraphics(fig, output_file, 'Resolution', 150);
fprintf('Figure saved: %s\n', output_file);

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  COMPLETE\n');
fprintf('========================================================================\n\n');
