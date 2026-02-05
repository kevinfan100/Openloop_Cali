%% ========================================================================
%  Hung vs NTU Bode Plot Comparison (NTU scaled by 7/5)
%  Compare measured frequency response data
%  NTU magnitude multiplied by 7/5 before normalization
% ========================================================================

clear; clc; close all;

%% Load Hung data
hung_csv = fullfile('Hung_tweezer', 'results', 'diagnostics', 'Raw_Bode_Data.csv');
if ~exist(hung_csv, 'file')
    hung_csv = fullfile('Hung_tweezer', 'results', 'diagnostics', 'Bode_Summary.csv');
end
hung_table = readtable(hung_csv);

hung_freq = hung_table.Frequency_Hz;
hung_mag = hung_table.Magnitude_Linear;
hung_phase_raw = hung_table.Phase_deg;

% Normalize magnitude by H(0.1 Hz)
[~, hung_min_idx] = min(hung_freq);
hung_H_ref = hung_mag(hung_min_idx);
hung_mag_norm = hung_mag / hung_H_ref;
hung_mag_dB = 20*log10(hung_mag_norm);

% Normalize phase (remove offset at lowest frequency)
hung_phase_offset = hung_phase_raw(hung_min_idx);
hung_phase = hung_phase_raw - hung_phase_offset;

fprintf('Hung: H(0.1 Hz) = %.4f [V/V], Phase offset = %.2f deg\n', hung_H_ref, hung_phase_offset);

%% Load NTU data and scale by 7/5
ntu_csv = fullfile('NTU_tweezer', 'results', 'diagnostics', 'Raw_Bode_Data.csv');
ntu_table = readtable(ntu_csv);

ntu_freq = ntu_table.Frequency_Hz;
ntu_mag_original = ntu_table.Magnitude_Linear;
ntu_phase_raw = ntu_table.Phase_deg;

% *** KEY CHANGE: Scale NTU magnitude by 7/5 ***
scaling_factor = 7/5;
ntu_mag_scaled = ntu_mag_original * scaling_factor;

fprintf('NTU:  Original H(0.1 Hz) = %.4f [V/V]\n', ntu_mag_original(1));
fprintf('      Scaled H(0.1 Hz) = %.4f [V/V] (× %.2f)\n', ntu_mag_scaled(1), scaling_factor);

% Normalize magnitude by scaled H(0.1 Hz)
[~, ntu_min_idx] = min(ntu_freq);
ntu_H_ref_scaled = ntu_mag_scaled(ntu_min_idx);
ntu_mag_norm = ntu_mag_scaled / ntu_H_ref_scaled;
ntu_mag_dB = 20*log10(ntu_mag_norm);

% Normalize phase (remove offset at lowest frequency)
ntu_phase_offset = ntu_phase_raw(ntu_min_idx);
ntu_phase = ntu_phase_raw - ntu_phase_offset;

fprintf('      Phase offset = %.2f deg\n', ntu_phase_offset);

%% Plot settings (Model_6_6 style)
freq_max = max([max(hung_freq); max(ntu_freq)]);
log_ticks = 10.^((-1:ceil(log10(freq_max))));
font_props = {'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2};
axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};

figure_size = [100, 100, 900, 720];
fig = figure('Name', 'Hung vs NTU Comparison (NTU scaled)', 'Position', figure_size);

%% Magnitude Plot
subplot(2, 1, 1);
hold on;

% Hung: blue
semilogx(hung_freq, hung_mag_dB, 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', sprintf('Hung (H(0.1 Hz)=%.4f)', hung_H_ref));

% NTU: red (scaled)
semilogx(ntu_freq, ntu_mag_dB, 's-r', 'LineWidth', 3.5, 'MarkerSize', 12, ...
    'MarkerFaceColor', 'none', ...
    'DisplayName', sprintf('NTU scaled (H(0.1 Hz)=%.4f)', ntu_H_ref_scaled));

ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);

set(gca, axis_props{:}, font_props{:});
y_min = min([min(hung_mag_dB); min(ntu_mag_dB)]) - 5;
ylim([y_min, 5]);

ax = gca;
ax.XAxis.LineWidth = 3;
ax.YAxis.LineWidth = 3;
box on;

%% Phase Plot
subplot(2, 1, 2);
hold on;

% Hung: blue
semilogx(hung_freq, hung_phase, 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, ...
    'MarkerFaceColor', 'none');

% NTU: red
semilogx(ntu_freq, ntu_phase, 's-r', 'LineWidth', 3.5, 'MarkerSize', 12, ...
    'MarkerFaceColor', 'none');

xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);

set(gca, axis_props{:}, font_props{:});
ylim([-180, 0]);

ax = gca;
ax.XAxis.LineWidth = 3;
ax.YAxis.LineWidth = 3;
box on;

%% Save figure
output_file = 'Comparison_Hung_NTU_Scaled_7_5.png';
exportgraphics(fig, output_file, 'Resolution', 150);
fprintf('\nScaled comparison plot saved: %s\n', output_file);
fprintf('Scaling factor applied to NTU: 7/5 = %.2f\n', scaling_factor);
