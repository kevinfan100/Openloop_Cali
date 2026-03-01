function step_mimo_plot(config, fit_results, varargin)
%STEP_MIMO_PLOT MIMO 6x6 繪圖
%
% 產生 4 種圖表:
%   1. Per-excitation Bode (x6): 每個激勵疊合 5 output channels + model
%   2. B Matrix 視覺化: imagesc + 數值標註
%   3. 共享假設檢驗圖: a1, a2 的 6x6 分布
%   4. Phase Correction Diagnostic: correction_map + raw vs corrected
%
% 使用方式:
%   step_mimo_plot(config, fit_results)

    %% 解析參數
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'config', @isstruct);
    addRequired(p, 'fit_results', @isstruct);
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, config, fit_results, varargin{:});
    opts = p.Results;

    fprintf('\n=== Step MIMO Plot ===\n');

    fr = fit_results;
    W = fr.frequencies;
    fig_folder = fullfile(config.output_folder, 'figures');

    % 通道顏色
    channel_colors = ['k'; 'b'; 'g'; 'r'; 'm'; 'c'];
    pair_map = config.mimo.pair_map;

    %% 1. Per-excitation Bode (x6)
    fprintf('Generating per-excitation Bode plots...\n');

    freq_smooth = logspace(log10(min(W)), log10(max(W)), 200);
    s_smooth = 1j * 2 * pi * freq_smooth;
    freq_max = max(W);
    log_ticks = 10.^(0:ceil(log10(freq_max)));

    for excited_ch = 1:6
        fig = figure('Name', sprintf('MIMO P%d Bode', excited_ch), ...
            'Position', [100, 100, 1000, 900], 'Visible', 'off');

        % === Magnitude ===
        subplot(2, 1, 1);
        hold on;

        % Model curve (normalized)
        H_model = fr.A2 ./ (s_smooth.^2 + fr.A1 * s_smooth + fr.A2);
        semilogx(freq_smooth, 20*log10(abs(H_model)), 'k-', ...
            'LineWidth', 6, 'DisplayName', 'Model');

        % Data (normalized by B matrix)
        for ch = 1:6
            if ch == pair_map(excited_ch), continue; end
            h_meas = squeeze(fr.H_mag(ch, excited_ch, :));
            dc_gain = fr.B_modified(ch, excited_ch);
            if dc_gain == 0, continue; end
            h_norm = h_meas / abs(dc_gain);
            semilogx(W, 20*log10(h_norm), 'o', ...
                'Color', channel_colors(ch), ...
                'LineWidth', 3.5, 'MarkerSize', 12, ...
                'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('P%d (b_{%d%d}=%.4f)', ...
                    ch, ch, excited_ch, dc_gain));
        end

        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
        legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 18);
        set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], ...
            'XTick', log_ticks, 'FontWeight', 'bold', 'FontSize', 24, ...
            'LineWidth', 2);
        ylim([-30, 1]);
        ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
        box on;

        % === Phase ===
        subplot(2, 1, 2);
        hold on;

        H_model_phase = angle(H_model) * 180 / pi;
        semilogx(freq_smooth, H_model_phase, 'k-', 'LineWidth', 6, ...
            'DisplayName', 'Model');

        for ch = 1:6
            if ch == pair_map(excited_ch), continue; end
            phi = squeeze(fr.H_phase_corrected(ch, excited_ch, :));
            dc_gain = fr.B_modified(ch, excited_ch);
            if dc_gain == 0, continue; end
            semilogx(W, phi, 'o', 'Color', channel_colors(ch), ...
                'LineWidth', 3.5, 'MarkerSize', 12, ...
                'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('P%d', ch));
        end

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);
        set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], ...
            'XTick', log_ticks, 'FontWeight', 'bold', 'FontSize', 24, ...
            'LineWidth', 2);
        ylim([-180, 0]);
        ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
        box on;

        sgtitle(sprintf('P%d', excited_ch), ...
            'FontWeight', 'bold', 'FontSize', 24);

        % 存檔
        fig_path = fullfile(fig_folder, sprintf('MIMO_Bode_P%d.png', excited_ch));
        exportgraphics(fig, fig_path, 'Resolution', config.output.figure_dpi);
        close(fig);
        if opts.Verbose
            fprintf('  Saved: %s\n', fig_path);
        end
    end

    %% 2. B Matrix 視覺化
    fprintf('Generating B matrix visualization...\n');
    fig = figure('Name', 'B Matrix', 'Position', [100, 100, 800, 700], ...
        'Visible', 'off');

    imagesc(fr.B_modified);
    colorbar;
    colormap(bluewhitered_simple(256));
    clim([-max(abs(fr.B_modified(:))), max(abs(fr.B_modified(:)))]);

    % 數值標註
    for i = 1:6
        for j = 1:6
            val = fr.B_modified(i, j);
            if abs(val) > 0.1
                txt_color = 'w';
            else
                txt_color = 'k';
            end
            text(j, i, sprintf('%.4f', val), ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 14, 'FontWeight', 'bold', 'Color', txt_color);
        end
    end

    xlabel('Input Channel (Excitation)', 'FontWeight', 'bold', 'FontSize', 24);
    ylabel('Output Channel (Sensor)', 'FontWeight', 'bold', 'FontSize', 24);
    title('B Matrix (off-diagonal negated)', 'FontWeight', 'bold', 'FontSize', 24);
    set(gca, 'XTick', 1:6, 'YTick', 1:6, 'FontSize', 18, 'FontWeight', 'bold');
    axis equal tight;

    fig_path = fullfile(fig_folder, 'MIMO_B_Matrix.png');
    exportgraphics(fig, fig_path, 'Resolution', config.output.figure_dpi);
    close(fig);
    if opts.Verbose, fprintf('  Saved: %s\n', fig_path); end

    %% 3. 共享假設檢驗圖
    fprintf('Generating shared hypothesis test plot...\n');
    fig = figure('Name', 'Shared Hypothesis', 'Position', [100, 100, 1200, 500], ...
        'Visible', 'off');

    bs = fr.batch_single;

    % a1 分布
    subplot(1, 2, 1);
    a1_vals = bs.a1_matrix(:);
    a1_pos = a1_vals(a1_vals > 0);
    histogram(a1_pos, 20, 'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'k');
    hold on;
    xline(mean(a1_pos), 'r-', 'LineWidth', 2);
    xline(fr.A1, 'k--', 'LineWidth', 2);
    xlabel('a_1 value', 'FontWeight', 'bold', 'FontSize', 18);
    ylabel('Count', 'FontWeight', 'bold', 'FontSize', 18);
    title(sprintf('a_1 Distribution (CV=%.1f%%)', bs.cv_a1), ...
        'FontWeight', 'bold', 'FontSize', 18);
    legend({'Single fits', 'Mean (single)', 'MIMO A_1'}, ...
        'FontSize', 14, 'Location', 'best');
    set(gca, 'FontSize', 14, 'FontWeight', 'bold');
    box on;

    % a2 分布
    subplot(1, 2, 2);
    a2_vals = bs.a2_matrix(:);
    a2_pos = a2_vals(a2_vals > 0);
    histogram(a2_pos, 20, 'FaceColor', [0.9, 0.5, 0.3], 'EdgeColor', 'k');
    hold on;
    xline(mean(a2_pos), 'r-', 'LineWidth', 2);
    xline(fr.A2, 'k--', 'LineWidth', 2);
    xlabel('a_2 value', 'FontWeight', 'bold', 'FontSize', 18);
    ylabel('Count', 'FontWeight', 'bold', 'FontSize', 18);
    title(sprintf('a_2 Distribution (CV=%.1f%%)', bs.cv_a2), ...
        'FontWeight', 'bold', 'FontSize', 18);
    legend({'Single fits', 'Mean (single)', 'MIMO A_2'}, ...
        'FontSize', 14, 'Location', 'best');
    set(gca, 'FontSize', 14, 'FontWeight', 'bold');
    box on;

    sgtitle('Shared Parameter Hypothesis Test', ...
        'FontWeight', 'bold', 'FontSize', 20);

    fig_path = fullfile(fig_folder, 'MIMO_Shared_Hypothesis.png');
    exportgraphics(fig, fig_path, 'Resolution', config.output.figure_dpi);
    close(fig);
    if opts.Verbose, fprintf('  Saved: %s\n', fig_path); end

    %% 4. Phase Correction Diagnostic
    fprintf('Generating phase correction diagnostic...\n');
    fig = figure('Name', 'Phase Correction', 'Position', [100, 100, 1200, 500], ...
        'Visible', 'off');

    pd = fr.phase_diag;

    % correction_map
    subplot(1, 2, 1);
    imagesc(double(pd.correction_map));
    colormap(gca, [0.9 0.9 0.9; 0.2 0.5 0.8]);
    clim([0, 1]);

    for i = 1:6
        for j = 1:6
            if pd.correction_map(i, j)
                txt = '180';
                c = 'w';
            else
                txt = '0';
                c = 'k';
            end
            text(j, i, txt, 'HorizontalAlignment', 'center', ...
                'FontSize', 14, 'FontWeight', 'bold', 'Color', c);
        end
    end

    xlabel('Excitation Channel', 'FontWeight', 'bold', 'FontSize', 18);
    ylabel('Output Channel', 'FontWeight', 'bold', 'FontSize', 18);
    title(sprintf('Correction Map (%d/36 corrected)', pd.num_corrected), ...
        'FontWeight', 'bold', 'FontSize', 18);
    set(gca, 'XTick', 1:6, 'YTick', 1:6, 'FontSize', 14, 'FontWeight', 'bold');
    axis equal tight;

    % Raw phase at DC
    subplot(1, 2, 2);
    raw_dc = pd.raw_phase_at_ref(:);
    bar_colors = zeros(36, 3);
    corr_flat = pd.correction_map(:);
    for k = 1:36
        if corr_flat(k)
            bar_colors(k, :) = [0.2, 0.5, 0.8];
        else
            bar_colors(k, :) = [0.7, 0.7, 0.7];
        end
    end

    b_handle = bar(raw_dc, 'FaceColor', 'flat');
    b_handle.CData = bar_colors;

    hold on;
    yline(90, 'r--', 'LineWidth', 2);
    yline(-90, 'r--', 'LineWidth', 2);
    xlabel('Channel index (row-major)', 'FontWeight', 'bold', 'FontSize', 18);
    ylabel('Raw Phase at DC (deg)', 'FontWeight', 'bold', 'FontSize', 18);
    title('Raw Phase at DC', 'FontWeight', 'bold', 'FontSize', 18);
    set(gca, 'FontSize', 14, 'FontWeight', 'bold');
    ylim([-200, 200]);
    box on;

    sgtitle('Phase Correction Diagnostic', ...
        'FontWeight', 'bold', 'FontSize', 20);

    fig_path = fullfile(fig_folder, 'MIMO_Phase_Correction.png');
    exportgraphics(fig, fig_path, 'Resolution', config.output.figure_dpi);
    close(fig);
    if opts.Verbose, fprintf('  Saved: %s\n', fig_path); end

    fprintf('MIMO plotting complete.\n');
end

%% === Local Function: Simple blue-white-red colormap ===
function cmap = bluewhitered_simple(n)
    % Simple diverging colormap: blue → white → red
    half = floor(n/2);
    r_low = linspace(0, 1, half)';
    g_low = linspace(0, 1, half)';
    b_low = ones(half, 1);

    r_high = ones(n - half, 1);
    g_high = linspace(1, 0, n - half)';
    b_high = linspace(1, 0, n - half)';

    cmap = [r_low, g_low, b_low; r_high, g_high, b_high];
end
