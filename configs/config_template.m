function config = NEW_EXPERIMENT_config()
%NEW_EXPERIMENT_CONFIG 新實驗配置 template
%
% 使用步驟:
%   1. 複製此檔案，重新命名為 <experiment>_config.m
%   2. 修改以下欄位
%   3. 將原始數據放入 data/<experiment>/single_raw_data/
%   4. 執行 run_analysis('<experiment>', 'all')

    config = default_config();

    %% === 必須修改 ===
    config.experiment_name = 'NEW_EXPERIMENT';       % 實驗 ID (無空格)
    config.display_name = 'New Experiment';          % 顯示名稱
    config.data_prefix = 'NewExp_single';            % 檔名前綴

    %% === 路徑 (自動生成) ===
    config.data_folder = fullfile(config.project_root, 'data', config.experiment_name, 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', config.experiment_name);

    %% === 自動生成 data_files ===
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);

    %% === 可選覆寫 ===
    % config.expected_sampling_rate = 100000;         % 若非 20kHz
    % config.enable_bad_point_repair = true;          % 100kHz 需要
    % config.fitting.exclude_frequencies = [0.1, 900];
    % config.fitting.wc_Hz = 50;                      % 覆寫截止頻率
end
