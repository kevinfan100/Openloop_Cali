%% ========================================================================
%  HUNG_TWEEZER (NO RING) DATA QUALITY DIAGNOSTIC - SUMMARY ONLY
%  快速診斷腳本：只生成總覽圖，不產生個別圖片
% ========================================================================
%
% Purpose:
%   快速執行所有頻率點診斷，只生成一張總覽 Dashboard
%   適合日常檢查使用，避免產生大量圖片檔案
%
% Author: Claude Code
% Date: 2026-02-06

clear; close all; clc;

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  HUNG (NO RING) QUICK DIAGNOSTIC (SUMMARY ONLY)\n');
fprintf('========================================================================\n\n');

%% Configuration
EXCLUDE_FREQUENCIES = [];  % 先不排除，跑完再看
RELATIVE_THRESHOLD_PERCENT = 0.2;   % 相對門檻
OUTPUT_FOLDER = fullfile(fileparts(mfilename('fullpath')), 'results_noring', 'diagnostics');

%% Load configuration
config = Hung_noring_config();
addpath(config.functions_path);

% Create output folder
if ~exist(OUTPUT_FOLDER, 'dir')
    mkdir(OUTPUT_FOLDER);
end

%% Determine files to process
exclude_mask = false(size(config.expected_frequencies));
for i = 1:length(EXCLUDE_FREQUENCIES)
    exclude_mask = exclude_mask | (abs(config.expected_frequencies - EXCLUDE_FREQUENCIES(i)) < 0.01);
end

valid_indices = find(~exclude_mask);
file_list = config.data_files(valid_indices);
freq_list = config.expected_frequencies(valid_indices);

fprintf('Processing %d frequency points...\n\n', length(freq_list));

%% Initialize storage
bode_table = table();

%% Process each file (no plots)
for file_idx = 1:length(file_list)
    filename = fullfile(config.data_folder, file_list{file_idx});
    target_freq = freq_list(file_idx);

    fprintf('[%d/%d] %.1f Hz ... ', file_idx, length(file_list), target_freq);

    try
        % Read data
        data = read_hsdata(filename);
        da_volt = (double(data.da) - 32768) * (20.0 / 65536);
        vm = data.vm;
        fs = data.sampling_rate;
        excite_ch = data.channel;
        vm_ch2 = vm(:, excite_ch);
        da_ch2 = da_volt(:, excite_ch);

        % Steady-state detection
        steady_info = detect_steady_state_relative(...
            vm_ch2, target_freq, fs, ...
            'RelativeThreshold', RELATIVE_THRESHOLD_PERCENT / 100, ...
            'ConsecutivePeriods', 3, 'CheckPoints', 25, 'Verbose', false);

        if steady_info.index <= 0
            fprintf('FAILED (no steady-state)\n');
            continue;
        end

        % FFT
        period_samples = steady_info.period_samples;
        steady_start = steady_info.index;
        available_samples = length(vm_ch2) - steady_start + 1;
        available_periods = floor(available_samples / period_samples);
        fft_length = available_periods * period_samples;
        vm_steady = vm_ch2(steady_start : steady_start + fft_length - 1);
        da_steady = da_ch2(steady_start : steady_start + fft_length - 1);

        VM_fft = fft(vm_steady);
        DA_fft = fft(da_steady);
        N = length(vm_steady);
        freq_axis = (0:N-1) * fs / N;

        % Find fundamental
        [~, fundamental_bin] = min(abs(freq_axis - target_freq));
        H_complex = VM_fft(fundamental_bin) / DA_fft(fundamental_bin);
        H_magnitude_linear = abs(H_complex);
        H_magnitude_dB = 20 * log10(H_magnitude_linear);
        H_phase_deg = angle(H_complex) * 180 / pi;

        % Calculate THD (simplified)
        half_N = floor(N/2) + 1;
        VM_magnitude = abs(VM_fft(1:half_N)) / N * 2;
        VM_magnitude(1) = VM_magnitude(1) / 2;
        fundamental_amplitude = VM_magnitude(fundamental_bin);

        harmonic_sum_sq = 0;
        for h = 2:10
            harmonic_freq = target_freq * h;
            if harmonic_freq > fs / 2, break; end
            [~, harmonic_bin] = min(abs(freq_axis(1:half_N) - harmonic_freq));
            harmonic_sum_sq = harmonic_sum_sq + VM_magnitude(harmonic_bin)^2;
        end
        THD_percent = sqrt(harmonic_sum_sq) / fundamental_amplitude * 100;

        % Store results
        new_row = table(target_freq, H_magnitude_linear, H_magnitude_dB, H_phase_deg, THD_percent, ...
            'VariableNames', {'Frequency_Hz', 'Magnitude_Linear', 'Magnitude_dB', 'Phase_deg', 'THD_percent'});
        bode_table = [bode_table; new_row];

        fprintf('OK (THD=%.2f%%)\n', THD_percent);

    catch ME
        fprintf('ERROR: %s\n', ME.message);
    end
end

fprintf('\n');

%% Phase normalization
if height(bode_table) > 0
    phase_offset = bode_table.Phase_deg(1);
    bode_table.Phase_normalized = bode_table.Phase_deg - phase_offset;
end

%% Generate Dashboard
fprintf('Generating dashboard...\n');

