function [Vm_clean, da_clean] = repair_bad_points(Vm_data, da_data, varargin)
%REPAIR_BAD_POINTS 修復壞數據點 (每 10000 筆固定一個)
%
% 在 100kHz 取樣時，每 10000 筆數據會有一個壞點，
% 此函數使用插值方法修復這些壞點。
%
% 使用方式:
%   [Vm_clean, da_clean] = repair_bad_points(Vm_data, da_data)
%   [Vm_clean, da_clean] = repair_bad_points(..., 'Name', 'Value', ...)
%
% 輸入:
%   Vm_data - Vm 電壓數據 (6 x N)
%   da_data - DA 輸出數據 (6 x N)
%
% 選項 (Name-Value pairs):
%   'BadPointInterval' - 壞點間隔 (default: 10000)
%   'Method'           - 插值方法 'linear'|'spline'|'pchip'|'makima' (default: 'spline')
%   'Verbose'          - 顯示處理信息 (default: true)
%
% 輸出:
%   Vm_clean - 修復後的 Vm 數據 (6 x N)
%   da_clean - 修復後的 DA 數據 (6 x N)

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'Vm_data', @isnumeric);
    addRequired(p, 'da_data', @isnumeric);
    addParameter(p, 'BadPointInterval', 10000, @isnumeric);
    addParameter(p, 'Method', 'spline', @(x) ismember(x, {'linear', 'spline', 'pchip', 'makima'}));
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, Vm_data, da_data, varargin{:});
    opts = p.Results;

    %% 獲取數據長度
    data_length = size(Vm_data, 2);

    %% 識別壞點索引
    bad_indices = 1:opts.BadPointInterval:data_length;
    num_bad_points = length(bad_indices);

    if opts.Verbose
        fprintf('  Repairing bad data points:\n');
        fprintf('    Interpolation method: %s\n', opts.Method);
        fprintf('    Bad point interval: every %d samples\n', opts.BadPointInterval);
    end

    %% 複製原始數據
    Vm_clean = Vm_data;
    da_clean = da_data;

    %% 如果沒有壞點，直接返回
    if num_bad_points == 0
        if opts.Verbose
            fprintf('    No bad points detected\n');
        end
        return;
    end

    %% 保存原始壞點值（用於計算修復誤差）
    Vm_bad_original = Vm_data(:, bad_indices);
    da_bad_original = da_data(:, bad_indices);

    %% 找出好的數據索引
    good_indices = setdiff(1:data_length, bad_indices);

    %% 對每個通道進行插值修復
    for ch = 1:6
        if length(good_indices) >= 4
            try
                % 使用指定的插值方法
                Vm_clean(ch, bad_indices) = interp1(good_indices, ...
                    Vm_data(ch, good_indices), bad_indices, opts.Method, 'extrap');
                da_clean(ch, bad_indices) = interp1(good_indices, ...
                    da_data(ch, good_indices), bad_indices, opts.Method, 'extrap');
            catch
                % 如果高級方法失敗，使用線性插值
                if opts.Verbose
                    fprintf('    Warning: Ch%d interpolation failed, using linear fallback\n', ch);
                end
                Vm_clean(ch, bad_indices) = interp1(good_indices, ...
                    Vm_data(ch, good_indices), bad_indices, 'linear', 'extrap');
                da_clean(ch, bad_indices) = interp1(good_indices, ...
                    da_data(ch, good_indices), bad_indices, 'linear', 'extrap');
            end
        else
            % 數據點不足，使用簡單的線性插值
            for idx = bad_indices
                if idx > 1 && idx < data_length
                    Vm_clean(ch, idx) = (Vm_data(ch, idx-1) + Vm_data(ch, idx+1)) / 2;
                    da_clean(ch, idx) = (da_data(ch, idx-1) + da_data(ch, idx+1)) / 2;
                end
            end
        end
    end

    %% 計算修復統計
    if opts.Verbose
        Vm_error_rms = sqrt(mean((Vm_clean(:, bad_indices) - Vm_bad_original).^2, 2));
        da_error_rms = sqrt(mean((da_clean(:, bad_indices) - da_bad_original).^2, 2));

        fprintf('    Vm repair RMS error: %.6f V (average)\n', mean(Vm_error_rms));
        fprintf('    DA repair RMS error: %.6f V (average)\n', mean(da_error_rms));
        fprintf('    Total points: %d, Repaired: %d\n', data_length, num_bad_points);
    end
end
