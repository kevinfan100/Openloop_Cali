function config = MIMO_config()
%MIMO_CONFIG MIMO 6x6 實驗設定
%
% 使用方式:
%   run_analysis('MIMO', 'mimo_all');
%   run_analysis('MIMO', 'mimo_fft');
%   run_analysis('MIMO', 'mimo_fit');
%   run_analysis('MIMO', 'mimo_plot');

    config = default_config();
    config.experiment_name = 'MIMO';

    %% MIMO 專用設定
    config.mimo = struct();
    config.mimo.num_channels = 6;
    config.mimo.data_source = 'legacy';           % 'legacy' | 'dat'
    config.mimo.legacy_data_folder = fullfile(config.project_root, 'legacy');
    config.mimo.pair_map = [2, 1, 4, 3, 6, 5];   % 配對通道 (繪圖用)

    % 各通道放大器增益
    config.mimo.k_A_diag = [0.3618, 0.3614, 0.3536, 0.3532, 0.3573, 0.3610];

    % ZOH 取樣時間
    config.mimo.T_sample = 1e-5;                   % 10 us (100 kHz)

    %% Fitting 參數 (覆寫 default)
    config.fitting.p_weight = 0.5;
    config.fitting.wc_Hz = 0.1;                    % 同 legacy

    %% 輸出路徑
    config.output_folder = fullfile(config.project_root, 'results', 'MIMO');
end
