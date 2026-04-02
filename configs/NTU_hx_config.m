function config = NTU_hx_config()
%NTU_HX_CONFIG NTU hexapole MIMO 6x6 實驗配置 (DAT 來源)
%
% 使用方式:
%   run_analysis('NTU_hx', 'mimo_all');
%   run_analysis('NTU_hx', 'mimo_fit');
%   run_analysis('NTU_hx', 'mimo_plot');

    config = default_config();
    config.experiment_name = 'NTU_hx';

    %% 15 點頻率表
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];

    %% MIMO 專用設定
    config.mimo = struct();
    config.mimo.num_channels = 6;
    config.mimo.data_source = 'dat';
    config.mimo.legacy_data_folder = '';
    config.mimo.pair_map = [2, 1, 4, 3, 6, 5];

    % DAT 來源設定
    config.mimo.dat_base_folder = fullfile(config.project_root, 'data', 'NTU_hx');
    config.mimo.dat_subfolder = {'hx_p1'; 'hx_p2'; 'hx_p3'; ...
                                  'hx_p4'; 'hx_p5'; 'hx_p6'};
    config.mimo.dat_prefix = {'NTU_hx_p1_'; 'NTU_hx_p2_'; 'NTU_hx_p3_'; ...
                               'NTU_hx_p4_'; 'NTU_hx_p5_'; 'NTU_hx_p6_'};

    % 各通道放大器增益
    config.mimo.k_A_diag = [0.3618, 0.3614, 0.3536, 0.3532, 0.3573, 0.3610];

    % ZOH 取樣時間
    config.mimo.T_sample = 1e-5;  % 10 us (100 kHz)

    %% Fitting 參數
    config.fitting.p_weight = 0.5;
    config.fitting.wc_Hz = 0.1;

    %% 輸出路徑
    config.output_folder = fullfile(config.project_root, 'results', 'NTU_hx');
end
