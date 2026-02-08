function config = Hung_noring_config()
%HUNG_NORING_CONFIG Hung (No Ring) 實驗配置
%
% 只覆寫與 default_config 不同的欄位。

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_noring';
    config.display_name = 'Hung (NoRing)';
    config.data_prefix = 'Hung_single_noring';

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_noring', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_noring');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);
end
