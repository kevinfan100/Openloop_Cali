function step_compare(experiment_names, varargin)
%STEP_COMPARE 多實驗比較圖
%
% Usage:
%   step_compare({'Hung', 'Hung_noring', 'NTU'})
%   step_compare({'Hung', 'NTU'}, 'Type', 'bode')
%   step_compare({'Hung', 'Hung_noring', 'NTU'}, 'Type', 'spectrum', 'Frequencies', [1, 10, 100])
%   step_compare({'Hung', 'Hung_noring', 'NTU'}, 'Type', 'lissajous', 'Frequencies', [1, 10, 100])
%   step_compare({'Hung', 'Hung_noring', 'NTU'}, 'Type', 'all', 'Frequencies', [1, 10, 100])
%
% Input:
%   experiment_names - cell array of experiment names
%
% Type:
%   'bode'      - Normalized Bode comparison (default)
%   'spectrum'  - VM steady-state spectrum comparison
%   'lissajous' - VM vs Current Lissajous comparison
%   'all'       - All comparison types
%
% 順序固定: Hung → Hung(NoRing) → NTU (Hung 系列相鄰)

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'SaveFigure', true, @islogical);
    addParameter(p, 'Type', 'bode', @ischar);
    addParameter(p, 'Frequencies', [1, 10, 100], @isnumeric);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;
    save_fig = p.Results.SaveFigure;
    compare_type = lower(p.Results.Type);
    plot_freqs = p.Results.Frequencies;

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_compare: %s [%s]\n', strjoin(experiment_names, ' vs '), compare_type);
        fprintf('========================================\n\n');
    end

    %% Get colors and markers
    colors = get_experiment_colors();

    %% Fixed display order: Hung → Hung_noring → NTU
    ordered_names = order_experiments(experiment_names);
    n_exp = length(ordered_names);
    project_root = fileparts(fileparts(mfilename('fullpath')));

    %% Dispatch by type
    switch compare_type
        case 'bode'
            compare_bode(ordered_names, n_exp, colors, project_root, save_fig, verbose);
        case 'spectrum'
            compare_spectrum(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        case 'lissajous'
            compare_lissajous(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        case 'all'
            compare_bode(ordered_names, n_exp, colors, project_root, save_fig, verbose);
            compare_spectrum(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
            compare_lissajous(ordered_names, n_exp, colors, project_root, plot_freqs, save_fig, verbose);
        otherwise
            error('step_compare:unknown_type', ...
                'Unknown Type: %s\nValid: bode, spectrum, lissajous, all', compare_type);
    end

    if verbose
        fprintf('\nstep_compare complete.\n');
    end
end

%% ===== Helper: fixed display order =====
function ordered = order_experiments(experiment_names)
    display_order = {'Hung', 'Hung_noring', 'NTU'};
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
function compare_bode(ordered_names, n_exp, colors, project_root, save_fig, verbose)
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

    %% Normalization
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
    fig = figure('Position', [100, 100, 900, 720], 'Name', 'Bode Comparison');
    freq_max = 2000;
    log_ticks = 10.^(-1:3);
    lw = 3.5;
    ms = 12;

    % Magnitude
    subplot(2, 1, 1);
    hold on;
    for i = 1:n_exp
        name = ordered_names{i};
        freq = exp_data{i}.Frequency_Hz;
        mag_dB = 20*log10(exp_data{i}.Magnitude_Linear / H_ref(i));
        c = colors.(name);
        semilogx(freq, mag_dB, [c.marker '-'], 'Color', c.rgb, ...
            'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none', ...
            'DisplayName', sprintf('%s (H(0.1)=%.4f)', c.display_name, H_ref(i)));
    end
    ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
    legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);
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
        phase = exp_data{i}.Phase_deg - phase_ref(i);
        c = colors.(name);
        semilogx(freq, phase, [c.marker '-'], 'Color', c.rgb, ...
            'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none');
    end
    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);
    set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks);
    ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
    box on;

    if save_fig
        out_folder = fullfile(project_root, 'results');
        if ~exist(out_folder, 'dir'), mkdir(out_folder); end
        out_file = fullfile(out_folder, 'Comparison_Bode.png');
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end
end

