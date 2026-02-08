function fit_results = step_fit(config, bode_table, varargin)
%STEP_FIT Phase offset removal + 二階轉移函數 fitting
%
% Usage:
%   fit_results = step_fit(config, bode_table)
%   fit_results = step_fit(config, [], 'FromCSV', true)
%   fit_results = step_fit(config, [], 'FromCSV', true, 'wc_Hz', 50)
%
% Input:
%   config     - experiment config struct
%   bode_table - MATLAB table (from step_fft), or [] if FromCSV=true
%
% Output:
%   fit_results - struct with fields:
%       .a1, .a2, .b          - fitted coefficients
%       .dc_gain, .wn, .zeta  - derived parameters
%       .poles, .pole_type     - pole locations
%       .R_squared, .RMSE_mag, .RMSE_phase - quality metrics
%       .frequencies, .magnitudes, .phases_normalized - data used
%       .H_fitted              - fitted complex frequency response
%       .config_snapshot       - fitting config used

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'FromCSV', false, @islogical);
    addParameter(p, 'wc_Hz', [], @isnumeric);
    addParameter(p, 'p_weight', [], @isnumeric);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;

    %% Override fitting params if specified
    wc_Hz = config.fitting.wc_Hz;
    p_weight = config.fitting.p_weight;
    if ~isempty(p.Results.wc_Hz), wc_Hz = p.Results.wc_Hz; end
    if ~isempty(p.Results.p_weight), p_weight = p.Results.p_weight; end

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_fit: %s\n', config.experiment_name);
        fprintf('========================================\n\n');
    end

    %% Load data
    if p.Results.FromCSV || isempty(bode_table)
        csv_path = fullfile(config.output_folder, 'diagnostics', 'Raw_Bode_Data.csv');
        if ~exist(csv_path, 'file')
            error('step_fit:no_csv', 'CSV not found: %s\nRun step_fft first.', csv_path);
        end
        bode_table = readtable(csv_path);
        if verbose, fprintf('Loaded from CSV: %s\n', csv_path); end
    end

    %% Extract data
    frequencies = bode_table.Frequency_Hz;
    magnitudes_linear = bode_table.Magnitude_Linear;
    phases_raw = bode_table.Phase_deg;

    %% Exclude frequencies
    exclude_mask = false(size(frequencies));
    for ex = config.fitting.exclude_frequencies
        exclude_mask = exclude_mask | (abs(frequencies - ex) < 0.01);
    end
    if any(exclude_mask) && verbose
        fprintf('Excluding %d frequencies: %s\n', sum(exclude_mask), ...
            mat2str(frequencies(exclude_mask)'));
    end
    frequencies = frequencies(~exclude_mask);
    magnitudes_linear = magnitudes_linear(~exclude_mask);
    phases_raw = phases_raw(~exclude_mask);

    %% Phase offset removal
    [~, min_freq_idx] = min(frequencies);
    phase_offset = phases_raw(min_freq_idx);
    phases_normalized = phases_raw - phase_offset;

    if verbose
        fprintf('Phase offset removed: %.2f deg at %.1f Hz\n', phase_offset, frequencies(min_freq_idx));
        fprintf('Fitting: p=%.2f, wc=%.2f Hz, %d points\n', p_weight, wc_Hz, length(frequencies));
    end

    %% Convert units
    phi_k = phases_normalized * pi / 180;    % deg → rad
    w_k = frequencies * 2 * pi;              % Hz → rad/s
    wc_rad = wc_Hz * 2 * pi;

    %% Fit
    [a1, a2, b, H_fitted] = fit_single_tf(magnitudes_linear, phi_k, w_k, ...
        'p', p_weight, 'wc_rad', wc_rad, 'Verbose', verbose);

    %% Derived parameters
    dc_gain = b / a2;
    wn = sqrt(a2);
    wn_Hz = wn / (2 * pi);
    zeta = a1 / (2 * wn);

    %% Poles
    discriminant = a1^2 - 4*a2;
    if discriminant >= 0
        pole1 = (-a1 + sqrt(discriminant)) / 2;
        pole2 = (-a1 - sqrt(discriminant)) / 2;
        poles = [pole1; pole2];
        pole_type = 'real';
    else
        real_part = -a1 / 2;
        imag_part = sqrt(-discriminant) / 2;
        poles = [real_part + 1j*imag_part; real_part - 1j*imag_part];
        pole_type = 'complex';
    end

    %% Quality metrics
    mag_fitted = abs(H_fitted);
    phase_fitted = angle(H_fitted) * 180 / pi;

    SS_res_mag = sum((magnitudes_linear - mag_fitted).^2);
    SS_tot_mag = sum((magnitudes_linear - mean(magnitudes_linear)).^2);
    R_squared = 1 - SS_res_mag / SS_tot_mag;
    RMSE_mag = sqrt(mean((magnitudes_linear - mag_fitted).^2));
    RMSE_phase = sqrt(mean((phases_normalized - phase_fitted).^2));

    %% Print results
    if verbose
        fprintf('\n  === Fitted Parameters ===\n');
        fprintf('    H(s) = %.6f / (s^2 + %.6f*s + %.6f)\n', b, a1, a2);
        fprintf('    DC Gain: %.6f\n', dc_gain);
        fprintf('    wn: %.2f rad/s (%.2f Hz)\n', wn, wn_Hz);
        fprintf('    zeta: %.6f\n', zeta);

        fprintf('\n  === Poles ===\n');
        if strcmp(pole_type, 'real')
            fprintf('    Real: p1=%.2f, p2=%.2f rad/s\n', poles(1), poles(2));
        else
            fprintf('    Complex: %.2f +/- %.2fj rad/s\n', real(poles(1)), imag(poles(1)));
        end

        fprintf('\n  === Quality ===\n');
        fprintf('    R^2: %.6f %s\n', R_squared, iff(R_squared >= 0.85, 'PASS', 'WARNING'));
        fprintf('    RMSE (mag): %.4e\n', RMSE_mag);
        fprintf('    RMSE (phase): %.2f deg\n', RMSE_phase);
        fprintf('    Stable: %s\n', iff(all(real(poles) < 0), 'YES', 'NO'));
    end

    %% Pack output
    fit_results = struct();
    fit_results.a1 = a1;
    fit_results.a2 = a2;
    fit_results.b = b;
    fit_results.dc_gain = dc_gain;
    fit_results.wn = wn;
    fit_results.wn_Hz = wn_Hz;
    fit_results.zeta = zeta;
    fit_results.poles = poles;
    fit_results.pole_type = pole_type;
    fit_results.R_squared = R_squared;
    fit_results.RMSE_mag = RMSE_mag;
    fit_results.RMSE_phase = RMSE_phase;
    fit_results.frequencies = frequencies;
    fit_results.magnitudes_linear = magnitudes_linear;
    fit_results.phases_normalized = phases_normalized;
    fit_results.H_fitted = H_fitted;
    fit_results.config_snapshot = struct('p_weight', p_weight, 'wc_Hz', wc_Hz);

    %% Save fitting results
    if config.output.save_fitting_results
        fit_folder = fullfile(config.output_folder, 'fitting_results');
        if ~exist(fit_folder, 'dir'), mkdir(fit_folder); end
        save(fullfile(fit_folder, 'fit_results.mat'), 'fit_results');
        if verbose
            fprintf('\nFitting results saved: %s\n', fullfile(fit_folder, 'fit_results.mat'));
        end
    end
end

function result = iff(cond, true_val, false_val)
    if cond, result = true_val; else, result = false_val; end
end
