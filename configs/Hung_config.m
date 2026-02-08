function config = Hung_config()
%HUNG_CONFIG Hung (with ring) 實驗配置
%
% 只覆寫與 default_config 不同的欄位。

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung';
    config.display_name = 'Hung';
    config.data_prefix = 'Hung_single';

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% 實驗特定覆寫 (若有)
    config.fitting.exclude_frequencies = [0.1, 900];  % 排除問題頻率
end
