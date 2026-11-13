function R = compare_fit_methods(varargin)
%COMPARE_FIT_METHODS 2025 vs 2026 open-loop data x legacy vs band fitting (shared 2nd order MIMO)
%
% Data sets
%   2025 : legacy/P1..P6.m (DA 2 V, 2025-09/10, 19 points) = data behind the current R controller model
%   2026 : results/PT3D_OL_2V_20261113/processed/MIMO_Raw_Bode_Data.mat (DA 2 V, 2026-11-13, 15 points;
%          created by run_analysis('PT3D_OL_2V_20261113', 'mimo_all') on the lab PC)
% Frequency sets
%   'all'    : every point of the data set up to 2000 Hz (2025: 19, 2026: 13)
%   'common' : the 11 frequencies both sweeps have (0.1 1 10 50 100 200 500 1000 1200 1600 2000)
% Methods (both inside step_mimo_fit, same phase correction / offset removal)
%   legacy : fit_mimo_tf, p 0.5, wc 0.1 Hz   (how the current controller model was made)
%   band   : fit_mimo_band, B = |H(0.1 Hz)|, A1/A2 over 200-1500 Hz, 6 diagonal curves
% Output: results/compare_fit_20261113/ (README.md, compare_fit.mat, figures)
%
% Usage: compare_fit_methods            % or compare_fit_methods('Band', [200 1500])

    pr = inputParser;
    addParameter(pr, 'Band', [200 1500], @isnumeric);
    parse(pr, varargin{:});
    root = fileparts(mfilename('fullpath'));
    out_dir = fullfile(root, 'results', 'compare_fit_20261113');
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end
    common = [0.1 1 10 50 100 200 500 1000 1200 1600 2000];

    %% load data sets (raw phase, no correction)
    cM = MIMO_config();
    [Hm25, Hp25, F25] = load_legacy_pdata(cM.mimo.legacy_data_folder, 'Verbose', false);
    S = load(fullfile(root, 'results', 'PT3D_OL_2V_20261113', 'processed', 'MIMO_Raw_Bode_Data.mat'));
    Hm26 = S.raw_bode.H_mag; Hp26 = S.raw_bode.H_phase_raw; F26 = S.raw_bode.frequencies;
    D = struct('name', {'2025', '2026'}, 'Hm', {Hm25, Hm26}, 'Hp', {Hp25, Hp26}, 'F', {F25(:).', F26(:).'});

    %% fit
    cfg = cM;
    cfg.output.save_csv = false; cfg.output.save_fitting_results = false; cfg.output.save_processed_mat = false;
    cfg.fitting.band.enable = true; cfg.fitting.band.range = pr.Results.Band; cfg.fitting.band.curves = 'diag';
    R = struct([]); n = 0;
    for d = 1:2
        for fs = {'all', 'common'}
            F = D(d).F;
            if strcmp(fs{1}, 'all'), k = F <= 2000 + 1e-6;
            else, k = ismembertol(round(F, 1), common, 1e-3); end
            [~, fr] = evalc('step_mimo_fit(cfg, D(d).Hm(:,:,k), D(d).Hp(:,:,k), F(k), ''Verbose'', false)');
            n = n + 1;
            R(n).data = D(d).name; R(n).fset = fs{1}; R(n).F = F(k); R(n).fit = fr;
        end
    end

    %% error of each model against each data set (diagonal curves, normalised to 0.1 Hz)
    for n = 1:numel(R)
        R(n).err_legacy = diag_err(R(n).fit, R(n).fit.A1, R(n).fit.A2);
        R(n).err_band = diag_err(R(n).fit, R(n).fit.band.A1, R(n).fit.band.A2);
    end
    save(fullfile(out_dir, 'compare_fit.mat'), 'R');

    %% figures and record
    plot_data_overlay(R, out_dir);
    plot_fit_overlay(R, out_dir);
    write_record(R, out_dir, pr.Results.Band);
    fprintf('Saved to %s\n', out_dir);
end

function E = diag_err(fr, A1, A2)
    f = fr.frequencies(:).'; [~, i0] = min(f); s = 1j*2*pi*f;
    G = A2 ./ (s.^2 + A1*s + A2);
    E = zeros(6, numel(f));
    for i = 1:6
        H = squeeze(fr.H_mag(i,i,:)).' .* exp(1j*squeeze(fr.H_phase_corrected(i,i,:)).'*pi/180);
        E(i,:) = abs(G ./ (H / H(i0)) - 1);
    end
end

function [Hn, f] = diag_norm(fr, i)
    f = fr.frequencies(:).'; [~, i0] = min(f);
    H = squeeze(fr.H_mag(i,i,:)).' .* exp(1j*squeeze(fr.H_phase_corrected(i,i,:)).'*pi/180);
    Hn = H / abs(H(i0));
end

