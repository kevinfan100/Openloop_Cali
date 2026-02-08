function config = default_config()
%DEFAULT_CONFIG 所有實驗共用的預設配置
%
% 新實驗只需寫一個 <experiment>_config.m，覆寫差異欄位即可。
% 必須覆寫的欄位:
%   config.experiment_name
%   config.data_prefix
%   config.data_folder
%   config.output_folder

    %% Project root (auto-detect)
    config = struct();
    config.project_root = fileparts(fileparts(mfilename('fullpath')));  % Openloop_cali/

    %% 頻率點 (19 points, 所有實驗共用)
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 300, 400, 500, 600, ...
        700, 800, 900, 1000, 1200, 1400, 1600, 1800, 2000
    ];

    %% 數據參數
    config.excitation_channel = 2;
    config.expected_sampling_rate = 20000;      % Hz (NOT 100kHz)
    config.expected_loop_mode = 1;              % Open-loop
    config.expected_amplitude = 2.0;            % V

    %% DAC → Voltage (固定公式)
    config.dac.zero_offset = 32768;
    config.dac.voltage_range = 20.0;            % ±10V (20V peak-to-peak)
    config.dac.resolution = 65536;              % 16-bit (2^16)

    %% 壞點修復
    config.enable_bad_point_repair = false;     % 20kHz 無需修復
    config.bad_point_interval = 10000;          % 僅 100kHz 時需要

    %% 穩態檢測
    config.steady_state.relative_threshold = 0.002;  % 0.2%
    config.steady_state.consecutive_periods = 3;
    config.steady_state.check_points = 25;
    config.steady_state.min_periods_for_fft = 2;

    %% FFT
    config.fft.mode = 'full';                   % 'full' | 'averaged'
    config.fft.min_da_threshold = 1e-10;
    config.fft.window = 'none';
    config.fft.thd_harmonics = 2:10;
    config.fft.thd_max_freq_ratio = 0.8;        % 上限 0.8 × Nyquist

    %% Fitting
    config.fitting.p_weight = 0.5;
    config.fitting.wc_Hz = 100;
    config.fitting.verbose = true;
    config.fitting.exclude_frequencies = [];     % e.g. [0.1, 900]

    %% Phase
    config.phase.normalize = true;
    config.phase.reference_freq_Hz = 0.1;

    %% Validation
    config.validation.min_R_squared = 0.85;
    config.validation.expected_dc_gain_range = [0.01, 10];
    config.validation.expected_wn_range = [10, 10000];   % rad/s
    config.validation.max_phase_residual = 20;           % deg

    %% Output
    config.output.save_csv = true;
    config.output.save_figures = true;
    config.output.save_fitting_results = true;
    config.output.figure_format = 'png';
    config.output.figure_dpi = 300;

    %% Plot style
    config.plot.figure_size_bode = [100, 100, 900, 720];
    config.plot.figure_size_spectrum = [100, 100, 1200, 1200];
    config.plot.figure_size_lissajous = [100, 100, 1800, 600];
    config.plot.figure_size_dashboard = [50, 50, 1600, 900];
    config.plot.line_width = 3.5;
    config.plot.marker_size = 12;
    config.plot.font_size_tick = 24;
    config.plot.font_size_label = 40;
    config.plot.font_size_legend = 22;
    config.plot.font_size_title = 24;
    config.plot.axis_line_width = 3;
    config.plot.freq_range = [0.08, 3000];

    %% Paths (functions)
    config.functions_path = fullfile(config.project_root, 'functions');

    %% Helper: auto-generate data_files from prefix + frequencies
    % 呼叫 build_data_files(config) 來生成
end
