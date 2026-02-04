%% ========================================================================
%  Hung_tweezer One-Curve Fitting 配置
%  數據來源：PT3D UI 專案 (commit f3c81cf)
%  系統鑑別：H(jω) = VM2(jω) / DA2(jω) [V/V]
% ========================================================================

function config = Hung_config()
    %% 路徑設定
    config = struct();
    config.project_root = fileparts(mfilename('fullpath'));  % Hung_tweezer/
    config.data_folder = fullfile(config.project_root, 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results');
    config.functions_path = fullfile(config.project_root, '..', 'functions');

    % 數據檔案清單（19 個頻率點）
    config.data_files = {
        'Hung_single_0.1hz.dat',
        'Hung_single_1hz.dat',
        'Hung_single_10hz.dat',
        'Hung_single_50hz.dat',
        'Hung_single_100hz.dat',
        'Hung_single_200hz.dat',
        'Hung_single_300hz.dat',
        'Hung_single_400hz.dat',
        'Hung_single_500hz.dat',
        'Hung_single_600hz.dat',
        'Hung_single_700hz.dat',
        'Hung_single_800hz.dat',
        'Hung_single_900hz.dat',
        'Hung_single_1000hz.dat',
        'Hung_single_1200hz.dat',
        'Hung_single_1400hz.dat',
        'Hung_single_1600hz.dat',
        'Hung_single_1800hz.dat',
        'Hung_single_2000hz.dat'
    };

    % 對應的頻率值（用於驗證和標籤）
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 300, 400, 500, 600, ...
        700, 800, 900, 1000, 1200, 1400, 1600, 1800, 2000
    ];

    %% 數據參數（已驗證）
    config.excitation_channel = 2;              % Channel 2 激勵
    config.expected_sampling_rate = 20000;      % Hz (不是 100kHz！)
    config.expected_loop_mode = 1;              % Open-loop
    config.expected_amplitude = 2.0;            % 激勵振幅 [V]

    %% DAC 轉電壓參數（關鍵！參考 openloop_bode.m Line 118-119）
    config.dac.zero_offset = 32768;             % 0V 對應的 DAC 值
    config.dac.voltage_range = 20.0;            % ±10V 範圍 (20V peak-to-peak)
    config.dac.resolution = 65536;              % 16-bit DAC (2^16)
    % 轉換公式：da_volt = (da - zero_offset) * (voltage_range / resolution)

    % 壞點修復（20kHz 無壞點問題，但保留彈性）
    config.enable_bad_point_repair = false;     % 20kHz 數據無需修復
    config.bad_point_interval = 10000;          % 僅 100kHz 時需要

    %% 穩態檢測參數
    config.steady_state.threshold = 2e-3;       % V
    config.steady_state.consecutive_periods = 3;
    config.steady_state.min_periods_for_fft = 2; % 最少需要的週期數（對低頻寬鬆）

    %% FFT 參數（整數週期處理）
    config.fft.mode = 'full';                   % 'full' | 'averaged'
    config.fft.min_da_threshold = 1e-10;        % 最小 DA 閾值（避免除零）
    config.fft.window = 'none';                 % 整數週期時不需窗函數

    %% One-Curve Fitting 參數（與主程式一致）
    config.fitting.p_weight = 0.5;              % 加權指數
    config.fitting.wc_Hz = 100;                 % 截止頻率 [Hz]
    config.fitting.verbose = true;              % 顯示擬合詳細資訊

    %% 相位正規化參數
    config.phase.normalize = true;              % 是否執行相位正規化
    config.phase.reference_freq_Hz = 0.1;       % 參考頻率（最低頻）

    %% 輸出設定
    config.output.save_bode_data = true;
    config.output.save_fitting_results = true;
    config.output.save_figures = true;
    config.output.figure_format = 'png';        % 'png' | 'fig' | 'eps'
    config.output.figure_dpi = 300;

    % 輸出子資料夾
    config.output.bode_folder = fullfile(config.output_folder, 'bode_data');
    config.output.fitting_folder = fullfile(config.output_folder, 'fitting_results');
    config.output.figure_folder = fullfile(config.output_folder, 'figures');

    %% 圖表選項
    config.plot.bode_diagram = true;            % Bode 圖
    config.plot.residuals = true;               % 殘差圖
    config.plot.pole_location = true;           % 極點位置圖
    config.plot.verbose = true;                 % 顯示詳細資訊
    config.plot.freq_range = [0.08, 3000];      % 繪圖頻率範圍 [Hz]
    config.plot.line_width = 1.5;
    config.plot.marker_size = 8;

    %% 驗證參數（用於 sanity check）
    config.validation.min_R_squared = 0.85;     % 最低 R² 要求
    config.validation.expected_dc_gain_range = [0.1, 10];
    config.validation.expected_wn_range = [10, 10000];  % rad/s
    config.validation.max_phase_residual = 20;  % deg

end
