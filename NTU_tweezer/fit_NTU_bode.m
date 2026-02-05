%% ========================================================================
%  NTU_tweezer Transfer Function Fitting with Bode Plot
%  讀取診斷後的頻域數據，執行二階擬合，繪製 Model_6_6 樣式的波德圖
% ========================================================================
%
% Purpose:
%   1. 讀取 prepare_bode_data.m 產生的 .mat 文件
%   2. 執行二階轉移函數擬合：H(s) = b / (s² + a1·s + a2)
%   3. 繪製 Model_6_6_Continuous_Weighted.m 樣式的波德圖
%
% Input:
%   results/bode_data/NTU_bode_data_for_fitting.mat
%
% Output:
%   - Console: 擬合參數和品質指標
%   - Figure: 波德圖（Magnitude + Phase）
%
% Author: Claude Code
% Date: 2026-02-05

clear; clc; close all;

%% ========================================================================
%  SECTION 1: CONFIGURATION
% ========================================================================

fprintf('\n');
fprintf('========================================================================\n');
fprintf('  NTU_tweezer Transfer Function Fitting\n');
fprintf('========================================================================\n\n');

% --- Path Configuration ---
project_root = fileparts(mfilename('fullpath'));  % NTU_tweezer/
functions_path = fullfile(project_root, '..', 'functions');
addpath(functions_path);

% --- Input File ---
% 選項 1: 使用 CSV (包含全部 19 個頻率點)
input_file = fullfile(project_root, 'results', 'diagnostics', 'Raw_Bode_Data.csv');
use_csv = true;

% 選項 2: 使用 .mat (排除了 0.1 Hz 和 900 Hz)
% input_file = fullfile(project_root, 'results', 'bode_data', 'NTU_bode_data_for_fitting.mat');
% use_csv = false;

% --- Fitting Parameters ---
p_weight = 0.5;              % Weighting exponent
wc_Hz = 10;                 % Cutoff frequency [Hz]

% --- Plot Configuration (Model_6_6 style) ---
PLOT_FIGURE = true;          % Generate Bode plot
SAVE_FIGURE = true;         % Save to file
figure_size = [100, 100, 900, 720];  % Model_6_6 size

%% ========================================================================
%  SECTION 2: DATA LOADING
% ========================================================================

fprintf('Stage 1: Loading frequency domain data...\n');

if ~exist(input_file, 'file')
    error('Input file not found: %s', input_file);
end

if use_csv
    % Load from CSV (includes all 19 frequencies)
    fprintf('  Loading from CSV: %s\n', input_file);
    bode_table = readtable(input_file);

    % Extract data
    frequencies = bode_table.Frequency_Hz;            % [Hz]
    magnitudes_linear = bode_table.Magnitude_Linear;  % [V/V]
    phases_raw = bode_table.Phase_deg;                % [deg] (原始相位)
    thd_percent = bode_table.THD_percent;             % [%]

    % 【關鍵】相位正規化：減去最低頻的相位偏移
    [~, min_freq_idx] = min(frequencies);
    phase_offset = phases_raw(min_freq_idx);
    phases_normalized = phases_raw - phase_offset;

    fprintf('  Phase normalized: removed %.2f deg offset at %.1f Hz\n', ...
        phase_offset, frequencies(min_freq_idx));

    % 計算品質統計
    num_total = height(bode_table);
    num_good = sum(thd_percent < 10);

    fprintf('  Frequency points: %d (%.1f ~ %.1f Hz)\n', ...
        num_total, min(frequencies), max(frequencies));
    fprintf('  Data quality: %d good (THD<10%%), %d fair/poor\n', ...
        num_good, num_total - num_good);

    % 顯示 THD 統計
    fprintf('  THD: mean=%.2f%%, max=%.2f%%, min=%.2f%%\n', ...
        mean(thd_percent), max(thd_percent), min(thd_percent));

