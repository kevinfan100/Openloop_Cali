function config = Hung_pair_2_config()
%HUNG_PAIR_2_CONFIG Hung pair 主通道配置 (DA ch2 → Vm ch2)
%
% 與 Hung_pair_3 共用同一組 .dat 檔案
% analysis_channel = 2 (excite channel)

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_pair_2';
    config.display_name = 'excite';
    config.data_prefix = 'Hung_pair';

    %% 分析通道: Vm ch2 (excite)
    config.analysis_channel = 2;

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_pair', 'pair_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_pair_2');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = [];
end
