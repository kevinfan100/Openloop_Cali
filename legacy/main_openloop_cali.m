%% MAIN_OPENLOOP_CALI - 開環校準主腳本
%
% 完整自動化流程：
%   Stage 1: 讀取 .dat 檔案 → FFT 分析 → 輸出 P1~P6.m
%   Stage 2: MIMO 轉移函數擬合 + ZOH 離散化
%   Stage 3: 輸出 LaTeX、MAT、圖表
%
% 使用方式:
%   直接執行此腳本，確保 raw_data/ 目錄下有 P1~P6 子目錄
%
% 版本: 2.0 (Pure MATLAB)
% 日期: 2026-01-26

clear; clc; close all;

%% ========================================================================
%  SECTION 1: 配置參數
% ========================================================================

fprintf('=== Openloop Calibration Pipeline ===\n');
fprintf('Version: 2.0 (Pure MATLAB)\n');
fprintf('Start time: %s\n\n', datestr(now));

% --- 路徑配置 ---
PROJECT_ROOT = fileparts(mfilename('fullpath'));
addpath(fullfile(PROJECT_ROOT, 'functions'));

RAW_DATA_DIR = fullfile(PROJECT_ROOT, 'raw_data');
RESULTS_DIR = fullfile(PROJECT_ROOT, 'results');
BODE_DATA_DIR = fullfile(RESULTS_DIR, 'bode_data');
FIGURES_DIR = fullfile(RESULTS_DIR, 'figures');
REPORTS_DIR = fullfile(RESULTS_DIR, 'reports');

% --- 取樣頻率配置 ---
SAMPLING_RATE = 100000;              % 預設取樣頻率 [Hz]
AUTO_DETECT_SAMPLING_RATE = true;    % 從 V6+ header 自動讀取

% --- 壞點修復配置 (100kHz 專用) ---
BAD_POINT_INTERVAL = 10000;          % 壞點間隔
INTERPOLATION_METHOD = 'spline';     % 插值方法: 'linear'|'spline'|'pchip'|'makima'
ENABLE_BAD_POINT_REPAIR = true;      % 啟用壞點修復

% --- 穩態檢測配置 ---
STABILITY_THRESHOLD = 2e-3;          % 穩態閾值 [V]
CONSECUTIVE_PERIODS = 3;             % 連續週期數

% --- 擬合參數配置 ---
P_WEIGHT = 0.5;                      % 加權指數
WC_HZ = 0.1;                         % 截止頻率 [Hz]

% --- 離散化配置 ---
T_SAMPLE = 1e-5;                     % 取樣時間 [s] (100 kHz)

% --- 放大器增益矩陣 (固定值) ---
K_A_DIAG = [0.3618, 0.3614, 0.3536, 0.3532, 0.3573, 0.3610];

% --- 輸出控制 ---
ENABLE_STAGE1 = true;                % Stage 1: .dat → FFT → P*.m
ENABLE_STAGE2 = true;                % Stage 2: MIMO 擬合
ENABLE_STAGE3 = true;                % Stage 3: 輸出

PLOT_BODE = true;                    % 繪製波德圖
PLOT_COMPARISON = true;              % 繪製對比圖
SAVE_FIGURES = true;                 % 保存圖片
EXPORT_LATEX = true;                 % 輸出 LaTeX
EXPORT_MAT = true;                   % 輸出 MAT

% --- 批次處理 36 通道獨立擬合 ---
ENABLE_ONE_CURVE_BATCH = true;       % 執行 36 通道獨立擬合

%% ========================================================================
%  SECTION 2: 初始化和驗證
% ========================================================================

fprintf('SECTION 2: Initialization\n');

% 建立輸出目錄
dirs_to_create = {RESULTS_DIR, BODE_DATA_DIR, FIGURES_DIR, REPORTS_DIR};
for i = 1:length(dirs_to_create)
    if ~exist(dirs_to_create{i}, 'dir')
        mkdir(dirs_to_create{i});
        fprintf('  Created: %s\n', dirs_to_create{i});
    end
end

% 驗證原始數據目錄
if ~exist(RAW_DATA_DIR, 'dir')
    warning('Raw data directory not found: %s', RAW_DATA_DIR);
    warning('Stage 1 will be skipped. Using existing P1~P6.m files if available.');
    ENABLE_STAGE1 = false;
