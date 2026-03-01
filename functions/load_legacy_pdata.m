function [H_mag, H_phase_raw, freq_out] = load_legacy_pdata(data_folder, varargin)
%LOAD_LEGACY_PDATA 從 legacy P1.m~P6.m 載入 6x6 頻率響應數據
%
% 從 P1.m~P6.m 載入並組裝為 pipeline 格式
% 使用原始相位 (phases) 而非已修正相位 (phases_processed)
%
% 使用方式:
%   [H_mag, H_phase_raw, frequencies] = load_legacy_pdata(data_folder)
%
% 輸入:
%   data_folder - P*.m 檔案所在資料夾路徑
%
% 選項:
%   'Verbose' - 顯示載入資訊 (default: true)
%
% 輸出:
%   H_mag         - 6 x 6 x N magnitude (linear)
%   H_phase_raw   - 6 x 6 x N phase (deg, 原始未修正)
%   freq_out      - 1 x N Hz

    %% 解析參數
    pr = inputParser;
    pr.KeepUnmatched = true;
    addRequired(pr, 'data_folder', @ischar);
    addParameter(pr, 'Verbose', true, @islogical);
    parse(pr, data_folder, varargin{:});
    opts = pr.Results;

    %% 載入 P1~P6
    num_files = 6;
    freq_out = [];

    % 暫存當前路徑，載入後恢復
    original_dir = pwd;
    cleanup = onCleanup(@() cd(original_dir));

    % 切換到數據資料夾以便 eval 能找到 P*.m
    cd(data_folder);

    for file_idx = 1:num_files
        script_name = sprintf('P%d', file_idx);
        script_file = fullfile(data_folder, [script_name '.m']);

        if ~exist(script_file, 'file')
            error('load_legacy_pdata:file_not_found', ...
                'File not found: %s', script_file);
        end

        % 執行 P*.m 腳本
        % P*.m 設定: frequencies, magnitudes_linear, phases, phases_processed
        eval(script_name);

        % 第一個檔案: 初始化輸出陣列
        if isempty(freq_out)
            freq_out = frequencies;
            num_freq = length(freq_out);
            H_mag = zeros(6, 6, num_freq);
            H_phase_raw = zeros(6, 6, num_freq);
        end

        % 儲存 magnitude 和原始 phase
        % magnitudes_linear: 6 x num_freq (rows = output channels)
        % phases: 6 x num_freq (原始未修正)
        H_mag(:, file_idx, :) = magnitudes_linear;
        H_phase_raw(:, file_idx, :) = phases;

        % 清除 P*.m 設定的變數
        clear frequencies magnitudes_linear phases phases_processed
    end

    if opts.Verbose
        fprintf('Legacy P-data loaded:\n');
        fprintf('  Source: %s\n', data_folder);
        fprintf('  Files: P1.m ~ P6.m\n');
        fprintf('  Freq range: %.2f ~ %.2f Hz (%d points)\n', ...
            min(freq_out), max(freq_out), length(freq_out));
        fprintf('  Using raw phases (not phases_processed)\n');
    end
end
