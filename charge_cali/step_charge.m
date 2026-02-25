function step_charge(config, mode, varargin)
%STEP_CHARGE Charge calibration pipeline
%
% Reads .dat files at multiple distances, computes |H| via FFT,
% fits inverse-square law H(x) = a^2 / (x+b)^2 to find offset b.
%
% Usage:
%   step_charge(config, 'full')
%   step_charge(config, 'full', 'fit_frequencies', [0.1, 1])
%   step_charge(config, 'fit')
%   step_charge(config, 'plot')
%
% Modes:
%   'full' - discover .dat → read → FFT → CSV → fit → plot
%   'fit'  - load CSV → fit → plot
%   'plot' - load .mat → plot

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'fit_frequencies', config.charge.fit_frequencies, @isnumeric);
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, varargin{:});
    fit_freqs = p.Results.fit_frequencies;
    verbose = p.Results.Verbose;

    %% Path setup
    diag_folder = fullfile(config.output_folder, 'diagnostics');
    fig_folder = fullfile(config.output_folder, 'figures');
    fit_folder = fullfile(config.output_folder, 'fitting_results');
    csv_path = fullfile(diag_folder, 'Charge_Data.csv');
    mat_path = fullfile(fit_folder, 'charge_fit_results.mat');

    switch lower(mode)
        case 'full'
            %% Discover files
            [distances, freq_list, file_map] = discover_files(config, verbose);

            %% Process all files → H_matrix
            H_matrix = process_all_files(config, distances, freq_list, file_map, verbose);

            %% Save CSV
            save_charge_csv(csv_path, distances, freq_list, H_matrix, verbose);

            %% Continue to fit
            charge_fit_results = do_fitting(distances, freq_list, H_matrix, ...
                fit_freqs, mat_path, fit_folder, verbose);

            %% Continue to plot
            do_plotting(config, charge_fit_results, fig_folder, verbose);

        case 'fit'
            %% Load CSV
            [distances, freq_list, H_matrix] = load_charge_csv(csv_path, verbose);

            %% Fit
            charge_fit_results = do_fitting(distances, freq_list, H_matrix, ...
                fit_freqs, mat_path, fit_folder, verbose);

            %% Plot
            do_plotting(config, charge_fit_results, fig_folder, verbose);

        case 'plot'
            %% Load .mat
            if ~exist(mat_path, 'file')
                error('step_charge:no_mat', 'Fit results not found: %s', mat_path);
            end
            loaded = load(mat_path, 'charge_fit_results');
            charge_fit_results = loaded.charge_fit_results;
            if verbose
                fprintf('Loaded fit results from: %s\n', mat_path);
            end

            %% Plot
            do_plotting(config, charge_fit_results, fig_folder, verbose);

        otherwise
            error('step_charge:unknown_mode', ...
                'Unknown mode: %s. Valid: full, fit, plot', mode);
    end
end

%% ============================================================
%  Local helper functions
%  ============================================================

function [distances, freq_list, file_map] = discover_files(config, verbose)
%DISCOVER_FILES Parse data folder for charge calibration .dat files
%
% Expected filename pattern: <prefix>_<distance>um_<freq>hz.dat
% Returns sorted unique distances, sorted frequencies, and a map.

    if verbose
        fprintf('\n========================================\n');
        fprintf('  Discovering files: %s\n', config.data_folder);
        fprintf('========================================\n\n');
    end

    if ~exist(config.data_folder, 'dir')
        error('step_charge:no_data_folder', 'Data folder not found: %s', config.data_folder);
    end

    files = dir(fullfile(config.data_folder, '*.dat'));
    if isempty(files)
        error('step_charge:no_dat_files', 'No .dat files found in: %s', config.data_folder);
    end

    % Pattern: <prefix>_<distance>um_<freq>hz.dat
    pattern = [regexptranslate('escape', config.data_prefix) ...
               '_(\d+)um_([\d.]+)hz\.dat'];

    dist_list = [];
    freq_list_raw = [];
    file_map = struct('distance', {}, 'frequency', {}, 'filename', {});

    for i = 1:length(files)
        tokens = regexp(files(i).name, pattern, 'tokens', 'ignorecase');
        if isempty(tokens)
            if verbose
                fprintf('  Skip (no match): %s\n', files(i).name);
            end
            continue;
        end
        d = str2double(tokens{1}{1});
        f = str2double(tokens{1}{2});
        dist_list(end+1) = d; %#ok<AGROW>
        freq_list_raw(end+1) = f; %#ok<AGROW>
        entry.distance = d;
        entry.frequency = f;
        entry.filename = files(i).name;
        file_map(end+1) = entry; %#ok<AGROW>
    end

    if isempty(file_map)
        error('step_charge:no_matching_files', ...
            'No files matching pattern "%s" in: %s', pattern, config.data_folder);
    end

    distances = sort(unique(dist_list));
    freq_list = sort(unique(freq_list_raw));

    if verbose
        fprintf('Found %d files: %d distances x %d frequencies\n', ...
            length(file_map), length(distances), length(freq_list));
        fprintf('Distances (um): %s\n', mat2str(distances));
        fprintf('Frequencies (Hz): %s\n', mat2str(freq_list));
    end
