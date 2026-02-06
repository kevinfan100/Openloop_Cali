%% ========================================================================
%  Three-Experiment Bode Comparison (Hung / Hung NoRing / NTU)
%  三組實驗的 Bode 圖疊加比較
% ========================================================================
%
% Purpose:
%   讀取三組實驗的 Raw_Bode_Data.csv，正規化後疊加比較
%   Magnitude: 各自除以自己的 H(0.1Hz)
%   Phase: 各自減去自己在 0.1 Hz 的相位值
%
% Data Sources:
%   Hung:       Hung_tweezer/results/diagnostics/Raw_Bode_Data.csv
%   NTU:        NTU_tweezer/results/diagnostics/Raw_Bode_Data.csv
%   Hung NoRing: Hung_tweezer/results_noring/diagnostics/Raw_Bode_Data.csv
%
% Output:
%   Comparison_Three_Bode.png
%
% Author: Claude Code
% Date: 2026-02-06

clear; clc; close all;

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  Three-Experiment Bode Comparison\n');
fprintf('========================================================================\n\n');

%% Configuration
script_root = fileparts(mfilename('fullpath'));

% CSV file paths
csv_files = {
    fullfile(script_root, 'Hung_tweezer', 'results', 'diagnostics', 'Raw_Bode_Data.csv'), ...
    fullfile(script_root, 'NTU_tweezer', 'results', 'diagnostics', 'Raw_Bode_Data.csv'), ...
    fullfile(script_root, 'Hung_tweezer', 'results_noring', 'diagnostics', 'Raw_Bode_Data.csv')
};

exp_names = {'Hung', 'NTU', 'Hung NoRing'};

%% Load data
for i = 1:3
    fprintf('Loading: %s\n', csv_files{i});
    if ~exist(csv_files{i}, 'file')
        error('File not found: %s', csv_files{i});
    end
    tables{i} = readtable(csv_files{i});
end

%% Extract H(0.1 Hz) reference values
H_ref = zeros(1, 3);
phase_ref = zeros(1, 3);
for i = 1:3
    [~, idx] = min(abs(tables{i}.Frequency_Hz - 0.1));
    H_ref(i) = tables{i}.Magnitude_Linear(idx);
    phase_ref(i) = tables{i}.Phase_deg(idx);
    fprintf('  %s: H(0.1Hz) = %.4f, Phase(0.1Hz) = %.2f deg\n', exp_names{i}, H_ref(i), phase_ref(i));
end

fprintf('\n');

%% Compute normalized magnitude and phase
% Hung: 20*log10(H / H_hung(0.1Hz))
freq_hung = tables{1}.Frequency_Hz;
mag_hung_dB = 20*log10(tables{1}.Magnitude_Linear / H_ref(1));
phase_hung = tables{1}.Phase_deg - phase_ref(1);

% NTU: 20*log10(H / H_ntu(0.1Hz))
freq_ntu = tables{2}.Frequency_Hz;
mag_ntu_dB = 20*log10(tables{2}.Magnitude_Linear / H_ref(2));
phase_ntu = tables{2}.Phase_deg - phase_ref(2);

% Hung NoRing: 20*log10(H / H_noring(0.1Hz))
freq_noring = tables{3}.Frequency_Hz;
mag_noring_dB = 20*log10(tables{3}.Magnitude_Linear / H_ref(3));
phase_noring = tables{3}.Phase_deg - phase_ref(3);

fprintf('Normalization references:\n');
fprintf('  Hung:      H_ref = %.4f\n', H_ref(1));
fprintf('  NTU:       H_ref = %.4f\n', H_ref(2));
fprintf('  NoRing:    H_ref = %.4f\n', H_ref(3));
fprintf('\n');

%% Create Bode plot (DataOnly Bode style)
fig = figure('Position', [100, 100, 900, 720], 'Name', 'Three-Experiment Bode Comparison');

% Line style settings (match Bode_Hung_noring_DataOnly.png)
line_width = 3.5;
marker_size = 12;
log_ticks = 10.^(-1:3);

% --- Magnitude subplot ---
subplot(2, 1, 1);
hold on;

% Plot order: Hung → Hung NoRing → NTU
semilogx(freq_hung, mag_hung_dB, 'o-b', 'LineWidth', line_width, 'MarkerSize', marker_size, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', sprintf('Hung (H(0.1)=%.4f)', H_ref(1)));

semilogx(freq_noring, mag_noring_dB, 'd-', 'Color', [0 0.6 0], 'LineWidth', line_width, ...
    'MarkerSize', marker_size, 'MarkerFaceColor', 'none', ...
    'DisplayName', sprintf('Hung NoRing (H(0.1)=%.4f)', H_ref(3)));

semilogx(freq_ntu, mag_ntu_dB, 's-r', 'LineWidth', line_width, 'MarkerSize', marker_size, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', sprintf('NTU (H(0.1)=%.4f)', H_ref(2) * 7/5));

ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);

ax = gca;
set(ax, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
set(ax, 'XScale', 'log', 'XLim', [0.1, 2000], 'XTick', log_ticks);
ax.XAxis.LineWidth = 3;
ax.YAxis.LineWidth = 3;
box on;

% --- Phase subplot ---
subplot(2, 1, 2);
hold on;

% Plot order: Hung → Hung NoRing → NTU
semilogx(freq_hung, phase_hung, 'o-b', 'LineWidth', line_width, 'MarkerSize', marker_size, ...
    'MarkerFaceColor', 'none');

semilogx(freq_noring, phase_noring, 'd-', 'Color', [0 0.6 0], 'LineWidth', line_width, ...
    'MarkerSize', marker_size, 'MarkerFaceColor', 'none');

semilogx(freq_ntu, phase_ntu, 's-r', 'LineWidth', line_width, 'MarkerSize', marker_size, ...
    'MarkerFaceColor', 'none');

xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);

ax = gca;
set(ax, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
set(ax, 'XScale', 'log', 'XLim', [0.1, 2000], 'XTick', log_ticks);
ax.XAxis.LineWidth = 3;
ax.YAxis.LineWidth = 3;
box on;

%% Save figure
output_file = fullfile(script_root, 'Comparison_Three_Bode.png');
exportgraphics(fig, output_file, 'Resolution', 150);
fprintf('Figure saved: %s\n', output_file);

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  COMPLETE\n');
fprintf('========================================================================\n\n');