end

% 初始化儲存變數
num_channels = 6;
num_files = 6;
frequencies_all = cell(num_files, 1);

fprintf('  Configuration complete.\n\n');

%% ========================================================================
%  SECTION 3: Stage 1 - 讀取 .dat 檔案並執行 FFT 分析
% ========================================================================

if ENABLE_STAGE1
    fprintf('SECTION 3: Stage 1 - Raw Data Processing\n');

    for file_idx = 1:num_files
        excite_ch = file_idx;
        folder_name = sprintf('P%d', excite_ch);
        folder_path = fullfile(RAW_DATA_DIR, folder_name);

        fprintf('\n--- Processing %s ---\n', folder_name);

        if ~exist(folder_path, 'dir')
            warning('Folder not found: %s, skipping.', folder_path);
            continue;
        end

        % 找出所有 .dat 檔案
        dat_files = dir(fullfile(folder_path, '*.dat'));
        if isempty(dat_files)
            warning('No .dat files in %s, skipping.', folder_path);
            continue;
        end

        % 收集所有頻率點的數據
        freq_list = [];
        mag_list = [];
        phase_list = [];

        for dat_idx = 1:length(dat_files)
            dat_path = fullfile(folder_path, dat_files(dat_idx).name);
            fprintf('  Reading: %s\n', dat_files(dat_idx).name);

            try
                % 讀取二進制數據
                data = read_hsdata(dat_path, 'Verbose', false);

                % 取得取樣頻率
                if AUTO_DETECT_SAMPLING_RATE && isfield(data, 'sampling_rate') && data.sampling_rate > 0
                    sampling_rate = data.sampling_rate;
                else
                    sampling_rate = SAMPLING_RATE;
                end

                % 提取 VM 和 DA 數據
                vm_data = data.vm;
                da_data = data.da;

                % 壞點修復 (100kHz 時)
                if ENABLE_BAD_POINT_REPAIR && sampling_rate >= 100000
                    [vm_clean, da_clean] = repair_bad_points(vm_data, da_data, ...
                        'BadPointInterval', BAD_POINT_INTERVAL, ...
                        'Method', INTERPOLATION_METHOD, ...
                        'Verbose', false);
                else
                    vm_clean = vm_data;
                    da_clean = da_data;
                end

                % 檢測激勵通道和頻率
                [detected_ch, excite_freq] = detect_excitation(da_clean, sampling_rate, ...
                    'Verbose', false);

                if detected_ch ~= excite_ch
                    warning('Detected excitation channel (%d) differs from expected (%d)', ...
                            detected_ch, excite_ch);
                end

                % 檢測穩態
                steady_info = detect_steady_state(vm_clean, sampling_rate, excite_freq, ...
                    'Threshold', STABILITY_THRESHOLD, ...
                    'ConsecutivePeriods', CONSECUTIVE_PERIODS, ...
                    'Verbose', false);

                % 執行 FFT
                [magnitudes, phases, ~] = perform_fft(vm_clean, da_clean, ...
                    steady_info, excite_ch, excite_freq, sampling_rate, ...
                    'Mode', 'full', ...
                    'Verbose', false);

                % 儲存結果
                freq_list = [freq_list; excite_freq];
                mag_list = [mag_list, magnitudes];
                phase_list = [phase_list, phases];

                fprintf('    Freq: %.2f Hz, Mag[%d]: %.4f\n', excite_freq, excite_ch, magnitudes(excite_ch));

            catch ME
                warning('Error processing %s: %s', dat_files(dat_idx).name, ME.message);
                continue;
            end
        end

        % 排序並保存
        if ~isempty(freq_list)
            [freq_sorted, sort_idx] = sort(freq_list);
            mag_sorted = mag_list(:, sort_idx);
            phase_sorted = phase_list(:, sort_idx);

            % 相位正規化 (移除最低頻偏移)
            [~, phase_norm] = normalize_data(mag_sorted, phase_sorted, freq_sorted, ...
                'RemovePhaseOffset', true, ...
                'NormalizeMagnitude', false, ...
                'Verbose', false);

            % 儲存數據
            output_path = fullfile(BODE_DATA_DIR, sprintf('P%d.m', excite_ch));
            save_bode_data(output_path, freq_sorted, mag_sorted, phase_norm, excite_ch, ...
                'Verbose', true);

            frequencies_all{file_idx} = freq_sorted;
        end
    end

    fprintf('\n  Stage 1 complete.\n\n');

