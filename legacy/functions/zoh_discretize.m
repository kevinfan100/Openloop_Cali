function [num_z, den_z, H_discrete, poles_z] = zoh_discretize(A1, A2, T_sample, varargin)
%ZOH_DISCRETIZE 零階保持離散化
%
% 將連續時間轉移函數通過 ZOH 方法轉換為離散時間系統
%
% 連續模型:
%   H(s) = A2 / (s² + A1·s + A2)
%
% 離散模型:
%   H(z⁻¹) = z⁻¹ * (b0 + b1·z⁻¹) / (1 + a1·z⁻¹ + a2·z⁻²)
%
% 使用方式:
%   [num_z, den_z] = zoh_discretize(A1, A2, T_sample)
%   [num_z, den_z, H_discrete, poles_z] = zoh_discretize(..., 'Verbose', true)
%
% 輸入:
%   A1       - 分母一次項係數
%   A2       - 分母常數項係數 (也是分子)
%   T_sample - 取樣時間 [s]
%
% 選項 (Name-Value pairs):
%   'Verbose' - 顯示處理信息 (default: true)
%
% 輸出:
%   num_z     - 分子係數 [b0, b1] (z⁻¹ 形式)
%   den_z     - 分母係數 [1, a1, a2] (已正規化)
%   H_discrete - 離散轉移函數物件 (tf)
%   poles_z   - Z 域極點

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'A1', @isnumeric);
    addRequired(p, 'A2', @isnumeric);
    addRequired(p, 'T_sample', @isnumeric);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, A1, A2, T_sample, varargin{:});
    opts = p.Results;

    %% 建立連續時間轉移函數
    num_s = A2;
    den_s = [1, A1, A2];
    H_continuous = tf(num_s, den_s);

    %% 使用 ZOH 方法離散化
    H_discrete = c2d(H_continuous, T_sample, 'zoh');

    %% 提取離散轉移函數係數
    [num_z_raw, den_z_raw] = tfdata(H_discrete, 'v');

    % 正規化分母 (確保首項為 1)
    den_z = den_z_raw / den_z_raw(1);
    num_z_normalized = num_z_raw / den_z_raw(1);

    % 提取 z⁻¹ 形式的係數
    % MATLAB 的 c2d 輸出為 [0, b0, b1] 形式 (因為有一個 z⁻¹ 延遲)
    num_z = [num_z_normalized(2), num_z_normalized(3)];

    %% 計算 Z 域極點
    poles_z = roots([1, den_z(2), den_z(3)]);

    %% 顯示結果
    if opts.Verbose
        fprintf('ZOH Discretization (T = %.0e s, Fs = %.0f kHz):\n', ...
                T_sample, 1/T_sample/1000);

        % 係數
        fprintf('  Numerator [b0, b1]: [%.6e, %.6e]\n', num_z(1), num_z(2));
        fprintf('  Denominator [1, a1, a2]: [1, %.6e, %.6e]\n', den_z(2), den_z(3));

        % 因式分解形式
        b0 = num_z(1);
        b1 = num_z(2);
        b1_over_b0 = b1 / b0;
        b0_exp = floor(log10(abs(b0)));
        b0_mantissa = b0 / 10^b0_exp;

        fprintf('  Factored form:\n');
        fprintf('    H(z⁻¹) = z⁻¹ × %.4f×10^%d × (1 + %.4f z⁻¹) / (1 + %.6f z⁻¹ + %.6f z⁻²)\n', ...
                b0_mantissa, b0_exp, b1_over_b0, den_z(2), den_z(3));

        % 極點分析
        fprintf('  Z-domain poles:\n');
        fprintf('    z1 = %.8f %+.8fi, |z1| = %.8f\n', ...
                real(poles_z(1)), imag(poles_z(1)), abs(poles_z(1)));
        fprintf('    z2 = %.8f %+.8fi, |z2| = %.8f\n', ...
                real(poles_z(2)), imag(poles_z(2)), abs(poles_z(2)));

        % 極點類型
        if abs(imag(poles_z(1))) > 1e-8
            fprintf('    Type: Complex conjugate pair (oscillatory)\n');
        else
            fprintf('    Type: Real poles\n');
        end

        % 穩定性檢查
        if all(abs(poles_z) < 1)
            fprintf('    Stability: STABLE (all poles inside unit circle)\n');
        else
            fprintf('    Stability: UNSTABLE (poles outside unit circle)\n');
        end
    end
end