fig = figure('Position', [50, 50, 1600, 900], 'Name', 'Diagnostic Dashboard', 'Visible', 'off');

% Subplot 1: Bode Magnitude
subplot(2,2,1);
semilogx(bode_table.Frequency_Hz, bode_table.Magnitude_dB, 'bo-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
xlabel('Frequency [Hz]', 'FontSize', 11);
ylabel('Magnitude [dB]', 'FontSize', 11);
title('Bode Magnitude (Raw)', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
xlim([0.05, 5000]);

% Subplot 2: Bode Phase
subplot(2,2,2);
semilogx(bode_table.Frequency_Hz, bode_table.Phase_deg, 'ro-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
xlabel('Frequency [Hz]', 'FontSize', 11);
ylabel('Phase [deg]', 'FontSize', 11);
title('Bode Phase (Raw)', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
xlim([0.05, 5000]);

% Subplot 3: THD Distribution
subplot(2,2,3);
bar(1:height(bode_table), bode_table.THD_percent, 'FaceColor', [0.3 0.6 0.9]);
hold on;
plot([0, height(bode_table)+1], [1, 1], 'g--', 'LineWidth', 2);
plot([0, height(bode_table)+1], [5, 5], 'y--', 'LineWidth', 2);
plot([0, height(bode_table)+1], [10, 10], 'r--', 'LineWidth', 2);
xlabel('Frequency Index', 'FontSize', 11);
ylabel('THD [%]', 'FontSize', 11);
title('Total Harmonic Distortion', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'XTick', 1:height(bode_table));
set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%.0f', x), bode_table.Frequency_Hz, 'UniformOutput', false));
xtickangle(45);
legend('THD', 'Excellent (1%)', 'Good (5%)', 'Fair (10%)', 'Location', 'northwest', 'FontSize', 9);
grid on;
ylim([0, min(max(bode_table.THD_percent)*1.2, 15)]);

% Subplot 4: Quality Summary
subplot(2,2,4);
axis off;

excellent_count = sum(bode_table.THD_percent < 1);
good_count = sum(bode_table.THD_percent >= 1 & bode_table.THD_percent < 5);
fair_count = sum(bode_table.THD_percent >= 5 & bode_table.THD_percent < 10);
poor_count = sum(bode_table.THD_percent >= 10);

avg_thd = mean(bode_table.THD_percent);
max_thd = max(bode_table.THD_percent);

if avg_thd < 1 && max_thd < 2
    overall_grade = 'A - Excellent';
elseif avg_thd < 3 && max_thd < 5
    overall_grade = 'B - Good';
elseif avg_thd < 5 && max_thd < 10
    overall_grade = 'C - Fair';
else
    overall_grade = 'D - Poor';
end

summary_text = {
    '\bf\fontsize{13}Data Quality Summary (HUNG NO RING)'; '';
    sprintf('\\fontsize{11}Total Frequencies: %d', height(bode_table)); '';
    '\bf\fontsize{11}THD Distribution:';
    sprintf('  Excellent (<1%%):  %d  (%.0f%%)', excellent_count, excellent_count/height(bode_table)*100);
    sprintf('  Good (1-5%%):      %d  (%.0f%%)', good_count, good_count/height(bode_table)*100);
    sprintf('  Fair (5-10%%):     %d  (%.0f%%)', fair_count, fair_count/height(bode_table)*100);
    sprintf('  Poor (>10%%):      %d  (%.0f%%)', poor_count, poor_count/height(bode_table)*100); '';
    '\bf\fontsize{11}THD Statistics:';
    sprintf('  Mean:   %.2f%%', avg_thd);
    sprintf('  Median: %.2f%%', median(bode_table.THD_percent));
    sprintf('  Max:    %.2f%%', max_thd);
    sprintf('  Min:    %.2f%%', min(bode_table.THD_percent)); '';
    '\bf\fontsize{11}Overall Grade:';
    sprintf('  \\color{blue}%s', overall_grade); '';
    '\bf\fontsize{11}Excluded Frequencies:';
    sprintf('  %s', mat2str(EXCLUDE_FREQUENCIES))
};

text(0.05, 0.95, summary_text, 'VerticalAlignment', 'top', 'FontSize', 10, ...
    'FontName', 'FixedWidth', 'Interpreter', 'tex');

% Save dashboard
sgtitle('HUNG (NO RING) - Diagnostic Dashboard', 'FontWeight', 'bold', 'FontSize', 14);

saveas(fig, fullfile(OUTPUT_FOLDER, 'Dashboard_Summary.png'));
fprintf('Dashboard saved: %s\n', fullfile(OUTPUT_FOLDER, 'Dashboard_Summary.png'));

% Save CSV
csv_filename = fullfile(OUTPUT_FOLDER, 'Raw_Bode_Data.csv');
writetable(bode_table, csv_filename);
fprintf('Data table saved: %s\n', csv_filename);

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  DIAGNOSTIC COMPLETE\n');
fprintf('========================================================================\n');
fprintf('\nSummary:\n');
fprintf('  Processed: %d frequencies\n', height(bode_table));
fprintf('  Average THD: %.2f%%\n', avg_thd);
fprintf('  Overall Grade: %s\n', overall_grade);
fprintf('\n');
fprintf('View dashboard: open(''%s'')\n', fullfile(OUTPUT_FOLDER, 'Dashboard_Summary.png'));
fprintf('\n');
