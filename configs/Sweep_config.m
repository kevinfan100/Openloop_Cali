function config = Sweep_config()
%SWEEP_CONFIG UI 自動掃頻 (Freq Sweep) 實驗 template
%
% 15 點頻率表，對應 PT3D_SW UI 的 Freq Sweep 功能。
% 使用者需覆寫: experiment_name, display_name, data_prefix, data_folder, output_folder
%
% 範例 (建立新掃頻實驗):
%   1. 複製此檔 → <name>_config.m
%   2. 覆寫 experiment_name, data_prefix, data_folder, output_folder
%   3. run_analysis('<name>', 'all')

    config = default_config();

    %% 實驗識別 (使用者覆寫)
    config.experiment_name = 'Sweep';
    config.display_name = 'Sweep';
    config.data_prefix = 'sweep';

    %% 15 點頻率表 (UI Freq Sweep)
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];

    %% 路徑 (使用者覆寫)
    config.data_folder = '';
    config.output_folder = '';

    %% 自動生成 data_files
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% Fitting
    config.fitting.exclude_frequencies = 0.1;
end
