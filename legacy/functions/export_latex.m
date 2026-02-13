function export_latex(output_path, A1, A2, B, num_z, den_z, varargin)
%EXPORT_LATEX 輸出轉移函數 LaTeX 格式
%
% 產生連續和離散轉移函數的 LaTeX 格式輸出
%
% 使用方式:
%   export_latex(output_path, A1, A2, B, num_z, den_z)
%   export_latex(..., 'Name', 'Value', ...)
%
% 輸入:
%   output_path - 輸出檔案路徑 (如 'results/reports/transfer_function_latex.txt')
%   A1, A2      - 連續轉移函數分母係數
%   B           - 6x6 增益矩陣
%   num_z       - 離散分子係數 [b0, b1]
%   den_z       - 離散分母係數 [1, a1, a2]
%
% 選項 (Name-Value pairs):
%   'T_sample'   - 取樣時間 [s] (default: 1e-5)
%   'k_A'        - 放大器增益矩陣 (default: 對角矩陣)
%   'Verbose'    - 顯示處理信息 (default: true)

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'output_path', @ischar);
    addRequired(p, 'A1', @isnumeric);
    addRequired(p, 'A2', @isnumeric);
    addRequired(p, 'B', @isnumeric);
    addRequired(p, 'num_z', @isnumeric);
    addRequired(p, 'den_z', @isnumeric);
    addParameter(p, 'T_sample', 1e-5, @isnumeric);
    addParameter(p, 'k_A', diag([0.3618, 0.3614, 0.3536, 0.3532, 0.3573, 0.3610]), @isnumeric);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, output_path, A1, A2, B, num_z, den_z, varargin{:});
    opts = p.Results;

    %% 確保輸出目錄存在
    [output_dir, ~, ~] = fileparts(output_path);
    if ~isempty(output_dir) && ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    %% 計算輔助數值
    num_channels = size(B, 1);

    % Z 域極點
    poles_z = roots([1, den_z(2), den_z(3)]);

    % 因式分解參數
    b0 = num_z(1);
    b1 = num_z(2);
    b0_exp = floor(log10(abs(b0)));
    b0_mantissa = b0 / 10^b0_exp;
    b1_over_b0 = b1 / b0;

    % 連續轉移函數指數
    A1_exp = floor(log10(abs(A1)));
    A2_exp = floor(log10(abs(A2)));
    A1_mantissa = A1 / 10^A1_exp;
    A2_mantissa = A2 / 10^A2_exp;

    %% 構建 LaTeX 輸出
    latex_output = {};

    % 檔頭
    latex_output{end+1} = '% ============================================';
    latex_output{end+1} = '% Transfer Function LaTeX Output';
    latex_output{end+1} = sprintf('%% Generated: %s', datestr(now));
    latex_output{end+1} = '% ============================================';
    latex_output{end+1} = '';

    % 1. 連續時間轉移函數
    latex_output{end+1} = '% === Continuous-Time Transfer Function ===';
    latex_output{end+1} = sprintf('%% H(s) = A2 / (s^2 + A1*s + A2) * B');
    latex_output{end+1} = sprintf('%% A1 = %.10f, A2 = %.10f', A1, A2);
    latex_output{end+1} = '';
    latex_output{end+1} = '\mathbf{H}(s) = \frac{';
    latex_output{end+1} = sprintf('%.4f \\times 10^{%d}', A2_mantissa, A2_exp);
    latex_output{end+1} = '}{';
    latex_output{end+1} = sprintf('s^2 + %.4f \\times 10^{%d} s + %.4f \\times 10^{%d}', ...
        A1_mantissa, A1_exp, A2_mantissa, A2_exp);
    latex_output{end+1} = '} \mathbf{B}';
    latex_output{end+1} = '';

    % 2. 離散時間轉移函數 (因式分解形式)
    latex_output{end+1} = '% === Discrete-Time Transfer Function (ZOH) ===';
    latex_output{end+1} = sprintf('%% Sampling Time: T = %.0e s (Fs = %.0f kHz)', ...
                                  opts.T_sample, 1/opts.T_sample/1000);
    latex_output{end+1} = sprintf('%% Numerator: [%.6e, %.6e]', num_z(1), num_z(2));
    latex_output{end+1} = sprintf('%% Denominator: [1, %.6e, %.6e]', den_z(2), den_z(3));
    latex_output{end+1} = '';

    % 根據極點類型選擇格式
    if abs(imag(poles_z(1))) > 1e-6
        % 複數共軛極點 - 使用二次形式
        latex_output{end+1} = '% Factored form (complex poles, using quadratic)';
        latex_output{end+1} = sprintf([...
            '\\mathbf{H}(z^{-1}) = z^{-1} \\frac{' ...
            '%.4f \\times 10^{%d} \\times (1 + %.4f z^{-1})' ...
            '}{' ...
            '1 + %.6f z^{-1} + %.6f z^{-2}' ...
            '} \\mathbf{B}'], ...
            b0_mantissa, b0_exp, b1_over_b0, den_z(2), den_z(3));

        latex_output{end+1} = sprintf([...
            '%% Complex factorization: (1 - (%.6f%+.6fi) z^{-1})(1 - (%.6f%+.6fi) z^{-1})'], ...
            real(poles_z(1)), imag(poles_z(1)), real(poles_z(2)), imag(poles_z(2)));
    else
        % 實數極點 - 因式分解形式
        latex_output{end+1} = '% Factored form (real poles)';
        latex_output{end+1} = sprintf([...
            '\\mathbf{H}(z^{-1}) = z^{-1} \\frac{' ...
            '%.4f \\times 10^{%d} \\times (1 + %.4f z^{-1})' ...
            '}{' ...
            '(1 - %.6f z^{-1})(1 - %.6f z^{-1})' ...
            '} \\mathbf{B}'], ...
            b0_mantissa, b0_exp, b1_over_b0, real(poles_z(1)), real(poles_z(2)));
    end

    % 極點信息
    latex_output{end+1} = sprintf('%% Z-domain poles: z1 = %.8f %+.8fi, z2 = %.8f %+.8fi', ...
        real(poles_z(1)), imag(poles_z(1)), real(poles_z(2)), imag(poles_z(2)));
    latex_output{end+1} = sprintf('%% Pole magnitudes: |z1| = %.8f, |z2| = %.8f', ...
        abs(poles_z(1)), abs(poles_z(2)));
    latex_output{end+1} = '';

    % 3. B 矩陣
    latex_output{end+1} = '% === B Matrix (DC Gain Matrix) ===';
    latex_output{end+1} = '\mathbf{B} = \begin{bmatrix}';
    for i = 1:num_channels
        row_str = '';
        for j = 1:num_channels
            if j == 1
                row_str = sprintf('%.4f', B(i,j));
            else
                row_str = sprintf('%s & %.4f', row_str, B(i,j));
            end
        end
        if i < num_channels
            latex_output{end+1} = sprintf('%s \\\\', row_str);
        else
            latex_output{end+1} = row_str;
        end
    end
    latex_output{end+1} = '\end{bmatrix}';
    latex_output{end+1} = '';

    % 4. 放大器增益矩陣
    latex_output{end+1} = '% === Amplifier Gain Matrix ===';
    latex_output{end+1} = 'k_A = \begin{bmatrix}';
    for i = 1:num_channels
        row_str = '';
        for j = 1:num_channels
            if j == 1
                row_str = sprintf('%.4f', opts.k_A(i,j));
            else
                row_str = sprintf('%s & %.4f', row_str, opts.k_A(i,j));
            end
        end
        if i < num_channels
            latex_output{end+1} = sprintf('%s \\\\', row_str);
        else
            latex_output{end+1} = row_str;
        end
    end
    latex_output{end+1} = '\end{bmatrix}';

    %% 寫入檔案
    fid = fopen(output_path, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', output_path);
    end

    for i = 1:length(latex_output)
        fprintf(fid, '%s\n', latex_output{i});
    end
    fclose(fid);

    if opts.Verbose
        fprintf('  LaTeX output saved: %s\n', output_path);
    end
end
