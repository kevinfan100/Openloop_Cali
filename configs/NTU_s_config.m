function config = NTU_s_config()
%NTU_S_CONFIG NTU surface sensor 配置 (DA ch2 → VM ch2)
%
% 與 NTU_t 共用同一組 .dat 檔案 (NTU_single_ts_*.dat)
% analysis_channel = 2 (surface sensor, = excitation_channel)

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'NTU_s';
    config.display_name = 'V_{surface}';
    config.data_prefix = 'NTU_single_ts';

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'NTU_ts', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'NTU_s');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = [];
end