end

function H_matrix = process_all_files(config, distances, freq_list, file_map, verbose)
%PROCESS_ALL_FILES Read all .dat files and compute |H| for each (distance, freq)
%
% Output: H_matrix [n_dist x n_freq], NaN for missing combinations

    n_dist = length(distances);
    n_freq = length(freq_list);
    H_matrix = NaN(n_dist, n_freq);
    total = length(file_map);

    if verbose
        fprintf('\n========================================\n');
        fprintf('  Processing %d files\n', total);
        fprintf('========================================\n\n');
    end

    for k = 1:total
        d = file_map(k).distance;
        f = file_map(k).frequency;
        fname = file_map(k).filename;
        di = find(distances == d, 1);
        fi = find(freq_list == f, 1);

        if verbose
            fprintf('[%d/%d] %d um @ %.1f Hz ... ', k, total, d, f);
        end

        filepath = fullfile(config.data_folder, fname);
        try
            H_mag = process_single_file(filepath, config, f);
            H_matrix(di, fi) = H_mag;
            if verbose, fprintf('OK (|H|=%.6f)\n', H_mag); end
        catch ME
            if verbose, fprintf('ERROR: %s\n', ME.message); end
        end
    end

    n_valid = sum(~isnan(H_matrix(:)));
    if verbose
        fprintf('\nProcessing complete: %d/%d valid entries.\n', n_valid, n_dist * n_freq);
    end
end

function H_mag = process_single_file(filepath, config, freq)
%PROCESS_SINGLE_FILE Read one .dat → steady-state → FFT → |H|

    fs = config.expected_sampling_rate;
    excite_ch = config.excitation_channel;
    analysis_ch = config.analysis_channel;

    %% Read binary
    data = read_hsdata(filepath);

    %% DAC → Voltage
    da_volt = (double(data.da) - config.dac.zero_offset) * ...
              (config.dac.voltage_range / config.dac.resolution);

    %% Extract channels
    Vm_ch = double(data.Vm(:, analysis_ch));
    da_ch = da_volt(:, excite_ch);

    %% Steady-state detection
    period_samples = round(fs / freq);
    check_pts = min(config.steady_state.check_points, period_samples);

    steady_info = detect_steady_state_relative(Vm_ch, freq, fs, ...
        'RelativeThreshold', config.steady_state.relative_threshold, ...
        'ConsecutivePeriods', config.steady_state.consecutive_periods, ...
        'CheckPoints', check_pts, ...
        'Verbose', false);

    if steady_info.index <= 0
        % Fallback: use last few periods
        total_samples = length(Vm_ch);
        min_per = config.steady_state.min_periods_for_fft;
        steady_info.index = max(1, total_samples - min_per * period_samples + 1);
        steady_info.period_samples = period_samples;
    end

    %% Super-period truncation
    [super_period, ~] = compute_super_period(freq, fs);
    steady_start = steady_info.index;
    available_samples = length(Vm_ch) - steady_start + 1;
    available_super = floor(available_samples / super_period);

    if available_super > 0
        fft_length = available_super * super_period;
    else
        % Fallback: approximate period
        available_periods = floor(available_samples / period_samples);
        fft_length = available_periods * period_samples;
    end

    if fft_length < period_samples
        error('process_single_file:too_short', 'Not enough steady-state data.');
    end

    Vm_steady = Vm_ch(steady_start : steady_start + fft_length - 1);
    da_steady = da_ch(steady_start : steady_start + fft_length - 1);

    %% FFT
    Vm_fft = fft(Vm_steady);
    DA_fft = fft(da_steady);
    N = length(Vm_steady);
    freq_axis = (0:N-1) * fs / N;

    %% Find fundamental bin
    [~, fundamental_bin] = min(abs(freq_axis - freq));

    %% H(jw) = Vm / DA
    H_complex = Vm_fft(fundamental_bin) / DA_fft(fundamental_bin);
    H_mag = abs(H_complex);
