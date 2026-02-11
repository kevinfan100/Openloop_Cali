function config = Hung_spring_washer_config()
%HUNG_SPRING_WASHER_CONFIG Hung (Spring Washer) 實驗配置
%
% 只覆寫與 default_config 不同的欄位。

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_spring_washer';
    config.display_name = 'Hung (SpringWasher)';
    config.data_prefix = 'Hung_single_spring_washer';

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_spring_washer', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_spring_washer');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% 實驗特定覆寫 (若有)
    config.fitting.exclude_frequencies = [];  % 所有頻率都用
end
