function [a1, a2, b, H_fitted] = fit_single_tf(h_k, phi_k, w_k, varargin)
%FIT_SINGLE_TF 單曲線二階轉移函數擬合
%
% 使用加權最小平方法擬合二階轉移函數
%
% 模型:
%   H(s) = b / (s² + a1·s + a2)
%
% 使用方式:
%   [a1, a2, b] = fit_single_tf(h_k, phi_k, w_k)
%   [a1, a2, b, H_fitted] = fit_single_tf(..., 'Name', 'Value', ...)
%
% 輸入:
%   h_k   - 幅值響應 (N x 1)
%   phi_k - 相位響應 [rad] (N x 1)
%   w_k   - 頻率向量 [rad/s] (N x 1)
%
% 選項 (Name-Value pairs):
%   'p'        - 加權指數 (default: 0.5)
%   'wc_rad'   - 截止頻率 [rad/s] (default: 0.1 * 2 * pi)
%   'Verbose'  - 顯示處理信息 (default: false)
%
% 輸出:
%   a1, a2  - 分母係數
%   b       - 分子係數
%   H_fitted - 擬合後的複數頻率響應 (可選)
%
% 加權函數:
%   w(ω) = 1/(1+(ω²/ωc²))^p
%   較大的 p 或較小的 ωc 會更強調低頻擬合

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'h_k', @isnumeric);
    addRequired(p, 'phi_k', @isnumeric);
    addRequired(p, 'w_k', @isnumeric);
    addParameter(p, 'p', 0.5, @isnumeric);
    addParameter(p, 'wc_rad', 0.1 * 2 * pi, @isnumeric);
    addParameter(p, 'Verbose', false, @islogical);

    parse(p, h_k, phi_k, w_k, varargin{:});
    opts = p.Results;

    % 確保為列向量
    h_k = h_k(:);
    phi_k = phi_k(:);
    w_k = w_k(:);

    %% 計算加權函數
    weight_k = 1 ./ (1 + (w_k.^2 / opts.wc_rad^2)).^opts.p;

    %% 預計算三角函數值
    sin_phi_k = sin(phi_k);
    cos_phi_k = cos(phi_k);

    %% 構建加權最小平方矩陣
    sum_hk2_wk2 = sum(weight_k .* h_k.^2 .* w_k.^2);
    sum_hk2 = sum(weight_k .* h_k.^2);
    sum_hk_sin_wk = sum(weight_k .* h_k .* sin_phi_k .* w_k);
    sum_hk_cos = sum(weight_k .* h_k .* cos_phi_k);
    sum_hk_cos_wk2 = sum(weight_k .* h_k .* cos_phi_k .* w_k.^2);
    sum_weight = sum(weight_k);

    %% 系統矩陣 (3x3)
    A_mat = [
        sum_hk2_wk2,        0,              sum_hk_sin_wk;
        0,                  sum_hk2,       -sum_hk_cos;
        sum_hk_sin_wk,     -sum_hk_cos,     sum_weight;
    ];

    %% 右側向量 (3x1)
    y_vec = [
        0;
        sum_hk2_wk2;
       -sum_hk_cos_wk2;
    ];

    %% 求解線性系統
    x = A_mat \ y_vec;

    a1 = x(1);
    a2 = x(2);
    b  = x(3);

    %% 計算擬合後的頻率響應 (可選輸出)
    if nargout >= 4
        s = 1j * w_k;
        H_fitted = b ./ (s.^2 + a1*s + a2);
    end

    %% 顯示結果
    if opts.Verbose
        dc_gain = b / a2;
        fprintf('  Single TF fitting:\n');
        fprintf('    Weighting: p=%.1f, wc=%.2f rad/s (%.2f Hz)\n', ...
                opts.p, opts.wc_rad, opts.wc_rad / (2*pi));
        fprintf('    Parameters: a1=%.6f, a2=%.6f, b=%.6f\n', a1, a2, b);
        fprintf('    DC gain (b/a2): %.6f\n', dc_gain);
    end
end
