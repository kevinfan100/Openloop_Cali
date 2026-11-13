function [A1, A2, b_vec, info] = fit_mimo_tf_sk(H_mag, H_phase, frequencies, varargin)
%FIT_MIMO_TF_SK 原本 fit_mimo_tf 的線性最小平方 (36 曲線共享 A1, A2, 各自 b) + 可選的修正
%
% 原本 (Levy 線性化): 最小化 sum_k w_k sum_l | b_l - H_lk (s_k^2 + A1 s_k + A2) |^2
%   → 乘上分母後誤差 ≈ |D(s)| * 真正誤差, |D| 隨頻率 ~ w^2 成長, 所以需要 wc 0.1 Hz 的強低頻權重壓住。
% 修正選項 (結構、未知數都不變, 仍是一次線性解):
%   'Iter' N      Sanathanan-Koerner 迭代: 權重再除以上一輪的 |D_prev(s)|^2, 收斂後等同直接最小化
%                 |b/D - H|^2 (不再被 |D| 放大), N = 0 即原本做法
%   'Relative'    true: 每條曲線再除以 |H_lk|^2 → 最小化相對誤差 |G/Hn - 1| (高頻小訊號不被忽略)
%   'p', 'wc_Hz'  同原本的頻率權重 w = 1/(1+(f/wc)^2)^p; wc = Inf 表示不加權
%   'Band'        [f_lo f_hi] 只用這段頻率 (default 全部)
% 輸入 H_phase 為已做 180 deg 修正與 offset removal 的相位 [deg] (同 fit_mimo_tf)
% 輸出 b_vec (36x1, 依 (i-1)*6+j 排列), B = b_vec / A2

    pr = inputParser;
    addParameter(pr, 'p', 0.5); addParameter(pr, 'wc_Hz', 0.1); addParameter(pr, 'Iter', 0);
    addParameter(pr, 'Relative', false); addParameter(pr, 'Band', [-Inf Inf]);
    parse(pr, varargin{:}); o = pr.Results;
    f = frequencies(:); k = f >= o.Band(1) & f <= o.Band(2); f = f(k);
    s = 1j*2*pi*f; nf = numel(f);
    H = reshape(H_mag .* exp(1j*H_phase*pi/180), 36, []); H = H(:, k);      % 36 x nf
    if isinf(o.wc_Hz), w = ones(nf, 1); else, w = 1 ./ (1 + (f/o.wc_Hz).^2).^o.p; end
    Dp = ones(nf, 1);
    for it = 0:o.Iter
        % unknowns x = [A1; A2; b_1..b_36]; residual r_lk = b_l - H_lk*(s_k*A1 + A2) - H_lk*s_k^2
        M = zeros(36*nf, 38); y = zeros(36*nf, 1); wt = zeros(36*nf, 1);
        for l = 1:36
            rows = (l-1)*nf + (1:nf);
            M(rows, 1) = -H(l,:).' .* s; M(rows, 2) = -H(l,:).'; M(rows, 2+l) = 1;
            y(rows) = H(l,:).' .* s.^2;
            ww = w ./ abs(Dp).^2;
            if o.Relative, ww = ww ./ abs(H(l,:).').^2 .* abs(H(l,1))^2; end
            wt(rows) = ww;
        end
        sw = sqrt(wt); Mr = [real(M); imag(M)] .* [sw; sw]; yr = [real(y); imag(y)] .* [sw; sw];
        x = Mr \ yr;
        A1 = x(1); A2 = x(2); b_vec = x(3:end);
        Dp = s.^2 + A1*s + A2;
    end
    info.frequencies = f; info.iter = o.Iter;
end