else
    % Load from .mat (excludes 0.1 Hz and 900 Hz)
    fprintf('  Loading from MAT: %s\n', input_file);
    loaded_data = load(input_file);
    bode_data = loaded_data.bode_data;

    fprintf('  Created: %s\n', char(bode_data.metadata.date_created));
    fprintf('  Frequency points: %d (valid: %d)\n', ...
        bode_data.metadata.num_total, bode_data.metadata.num_valid);

    % Extract data
    frequencies = bode_data.frequencies;                    % [Hz]
    magnitudes_linear = bode_data.magnitudes_linear;        % [V/V]
    phases_normalized = bode_data.phases_normalized;        % [deg]

    % 顯示品質統計
    num_total = length(frequencies);
    num_good = sum(bode_data.quality_flags);
    fprintf('  Using ALL %d data points (%.1f ~ %.1f Hz)\n', ...
        num_total, min(frequencies), max(frequencies));
    fprintf('  Data quality: %d good (THD<10%%), %d fair/poor\n', ...
        num_good, num_total - num_good);
    fprintf('  Excluded frequencies: %s Hz\n', ...
        mat2str(bode_data.metadata.excluded_frequencies));
end

% Phase conversion: deg -> rad
phi_k = phases_normalized * pi / 180;  % [rad]

% Angular frequency: Hz -> rad/s
w_k = frequencies * 2 * pi;  % [rad/s]

fprintf('\nStage 1 complete.\n\n');

%% ========================================================================
%  SECTION 3: TRANSFER FUNCTION FITTING
% ========================================================================

fprintf('Stage 2: Transfer Function Fitting...\n');
fprintf('  Model: H(s) = b / (s² + a1·s + a2)\n');
fprintf('  Weighting: w(ω) = 1/(1+(ω²/ωc²))^p\n');
fprintf('  Parameters: p = %.2f, wc = %.2f Hz\n', p_weight, wc_Hz);

% Convert cutoff frequency
wc_rad = wc_Hz * 2 * pi;

% Call fitting function
fprintf('\n  Fitting in progress...\n');
[a1, a2, b, H_fitted] = fit_single_tf(magnitudes_linear, phi_k, w_k, ...
    'p', p_weight, 'wc_rad', wc_rad, 'Verbose', true);

% Compute derived parameters
dc_gain = b / a2;
wn = sqrt(a2);
wn_Hz = wn / (2 * pi);
zeta = a1 / (2 * wn);

% Compute poles
discriminant = a1^2 - 4*a2;
if discriminant >= 0
    % Real poles
    pole1 = (-a1 + sqrt(discriminant)) / 2;
    pole2 = (-a1 - sqrt(discriminant)) / 2;
    poles = [pole1; pole2];
    pole_type = 'real';
else
    % Complex poles
    real_part = -a1 / 2;
    imag_part = sqrt(-discriminant) / 2;
    poles = [real_part + 1j*imag_part; real_part - 1j*imag_part];
    pole_type = 'complex';
end

% Compute fitting quality
mag_fitted = abs(H_fitted);
phase_fitted = angle(H_fitted) * 180 / pi;  % [rad -> deg]

% R² (magnitude)
SS_res_mag = sum((magnitudes_linear - mag_fitted).^2);
SS_tot_mag = sum((magnitudes_linear - mean(magnitudes_linear)).^2);
R_squared = 1 - SS_res_mag / SS_tot_mag;

% RMSE
RMSE_mag = sqrt(mean((magnitudes_linear - mag_fitted).^2));
RMSE_phase = sqrt(mean((phases_normalized - phase_fitted).^2));

% Output results
fprintf('\n  === Fitted Parameters (Standard Form) ===\n');
fprintf('    H(s) = b / (s² + a1·s + a2)\n');
fprintf('    a1:           %12.6f rad/s\n', a1);
fprintf('    a2:           %12.6f rad²/s²\n', a2);
fprintf('    b:            %12.6f\n', b);
fprintf('    DC Gain:      %12.6f [V/V]\n', dc_gain);
fprintf('    wn:           %12.6f rad/s (%.2f Hz)\n', wn, wn_Hz);
fprintf('    zeta:         %12.6f\n', zeta);