end

function save_charge_csv(csv_path, distances, freq_list, H_matrix, verbose)
%SAVE_CHARGE_CSV Write wide-format CSV: Distance_um, H_<freq>Hz, ...

    n_dist = length(distances);
    n_freq = length(freq_list);

    %% Build column names
    col_names = cell(1, 1 + n_freq);
    col_names{1} = 'Distance_um';
    for j = 1:n_freq
        % Replace dots with 'p' for valid variable name: H_0p1Hz
        freq_str = strrep(sprintf('%.4g', freq_list(j)), '.', 'p');
        col_names{j+1} = sprintf('H_%sHz', freq_str);
    end

    %% Build data matrix
    data_mat = [distances(:), H_matrix];

    %% Write
    T = array2table(data_mat, 'VariableNames', col_names);
    writetable(T, csv_path);

    if verbose
        fprintf('\nCSV saved: %s (%d distances x %d frequencies)\n', ...
            csv_path, n_dist, n_freq);
    end
end

function [distances, freq_list, H_matrix] = load_charge_csv(csv_path, verbose)
%LOAD_CHARGE_CSV Read wide-format CSV back into distances/frequencies/H_matrix

    if ~exist(csv_path, 'file')
        error('step_charge:no_csv', 'CSV not found: %s', csv_path);
    end

    T = readtable(csv_path);
    distances = T{:, 1};

    %% Parse frequency from column names: H_<freq>Hz
    col_names = T.Properties.VariableNames(2:end);
    n_freq = length(col_names);
    freq_list = zeros(1, n_freq);
    for j = 1:n_freq
        % Column name like H_0p1Hz → 0.1
        name = col_names{j};
        freq_str = regexprep(name, '^H_', '');
        freq_str = regexprep(freq_str, 'Hz$', '');
        freq_str = strrep(freq_str, 'p', '.');
        freq_list(j) = str2double(freq_str);
    end

    H_matrix = T{:, 2:end};

    if verbose
        fprintf('Loaded CSV: %s (%d distances x %d frequencies)\n', ...
            csv_path, length(distances), n_freq);
    end
end

function charge_fit_results = do_fitting(distances, freq_list, H_matrix, ...
    fit_freqs, mat_path, fit_folder, verbose)
