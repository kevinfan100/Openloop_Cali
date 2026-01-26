function [H_mag_norm, H_phase_norm] = normalize_data(H_mag, H_phase, frequencies, varargin)
%NORMALIZE_DATA 頻率響應數據正規化
%
% 執行相位偏移移除和可選的幅值正規化
%
% 使用方式:
%   [H_mag_norm, H_phase_norm] = normalize_data(H_mag, H_phase, frequencies)
%   [H_mag_norm, H_phase_norm] = normalize_data(..., 'Name', 'Value', ...)
%
% 輸入:
%   H_mag       - 幅值矩陣 (6 x N) 或 (6 x 6 x N)
%   H_phase     - 相位矩陣 [deg] (6 x N) 或 (6 x 6 x N)
%   frequencies - 頻率向量 [Hz]
%
% 選項 (Name-Value pairs):
%   'RemovePhaseOffset'   - 移除最低頻相位偏移 (default: true)
%   'NormalizeMagnitude'  - 正規化幅值到最低頻 (default: false)
%   'ReferenceFreqIdx'    - 參考頻率索引 (default: 1, 最低頻)
%   'Verbose'             - 顯示處理信息 (default: false)
%
% 輸出:
%   H_mag_norm   - 正規化後的幅值
%   H_phase_norm - 正規化後的相位
%
% 正規化方法:
%   1. 相位偏移移除:
%      H_phase_norm(i,j,:) = H_phase(i,j,:) - H_phase(i,j,freq_min)
%
%   2. 幅值正規化 (可選):
%      H_mag_norm(i,j,:) = H_mag(i,j,:) / H_mag(i,j,freq_min)
%      這使得所有通道在參考頻率處的增益為 1

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'H_mag', @isnumeric);
    addRequired(p, 'H_phase', @isnumeric);
    addRequired(p, 'frequencies', @isnumeric);
    addParameter(p, 'RemovePhaseOffset', true, @islogical);
    addParameter(p, 'NormalizeMagnitude', false, @islogical);
    addParameter(p, 'ReferenceFreqIdx', 1, @isnumeric);
    addParameter(p, 'Verbose', false, @islogical);

    parse(p, H_mag, H_phase, frequencies, varargin{:});
    opts = p.Results;

    %% 確定數據維度
    dims = size(H_mag);
    ndims_data = length(dims);

    if ndims_data == 2
        % 2D: (6 x N) 單激勵通道
        [num_channels, num_freq] = size(H_mag);
        is_3d = false;
    elseif ndims_data == 3
        % 3D: (6 x 6 x N) MIMO 完整矩陣
        [num_out, num_in, num_freq] = size(H_mag);
        is_3d = true;
    else
        error('H_mag must be 2D (6 x N) or 3D (6 x 6 x N)');
    end

    % 驗證頻率向量
    if length(frequencies) ~= num_freq
        error('frequencies length (%d) does not match data (%d)', length(frequencies), num_freq);
    end

    % 參考頻率索引
    ref_idx = opts.ReferenceFreqIdx;
    if ref_idx < 1 || ref_idx > num_freq
        warning('ReferenceFreqIdx out of range, using 1');
        ref_idx = 1;
    end

    %% 初始化輸出
    H_mag_norm = H_mag;
    H_phase_norm = H_phase;

    %% 執行正規化
    if is_3d
        % 3D MIMO 矩陣處理
        for i = 1:num_out
            for j = 1:num_in
                % 相位偏移移除
                if opts.RemovePhaseOffset
                    phase_offset = H_phase(i, j, ref_idx);
                    H_phase_norm(i, j, :) = H_phase(i, j, :) - phase_offset;

                    if opts.Verbose
                        fprintf('  Channel (%d,%d): Phase offset removed = %.2f deg\n', ...
                            i, j, phase_offset);
                    end
                end

                % 幅值正規化
                if opts.NormalizeMagnitude
                    mag_ref = H_mag(i, j, ref_idx);
                    if mag_ref > 0
                        H_mag_norm(i, j, :) = H_mag(i, j, :) / mag_ref;
                    else
                        warning('Channel (%d,%d): Reference magnitude is zero, skipping normalization', i, j);
                    end
                end
            end
        end
    else
        % 2D 單激勵通道處理
        for ch = 1:num_channels
            % 相位偏移移除
            if opts.RemovePhaseOffset
                phase_offset = H_phase(ch, ref_idx);
                H_phase_norm(ch, :) = H_phase(ch, :) - phase_offset;

                if opts.Verbose
                    fprintf('  Channel %d: Phase offset removed = %.2f deg\n', ch, phase_offset);
                end
            end

            % 幅值正規化
            if opts.NormalizeMagnitude
                mag_ref = H_mag(ch, ref_idx);
                if mag_ref > 0
                    H_mag_norm(ch, :) = H_mag(ch, :) / mag_ref;
                else
                    warning('Channel %d: Reference magnitude is zero, skipping normalization', ch);
                end
            end
        end
    end

    %% 顯示摘要
    if opts.Verbose
        fprintf('Normalization complete:\n');
        fprintf('  Reference frequency: %.2f Hz (index %d)\n', frequencies(ref_idx), ref_idx);
        fprintf('  Phase offset removal: %s\n', mat2str(opts.RemovePhaseOffset));
        fprintf('  Magnitude normalization: %s\n', mat2str(opts.NormalizeMagnitude));
    end
end