else
    fprintf('SECTION 3: Stage 1 SKIPPED (ENABLE_STAGE1 = false)\n\n');
end

%% ========================================================================
%  SECTION 4: Stage 2 - MIMO 轉移函數擬合
% ========================================================================

if ENABLE_STAGE2
    fprintf('SECTION 4: Stage 2 - Transfer Function Fitting\n');

    % --- 載入數據 ---
    fprintf('  Loading Bode data from P1~P6.m...\n');

    % 嘗試從 BODE_DATA_DIR 載入，否則從當前目錄
    H_mag = [];
    H_phase = [];
    W = [];

    for file_idx = 1:num_files
        script_path = fullfile(BODE_DATA_DIR, sprintf('P%d.m', file_idx));

        if ~exist(script_path, 'file')
            % 嘗試當前目錄
            script_path = fullfile(PROJECT_ROOT, sprintf('P%d.m', file_idx));
        end

        if exist(script_path, 'file')
            run(script_path);

            if isempty(W)
                W = frequencies;
                num_freq = length(W);
                H_mag = zeros(num_channels, num_files, num_freq);
                H_phase = zeros(num_channels, num_files, num_freq);
            end

            H_mag(:, file_idx, :) = magnitudes_linear;
            H_phase(:, file_idx, :) = phases_processed;

            clear frequencies magnitudes_linear phases_processed
        else
            error('Cannot find P%d.m in %s or %s', file_idx, BODE_DATA_DIR, PROJECT_ROOT);
        end
    end

    fprintf('    Loaded: %d files, freq range %.2f ~ %.2f Hz\n', num_files, min(W), max(W));

    % --- 相位偏移移除 ---
    fprintf('  Removing phase offset at lowest frequency...\n');
    [~, H_phase_norm] = normalize_data(H_mag, H_phase, W, ...
        'RemovePhaseOffset', true, ...
        'NormalizeMagnitude', false, ...
        'Verbose', false);

    % --- 批次 36 通道獨立擬合 (可選) ---
    if ENABLE_ONE_CURVE_BATCH
        fprintf('  Batch fitting 36 individual transfer functions...\n');

        one_curve_results = struct();
        one_curve_results.a1_matrix = zeros(6, 6);
        one_curve_results.a2_matrix = zeros(6, 6);
        one_curve_results.b_matrix = zeros(6, 6);

        w_k = W(:) * 2 * pi;
        wc_rad = WC_HZ * 2 * pi;

        for i = 1:6
            for j = 1:6
                h_k = squeeze(H_mag(i, j, :));
                phi_k = squeeze(H_phase_norm(i, j, :)) * pi / 180;

                [a1_ij, a2_ij, b_ij] = fit_single_tf(h_k, phi_k, w_k, ...
                    'p', P_WEIGHT, 'wc_rad', wc_rad, 'Verbose', false);

                one_curve_results.a1_matrix(i, j) = a1_ij;
                one_curve_results.a2_matrix(i, j) = a2_ij;
                one_curve_results.b_matrix(i, j) = b_ij;
            end
        end

        one_curve_results.meta = struct(...
            'date', datestr(now), ...
            'p', P_WEIGHT, ...
            'wc_Hz', WC_HZ, ...
            'frequencies', W, ...
            'description', '36-channel individual transfer functions' ...
        );

        fprintf('    36 individual TFs fitted.\n');
    else
        one_curve_results = [];
    end

    % --- MIMO 多曲線擬合 ---
    fprintf('  Fitting MIMO transfer function (shared denominator)...\n');

    [A1, A2, B, b_vec] = fit_mimo_tf(H_mag, H_phase_norm, W, ...
        'p', P_WEIGHT, ...
        'wc_Hz', WC_HZ, ...
        'NegateOffDiagonal', true, ...
        'Verbose', true);

    % --- ZOH 離散化 ---
    fprintf('\n  ZOH discretization...\n');

    [num_z, den_z, H_discrete, poles_z] = zoh_discretize(A1, A2, T_SAMPLE, ...
        'Verbose', true);

    fprintf('\n  Stage 2 complete.\n\n');

