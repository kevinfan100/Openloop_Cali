function step_plot(config, fit_results, varargin)
%STEP_PLOT Bode 圖生成 (Data Only / Model+Data)
%
% Usage:
%   step_plot(config, fit_results)
%   step_plot(config, [], 'DataOnly', true, 'FromCSV', true)
%
% Input:
%   config      - experiment config struct
%   fit_results - step_fit 的輸出 (或 [] 搭配 DataOnly/FromCSV)

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'DataOnly', false, @islogical);
    addParameter(p, 'FromCSV', false, @islogical);
    addParameter(p, 'SaveFigure', true, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;
    data_only = p.Results.DataOnly;
    save_fig = p.Results.SaveFigure;

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_plot: %s\n', config.experiment_name);
        fprintf('========================================\n\n');
    end

    %% Load data
    if p.Results.FromCSV || (isempty(fit_results) && data_only)
        csv_path = fullfile(config.output_folder, 'diagnostics', 'Raw_Bode_Data.csv');
        bode_table = readtable(csv_path);
        frequencies = bode_table.Frequency_Hz;
        magnitudes_linear = bode_table.Magnitude_Linear;
        phases_raw = bode_table.Phase_deg;
        [~, min_idx] = min(frequencies);
        phase_offset = phases_raw(min_idx);
        phases_normalized = phases_raw - phase_offset;
        H_ref = magnitudes_linear(min_idx);
    else
        frequencies = fit_results.frequencies;
        magnitudes_linear = fit_results.magnitudes_linear;
        phases_normalized = fit_results.phases_normalized;
        [~, min_idx] = min(frequencies);
        H_ref = magnitudes_linear(min_idx);
    end

    %% Figure size and style
    fig_size = config.plot.figure_size_bode;
    lw = config.plot.line_width;
    ms = config.plot.marker_size;
    freq_max = max(frequencies);
    log_ticks = 10.^((-1:ceil(log10(freq_max))));
    font_props = {'FontWeight', 'bold', 'FontSize', config.plot.font_size_tick, 'LineWidth', 2};
    axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};

    %% Normalize magnitudes
    h_db_norm = 20*log10(magnitudes_linear / H_ref);

    %% Create figure with tabs
    fig = figure('Name', sprintf('Bode - %s', config.experiment_name), 'Position', fig_size);

    if ~data_only && ~isempty(fit_results)
        tabgp = uitabgroup(fig);

        %% ===== Tab 1: Model + Measured =====
        tab1 = uitab(tabgp, 'Title', 'Model + Measured');

        % Model curve
        dc_gain = fit_results.dc_gain;
        a1 = fit_results.a1;
        a2 = fit_results.a2;
        b = fit_results.b;
        freq_smooth = logspace(log10(0.1), log10(freq_max), 200);
        s_smooth = 1j * 2 * pi * freq_smooth;
        H_model = b ./ (s_smooth.^2 + a1*s_smooth + a2);

        h_k_tab1 = magnitudes_linear / dc_gain;
        h_db_tab1 = 20*log10(h_k_tab1);
        H_model_norm = H_model / dc_gain;

        % Magnitude
        subplot(2, 1, 1, 'Parent', tab1);
        hold on;
        semilogx(freq_smooth, 20*log10(abs(H_model_norm)), 'k-', 'LineWidth', 3, ...
            'DisplayName', 'Model');
        semilogx(frequencies, h_db_tab1, 'o-b', 'LineWidth', lw, 'MarkerSize', ms, ...
            'MarkerFaceColor', 'none', ...
            'DisplayName', sprintf('Measured (H(0)=%.4f)', dc_gain));
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_label);
        legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_legend);
        set(gca, axis_props{:}, font_props{:});
        ylim([min(real(h_db_tab1)) - 5, 5]);
        ax = gca; ax.XAxis.LineWidth = config.plot.axis_line_width; ax.YAxis.LineWidth = config.plot.axis_line_width;
        box on;

        % Phase
        subplot(2, 1, 2, 'Parent', tab1);
        hold on;
        semilogx(frequencies, phases_normalized, 'o-b', 'LineWidth', lw, ...
            'MarkerSize', ms, 'MarkerFaceColor', 'none');
        H_model_phase = angle(H_model) * 180/pi;
        semilogx(freq_smooth, H_model_phase, 'k-', 'LineWidth', 3);
        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_label);
        ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_label);
        set(gca, axis_props{:}, font_props{:});
        ylim([-180, 0]);
        ax = gca; ax.XAxis.LineWidth = config.plot.axis_line_width; ax.YAxis.LineWidth = config.plot.axis_line_width;
        box on;

        p_w = fit_results.config_snapshot.p_weight;
        wc = fit_results.config_snapshot.wc_Hz;
        sgtitle(sprintf('H(s), p=%.1f, \\omega_c=%.1f Hz', p_w, wc), ...
            'FontWeight', 'bold', 'FontSize', config.plot.font_size_title);

        if save_fig
            fig_folder = fullfile(config.output_folder, 'figures');
            if ~exist(fig_folder, 'dir'), mkdir(fig_folder); end
            out_file = fullfile(fig_folder, sprintf('Bode_%s_Model66_style.png', config.experiment_name));
            exportgraphics(tab1, out_file, 'Resolution', 150);
            if verbose, fprintf('Saved: %s\n', out_file); end
        end

        %% ===== Tab 2: Data Only =====
        tab2 = uitab(tabgp, 'Title', 'Measured Data Only');
    else
        tab2 = fig;
    end

    %% Data Only plot
    if ~data_only && ~isempty(fit_results)
        parent = tab2;
    else
        parent = fig;
    end

    freq_ref = frequencies(min_idx);

    % Magnitude
    subplot(2, 1, 1, 'Parent', parent);
    hold on;
    semilogx(frequencies, h_db_norm, 'o-b', 'LineWidth', lw, 'MarkerSize', ms, ...
        'MarkerFaceColor', 'none', ...
        'DisplayName', sprintf('Measured (H(%.1f Hz)=%.4f)', freq_ref, H_ref));
    ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_label);
    legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_legend);
    set(gca, axis_props{:}, font_props{:});
    ylim([min(real(h_db_norm)) - 5, 5]);
    ax = gca; ax.XAxis.LineWidth = config.plot.axis_line_width; ax.YAxis.LineWidth = config.plot.axis_line_width;
    box on;

    % Phase
    subplot(2, 1, 2, 'Parent', parent);
    hold on;
    semilogx(frequencies, phases_normalized, 'o-b', 'LineWidth', lw, ...
        'MarkerSize', ms, 'MarkerFaceColor', 'none');
    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_label);
    ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', config.plot.font_size_label);
    set(gca, axis_props{:}, font_props{:});
    ylim([-180, 0]);
    ax = gca; ax.XAxis.LineWidth = config.plot.axis_line_width; ax.YAxis.LineWidth = config.plot.axis_line_width;
    box on;

    if save_fig
        fig_folder = fullfile(config.output_folder, 'figures');
        if ~exist(fig_folder, 'dir'), mkdir(fig_folder); end
        out_file = fullfile(fig_folder, sprintf('Bode_%s_DataOnly.png', config.experiment_name));
        if ~data_only && ~isempty(fit_results)
            tabgp.SelectedTab = tab2;
            drawnow;
            exportgraphics(tab2, out_file, 'Resolution', 150);
            tabgp.SelectedTab = tab1;
        else
            exportgraphics(fig, out_file, 'Resolution', 150);
        end
        if verbose, fprintf('Saved: %s\n', out_file); end
    end

    if verbose
        fprintf('\nstep_plot complete.\n');
    end
end