%% ===== VM Spectrum Comparison =====
function compare_spectrum(ordered_names, n_exp, ~, project_root, plot_freqs, save_fig, verbose)
    NUM_PERIODS = 3;
    RELATIVE_THRESHOLD = 0.002;
    freq_colors = lines(length(plot_freqs));

    fig = figure('Position', [100, 100, 1200, 1200], 'Name', 'VM Spectrum Comparison');

    for exp_idx = 1:n_exp
        name = ordered_names{exp_idx};
        config = load_experiment_config(name);

        subplot(n_exp, 1, exp_idx);
        hold on;

        if verbose, fprintf('Spectrum: %s\n', name); end

        for freq_idx = 1:length(plot_freqs)
            target_freq = plot_freqs(freq_idx);
            [dat_file, ~] = find_dat_file(config, target_freq);

            if isempty(dat_file)
                if verbose, fprintf('  %.0f Hz: NOT FOUND\n', target_freq); end
                continue;
            end

            try
                data = read_hsdata(dat_file);
                ch = data.channel;
                fs = data.sampling_rate;
                vm_ch = data.vm(:, ch);

                steady_info = detect_steady_state_relative(vm_ch, target_freq, fs, ...
                    'RelativeThreshold', RELATIVE_THRESHOLD, ...
                    'ConsecutivePeriods', 3, ...
                    'CheckPoints', min(25, round(fs/target_freq)), ...
                    'Verbose', false);

                if steady_info.index <= 0
                    if verbose, fprintf('  %.0f Hz: NO STEADY STATE\n', target_freq); end
                    continue;
                end

                ss_start = steady_info.index;
                period_samples = steady_info.period_samples;
                ss_length = NUM_PERIODS * period_samples;
                if ss_start + ss_length - 1 > length(vm_ch)
                    ss_length = floor((length(vm_ch) - ss_start + 1) / period_samples) * period_samples;
                end
                VM_ss = vm_ch(ss_start : ss_start + ss_length - 1);

                N = length(VM_ss);
                VM_fft = fft(VM_ss);
                amp = abs(VM_fft(1:floor(N/2)+1)) / N * 2;
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
        ylabel('|VM| (V)', 'FontWeight', 'bold', 'FontSize', 40);
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
        out_file = fullfile(project_root, 'results', 'Comparison_VM_Spectrum.png');
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

    fig = figure('Position', [100, 100, 1800, 600], 'Name', 'VM vs Current Comparison');

    all_ylim = zeros(n_exp, 2);

    for exp_idx = 1:n_exp
        name = ordered_names{exp_idx};
        config = load_experiment_config(name);

        subplot(1, n_exp, exp_idx);
        hold on;

        if verbose, fprintf('Lissajous: %s\n', name); end

        for freq_idx = 1:length(plot_freqs)
            target_freq = plot_freqs(freq_idx);
            [dat_file, ~] = find_dat_file(config, target_freq);

            if isempty(dat_file)
                if verbose, fprintf('  %.0f Hz: NOT FOUND\n', target_freq); end
                continue;
            end

            try
                data = read_hsdata(dat_file);
                ch = data.channel;
                fs = data.sampling_rate;
                vm_ch = data.vm(:, ch);
                da_raw = double(data.da(:, ch));
                V_dac = (da_raw - DAC_ZERO) * (DAC_RANGE / DAC_RES);
                I = k_A * V_dac;

                steady_info = detect_steady_state_relative(vm_ch, target_freq, fs, ...
                    'RelativeThreshold', RELATIVE_THRESHOLD, ...
                    'ConsecutivePeriods', 3, ...
                    'CheckPoints', min(25, round(fs/target_freq)), ...
                    'Verbose', false);

                if steady_info.index <= 0
                    if verbose, fprintf('  %.0f Hz: NO STEADY STATE\n', target_freq); end
                    continue;
                end

                ss_start = steady_info.index;
                period_samples = steady_info.period_samples;
                ss_length = NUM_PERIODS * period_samples;
                if ss_start + ss_length - 1 > length(I)
                    ss_length = floor((length(I) - ss_start + 1) / period_samples) * period_samples;
                end
                I_ss = I(ss_start : ss_start + ss_length - 1);
                VM_ss = vm_ch(ss_start : ss_start + ss_length - 1);

                plot(I_ss, VM_ss, '-', 'LineWidth', 3, 'Color', freq_colors(freq_idx, :), ...
                    'DisplayName', sprintf('%.0f Hz', target_freq));

                if verbose, fprintf('  %.0f Hz: OK (%d samples)\n', target_freq, length(I_ss)); end
            catch ME
                if verbose, fprintf('  %.0f Hz: ERROR: %s\n', target_freq, ME.message); end
            end
        end

        % Format subplot
        xlabel('Current (A)', 'FontWeight', 'bold', 'FontSize', 40);
        if exp_idx == 1
            ylabel('VM (V)', 'FontWeight', 'bold', 'FontSize', 40);
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
