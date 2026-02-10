function config = NTU_t_config()
%NTU_T_CONFIG NTU tip sensor 配置 (DA ch2 → Vm ch3)
%
% 與 NTU_s 共用同一組 .dat 檔案 (NTU_single_ts_*.dat)
% analysis_channel = 3 (tip sensor)

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'NTU_t';
    config.display_name = 'V_{tip}';
    config.data_prefix = 'NTU_single_ts';

    %% 跨通道: Vm ch3 (tip sensor)
    config.analysis_channel = 3;

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'NTU_ts', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'NTU_t');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = [];
end
