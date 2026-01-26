function [A1, A2, B, b_vec] = fit_mimo_tf(H_mag, H_phase, frequencies, varargin)
%FIT_MIMO_TF MIMO 多曲線轉移函數擬合
%
% 使用加權最小平方法擬合 6x6 MIMO 轉移函數
% 所有 36 個通道共享相同的分母 (A1, A2)
%
% 模型:
%   H(s) = [A2 / (s² + A1·s + A2)] · B
%   其中 B 是 6x6 增益矩陣
%
% 使用方式:
%   [A1, A2, B] = fit_mimo_tf(H_mag, H_phase, frequencies)
%   [A1, A2, B, b_vec] = fit_mimo_tf(..., 'Name', 'Value', ...)
%
% 輸入:
%   H_mag       - 幅值矩陣 (6 x 6 x N)
%   H_phase     - 相位矩陣 [deg] (6 x 6 x N)，應已移除相位偏移
%   frequencies - 頻率向量 [Hz] (1 x N)
%
% 選項 (Name-Value pairs):
%   'p'                  - 加權指數 (default: 0.5)
%   'wc_Hz'              - 截止頻率 [Hz] (default: 0.1)
%   'NegateOffDiagonal'  - 對非對角元素取反 (default: true)
%   'Verbose'            - 顯示處理信息 (default: true)
%
% 輸出:
%   A1, A2 - 共享分母係數
%   B      - 6x6 增益矩陣 (DC 增益 = B(i,j))
%   b_vec  - 36x1 原始 b 向量 (可選)
%
% 加權函數:
%   w(ω) = 1/(1+(ω²/ωc²))^p

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'H_mag', @isnumeric);
    addRequired(p, 'H_phase', @isnumeric);
    addRequired(p, 'frequencies', @isnumeric);
    addParameter(p, 'p', 0.5, @isnumeric);
    addParameter(p, 'wc_Hz', 0.1, @isnumeric);
    addParameter(p, 'NegateOffDiagonal', true, @islogical);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, H_mag, H_phase, frequencies, varargin{:});
    opts = p.Results;

    %% 驗證輸入維度
    [num_out, num_in, num_freq] = size(H_mag);
    if num_out ~= 6 || num_in ~= 6
        error('H_mag must be 6 x 6 x N');
    end
    if length(frequencies) ~= num_freq
        error('frequencies length must match third dimension of H_mag');
    end

    %% 轉換頻率為 rad/s
    w_k = frequencies(:) * 2 * pi;
    wc_rad = opts.wc_Hz * 2 * pi;

    %% 計算加權函數
    weight_k = 1 ./ (1 + (w_k.^2 / wc_rad^2)).^opts.p;

    if opts.Verbose
        fprintf('MIMO TF Fitting:\n');
        fprintf('  Weighting: p=%.1f, wc=%.2f Hz\n', opts.p, opts.wc_Hz);
    end

    %% 重整數據: 6x6xN → 36xN
    h_Lk = zeros(36, num_freq);
    phi_Lk = zeros(36, num_freq);

    for i = 1:6
        for j = 1:6
            L = (i-1)*6 + j;
            h_Lk(L, :) = squeeze(H_mag(i, j, :));
            phi_Lk(L, :) = squeeze(H_phase(i, j, :)) * pi / 180;  % deg → rad
        end
    end

    sin_phi_Lk = sin(phi_Lk);
    cos_phi_Lk = cos(phi_Lk);

    %% 構建 2x2 區塊矩陣元素

    % a11: Σ_k w(ω_k) (Σ_ℓ h²_ℓk) ω²_k
    a11 = 0;
    for k = 1:num_freq
        sum_h2 = sum(h_Lk(:, k).^2);
        a11 = a11 + weight_k(k) * sum_h2 * w_k(k)^2;
    end

    % a22: Σ_k w(ω_k) (Σ_ℓ h²_ℓk)
    a22 = 0;
    for k = 1:num_freq
        sum_h2 = sum(h_Lk(:, k).^2);
        a22 = a22 + weight_k(k) * sum_h2;
    end

    % v1: a1(2+ℓ) = Σ_k w(ω_k) h_ℓk s_ℓk ω_k
    v1 = zeros(36, 1);
    for L = 1:36
        for k = 1:num_freq
            v1(L) = v1(L) + weight_k(k) * h_Lk(L, k) * sin_phi_Lk(L, k) * w_k(k);
        end
    end

    % v2: a2(2+ℓ) = -Σ_k w(ω_k) h_ℓk c_ℓk
    v2 = zeros(36, 1);
    for L = 1:36
        for k = 1:num_freq
            v2(L) = v2(L) - weight_k(k) * h_Lk(L, k) * cos_phi_Lk(L, k);
        end
    end

    % yb: y(2+ℓ) = -Σ_k w(ω_k) h_ℓk c_ℓk ω²_k
    yb = zeros(36, 1);
    for L = 1:36
        for k = 1:num_freq
            yb(L) = yb(L) - weight_k(k) * h_Lk(L, k) * cos_phi_Lk(L, k) * w_k(k)^2;
        end
    end

    % y1, y2
    y1 = 0;
    y2 = 0;
    for k = 1:num_freq
        sum_h2 = sum(h_Lk(:, k).^2);
        y2 = y2 + weight_k(k) * sum_h2 * w_k(k)^2;
    end

    % 總權重
    W_total = sum(weight_k);

    %% 構建 2x2 區塊矩陣
    A_2x2 = [
        a11 - (1/W_total)*v1'*v1,     -(1/W_total)*v1'*v2;
        -(1/W_total)*v2'*v1,          a22 - (1/W_total)*v2'*v2
    ];

    Y_2x2 = [
        y1 - (1/W_total)*v1'*yb;
        y2 - (1/W_total)*v2'*yb
    ];

    % 檢查矩陣條件數
    cond_num = cond(A_2x2);
    if cond_num > 1e12
        warning('Matrix may be ill-conditioned (cond=%.2e)', cond_num);
    end

    %% 求解 A1, A2
    X_2x2 = A_2x2 \ Y_2x2;
    A1 = X_2x2(1);
    A2 = X_2x2(2);

    %% 求解 b 向量和 B 矩陣
    b_vec = (1/W_total) * (yb - A1*v1 - A2*v2);  % 36x1

    B = zeros(6, 6);
    for i = 1:6
        for j = 1:6
            L = (i-1)*6 + j;
            b_ij = b_vec(L);
            B(i, j) = b_ij / A2;  % DC 增益 = b / A2
        end
    end

    %% 非對角元素取反 (表示耦合抑制)
    if opts.NegateOffDiagonal
        for i = 1:6
            for j = 1:6
                if i ~= j
                    B(i, j) = -B(i, j);
                end
            end
        end
    end

    %% 顯示結果
    if opts.Verbose
        fprintf('  Parameters:\n');
        fprintf('    A1 = %.10f\n', A1);
        fprintf('    A2 = %.10f\n', A2);
        fprintf('  Transfer function:\n');
        fprintf('    H(s) = [%.4e / (s^2 + %.4e*s + %.4e)] * B\n', A2, A1, A2);
        fprintf('  Matrix condition number: %.2e\n', cond_num);

        % 顯示 B 矩陣對角線元素
        fprintf('  B matrix diagonal: [');
        for i = 1:6
            if i > 1
                fprintf(', ');
            end
            fprintf('%.4f', B(i,i));
        end
        fprintf(']\n');
    end
end
