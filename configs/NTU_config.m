function config = NTU_config()
%NTU_CONFIG NTU 實驗配置
%
% 只覆寫與 default_config 不同的欄位。

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'NTU';
    config.display_name = 'NTU';
    config.data_prefix = 'NTU_single';

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'NTU', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'NTU');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);
end