%DO_FITTING Fit inverse-square model for each selected frequency

    if verbose
        fprintf('\n========================================\n');
        fprintf('  Fitting: H(x) = a^2 / (x + b)^2\n');
        fprintf('  Fit frequencies: %s Hz\n', mat2str(fit_freqs));
        fprintf('========================================\n\n');
    end

    n_fit = length(fit_freqs);
    fits = struct('frequency', {}, 'a', {}, 'b', {}, 'R_squared', {}, ...
                  'fitted_magnitudes', {}, 'fit_distances_smooth', {}, ...
                  'fit_magnitudes_smooth', {});

    for k = 1:n_fit
        f = fit_freqs(k);
        fi = find(abs(freq_list - f) < 1e-6, 1);
        if isempty(fi)
            if verbose
                fprintf('  %.1f Hz: NOT FOUND in data, skipping.\n', f);
            end
            continue;
        end

        H_col = H_matrix(:, fi);
        valid = ~isnan(H_col);

        if sum(valid) < 2
            if verbose
                fprintf('  %.1f Hz: insufficient valid points (%d), skipping.\n', f, sum(valid));
            end
            continue;
        end

        try
            result = fit_charge_model(distances(valid), H_col(valid));
            entry.frequency = f;
            entry.a = result.a;
            entry.b = result.b;
            entry.R_squared = result.R_squared;
            entry.fitted_magnitudes = result.fitted_magnitudes;
            entry.fit_distances_smooth = result.fit_distances_smooth;
            entry.fit_magnitudes_smooth = result.fit_magnitudes_smooth;
            fits(end+1) = entry; %#ok<AGROW>

            if verbose
                fprintf('  %.1f Hz: a=%.4f, b=%.2f um, R^2=%.6f\n', ...
                    f, result.a, result.b, result.R_squared);
            end
        catch ME
            if verbose
                fprintf('  %.1f Hz: FIT ERROR: %s\n', f, ME.message);
            end
        end
    end

    %% Compute summary statistics
    if ~isempty(fits)
        b_values = [fits.b];
        mean_b = mean(b_values);
        std_b = std(b_values);
    else
        mean_b = NaN;
        std_b = NaN;
    end

    if verbose
        fprintf('\n  Mean b = %.2f um, Std b = %.2f um\n', mean_b, std_b);
    end

    %% Pack results
    charge_fit_results.distances = distances;
    charge_fit_results.frequencies = freq_list(:);
    charge_fit_results.H_matrix = H_matrix;
    charge_fit_results.fit_frequencies = fit_freqs(:);
    charge_fit_results.fits = fits;
    charge_fit_results.mean_b = mean_b;
    charge_fit_results.std_b = std_b;

    %% Save .mat
    save(mat_path, 'charge_fit_results');
    if verbose
        fprintf('  Saved: %s\n', mat_path);
    end

    %% Save summary CSV
    if ~isempty(fits)
        freq_col = [fits.frequency]';
        a_col = [fits.a]';
        b_col = [fits.b]';
        r2_col = [fits.R_squared]';
        T = table(freq_col, a_col, b_col, r2_col, ...
            'VariableNames', {'Frequency_Hz', 'a', 'b_um', 'R_squared'});
        csv_fit_path = fullfile(fit_folder, 'Charge_Fit_Results.csv');
        writetable(T, csv_fit_path);
        if verbose
            fprintf('  Saved: %s\n', csv_fit_path);
        end
    end
end

