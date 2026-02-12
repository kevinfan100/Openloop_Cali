function config = Hung_pair_3_config()
%HUNG_PAIR_3_CONFIG Hung pair 耦合通道配置 (DA ch2 → Vm ch3)
%
% 與 Hung_pair_2 共用同一組 .dat 檔案
% analysis_channel = 3 (coupled channel)

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'Hung_pair_3';
    config.display_name = 'V_{coupled}';
    config.data_prefix = 'Hung_pair';

    %% 跨通道: Vm ch3 (coupled)
    config.analysis_channel = 3;

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'Hung_pair', 'pair_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung_pair_3');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = [];
end
