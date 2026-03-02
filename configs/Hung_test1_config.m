function config = Hung_test1_config()
%HUNG_TEST1_CONFIG Hung single pole test1 實驗配置
%
% 15 點頻率表，single channel ch2→ch2。

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_test1';
    config.display_name = 'single';
    config.data_prefix = 'Hung_single_test1';

    %% 15 點頻率表
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_test1', 'single_raw_data_test1');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_test1');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = [];
end