function do_plotting(config, charge_fit_results, fig_folder, verbose)
%DO_PLOTTING Generate Charge_Fit_Overlay and Charge_Fit_Summary

    if verbose
        fprintf('\n========================================\n');
        fprintf('  Plotting\n');
        fprintf('========================================\n\n');
    end

    fits = charge_fit_results.fits;
    if isempty(fits)
        if verbose, fprintf('  No fit results to plot.\n'); end
        return;
    end

    distances = charge_fit_results.distances;
    H_matrix = charge_fit_results.H_matrix;
    freq_list = charge_fit_results.frequencies;

    %% Style shortcuts
    LW = config.plot.line_width;
    MS = config.plot.marker_size;
    FS_tick = config.plot.font_size_tick;
    FS_label = config.plot.font_size_label;
    FS_legend = config.plot.font_size_legend;
    AX_LW = config.plot.axis_line_width;

    %% ---- Figure 1: Fit Overlay ----
    fig1 = figure('Visible', 'off', 'Position', [100, 100, 1200, 800]);
    hold on;

    n_fit = length(fits);
    colors = lines(n_fit);

    for k = 1:n_fit
        f = fits(k).frequency;
        fi = find(abs(freq_list - f) < 1e-6, 1);
        H_col = H_matrix(:, fi);
        valid_mask = ~isnan(H_col);

        % Data markers
        plot(distances(valid_mask), H_col(valid_mask), 'o', ...
            'Color', colors(k,:), 'MarkerSize', MS, ...
            'LineWidth', LW, 'MarkerFaceColor', 'none', ...
            'HandleVisibility', 'off');

        % Fitted curve
        plot(fits(k).fit_distances_smooth, fits(k).fit_magnitudes_smooth, '-', ...
            'Color', colors(k,:), 'LineWidth', LW, ...
            'DisplayName', sprintf('%.4g Hz (b=%.1f um, R^2=%.4f)', ...
                f, fits(k).b, fits(k).R_squared));

        % Re-plot data on top with legend entry
        plot(distances(valid_mask), H_col(valid_mask), 'o', ...
            'Color', colors(k,:), 'MarkerSize', MS, ...
            'LineWidth', LW, 'MarkerFaceColor', 'none', ...
            'HandleVisibility', 'off');
    end

    xlabel('Distance (um)', 'FontSize', FS_label, 'FontWeight', 'bold');
    ylabel('|H| (V/V)', 'FontSize', FS_label, 'FontWeight', 'bold');
    lgd = legend('Location', 'northeast', 'FontSize', FS_legend, 'FontWeight', 'bold');
    lgd.Box = 'on';
    set(gca, 'FontSize', FS_tick, 'FontWeight', 'bold', ...
        'LineWidth', AX_LW, 'Box', 'on');
    hold off;

    %% Save
    overlay_path = fullfile(fig_folder, 'Charge_Fit_Overlay.png');
    exportgraphics(fig1, overlay_path, 'Resolution', 300);
    close(fig1);
    if verbose, fprintf('  Saved: %s\n', overlay_path); end

    %% ---- Figure 2: Fit Summary (2x1 subplot) ----
    fig2 = figure('Visible', 'off', 'Position', [100, 100, 1200, 700]);

    fit_freqs_vec = [fits.frequency];
    b_values = [fits.b];
    r2_values = [fits.R_squared];
    mean_b = charge_fit_results.mean_b;
    std_b = charge_fit_results.std_b;

    % --- Top: b vs frequency ---
    ax1 = subplot(2, 1, 1);
    semilogx(fit_freqs_vec, b_values, 'bo-', ...
        'LineWidth', LW, 'MarkerSize', MS, 'MarkerFaceColor', 'none');
    hold on;
    xl = xlim;
    plot(xl, [mean_b, mean_b], 'r--', 'LineWidth', 2, ...
        'DisplayName', sprintf('mean = %.2f um', mean_b));
    % Shade +/- std
    if ~isnan(std_b) && std_b > 0
        fill([xl(1), xl(2), xl(2), xl(1)], ...
             [mean_b - std_b, mean_b - std_b, mean_b + std_b, mean_b + std_b], ...
             'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
    hold off;
    ylabel('b (um)', 'FontSize', FS_label, 'FontWeight', 'bold');
    title(sprintf('Offset b: mean = %.2f +/- %.2f um', mean_b, std_b), ...
        'FontSize', config.plot.font_size_title, 'FontWeight', 'bold');
    lgd2 = legend('b', sprintf('mean = %.2f um', mean_b), ...
        'Location', 'best', 'FontSize', FS_legend, 'FontWeight', 'bold');
    lgd2.Box = 'on';
    set(ax1, 'FontSize', FS_tick, 'FontWeight', 'bold', ...
        'LineWidth', AX_LW, 'Box', 'on');
    grid on;

    % --- Bottom: R^2 vs frequency ---
    ax2 = subplot(2, 1, 2);
    semilogx(fit_freqs_vec, r2_values, 'ko-', ...
        'LineWidth', LW, 'MarkerSize', MS, 'MarkerFaceColor', 'none');
    hold on;
    xl2 = xlim;
    plot(xl2, [0.99, 0.99], 'r--', 'LineWidth', 2);
    hold off;
    xlabel('Frequency (Hz)', 'FontSize', FS_label, 'FontWeight', 'bold');
    ylabel('R^2', 'FontSize', FS_label, 'FontWeight', 'bold');
    title('Fitting Quality', 'FontSize', config.plot.font_size_title, 'FontWeight', 'bold');
    lgd3 = legend('R^2', 'R^2 = 0.99', ...
        'Location', 'best', 'FontSize', FS_legend, 'FontWeight', 'bold');
    lgd3.Box = 'on';
    set(ax2, 'FontSize', FS_tick, 'FontWeight', 'bold', ...
        'LineWidth', AX_LW, 'Box', 'on');
    grid on;

    %% Save
    summary_path = fullfile(fig_folder, 'Charge_Fit_Summary.png');
    exportgraphics(fig2, summary_path, 'Resolution', 300);
    close(fig2);
    if verbose, fprintf('  Saved: %s\n', summary_path); end
end
