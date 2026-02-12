function config = Hung_single_yoke_config()
%HUNG_SINGLE_YOKE_CONFIG Hung single yoke 實驗配置
%
% 15 點頻率表 (UI Freq Sweep)，single channel ch2→ch2。

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_single_yoke';
    config.display_name = 'Hung (Single Yoke)';
    config.data_prefix = 'Hung_single_yoke';

    %% 15 點頻率表
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_single_yoke', 'single_yoke_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_single_yoke');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting — 先不排除任何頻率
    config.fitting.exclude_frequencies = [];
end
