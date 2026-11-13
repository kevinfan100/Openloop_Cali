function out = fit_mimo_band(H_mag, H_phase, frequencies, varargin)
%FIT_MIMO_BAND 共享二階形狀擬合 (B 取低頻實測, A1/A2 只擬合指定頻帶)
%
% 模型 (與 fit_mimo_tf 相同結構):
%   H(s) = G(s) * B,   G(s) = A2 / (s^2 + A1*s + A2),   G(0) = 1
%
% 與 fit_mimo_tf (legacy) 的差別:
%   legacy: A1, A2, B 一起做加權最小平方, 權重 w = 1/(1+(f/wc)^2)^p, wc = 0.1 Hz
%           → 權重約 0.1/f, 高頻幾乎不影響 A1/A2
%   band  : 1. B 直接取最低頻點 (0.1 Hz) 的實測振幅 |H_ij(f_min)| (相位已在 f_min 歸零, 與 legacy B_raw 同義);
%              B_modified 依 legacy 慣例將非對角取負
%           2. 固定 G(0) = 1, 只調 A1/A2, 使所選曲線在頻帶 [f_lo, f_hi] 的
%              複數相對誤差 sum |G(jw) / Hn(jw) - 1|^2 最小, Hn = H / H(f_min)
%
% 使用方式:
%   out = fit_mimo_band(H_mag, H_phase_corrected, frequencies)
%   out = fit_mimo_band(..., 'Band', [200 1500], 'Curves', 'diag', 'Init', [A1 A2])
%
% 輸入:
%   H_mag       - 6 x 6 x N magnitude
%   H_phase     - 6 x 6 x N phase [deg], 已做 180 deg 修正與 offset removal (step_mimo_fit 的 H_phase_corrected)
%   frequencies - 1 x N [Hz]
%
% 選項:
%   'Band'    - 擬合頻帶 [Hz] (default [200 1500])
%   'Curves'  - 'diag' (6 條對角, default) | 'all' (36 條, 以 |H(f_min)| 加權)
%   'Init'    - 初始 [A1 A2] (default [9192 1.92e7])
%   'Verbose' - default true
%
% 輸出 struct:
%   A1, A2, B_raw (6x6, |H_ij(f_min)|), B_modified (非對角取負), poles_Hz, band, curves, cost,
%   rel_err (6 x N, 對角曲線的複數相對誤差)

    pr = inputParser;
    addParameter(pr, 'Band', [200 1500], @isnumeric);
    addParameter(pr, 'Curves', 'diag', @ischar);
    addParameter(pr, 'Init', [9192 1.92e7], @isnumeric);
    addParameter(pr, 'Verbose', true, @islogical);
    parse(pr, varargin{:});
    o = pr.Results;

    f = frequencies(:).';
    [~, i0] = min(f);
    s = 1j * 2 * pi * f;
    Hc = H_mag .* exp(1j * H_phase * pi / 180);           % 6 x 6 x N complex
    B = abs(Hc(:, :, i0));                                 % low-frequency gain (= legacy B_raw convention)
    band = f >= o.Band(1) & f <= o.Band(2);
    if nnz(band) < 2
        error('fit_mimo_band:band', 'Fewer than 2 frequency points in the band [%g %g] Hz', o.Band);
    end

    switch lower(o.Curves)
        case 'diag'
            idx = sub2ind([6 6], 1:6, 1:6); w = ones(1, 6);
        case 'all'
            idx = 1:36; w = abs(B(idx)) / max(abs(diag(B)));
        otherwise
            error('fit_mimo_band:curves', 'Curves must be ''diag'' or ''all''');
    end
    Hr = reshape(Hc, 36, []);
    Hn = Hr(idx, :) ./ Hr(idx, i0);                        % normalised to the lowest frequency

    G = @(x) x(2) ./ (s.^2 + x(1) * s + x(2));
    sb = s(band);
    Gb = @(x) x(2) ./ (sb.^2 + x(1) * sb + x(2));
    J = @(y) sum(w(:) .* sum(abs(Gb(exp(y)) ./ Hn(:, band) - 1).^2, 2));
    opt = optimset('MaxFunEvals', 1e4, 'MaxIter', 1e4, 'TolX', 1e-10, 'TolFun', 1e-12, 'Display', 'off');
    [y, cost] = fminsearch(J, log(o.Init), opt);
    x = exp(y);

    out = struct();
    out.A1 = x(1); out.A2 = x(2); out.B_raw = B;
    out.B_modified = -B; out.B_modified(1:7:end) = diag(B);   % legacy sign convention: off-diagonal negated
    out.poles_Hz = sort(-roots([1 x(1) x(2)]) / (2 * pi)).';
    out.band = o.Band; out.curves = o.Curves; out.cost = cost;
    Hd = Hr(sub2ind([6 6], 1:6, 1:6), :) ./ Hr(sub2ind([6 6], 1:6, 1:6), i0);
    out.rel_err = abs(G(x) ./ Hd - 1);

    if o.Verbose
        fprintf('Band fit (%s curves, %g-%g Hz): A1 = %.6g, A2 = %.6g, poles %s Hz\n', ...
            o.Curves, o.Band(1), o.Band(2), x(1), x(2), mat2str(out.poles_Hz, 5));
        fprintf('  B diagonal (f = %g Hz): %s\n', f(i0), mat2str(diag(B).', 4));
    end
end