function plot_data_overlay(R, out_dir)
    % measured diagonal curves (phase offset removed), 2025 vs 2026, one column per axis
    a25 = R(strcmp({R.data}, '2025') & strcmp({R.fset}, 'all')).fit;
    a26 = R(strcmp({R.data}, '2026') & strcmp({R.fset}, 'all')).fit;
    C = [0 0 0.5; 0 0 1; 0 0.5 0; 1 0 0; 0.8 0 0.8; 0 0.75 0.75];
    fig = figure('Color', 'w', 'Position', [40 40 1800 700], 'Visible', 'off');
    tl = tiledlayout(fig, 2, 6, 'Padding', 'compact', 'TileSpacing', 'compact');
    for p = 1:2
        for i = 1:6
            ax = nexttile(tl, (p-1)*6 + i); hold(ax, 'on');
            [h25, f25] = diag_norm(a25, i); [h26, f26] = diag_norm(a26, i);
            Y = @(h) (p == 1)*abs(h) + (p == 2)*unwrap(angle(h))*180/pi;
            l1 = plot(ax, f25, Y(h25), 'o-', 'Color', [0.55 0.55 0.55], 'LineWidth', 2, 'MarkerSize', 7);
            l2 = plot(ax, f26, Y(h26), 'd-', 'Color', C(i,:), 'LineWidth', 2, 'MarkerSize', 7);
            set(ax, 'XScale', 'log', 'FontName', 'Arial', 'FontSize', 11, 'LineWidth', 1.5, 'Box', 'on', 'TickDir', 'out');
            grid(ax, 'on'); xlim(ax, [0.1 2500]);
            if p == 1
                ylim(ax, [0 1.15]); title(ax, sprintf('P%d', i), 'FontSize', 13, 'FontWeight', 'bold');
                if i == 1, ylabel(ax, 'Magnitude (norm.)', 'FontSize', 12, 'FontWeight', 'bold'); end
            else
                ylim(ax, [-180 5]); yticks(ax, -180:30:0); xlabel(ax, 'Frequency (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
                if i == 1, ylabel(ax, 'Phase (deg)', 'FontSize', 12, 'FontWeight', 'bold'); end
            end
        end
    end
    lg = legend([l1 l2], {'2025-09/10 (legacy P*.m)', '2026-11-13'}, 'Orientation', 'horizontal', 'FontSize', 12);
    lg.Layout.Tile = 'south';
    exportgraphics(fig, fullfile(out_dir, 'data_2025_vs_2026_diag.png'), 'Resolution', 200); close(fig);
end

function plot_fit_overlay(R, out_dir)
    % all 6 diagonal curves of each data set with the legacy and the band model of that data set
    C = [0 0 0.5; 0 0 1; 0 0.5 0; 1 0 0; 0.8 0 0.8; 0 0.75 0.75]; M = {'o','s','^','d','v','p'};
    fig = figure('Color', 'w', 'Position', [40 40 1600 850], 'Visible', 'off');
    tl = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    names = {'2025', '2026'}; fv = logspace(-1, log10(2500), 400); sv = 1j*2*pi*fv;
    for c = 1:2
        fr = R(strcmp({R.data}, names{c}) & strcmp({R.fset}, 'all')).fit;
        Gl = fr.A2 ./ (sv.^2 + fr.A1*sv + fr.A2); Gb = fr.band.A2 ./ (sv.^2 + fr.band.A1*sv + fr.band.A2);
        for p = 1:2
            ax = nexttile(tl, (p-1)*2 + c); hold(ax, 'on');
            Y = @(h) (p == 1)*abs(h) + (p == 2)*unwrap(angle(h))*180/pi;
            yl = [0 1.15; -180 5]; yl = yl(p,:);
            patch(ax, [fr.band.band fliplr(fr.band.band)], [yl(1) yl(1) yl(2) yl(2)], [0.93 0.93 0.93], 'EdgeColor', 'none');
            for i = 1:6
                [h, f] = diag_norm(fr, i);
                hp(i) = plot(ax, f, Y(h), M{i}, 'Color', C(i,:), 'LineWidth', 2, 'MarkerSize', 8); %#ok<AGROW>
            end
            hl = plot(ax, fv, Y(Gl), '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 3.5);
            hb = plot(ax, fv, Y(Gb), '--', 'Color', [0 0 0], 'LineWidth', 3);
            set(ax, 'XScale', 'log', 'FontName', 'Arial', 'FontSize', 12, 'LineWidth', 1.5, 'Box', 'on', 'TickDir', 'out', 'Layer', 'top');
            grid(ax, 'on'); xlim(ax, [0.1 2500]); ylim(ax, yl);
            if p == 1
                title(ax, sprintf('%s data', names{c}), 'FontSize', 14, 'FontWeight', 'bold');
                ylabel(ax, 'Magnitude (norm.)', 'FontSize', 13, 'FontWeight', 'bold');
            else
                yticks(ax, -180:30:0); ylabel(ax, 'Phase (deg)', 'FontSize', 13, 'FontWeight', 'bold');
                xlabel(ax, 'Frequency (Hz)', 'FontSize', 13, 'FontWeight', 'bold');
            end
        end
    end
    lg = legend([hp hl hb], {'P1','P2','P3','P4','P5','P6', 'Legacy fit (w_c 0.1 Hz)', 'Band fit (shaded band)'}, ...
        'NumColumns', 8, 'FontSize', 11);
    lg.Layout.Tile = 'south';
    exportgraphics(fig, fullfile(out_dir, 'fits_legacy_vs_band.png'), 'Resolution', 200); close(fig);
end

function write_record(R, out_dir, band)
    fid = fopen(fullfile(out_dir, 'README.md'), 'w', 'n', 'UTF-8'); c = onCleanup(@() fclose(fid));
    w = @(varargin) fprintf(fid, varargin{:});
    w('# Open-loop plant fit: 2025 vs 2026 data, legacy vs band method\n\n');
    w('Generated by `compare_fit_methods.m` (%s).\n\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
    w('- **2025**: `legacy/P1..P6.m`, DA 2 V, recorded 2025-09-15/16 and 2025-10-03 (raw files on the WD_BLACK drive `F:\\P1..P6`). This is the data behind the current R controller model.\n');
    w('- **2026**: PT3D_SW FreqSweep, open loop, DA 2 V, 2026-11-13, HSData V8, 100 kHz (`results/PT3D_OL_2V_20261113/processed/`).\n');
    w('- **legacy** method: `fit_mimo_tf`, p 0.5, wc 0.1 Hz (all 36 curves, shared A1/A2). **band** method: `fit_mimo_band`, B = |H(0.1 Hz)|, A1/A2 over %g-%g Hz on the 6 diagonal curves.\n', band);
    w('- Both use the same `step_mimo_fit` preprocessing: auto 180 deg correction, phase offset removed at 0.1 Hz. Continuous model G(s) = A2/(s^2 + A1 s + A2), H = G B; discrete = ZOH at T = 1e-5 s: H(z) = k_o (z^-1 + b z^-2)/(1 - a1 z^-1 - a2 z^-2).\n');
    w('- Frequency sets: **all** = every point up to 2000 Hz; **common** = the 11 frequencies both sweeps have.\n\n');
    w('## Transfer functions\n\n');
    w('| data | freq set | method | A1 | A2 | poles (Hz) | k_o | b | a1 | a2 | B diag |\n|---|---|---|---|---|---|---|---|---|---|---|\n');
    for n = 1:numel(R)
        fr = R(n).fit; pz = -roots([1 fr.A1 fr.A2]).'/(2*pi);
        nz = fr.discrete.num_z; dz = fr.discrete.den_z;
        w('| %s | %s (%d) | legacy | %.1f | %.4e | %s | %.4e | %.4f | %.6f | %.6f | %s |\n', R(n).data, R(n).fset, numel(R(n).F), ...
            fr.A1, fr.A2, pstr(pz), nz(2), nz(3)/nz(2), -dz(2), -dz(3), mat2str(diag(fr.B_modified).', 4));
        b = fr.band;
        w('| %s | %s (%d) | band | %.1f | %.4e | %s | %.4e | %.4f | %.6f | %.6f | %s |\n', R(n).data, R(n).fset, numel(R(n).F), ...
            b.A1, b.A2, pstr(b.poles_Hz), b.discrete.k_o, b.discrete.b, b.discrete.a1, b.discrete.a2, mat2str(diag(b.B_modified).', 4));
    end
    w('\n(Current R controller constants, PT3D_SW before 2026-11-13: k_o 5.6695e-4, b 0.9782, a1 1.934848, a2 -0.935970 = legacy fit of the 2025 data.)\n\n');
    w('## Fit error (complex relative error |G/Hn - 1|, mean of the 6 diagonal curves)\n\n');
    fq = [100 200 500 1000 1600 2000];
    w('| data | freq set | method |'); w(' %g Hz |', fq); w('\n|---|---|---|'); w(repmat('---|', 1, numel(fq))); w('\n');
    for n = 1:numel(R)
        for m = {'legacy', 'band'}
            E = R(n).(['err_' m{1}]); f = R(n).F;
            w('| %s | %s | %s |', R(n).data, R(n).fset, m{1});
            for q = fq
                [d, j] = min(abs(f - q));
                if d < 1, w(' %.0f%% |', 100*mean(E(:, j))); else, w(' - |'); end
            end
            w('\n');
        end
    end
    w('\n## B matrix (B_modified, legacy method, all points)\n\n');
    for d = {'2025', '2026'}
        fr = R(strcmp({R.data}, d{1}) & strcmp({R.fset}, 'all')).fit;
        w('%s:\n```\n', d{1}); w('%s\n', strtrim(evalc('disp(round(fr.B_modified, 4))'))); w('```\n');
    end
    w('\n## Figures\n\n![data](data_2025_vs_2026_diag.png)\n\n![fits](fits_legacy_vs_band.png)\n');
end

function s = pstr(p)
    p = p(:).';
    if any(abs(imag(p)) > 1e-6), s = sprintf('%.1f ± %.1fj', real(p(1)), abs(imag(p(1))));
    else, s = sprintf('%.1f, %.1f', sort(real(p))); end
end
