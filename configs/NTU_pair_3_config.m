function config = NTU_pair_3_config()
%NTU_PAIR_3_CONFIG NTU pair 耦合通道配置 (DA ch2 → Vm ch3)
%
% 與 NTU_pair_2 共用同一組 .dat 檔案
% analysis_channel = 3 (coupled channel)
% 15 點頻率表 (UI Freq Sweep)

    config = default_config();

    %% 實驗識別
    config.experiment_name = 'NTU_pair_3';
    config.display_name = 'coupled';
    config.data_prefix = 'NTU_pair';

    %% 15 點頻率表 (UI Freq Sweep)
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];

    %% 跨通道: Vm ch3 (coupled)
    config.analysis_channel = 3;

    %% 路徑
    config.data_folder = fullfile(config.project_root, 'data', 'NTU_pair', 'pair_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'NTU_pair_3');

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = [];
end