else
    fprintf('SECTION 4: Stage 2 SKIPPED (ENABLE_STAGE2 = false)\n\n');
    % 定義預設值以供 Stage 3 使用
    A1 = 0; A2 = 0; B = zeros(6,6);
    num_z = [0,0]; den_z = [1,0,0];
    one_curve_results = [];
    H_mag = []; H_phase_norm = []; W = [];
end

%% ========================================================================
%  SECTION 5: Stage 3 - 輸出結果
% ========================================================================

if ENABLE_STAGE3 && ENABLE_STAGE2
    fprintf('SECTION 5: Stage 3 - Output Generation\n');

    % --- 輸出 MAT 檔案 ---
    if EXPORT_MAT
        mat_path = fullfile(REPORTS_DIR, 'fitting_results.mat');
        results = struct();
        results.A1 = A1;
        results.A2 = A2;
        results.B = B;
        results.num_z = num_z;
        results.den_z = den_z;
        results.poles_z = poles_z;
        results.T_sample = T_SAMPLE;
        results.frequencies = W;
        results.p_weight = P_WEIGHT;
        results.wc_Hz = WC_HZ;
        results.k_A = diag(K_A_DIAG);
        results.date = datestr(now);

        if ~isempty(one_curve_results)
            results.one_curve = one_curve_results;
        end

        save(mat_path, 'results');
        fprintf('  MAT saved: %s\n', mat_path);
    end

    % --- 輸出 LaTeX ---
    if EXPORT_LATEX
        latex_path = fullfile(REPORTS_DIR, 'transfer_function_latex.txt');
        export_latex(latex_path, A1, A2, B, num_z, den_z, ...
            'T_sample', T_SAMPLE, ...
            'k_A', diag(K_A_DIAG), ...
            'Verbose', true);
    end

    % --- 繪製波德圖 ---
    if PLOT_BODE && ~isempty(W)
        fprintf('  Generating Bode plots...\n');

        for excite_ch = 1:6
            mag_ch = squeeze(H_mag(:, excite_ch, :));
            phase_ch = squeeze(H_phase_norm(:, excite_ch, :));

            if SAVE_FIGURES
                save_path = fullfile(FIGURES_DIR, sprintf('Bode_P%d.png', excite_ch));
            else
                save_path = '';
            end

            plot_bode(W, mag_ch, phase_ch, ...
                'Title', sprintf('P%d Excitation', excite_ch), ...
                'ExcitedChannel', excite_ch, ...
                'LogScale', true, ...
                'SavePath', save_path, ...
                'Resolution', 300);
        end
    end

    % --- 繪製對比圖 ---
    if PLOT_COMPARISON && ~isempty(W) && ~isempty(one_curve_results)
        fprintf('  Generating comparison plots...\n');

        if SAVE_FIGURES
            save_prefix = fullfile(FIGURES_DIR, 'Comparison');
        else
            save_prefix = '';
        end

        % 分組對比圖
        plot_comparison(W, H_mag, H_phase_norm, A1, A2, B, ...
            'OneCurveResults', one_curve_results, ...
            'ExcitedChannels', 1:6, ...
            'PlotType', 'grouped', ...
            'SavePath', save_prefix);

        % DC 增益對比
        plot_comparison(W, H_mag, H_phase_norm, A1, A2, B, ...
            'OneCurveResults', one_curve_results, ...
            'PlotType', 'dc_gain', ...
            'SavePath', save_prefix);

        % 36 通道網格圖
        plot_comparison(W, H_mag, H_phase_norm, A1, A2, B, ...
            'OneCurveResults', one_curve_results, ...
            'PlotType', 'grid', ...
            'SavePath', save_prefix);
    end

    fprintf('\n  Stage 3 complete.\n\n');

else
    fprintf('SECTION 5: Stage 3 SKIPPED\n\n');
end

%% ========================================================================
%  SECTION 6: 完成
% ========================================================================

fprintf('=== Pipeline Complete ===\n');
fprintf('End time: %s\n', datestr(now));
fprintf('\nOutput files:\n');
fprintf('  - Bode data: %s\n', BODE_DATA_DIR);
fprintf('  - Figures: %s\n', FIGURES_DIR);
fprintf('  - Reports: %s\n', REPORTS_DIR);
