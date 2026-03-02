function config = Hung_pair_test1_2_config()
%HUNG_PAIR_TEST1_2_CONFIG Hung pair test1 主通道配置 (DA ch2 → Vm ch2)
%
% 與 Hung_pair_test1_3 共用同一組 .dat 檔案
% analysis_channel = 2 (excite channel)

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_pair_test1_2';
    config.display_name = 'pair excite';
    config.data_prefix = 'Hung_pair_test1';

    %% 分析通道: Vm ch2 (excite)
    config.analysis_channel = 2;

    %% 15 點頻率表
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_pair_test1', 'pair_raw_data_test1');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_pair_test1_2');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = [];
end
