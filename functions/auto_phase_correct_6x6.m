function [phase_corrected, correction_map, diagnostics] = auto_phase_correct_6x6( ...
    H_phase, H_mag, frequencies, varargin)
%AUTO_PHASE_CORRECT_6X6 自動 180 度相位修正 (6x6 MIMO)
%
% 對 36 個 H_ij 通道各自檢查低頻相位，判斷是否需要 180 度修正
%
% 演算法:
%   1. 取最低 NumRefFreqs 個頻率的相位進行投票
%   2. 若多數票 |Phase| > Threshold → 減去 180 度
%   3. 若 magnitude < MagFloor → 仍修正但標記低可靠度
%   4. 最後減去殘餘 Phase(w_min) (offset removal)
%
% 使用方式:
%   [phase_corrected, correction_map, diag] = auto_phase_correct_6x6(H_phase, H_mag, frequencies)
%   [...] = auto_phase_correct_6x6(..., 'Threshold', 90, 'NumRefFreqs', 3)
%
% 輸入:
%   H_phase     - 相位矩陣 [deg] (6 x 6 x N)，原始未修正
%   H_mag       - 幅值矩陣 (6 x 6 x N)
%   frequencies - 頻率向量 [Hz] (1 x N)
%
% 選項 (Name-Value pairs):
%   'Threshold'    - 判定門檻 [deg] (default: 90)
%   'NumRefFreqs'  - 投票用的低頻點數 (default: 3)
%   'MagFloor'     - 低幅值門檻 (default: 1e-4)
%   'RemoveOffset' - 修正後是否移除殘餘 offset (default: true)
%   'Verbose'      - 顯示處理信息 (default: true)
%
% 輸出:
%   phase_corrected - 修正後的相位 [deg] (6 x 6 x N)
%   correction_map  - 修正標記 (6 x 6 logical)，true = 已修正 180 度
%   diagnostics     - struct: raw_phase_at_ref, confidence, warnings

    %% 解析輸入參數
    pr = inputParser;
    pr.KeepUnmatched = true;
    addRequired(pr, 'H_phase', @isnumeric);
    addRequired(pr, 'H_mag', @isnumeric);
    addRequired(pr, 'frequencies', @isnumeric);
    addParameter(pr, 'Threshold', 90, @isnumeric);
    addParameter(pr, 'NumRefFreqs', 3, @isnumeric);
    addParameter(pr, 'MagFloor', 1e-4, @isnumeric);
    addParameter(pr, 'RemoveOffset', true, @islogical);
    addParameter(pr, 'Verbose', true, @islogical);

    parse(pr, H_phase, H_mag, frequencies, varargin{:});
    opts = pr.Results;

    %% 驗證輸入維度
    [num_out, num_in, num_freq] = size(H_phase);
    if num_out ~= 6 || num_in ~= 6
        error('auto_phase_correct_6x6:dim', 'H_phase must be 6 x 6 x N');
    end
    if length(frequencies) ~= num_freq
        error('auto_phase_correct_6x6:freq', ...
            'frequencies length (%d) must match 3rd dimension (%d)', ...
            length(frequencies), num_freq);
    end

    %% 排序頻率並取最低 NumRefFreqs 個
    [~, sort_idx] = sort(frequencies);
    num_ref = min(opts.NumRefFreqs, num_freq);
    ref_idx = sort_idx(1:num_ref);

    %% 初始化輸出
    phase_corrected = H_phase;
    correction_map = false(6, 6);
    raw_phase_at_ref = zeros(6, 6);
    confidence = zeros(6, 6);
    warn_list = {};

    %% 逐通道判斷
    for i = 1:6
        for j = 1:6
            % 取參考頻率的相位
            ref_phases = squeeze(H_phase(i, j, ref_idx));
            ref_mags = squeeze(H_mag(i, j, ref_idx));

            % 記錄最低頻率的原始相位
            raw_phase_at_ref(i, j) = ref_phases(1);

            % 投票: 有多少個參考頻率的 |phase| > threshold
            votes_for_correction = sum(abs(ref_phases) > opts.Threshold);
            needs_correction = votes_for_correction > num_ref / 2;

            % 計算可靠度 (1 = 全票通過)
            confidence(i, j) = votes_for_correction / num_ref;

            % 低幅值警告
            if any(ref_mags < opts.MagFloor)
                warn_list{end+1} = sprintf( ...
                    'H(%d,%d): low magnitude at ref freqs (min=%.2e)', ...
                    i, j, min(ref_mags)); %#ok<AGROW>
            end

            % 執行修正
            if needs_correction
                correction_map(i, j) = true;
                phase_corrected(i, j, :) = squeeze(H_phase(i, j, :)) - 180;
            end
        end
    end

    %% Phase offset removal (減去殘餘 Phase(w_min))
    if opts.RemoveOffset
        [~, min_freq_idx] = min(frequencies);
        for i = 1:6
            for j = 1:6
                phase_offset = phase_corrected(i, j, min_freq_idx);
                phase_corrected(i, j, :) = phase_corrected(i, j, :) - phase_offset;
            end
        end
    end

    %% 組裝 diagnostics
    diagnostics = struct();
    diagnostics.correction_map = correction_map;
    diagnostics.raw_phase_at_ref = raw_phase_at_ref;
    diagnostics.confidence = confidence;
    diagnostics.warnings = warn_list;
    diagnostics.num_corrected = sum(correction_map(:));
    diagnostics.ref_frequencies = frequencies(ref_idx);

    %% Console 輸出
    if opts.Verbose
        fprintf('Phase correction (auto):\n');
        fprintf('  Reference frequencies: [');
        fprintf('%.1f ', frequencies(ref_idx));
        fprintf('] Hz\n');
        fprintf('  Threshold: %.0f deg\n', opts.Threshold);
        fprintf('  Channels corrected: %d / 36\n', diagnostics.num_corrected);
        if opts.RemoveOffset
            fprintf('  Phase offset removed at %.1f Hz\n', frequencies(min_freq_idx));
        end
        if ~isempty(warn_list)
            fprintf('  Warnings:\n');
            for w = 1:length(warn_list)
                fprintf('    - %s\n', warn_list{w});
            end
        end
    end
end