fprintf('\n  === Pole Locations ===\n');
if strcmp(pole_type, 'real')
    fprintf('    Pole type: Real (overdamped)\n');
    fprintf('    p1 = %12.6f rad/s (%.2f Hz)\n', poles(1), poles(1)/(2*pi));
    fprintf('    p2 = %12.6f rad/s (%.2f Hz)\n', poles(2), poles(2)/(2*pi));

    % Factored form with real poles
    fprintf('\n  === Factored Form (Real Poles) ===\n');
    fprintf('    H(s) = %.6f / [(s - (%.6f)) × (s - (%.6f))]\n', b, poles(1), poles(2));
    fprintf('    H(s) = %.6f / [(s + %.6f) × (s + %.6f)]\n', b, -poles(1), -poles(2));
else
    fprintf('    Pole type: Complex conjugate pair (underdamped)\n');
    sigma = real(poles(1));
    omega_d = imag(poles(1));
    pole_magnitude = abs(poles(1));
    pole_angle = angle(poles(1)) * 180 / pi;

    fprintf('    p1 = %.6f + %.6fj rad/s\n', sigma, omega_d);
    fprintf('    p2 = %.6f - %.6fj rad/s (conjugate)\n', sigma, omega_d);
    fprintf('\n    Polar form:\n');
    fprintf('      |p| = %.6f rad/s (%.2f Hz)\n', pole_magnitude, pole_magnitude/(2*pi));
    fprintf('      ∠p  = %.2f°\n', pole_angle);
    fprintf('      σ   = %.6f rad/s (real part)\n', sigma);
    fprintf('      ωd  = %.6f rad/s (imaginary part, damped frequency)\n', omega_d);

    % Factored form with complex poles
    fprintf('\n  === Factored Form (Complex Poles) ===\n');
    fprintf('    H(s) = %.6f / [(s - (%.6f + %.6fj)) × (s - (%.6f - %.6fj))]\n', ...
        b, sigma, omega_d, sigma, omega_d);
    fprintf('    H(s) = %.6f / [(s + %.6f - %.6fj) × (s + %.6f + %.6fj)]\n', ...
        b, -sigma, -omega_d, -sigma, -omega_d);
    fprintf('    H(s) = %.6f / [s² - 2(%.6f)s + %.6f]\n', ...
        b, sigma, sigma^2 + omega_d^2);
end

fprintf('\n  === Fitting Quality ===\n');
fprintf('    R²:           %12.6f\n', R_squared);
fprintf('    RMSE (mag):   %12.6e\n', RMSE_mag);
fprintf('    RMSE (phase): %12.6f deg\n', RMSE_phase);

% Validation
fprintf('\n  === Validation ===\n');
if R_squared > 0.85
    fprintf('    R² > 0.85: PASS\n');
else
    fprintf('    R² = %.4f: WARNING (below 0.85)\n', R_squared);
end

if all(real(poles) < 0)
    fprintf('    Poles in LHP: PASS (stable system)\n');
else
    fprintf('    WARNING: Poles not in left half-plane\n');
end

fprintf('\nStage 2 complete.\n\n');

%% ========================================================================
%  SECTION 4: BODE PLOT VISUALIZATION (Model_6_6 Style)
% ========================================================================

