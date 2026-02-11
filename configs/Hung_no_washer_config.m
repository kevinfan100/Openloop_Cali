function config = Hung_no_washer_config()
%HUNG_NO_WASHER_CONFIG Hung (No Washer) 實驗配置
%
% 只覆寫與 default_config 不同的欄位。

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_no_washer';
    config.display_name = 'Hung (NoWasher)';
    config.data_prefix = 'Hung_single_no_washer';

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_no_washer', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_no_washer');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);
end
