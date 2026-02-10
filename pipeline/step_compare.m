function step_compare(experiment_names, varargin)
%STEP_COMPARE 多實驗比較圖
%
% Usage:
%   step_compare({'Hung', 'Hung_noring', 'NTU'})
%   step_compare({'Hung', 'NTU'}, 'Type', 'bode')
%   step_compare({'Hung', 'Hung_noring', 'NTU'}, 'Type', 'spectrum', 'Frequencies', [1, 10, 100])
%   step_compare({'Hung', 'Hung_noring', 'NTU'}, 'Type', 'lissajous', 'Frequencies', [1, 10, 100])
%   step_compare({'NTU_t', 'NTU_s'}, 'Normalize', false)
%   step_compare({'NTU_t', 'NTU_s'}, 'Type', 'ratio')
%   step_compare({'NTU_t', 'NTU_s'}, 'Type', 'cross_channel', 'Frequencies', [500, 1000, 2000])
%   step_compare({'Hung', 'Hung_noring', 'NTU'}, 'Type', 'all', 'Frequencies', [1, 10, 100])
%
% Input:
%   experiment_names - cell array of experiment names
%
% Type:
%   'bode'          - Bode comparison (default, normalized or raw)
%   'spectrum'      - Vm steady-state spectrum comparison
%   'lissajous'     - Vm vs Current Lissajous comparison
%   'ratio'         - Magnitude ratio + Phase difference (2 experiments)
%   'cross_channel' - Cross-channel time-domain scatter (2 experiments)
%   'all'           - All comparison types
%
% Options:
%   'Normalize' - true (default): normalize to H(0.1Hz), false: raw values
%   'Scale'     - 'dB' (default) or 'linear' (only when Normalize=false)
%
% 順序固定: Hung → Hung(NoRing) → NTU → NTU_t → NTU_s

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'SaveFigure', true, @islogical);
    addParameter(p, 'Type', 'bode', @ischar);
    addParameter(p, 'Frequencies', [1, 10, 100], @isnumeric);
    addParameter(p, 'Normalize', true, @islogical);
    addParameter(p, 'Scale', 'dB', @ischar);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;
    save_fig = p.Results.SaveFigure;
    compare_type = lower(p.Results.Type);
    plot_freqs = p.Results.Frequencies;
    do_normalize = p.Results.Normalize;
    scale_mode = lower(p.Results.Scale);

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_compare: %s [%s]\n', strjoin(experiment_names, ' vs '), compare_type);
        fprintf('========================================\n\n');
    end

    %% Get colors and markers
    colors = get_experiment_colors();

    %% Fixed display order
    ordered_names = order_experiments(experiment_names);
    n_exp = length(ordered_names);
    project_root = fileparts(fileparts(mfilename('fullpath')));

    %% Dispatch by type
    switch compare_type
        case 'bode'
            compare_bode(ordered_names, n_exp, colors, project_root, ...
                do_normalize, scale_mode, save_fig, verbose);
        case 'spectrum'
            compare_spectrum(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        case 'lissajous'
            compare_lissajous(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        case 'ratio'
            compare_ratio(ordered_names, n_exp, colors, project_root, save_fig, verbose);
        case 'cross_channel'
            compare_cross_channel(ordered_names, n_exp, project_root, plot_freqs, save_fig, verbose);
        case 'ts_lissajous'
            compare_ts_lissajous(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        case 'ts_timedomain'
            compare_ts_timedomain(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        case 'all'
            compare_bode(ordered_names, n_exp, colors, project_root, ...
                do_normalize, scale_mode, save_fig, verbose);
            compare_spectrum(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
            compare_lissajous(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
            compare_ratio(ordered_names, n_exp, colors, project_root, save_fig, verbose);
            compare_cross_channel(ordered_names, n_exp, project_root, plot_freqs, save_fig, verbose);
            compare_ts_lissajous(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
            compare_ts_timedomain(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        otherwise
            error('step_compare:unknown_type', ...
                'Unknown Type: %s\nValid: bode, spectrum, lissajous, ratio, cross_channel, ts_lissajous, ts_timedomain, all', compare_type);
    end

    if verbose
        fprintf('\nstep_compare complete.\n');
    end
end

%% ===== Helper: fixed display order =====
function ordered = order_experiments(experiment_names)
    display_order = {'Hung'; 'Hung_noring'; 'NTU'; 'NTU_t'; 'NTU_s'};
    ordered = {};
    for k = 1:length(display_order)
        if any(strcmp(experiment_names, display_order{k}))
            ordered{end+1} = display_order{k}; %#ok<AGROW>
        end
    end
    for k = 1:length(experiment_names)
        if ~any(strcmp(ordered, experiment_names{k}))
            ordered{end+1} = experiment_names{k}; %#ok<AGROW>
        end
    end
end

%% ===== Bode Comparison =====
function compare_bode(ordered_names, n_exp, colors, project_root, do_normalize, scale_mode, save_fig, verbose)
    %% Load CSV data
    exp_data = cell(1, n_exp);
    for i = 1:n_exp
        name = ordered_names{i};
        csv_path = fullfile(project_root, 'results', name, 'diagnostics', 'Raw_Bode_Data.csv');
        if ~exist(csv_path, 'file')
            error('step_compare:no_csv', 'CSV not found for %s: %s', name, csv_path);
        end
        exp_data{i} = readtable(csv_path);
        if verbose, fprintf('Loaded: %s (%d points)\n', name, height(exp_data{i})); end
    end

    %% Reference values
    H_ref = zeros(1, n_exp);
    phase_ref = zeros(1, n_exp);
    for i = 1:n_exp
        [~, idx] = min(abs(exp_data{i}.Frequency_Hz - 0.1));
        H_ref(i) = exp_data{i}.Magnitude_Linear(idx);
        phase_ref(i) = exp_data{i}.Phase_deg(idx);
        if verbose
            fprintf('  %s: H(0.1Hz) = %.4f, Phase(0.1Hz) = %.2f deg\n', ...
                ordered_names{i}, H_ref(i), phase_ref(i));
        end
    end

    %% Plot
    if do_normalize
        fig_name = 'Bode Comparison (Normalized)';
    elseif strcmp(scale_mode, 'linear')
        fig_name = 'Bode Comparison (Linear)';
    else
        fig_name = 'Bode Comparison (dB)';
    end
    fig = figure('Position', [100, 100, 900, 720], 'Name', fig_name);
    freq_max = max(cellfun(@(d) max(d.Frequency_Hz), exp_data));
    log_ticks = 10.^(-1:ceil(log10(freq_max)));
    lw = 3.5;
    ms = 12;

    % Magnitude
    subplot(2, 1, 1);
    hold on;
    for i = 1:n_exp
        name = ordered_names{i};
        freq = exp_data{i}.Frequency_Hz;
        c = colors.(name);

        if do_normalize
            mag_dB = 20*log10(exp_data{i}.Magnitude_Linear / H_ref(i));
            semilogx(freq, mag_dB, [c.marker '-'], 'Color', c.rgb, ...
                'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('%s (H(0.1)=%.4f)', c.display_name, H_ref(i)));
        elseif strcmp(scale_mode, 'linear')
            mag_lin = exp_data{i}.Magnitude_Linear;
            semilogx(freq, mag_lin, [c.marker '-'], 'Color', c.rgb, ...
                'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none', ...
                'DisplayName', c.display_name);
        else
            mag_dB = exp_data{i}.Magnitude_dB;
            semilogx(freq, mag_dB, [c.marker '-'], 'Color', c.rgb, ...
                'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none', ...
                'DisplayName', c.display_name);
        end
    end

    if do_normalize
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
    elseif strcmp(scale_mode, 'linear')
        ylabel('Magnitude (V/V)', 'FontWeight', 'bold', 'FontSize', 40);
        set(gca, 'YScale', 'log');
    else
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
    end
    set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks);
    ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
    box on;

    % Phase
    subplot(2, 1, 2);
    hold on;
    for i = 1:n_exp
        name = ordered_names{i};
        freq = exp_data{i}.Frequency_Hz;
        c = colors.(name);

        if do_normalize
            phase = exp_data{i}.Phase_deg - phase_ref(i);
        else
            phase = exp_data{i}.Phase_deg;
        end
        semilogx(freq, phase, [c.marker '-'], 'Color', c.rgb, ...
            'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none');
    end
    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);
    if ~do_normalize
        ylim([-90, 1]);
    end
    set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks);
    ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
    box on;

    % Legend
    ax_mag = subplot(2, 1, 1);
    if do_normalize
        legend(ax_mag, 'Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);
    else
        legend(ax_mag, 'Orientation', 'horizontal', 'FontWeight', 'bold', 'FontSize', 22, ...
            'Location', 'northoutside');
    end

    if save_fig
        out_folder = fullfile(project_root, 'results');
        if ~exist(out_folder, 'dir'), mkdir(out_folder); end
        if do_normalize
            % TS pair → separate filename
            is_ts = n_exp == 2 && any(strcmp(ordered_names, 'NTU_t')) && any(strcmp(ordered_names, 'NTU_s'));
            if is_ts
                out_file = fullfile(out_folder, 'Comparison_Bode_TS.png');
            else
                out_file = fullfile(out_folder, 'Comparison_Bode.png');
            end
        elseif strcmp(scale_mode, 'linear')
            out_file = fullfile(out_folder, 'Comparison_Bode_Linear.png');
        else
            out_file = fullfile(out_folder, 'Comparison_Bode_dB.png');
        end
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end
end

%% ===== Ratio Comparison =====
function compare_ratio(ordered_names, n_exp, colors, project_root, save_fig, verbose)
    if n_exp ~= 2
        if verbose, fprintf('Ratio requires exactly 2 experiments, got %d. Skipping.\n', n_exp); end
        return;
    end

    %% Load CSV data
    exp_data = cell(1, 2);
    for i = 1:2
        name = ordered_names{i};
        csv_path = fullfile(project_root, 'results', name, 'diagnostics', 'Raw_Bode_Data.csv');
        if ~exist(csv_path, 'file')
            error('step_compare:no_csv', 'CSV not found for %s: %s', name, csv_path);
        end
        exp_data{i} = readtable(csv_path);
        if verbose, fprintf('Loaded: %s (%d points)\n', name, height(exp_data{i})); end
    end

    %% Compute ratio: second / first
    freq1 = exp_data{1}.Frequency_Hz;
    freq2 = exp_data{2}.Frequency_Hz;

    % Match frequencies
    [common_freq, ia, ib] = intersect(round(freq1*1000)/1000, round(freq2*1000)/1000);
    if isempty(common_freq)
        error('step_compare:no_common_freq', 'No common frequencies between %s and %s', ...
            ordered_names{1}, ordered_names{2});
    end

    mag_ratio = exp_data{2}.Magnitude_Linear(ib) ./ exp_data{1}.Magnitude_Linear(ia);
    phase_diff = exp_data{2}.Phase_deg(ib) - exp_data{1}.Phase_deg(ia);

    c1 = colors.(ordered_names{1});
    c2 = colors.(ordered_names{2});
    ratio_label = sprintf('%s / %s', c2.display_name, c1.display_name);

    lw = 3.5;
    ms = 12;
    freq_max = max(common_freq);
    log_ticks = 10.^(-1:ceil(log10(freq_max)));

    fig = figure('Position', [100, 100, 900, 720], 'Name', 'Magnitude Ratio');

    % Magnitude ratio
    subplot(2, 1, 1);
    semilogx(common_freq, mag_ratio, ['o' '-'], 'Color', [0, 0, 0], ...
        'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none', ...
        'DisplayName', ratio_label);
    ylabel(ratio_label, 'FontWeight', 'bold', 'FontSize', 40);
    ylim([0, max(mag_ratio) * 1.15]);
    set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks);
    ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
    box on;

    % Phase difference
    subplot(2, 1, 2);
    semilogx(common_freq, phase_diff, ['o' '-'], 'Color', [0, 0, 0], ...
        'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none');
    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    ylabel('Phase diff (deg)', 'FontWeight', 'bold', 'FontSize', 40);
    ylim([-90, 1]);
    set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks);
    ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
    box on;

    % Shared legend at top (auto-size, centered)
    ax_ratio = subplot(2, 1, 1);
    legend(ax_ratio, 'Orientation', 'horizontal', 'FontWeight', 'bold', 'FontSize', 22, ...
        'Location', 'northoutside');

    if save_fig
        out_file = fullfile(project_root, 'results', 'Comparison_Ratio.png');
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end
end

%% ===== Cross-Channel Comparison =====
function compare_cross_channel(ordered_names, n_exp, project_root, plot_freqs, save_fig, verbose)
    if n_exp ~= 2
        if verbose, fprintf('Cross-channel requires exactly 2 experiments, got %d. Skipping.\n', n_exp); end
        return;
    end

    NUM_PERIODS = 3;
    RELATIVE_THRESHOLD = 0.002;

    config1 = load_experiment_config(ordered_names{1});
    config2 = load_experiment_config(ordered_names{2});

    colors_info = get_experiment_colors();
    c1 = colors_info.(ordered_names{1});
    c2 = colors_info.(ordered_names{2});

    n_freq = length(plot_freqs);
    fig = figure('Position', [100, 100, 1800, 600], 'Name', 'Cross-Channel');

    for freq_idx = 1:n_freq
        target_freq = plot_freqs(freq_idx);
        [dat_file1, ~] = find_dat_file(config1, target_freq);

        subplot(1, n_freq, freq_idx);
        hold on;

        if isempty(dat_file1)
            if verbose, fprintf('  %.0f Hz: NOT FOUND\n', target_freq); end
            title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
            continue;
        end

        try
            data = read_hsdata(dat_file1);
            fs = data.sampling_rate;
            ch1 = config1.analysis_channel;
            ch2 = config2.analysis_channel;
            Vm_ch1 = data.Vm(:, ch1);
            Vm_ch2 = data.Vm(:, ch2);

            steady_info = detect_steady_state_relative(Vm_ch1, target_freq, fs, ...
                'RelativeThreshold', RELATIVE_THRESHOLD, ...
                'ConsecutivePeriods', 3, ...
                'CheckPoints', min(25, round(fs/target_freq)), ...
                'Verbose', false);

            if steady_info.index <= 0
                if verbose, fprintf('  %.0f Hz: NO STEADY STATE\n', target_freq); end
                title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
                continue;
            end

            ss_start = steady_info.index;
            [super_period, min_per] = compute_super_period(target_freq, fs);
            n_super = max(1, ceil(NUM_PERIODS / min_per));
            ss_length = n_super * super_period;
            avail = length(Vm_ch1) - ss_start + 1;
            if ss_length > avail
                avail_super = floor(avail / super_period);
                if avail_super > 0
                    ss_length = avail_super * super_period;
                else
                    approx_period = round(fs / target_freq);
                    ss_length = floor(avail / approx_period) * approx_period;
                end
            end
            Vm1_ss = Vm_ch1(ss_start : ss_start + ss_length - 1);
            Vm2_ss = Vm_ch2(ss_start : ss_start + ss_length - 1);

            plot(Vm1_ss, Vm2_ss, '-', 'LineWidth', 2, 'Color', [0, 0, 0]);

            if verbose, fprintf('  %.0f Hz: OK (%d samples)\n', target_freq, length(Vm1_ss)); end
        catch ME
            if verbose, fprintf('  %.0f Hz: ERROR: %s\n', target_freq, ME.message); end
        end

        % Format subplot
        if freq_idx == 1
            ylabel(c2.display_name, 'FontWeight', 'bold', 'FontSize', 40);
        end
        xlabel(c1.display_name, 'FontWeight', 'bold', 'FontSize', 40);
        title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
        set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
        ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
        pbaspect([1 1 1]);
        box on; grid on;
    end

    if save_fig
        out_file = fullfile(project_root, 'results', 'Comparison_CrossChannel.png');
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end
end

%% ===== TS Lissajous (Vm vs Current, tip & surface overlay) =====
function compare_ts_lissajous(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose)
    if n_exp ~= 2
        if verbose, fprintf('TS Lissajous requires exactly 2 experiments, got %d. Skipping.\n', n_exp); end
        return;
    end

    NUM_PERIODS = 3;
    RELATIVE_THRESHOLD = 0.002;
    k_A = 0.3614;
    DAC_ZERO = 32768;
    DAC_RANGE = 20.0;
    DAC_RES = 65536;

    config1 = load_experiment_config(ordered_names{1});
    config2 = load_experiment_config(ordered_names{2});
    c1 = colors.(ordered_names{1});
    c2 = colors.(ordered_names{2});

    n_freq = length(plot_freqs);
    fig = figure('Position', [100, 100, 1800, 650], 'Name', 'TS Lissajous');

    all_xlim = zeros(n_freq, 2);
    all_ylim = zeros(n_freq, 2);
    stored_data = cell(n_freq, 1);

    for freq_idx = 1:n_freq
        target_freq = plot_freqs(freq_idx);
        [dat_file, ~] = find_dat_file(config1, target_freq);

        subplot(1, n_freq, freq_idx);
        hold on;

        if isempty(dat_file)
            if verbose, fprintf('  %.0f Hz: NOT FOUND\n', target_freq); end
            title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
            continue;
        end

        try
            data = read_hsdata(dat_file);
            fs = data.sampling_rate;
            excite_ch = config1.excitation_channel;
            ch1 = config1.analysis_channel;
            ch2 = config2.analysis_channel;

            % Current from DA
            da_raw = double(data.da(:, excite_ch));
            V_dac = (da_raw - DAC_ZERO) * (DAC_RANGE / DAC_RES);
            I = k_A * V_dac;

            % Vm for both channels
            Vm_ch1 = data.Vm(:, ch1);
            Vm_ch2 = data.Vm(:, ch2);

            % Steady state detection on first channel
            steady_info = detect_steady_state_relative(Vm_ch1, target_freq, fs, ...
                'RelativeThreshold', RELATIVE_THRESHOLD, ...
                'ConsecutivePeriods', 3, ...
                'CheckPoints', min(25, round(fs/target_freq)), ...
                'Verbose', false);

            if steady_info.index <= 0
                if verbose, fprintf('  %.0f Hz: NO STEADY STATE\n', target_freq); end
                title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
                continue;
            end

            ss_start = steady_info.index;
            [super_period, min_per] = compute_super_period(target_freq, fs);
            n_super = max(1, ceil(NUM_PERIODS / min_per));
            ss_length = n_super * super_period;
            avail = length(I) - ss_start + 1;
            if ss_length > avail
                avail_super = floor(avail / super_period);
                if avail_super > 0
                    ss_length = avail_super * super_period;
                else
                    approx_period = round(fs / target_freq);
                    ss_length = floor(avail / approx_period) * approx_period;
                end
            end
            I_ss = I(ss_start : ss_start + ss_length - 1);
            Vm1_ss = Vm_ch1(ss_start : ss_start + ss_length - 1);
            Vm2_ss = Vm_ch2(ss_start : ss_start + ss_length - 1);

            % Plot both channels (lines only, no markers)
            plot(I_ss, Vm1_ss, '-', 'Color', c1.rgb, 'LineWidth', 2, ...
                'DisplayName', c1.display_name);
            plot(I_ss, Vm2_ss, '-', 'Color', c2.rgb, 'LineWidth', 2, ...
                'DisplayName', c2.display_name);

            stored_data{freq_idx} = struct('I_ss', I_ss, 'Vm1_ss', Vm1_ss, 'Vm2_ss', Vm2_ss);

            if verbose, fprintf('  %.0f Hz: OK (%d samples)\n', target_freq, length(I_ss)); end
        catch ME
            if verbose, fprintf('  %.0f Hz: ERROR: %s\n', target_freq, ME.message); end
        end

        % Format subplot
        xlabel('Current (A)', 'FontWeight', 'bold', 'FontSize', 40);
        if freq_idx == 1
            ylabel('Vm (V)', 'FontWeight', 'bold', 'FontSize', 40);
        end
        title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
        set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
        ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
        pbaspect([1 1 1]);
        box on; grid on;
        all_xlim(freq_idx, :) = xlim;
        all_ylim(freq_idx, :) = ylim;
    end

    % Unify axes
    global_xlim = [min(all_xlim(:,1)), max(all_xlim(:,2))];
    global_ylim = [min(all_ylim(:,1)), max(all_ylim(:,2))];
    for k = 1:n_freq
        subplot(1, n_freq, k);
        xlim(global_xlim);
        ylim(global_ylim);
    end

    % Shared legend at top (centered, no subplot resize)
    ax_first = subplot(1, n_freq, 1);
    lgd = legend(ax_first, 'Orientation', 'horizontal', 'FontWeight', 'bold', 'FontSize', 22);
    lgd.Units = 'normalized';
    drawnow;
    lgd.Position = [0.5 - lgd.Position(3)/2, 0.92, lgd.Position(3), lgd.Position(4)];

    if save_fig
        freq_str = strjoin(arrayfun(@(f) sprintf('%.0f', f), plot_freqs, 'UniformOutput', false), '_');
        out_file = fullfile(project_root, 'results', sprintf('Comparison_TS_Lissajous_%s.png', freq_str));
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end

    %% Normalized version
    fig2 = figure('Position', [100, 100, 1800, 650], 'Name', 'TS Lissajous (Normalized)');
    all_xlim2 = zeros(n_freq, 2);

    for freq_idx = 1:n_freq
        subplot(1, n_freq, freq_idx);
        hold on;

        if isempty(stored_data{freq_idx})
            title(sprintf('%.0f Hz', plot_freqs(freq_idx)), 'FontWeight', 'bold', 'FontSize', 24);
            continue;
        end

        d = stored_data{freq_idx};
        I_ac = d.I_ss - mean(d.I_ss);
        Vm1_ac = d.Vm1_ss - mean(d.Vm1_ss);
        Vm2_ac = d.Vm2_ss - mean(d.Vm2_ss);
        I_norm = I_ac / max(abs(I_ac));
        Vm1_norm = Vm1_ac / max(abs(Vm1_ac));
        Vm2_norm = Vm2_ac / max(abs(Vm2_ac));

        plot(I_norm, Vm1_norm, '-', 'Color', c1.rgb, 'LineWidth', 2, ...
            'DisplayName', c1.display_name);
        plot(I_norm, Vm2_norm, '-', 'Color', c2.rgb, 'LineWidth', 2, ...
            'DisplayName', c2.display_name);

        xlabel('Normalized Current', 'FontWeight', 'bold', 'FontSize', 40);
        if freq_idx == 1
            ylabel('Normalized Vm', 'FontWeight', 'bold', 'FontSize', 40);
        end
        title(sprintf('%.0f Hz', plot_freqs(freq_idx)), 'FontWeight', 'bold', 'FontSize', 24);
        set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
        ax2 = gca; ax2.XAxis.LineWidth = 3; ax2.YAxis.LineWidth = 3;
        pbaspect([1 1 1]);
        box on; grid on;
        all_xlim2(freq_idx, :) = xlim;
    end

    % Unify axes
    global_xlim2 = [min(all_xlim2(:,1)), max(all_xlim2(:,2))];
    for k = 1:n_freq
        subplot(1, n_freq, k);
        xlim(global_xlim2);
        ylim([-1.1, 1.1]);
    end

    % Shared legend at top
    ax_first2 = subplot(1, n_freq, 1);
    lgd2 = legend(ax_first2, 'Orientation', 'horizontal', 'FontWeight', 'bold', 'FontSize', 22);
    lgd2.Units = 'normalized';
    drawnow;
    lgd2.Position = [0.5 - lgd2.Position(3)/2, 0.92, lgd2.Position(3), lgd2.Position(4)];

    if save_fig
        out_file2 = fullfile(project_root, 'results', sprintf('Comparison_TS_Lissajous_Normalized_%s.png', freq_str));
        exportgraphics(fig2, out_file2, 'Resolution', 150);
        if verbose, fprintf('Saved: %s\n', out_file2); end
    end
end

%% ===== TS Time-Domain (tip & surface overlay vs time) =====
function compare_ts_timedomain(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose)
    if n_exp ~= 2
        if verbose, fprintf('TS TimeDomain requires exactly 2 experiments, got %d. Skipping.\n', n_exp); end
        return;
    end

    NUM_PERIODS = 3;
    RELATIVE_THRESHOLD = 0.002;

    config1 = load_experiment_config(ordered_names{1});
    config2 = load_experiment_config(ordered_names{2});
    c1 = colors.(ordered_names{1});
    c2 = colors.(ordered_names{2});

    n_freq = length(plot_freqs);
    fig = figure('Position', [100, 100, 1800, 700], 'Name', 'TS Time-Domain');
    ax_handles = gobjects(1, n_freq);

    for freq_idx = 1:n_freq
        target_freq = plot_freqs(freq_idx);
        [dat_file, ~] = find_dat_file(config1, target_freq);

        ax_handles(freq_idx) = subplot(1, n_freq, freq_idx);
        hold on;

        if isempty(dat_file)
            if verbose, fprintf('  %.0f Hz: NOT FOUND\n', target_freq); end
            title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
            continue;
        end

        try
            data = read_hsdata(dat_file);
            fs = data.sampling_rate;
            ch1 = config1.analysis_channel;
            ch2 = config2.analysis_channel;

            Vm_ch1 = data.Vm(:, ch1);
            Vm_ch2 = data.Vm(:, ch2);

            % Steady state detection
            steady_info = detect_steady_state_relative(Vm_ch1, target_freq, fs, ...
                'RelativeThreshold', RELATIVE_THRESHOLD, ...
                'ConsecutivePeriods', 3, ...
                'CheckPoints', min(25, round(fs/target_freq)), ...
                'Verbose', false);

            if steady_info.index <= 0
                if verbose, fprintf('  %.0f Hz: NO STEADY STATE\n', target_freq); end
                title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
                continue;
            end

            ss_start = steady_info.index;
            [super_period, min_per] = compute_super_period(target_freq, fs);
            n_super = max(1, ceil(NUM_PERIODS / min_per));
            ss_length = n_super * super_period;
            avail = length(Vm_ch1) - ss_start + 1;
            if ss_length > avail
                avail_super = floor(avail / super_period);
                if avail_super > 0
                    ss_length = avail_super * super_period;
                else
                    approx_period = round(fs / target_freq);
                    ss_length = floor(avail / approx_period) * approx_period;
                end
            end
            Vm1_ss = Vm_ch1(ss_start : ss_start + ss_length - 1);
            Vm2_ss = Vm_ch2(ss_start : ss_start + ss_length - 1);

            % Time axis in ms
            t_ms = (0:length(Vm1_ss)-1) / fs * 1000;

            plot(t_ms, Vm1_ss, '-', 'Color', c1.rgb, 'LineWidth', 2, ...
                'DisplayName', c1.display_name);
            plot(t_ms, Vm2_ss, '-', 'Color', c2.rgb, 'LineWidth', 2, ...
                'DisplayName', c2.display_name);

            if verbose, fprintf('  %.0f Hz: OK (%d samples)\n', target_freq, length(Vm1_ss)); end
        catch ME
            if verbose, fprintf('  %.0f Hz: ERROR: %s\n', target_freq, ME.message); end
        end

        % Format subplot
        if freq_idx == n_freq
            xlabel('Time (ms)', 'FontWeight', 'bold', 'FontSize', 40);
        end
        if freq_idx == 1
            ylabel('Vm (V)', 'FontWeight', 'bold', 'FontSize', 40);
        end
        title(sprintf('%.0f Hz', target_freq), 'FontWeight', 'bold', 'FontSize', 24);
        set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
        ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
        box on; grid on;
    end

    % Shrink subplots to make room for legend at top
    for k = 1:n_freq
        pos = get(ax_handles(k), 'Position');
        pos(4) = pos(4) * 0.88;
        set(ax_handles(k), 'Position', pos);
    end

    % Shared legend at top (centered)
    lgd = legend(ax_handles(1), 'Orientation', 'horizontal', 'FontWeight', 'bold', 'FontSize', 22);
    lgd.Units = 'normalized';
    drawnow;
    lgd.Position = [0.5 - lgd.Position(3)/2, 0.94, lgd.Position(3), lgd.Position(4)];

    if save_fig
        freq_str = strjoin(arrayfun(@(f) sprintf('%.0f', f), plot_freqs, 'UniformOutput', false), '_');
        out_file = fullfile(project_root, 'results', sprintf('Comparison_TS_TimeDomain_%s.png', freq_str));
        exportgraphics(fig, out_file, 'Resolution', 300);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end
end

%% ===== Vm Spectrum Comparison =====
function compare_spectrum(ordered_names, n_exp, ~, project_root, plot_freqs, save_fig, verbose)
    NUM_PERIODS = 3;
    RELATIVE_THRESHOLD = 0.002;
    freq_colors = lines(length(plot_freqs));

    fig = figure('Position', [100, 100, 1200, 1200], 'Name', 'Vm Spectrum Comparison');

    for exp_idx = 1:n_exp
        name = ordered_names{exp_idx};
        config = load_experiment_config(name);
        analysis_ch = config.analysis_channel;

        subplot(n_exp, 1, exp_idx);
        hold on;

        if verbose, fprintf('Spectrum: %s (ch%d)\n', name, analysis_ch); end

        for freq_idx = 1:length(plot_freqs)
            target_freq = plot_freqs(freq_idx);
            [dat_file, ~] = find_dat_file(config, target_freq);

            if isempty(dat_file)
                if verbose, fprintf('  %.0f Hz: NOT FOUND\n', target_freq); end
                continue;
            end

            try
                data = read_hsdata(dat_file);
                fs = data.sampling_rate;
                Vm_ch = data.Vm(:, analysis_ch);

                steady_info = detect_steady_state_relative(Vm_ch, target_freq, fs, ...
                    'RelativeThreshold', RELATIVE_THRESHOLD, ...
                    'ConsecutivePeriods', 3, ...
                    'CheckPoints', min(25, round(fs/target_freq)), ...
                    'Verbose', false);

                if steady_info.index <= 0
                    if verbose, fprintf('  %.0f Hz: NO STEADY STATE\n', target_freq); end
                    continue;
                end

                ss_start = steady_info.index;
                [super_period, min_per] = compute_super_period(target_freq, fs);
                n_super = max(1, ceil(NUM_PERIODS / min_per));
                ss_length = n_super * super_period;
                avail = length(Vm_ch) - ss_start + 1;
                if ss_length > avail
                    avail_super = floor(avail / super_period);
                    if avail_super > 0
                        ss_length = avail_super * super_period;
                    else
                        approx_period = round(fs / target_freq);
                        ss_length = floor(avail / approx_period) * approx_period;
                    end
                end
                Vm_ss = Vm_ch(ss_start : ss_start + ss_length - 1);

                N = length(Vm_ss);
                Vm_fft = fft(Vm_ss);
                amp = abs(Vm_fft(1:floor(N/2)+1)) / N * 2;
                amp(1) = amp(1) / 2;
                freq_axis = (0:floor(N/2)) * fs / N;

                loglog(freq_axis, amp, '-', 'LineWidth', 2, 'Color', freq_colors(freq_idx, :), ...
                    'DisplayName', sprintf('%.0f Hz', target_freq));

                if verbose, fprintf('  %.0f Hz: OK (%d samples)\n', target_freq, N); end
            catch ME
                if verbose, fprintf('  %.0f Hz: ERROR: %s\n', target_freq, ME.message); end
            end
        end

        % Format subplot
        if exp_idx == n_exp
            xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        end
        ylabel('|Vm| (V)', 'FontWeight', 'bold', 'FontSize', 40);
        title(get_display_name(name), 'FontWeight', 'bold', 'FontSize', 24);
        set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
        set(gca, 'XScale', 'log', 'YScale', 'log');
        xlim([0.5, fs/2]);
        ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
        box on; grid on;
    end

    % Shared legend at top
    ax_first = subplot(n_exp, 1, 1);
    lgd = legend(ax_first, 'Orientation', 'horizontal', 'FontWeight', 'bold', 'FontSize', 22);
    lgd.Position = [0.25, 0.965, 0.5, 0.03];

    if save_fig
        out_file = fullfile(project_root, 'results', 'Comparison_Vm_Spectrum.png');
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end
end

%% ===== Lissajous Comparison =====
function compare_lissajous(ordered_names, n_exp, ~, project_root, plot_freqs, save_fig, verbose)
    NUM_PERIODS = 3;
    RELATIVE_THRESHOLD = 0.002;
    k_A = 0.3614;
    DAC_ZERO = 32768;
    DAC_RANGE = 20.0;
    DAC_RES = 65536;
    freq_colors = lines(length(plot_freqs));

    fig = figure('Position', [100, 100, 1800, 600], 'Name', 'Vm vs Current Comparison');

    all_ylim = zeros(n_exp, 2);

    for exp_idx = 1:n_exp
        name = ordered_names{exp_idx};
        config = load_experiment_config(name);
        analysis_ch = config.analysis_channel;
        excite_ch = config.excitation_channel;

        subplot(1, n_exp, exp_idx);
        hold on;

        if verbose, fprintf('Lissajous: %s (Vm ch%d, DA ch%d)\n', name, analysis_ch, excite_ch); end

        for freq_idx = 1:length(plot_freqs)
            target_freq = plot_freqs(freq_idx);
            [dat_file, ~] = find_dat_file(config, target_freq);

            if isempty(dat_file)
                if verbose, fprintf('  %.0f Hz: NOT FOUND\n', target_freq); end
                continue;
            end

            try
                data = read_hsdata(dat_file);
                fs = data.sampling_rate;
                Vm_ch = data.Vm(:, analysis_ch);
                da_raw = double(data.da(:, excite_ch));
                V_dac = (da_raw - DAC_ZERO) * (DAC_RANGE / DAC_RES);
                I = k_A * V_dac;

                steady_info = detect_steady_state_relative(Vm_ch, target_freq, fs, ...
                    'RelativeThreshold', RELATIVE_THRESHOLD, ...
                    'ConsecutivePeriods', 3, ...
                    'CheckPoints', min(25, round(fs/target_freq)), ...
                    'Verbose', false);

                if steady_info.index <= 0
                    if verbose, fprintf('  %.0f Hz: NO STEADY STATE\n', target_freq); end
                    continue;
                end

                ss_start = steady_info.index;
                [super_period, min_per] = compute_super_period(target_freq, fs);
                n_super = max(1, ceil(NUM_PERIODS / min_per));
                ss_length = n_super * super_period;
                avail = length(I) - ss_start + 1;
                if ss_length > avail
                    avail_super = floor(avail / super_period);
                    if avail_super > 0
                        ss_length = avail_super * super_period;
                    else
                        approx_period = round(fs / target_freq);
                        ss_length = floor(avail / approx_period) * approx_period;
                    end
                end
                I_ss = I(ss_start : ss_start + ss_length - 1);
                Vm_ss = Vm_ch(ss_start : ss_start + ss_length - 1);

                plot(I_ss, Vm_ss, '-', 'LineWidth', 3, 'Color', freq_colors(freq_idx, :), ...
                    'DisplayName', sprintf('%.0f Hz', target_freq));

                if verbose, fprintf('  %.0f Hz: OK (%d samples)\n', target_freq, length(I_ss)); end
            catch ME
                if verbose, fprintf('  %.0f Hz: ERROR: %s\n', target_freq, ME.message); end
            end
        end

        % Format subplot
        xlabel('Current (A)', 'FontWeight', 'bold', 'FontSize', 40);
        if exp_idx == 1
            ylabel('Vm (V)', 'FontWeight', 'bold', 'FontSize', 40);
        end
        title(get_display_name(name), 'FontWeight', 'bold', 'FontSize', 24);
        set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
        ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
        pbaspect([1 1 1]);
        box on; grid on;
        all_ylim(exp_idx, :) = ylim;
    end

    % Unify Y-axis
    global_ylim = [min(all_ylim(:,1)), max(all_ylim(:,2))];
    for k = 1:n_exp
        subplot(1, n_exp, k);
        ylim(global_ylim);
    end

    % Shared legend at top
    ax_first = subplot(1, n_exp, 1);
    lgd = legend(ax_first, 'Orientation', 'horizontal', 'FontWeight', 'bold', 'FontSize', 22);
    lgd.Position = [0.3, 0.95, 0.4, 0.04];

    if save_fig
        out_file = fullfile(project_root, 'results', 'Comparison_Lissajous.png');
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end
end

%% ===== Helper: load config for experiment =====
function config = load_experiment_config(name)
    config_func = str2func([name '_config']);
    config = config_func();
end

%% ===== Helper: find .dat file for a target frequency =====
function [dat_file, freq_idx] = find_dat_file(config, target_freq)
    freq_idx = find(abs(config.expected_frequencies - target_freq) < 0.01, 1);
    if isempty(freq_idx)
        dat_file = '';
        return;
    end
    dat_file = fullfile(config.data_folder, config.data_files{freq_idx});
    if ~exist(dat_file, 'file')
        dat_file = '';
    end
end

%% ===== Helper: display name =====
function dname = get_display_name(name)
    colors = get_experiment_colors();
    if isfield(colors, name)
        dname = colors.(name).display_name;
    else
        dname = name;
    end
end