if PLOT_FIGURE
    fprintf('Stage 3: Generating Bode plot (Model_6_6 style)...\n');

    % --- Generate smooth model curve ---
    freq_max = max(frequencies);
    freq_smooth = logspace(log10(0.1), log10(freq_max), 200);
    s_smooth = 1j * 2 * pi * freq_smooth;
    H_model_smooth = b ./ (s_smooth.^2 + a1*s_smooth + a2);

    % --- Normalization references ---
    % For Tab 1 (Model + Measured): use fitted DC gain for comparison
    % For Tab 2 (Measured Only): use measured H(0.1 Hz) as reference
    [~, min_freq_idx] = min(frequencies);
    H_ref_measured = magnitudes_linear(min_freq_idx);  % H(0.1 Hz) measured value
    freq_ref = frequencies(min_freq_idx);               % Reference frequency (0.1 Hz)

    % Tab 1: Normalize by fitted DC gain (for model-data comparison)
    H_model_norm_tab1 = H_model_smooth / dc_gain;
    h_k_norm_tab1 = magnitudes_linear / dc_gain;
    h_db_norm_tab1 = 20*log10(h_k_norm_tab1);

    % Tab 2: Normalize by measured H(0.1 Hz) (pure experimental data)
    h_k_norm_tab2 = magnitudes_linear / H_ref_measured;
    h_db_norm_tab2 = 20*log10(h_k_norm_tab2);

    % --- Model_6_6 plot settings ---
    log_ticks = 10.^((-1:ceil(log10(freq_max))));
    font_props = {'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2};
    axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};

    % --- Create tabbed figure ---
    fig = figure('Name', 'Bode Plot', 'Position', figure_size);
    tabgp = uitabgroup(fig);

    % ===================== Tab 1: Model + Measured =====================
    tab1 = uitab(tabgp, 'Title', 'Model + Measured');

    % === Magnitude Plot ===
    subplot(2, 1, 1, 'Parent', tab1);
    hold on;

    % Model curve: black thick line
    semilogx(freq_smooth, 20*log10(abs(H_model_norm_tab1)), 'k-', 'LineWidth', 3, ...
        'DisplayName', 'Model');

    % Measured data: blue open circles (normalized by fitted DC gain)
    semilogx(frequencies, h_db_norm_tab1, 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, ...
        'MarkerFaceColor', 'none', ...
        'DisplayName', sprintf('Measured (H(0)=%.4f)', dc_gain));

    ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
    legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);

    set(gca, axis_props{:}, font_props{:});
    y_min = min(real(h_db_norm_tab1)) - 5;  % 確保是實數
    ylim([y_min, 5]);

    ax = gca;
    ax.XAxis.LineWidth = 3;
    ax.YAxis.LineWidth = 3;
    box on;

    % === Phase Plot ===
    subplot(2, 1, 2, 'Parent', tab1);
    hold on;

    % Measured phase: blue open circles
    semilogx(frequencies, phases_normalized, 'o-b', 'LineWidth', 3.5, ...
        'MarkerSize', 12, 'MarkerFaceColor', 'none');

    % Model phase: black thick line
    H_model_phase = angle(H_model_smooth) * 180/pi;
    semilogx(freq_smooth, H_model_phase, 'k-', 'LineWidth', 3);

    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);

    set(gca, axis_props{:}, font_props{:});
    ylim([-180, 0]);

    ax = gca;
    ax.XAxis.LineWidth = 3;
    ax.YAxis.LineWidth = 3;
    box on;

    % === Title ===
    sgtitle(sprintf('H(s), p=%.1f, \\omega_c=%.1f Hz', p_weight, wc_Hz), ...
        'FontWeight', 'bold', 'FontSize', 24);

    fprintf('  Bode plot generated.\n');

    if SAVE_FIGURE
        output_file = fullfile(project_root, 'results', 'figures', 'Bode_NTU_Model66_style.png');
        exportgraphics(tab1, output_file, 'Resolution', 150);
        fprintf('  Figure saved: %s\n', output_file);
    end

    fprintf('\nStage 3 complete.\n\n');

    % ===================== Tab 2: Measured Data Only =====================
    fprintf('Stage 4: Generating data-only Bode plot...\n');

    tab2 = uitab(tabgp, 'Title', 'Measured Data Only');

    % === Magnitude Plot ===
    subplot(2, 1, 1, 'Parent', tab2);
    hold on;

    % Measured data only (normalized by measured H(0.1 Hz))
    semilogx(frequencies, h_db_norm_tab2, 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, ...
        'MarkerFaceColor', 'none', ...
        'DisplayName', sprintf('Measured (H(%.1f Hz)=%.4f)', freq_ref, H_ref_measured));

    ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
    legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);

    set(gca, axis_props{:}, font_props{:});
    y_min2 = min(real(h_db_norm_tab2)) - 5;
    ylim([y_min2, 5]);

    ax = gca;
    ax.XAxis.LineWidth = 3;
    ax.YAxis.LineWidth = 3;
    box on;

    % === Phase Plot ===
    subplot(2, 1, 2, 'Parent', tab2);
    hold on;

    semilogx(frequencies, phases_normalized, 'o-b', 'LineWidth', 3.5, ...
        'MarkerSize', 12, 'MarkerFaceColor', 'none');

    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);

    set(gca, axis_props{:}, font_props{:});
    ylim([-180, 0]);

    ax = gca;
    ax.XAxis.LineWidth = 3;
    ax.YAxis.LineWidth = 3;
    box on;

    % Save Tab 2 as separate image
    fig_dir = fullfile(project_root, 'results', 'figures');
    if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end
    tabgp.SelectedTab = tab2;
    drawnow;
    output_file2 = fullfile(fig_dir, 'Bode_NTU_DataOnly.png');
    exportgraphics(tab2, output_file2, 'Resolution', 150);
    fprintf('  Data-only Bode plot saved: %s\n', output_file2);
    tabgp.SelectedTab = tab1;

    fprintf('\nStage 4 complete.\n\n');
end

%% ========================================================================
%  Summary
% ========================================================================

fprintf('========================================================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('========================================================================\n\n');

fprintf('Transfer Function (Standard Form):\n');
fprintf('  H(s) = %.6f / (s² + %.6f·s + %.6f)\n\n', b, a1, a2);

if strcmp(pole_type, 'real')
    fprintf('Transfer Function (Factored Form - Real Poles):\n');
    fprintf('  H(s) = %.6f / [(s + %.6f) × (s + %.6f)]\n\n', b, -poles(1), -poles(2));
else
    sigma = real(poles(1));
    omega_d = imag(poles(1));
    fprintf('Transfer Function (Factored Form - Complex Poles):\n');
    fprintf('  H(s) = %.6f / [(s + %.6f - %.6fj) × (s + %.6f + %.6fj)]\n\n', ...
        b, -sigma, -omega_d, -sigma, -omega_d);
end

fprintf('Key Parameters:\n');
fprintf('  DC Gain:           %.6f [V/V]\n', dc_gain);
fprintf('  Natural Frequency: %.2f rad/s (%.2f Hz)\n', wn, wn_Hz);
fprintf('  Damping Ratio:     %.6f\n', zeta);
fprintf('  R²:                %.6f\n', R_squared);

fprintf('\nPole Locations:\n');
if strcmp(pole_type, 'real')
    fprintf('  Type: Real (overdamped)\n');
    fprintf('  p1 = %.2f rad/s (%.2f Hz)\n', poles(1), poles(1)/(2*pi));
    fprintf('  p2 = %.2f rad/s (%.2f Hz)\n', poles(2), poles(2)/(2*pi));
else
    sigma = real(poles(1));
    omega_d = imag(poles(1));
    pole_magnitude = abs(poles(1));
    fprintf('  Type: Complex conjugate pair (underdamped)\n');
    fprintf('  p1,2 = %.2f ± %.2fj rad/s\n', sigma, omega_d);
    fprintf('  |p|  = %.2f rad/s (%.2f Hz)\n', pole_magnitude, pole_magnitude/(2*pi));
    fprintf('  σ    = %.2f rad/s (real part, decay rate)\n', sigma);
    fprintf('  ωd   = %.2f rad/s (imaginary part, damped frequency)\n', omega_d);
end

fprintf('\n');
