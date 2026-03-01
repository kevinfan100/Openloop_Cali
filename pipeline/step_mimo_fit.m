function fit_results = step_mimo_fit(config, H_mag_in, H_phase_in, frequencies_in, varargin)
%STEP_MIMO_FIT Stage 2: 相位修正 → 擬合 (6x6 MIMO)
%
% 自動 180 度修正 → phase offset removal → batch single + MIMO fitting → ZOH
%
% 使用方式:
%   fit_results = step_mimo_fit(config, H_mag, H_phase, frequencies)
%   fit_results = step_mimo_fit(config, [], [], [])           % 從 CSV 載入
%   fit_results = step_mimo_fit(..., 'wc_Hz', 10)             % 覆寫參數
%
% 輸入:
%   config       - MIMO_config() 回傳的設定
%   H_mag_in     - 6 x 6 x N magnitude (或 [] 從 CSV 載入)
%   H_phase_in   - 6 x 6 x N phase deg 原始 (或 [])
%   frequencies_in - 1 x N Hz (或 [])
%
% 輸出:
%   fit_results - struct 包含所有擬合結果

    %% 解析參數
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'config', @isstruct);
    addRequired(p, 'H_mag_in');
    addRequired(p, 'H_phase_in');
    addRequired(p, 'frequencies_in');
    addParameter(p, 'wc_Hz', config.fitting.wc_Hz, @isnumeric);
    addParameter(p, 'p_weight', config.fitting.p_weight, @isnumeric);
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, config, H_mag_in, H_phase_in, frequencies_in, varargin{:});
    opts = p.Results;

    fprintf('\n=== Step MIMO Fit: Stage 2 (Phase Correction -> Fitting) ===\n');

    %% 載入數據 (從參數或 CSV)
    if isempty(H_mag_in) || isempty(H_phase_in) || isempty(frequencies_in)
        csv_path = fullfile(config.output_folder, 'fitting_results', ...
            'MIMO_Raw_Bode_Data.csv');
        if ~exist(csv_path, 'file')
            error('step_mimo_fit:csv_not_found', ...
                'CSV not found: %s\nRun mimo_fft first.', csv_path);
        end
        fprintf('Loading from CSV: %s\n', csv_path);
        [H_mag, H_phase_raw, frequencies] = read_mimo_csv(csv_path);
    else
        H_mag = H_mag_in;
        H_phase_raw = H_phase_in;
        frequencies = frequencies_in;
    end

    %% 1. 自動 180 度相位修正
    [H_phase_corrected, ~, phase_diag] = auto_phase_correct_6x6( ...
        H_phase_raw, H_mag, frequencies, 'Verbose', opts.Verbose);

    %% 輸出修正後 CSV
    if config.output.save_csv
        csv_corrected = fullfile(config.output_folder, 'fitting_results', ...
            'MIMO_Corrected_Bode_Data.csv');
        write_mimo_csv(csv_corrected, H_mag, H_phase_corrected, frequencies);
        if opts.Verbose
            fprintf('Corrected CSV saved: %s\n', csv_corrected);
        end
    end

    %% 2. Batch single-curve fitting (36 channels)
    fprintf('\n--- Batch Single-Curve Fitting (36 channels) ---\n');
    wc_rad = opts.wc_Hz * 2 * pi;
    w_k = frequencies(:) * 2 * pi;

    a1_matrix = zeros(6, 6);
    a2_matrix = zeros(6, 6);
    b_matrix = zeros(6, 6);
    R2_matrix = zeros(6, 6);

    for i = 1:6
        for j = 1:6
            h_k = squeeze(H_mag(i, j, :));
            phi_k = squeeze(H_phase_corrected(i, j, :)) * pi / 180;

            [a1_ij, a2_ij, b_ij, H_fitted] = fit_single_tf( ...
                h_k, phi_k, w_k, 'p', opts.p_weight, 'wc_rad', wc_rad);

            a1_matrix(i, j) = a1_ij;
            a2_matrix(i, j) = a2_ij;
            b_matrix(i, j) = b_ij;

            % 計算 R^2
            H_data = h_k .* exp(1j * phi_k);
            ss_res = sum(abs(H_data - H_fitted).^2);
            ss_tot = sum(abs(H_data - mean(H_data)).^2);
            if ss_tot > 0
                R2_matrix(i, j) = 1 - ss_res / ss_tot;
            else
                R2_matrix(i, j) = NaN;
            end
        end
    end

    %% 3. 共享假設檢驗 (CV)
    fprintf('\n--- Shared Parameter Hypothesis Test ---\n');
    a1_valid = a1_matrix(a1_matrix > 0);
    a2_valid = a2_matrix(a2_matrix > 0);

    cv_a1 = std(a1_valid) / mean(a1_valid) * 100;
    cv_a2 = std(a2_valid) / mean(a2_valid) * 100;

    fprintf('  a1: mean=%.4e, std=%.4e, CV=%.2f%%\n', ...
        mean(a1_valid), std(a1_valid), cv_a1);
    fprintf('  a2: mean=%.4e, std=%.4e, CV=%.2f%%\n', ...
        mean(a2_valid), std(a2_valid), cv_a2);

    if cv_a1 < 10 && cv_a2 < 10
        fprintf('  -> Shared parameter assumption VALID (CV < 10%%)\n');
    else
        fprintf('  -> Shared parameter assumption QUESTIONABLE (CV >= 10%%)\n');
    end

    %% 4. MIMO fitting (共享 A1, A2)
    fprintf('\n--- MIMO Multi-Curve Fitting ---\n');
    [A1, A2, B_modified, b_vec] = fit_mimo_tf( ...
        H_mag, H_phase_corrected, frequencies, ...
        'p', opts.p_weight, 'wc_Hz', opts.wc_Hz, ...
        'NegateOffDiagonal', true, 'Verbose', opts.Verbose);

    % B_raw (不取負)
    B_raw = zeros(6, 6);
    for i = 1:6
        for j = 1:6
            L = (i-1)*6 + j;
            B_raw(i, j) = b_vec(L) / A2;
        end
    end

    %% 5. ZOH 離散化
    fprintf('\n--- ZOH Discretization ---\n');
    T_sample = config.mimo.T_sample;
    num_s = A2;
    den_s = [1, A1, A2];
    H_continuous = tf(num_s, den_s);
    H_discrete = c2d(H_continuous, T_sample, 'zoh');

    [num_z, den_z] = tfdata(H_discrete, 'v');
    den_z = den_z / den_z(1);
    num_z = num_z / den_z(1);

    poles_z = roots([1, den_z(2), den_z(3)]);

    fprintf('  T_sample = %.0e s\n', T_sample);
    fprintf('  Numerator [b0, b1]: [%.6e, %.6e]\n', num_z(2), num_z(3));
    fprintf('  Denominator [1, a1, a2]: [1, %.6e, %.6e]\n', den_z(2), den_z(3));
    fprintf('  Poles: z1=%.8f, z2=%.8f\n', poles_z(1), poles_z(2));
    fprintf('  |z1|=%.8f, |z2|=%.8f\n', abs(poles_z(1)), abs(poles_z(2)));

    if all(abs(poles_z) < 1)
        fprintf('  System STABLE (all poles inside unit circle)\n');
    else
        fprintf('  System UNSTABLE\n');
    end

    %% 6. 放大器增益矩陣
    k_A = diag(config.mimo.k_A_diag);

    %% 組裝 fit_results
    fit_results = struct();
    fit_results.A1 = A1;
    fit_results.A2 = A2;
    fit_results.B_raw = B_raw;
    fit_results.B_modified = B_modified;
    fit_results.b_vec = b_vec;
    fit_results.frequencies = frequencies;
    fit_results.H_mag = H_mag;
    fit_results.H_phase_corrected = H_phase_corrected;
    fit_results.H_phase_raw = H_phase_raw;

    % Batch single results
    fit_results.batch_single.a1_matrix = a1_matrix;
    fit_results.batch_single.a2_matrix = a2_matrix;
    fit_results.batch_single.b_matrix = b_matrix;
    fit_results.batch_single.R2_matrix = R2_matrix;
    fit_results.batch_single.cv_a1 = cv_a1;
    fit_results.batch_single.cv_a2 = cv_a2;

    % Discrete
    fit_results.discrete.num_z = num_z;
    fit_results.discrete.den_z = den_z;
    fit_results.discrete.poles_z = poles_z;
    fit_results.discrete.T_sample = T_sample;

    % Amplifier gain
    fit_results.k_A = k_A;

    % Phase correction diagnostics
    fit_results.phase_diag = phase_diag;

    % Fitting parameters
    fit_results.fitting_params.p = opts.p_weight;
    fit_results.fitting_params.wc_Hz = opts.wc_Hz;

    %% Console 摘要
    fprintf('\n--- MIMO Fitting Summary ---\n');
    fprintf('  A1 = %.15e\n', A1);
    fprintf('  A2 = %.15e\n', A2);
    fprintf('  B_modified diagonal: [');
    for i = 1:6
        if i > 1, fprintf(', '); end
        fprintf('%.10e', B_modified(i, i));
    end
    fprintf(']\n');

    %% 7. 儲存結果
    if config.output.save_fitting_results
        % .mat (full precision)
        mat_path = fullfile(config.output_folder, 'fitting_results', ...
            'mimo_fit_results.mat');
        save(mat_path, 'fit_results');
        fprintf('MAT saved: %s\n', mat_path);

        % CSV (10 significant digits)
        csv_fit = fullfile(config.output_folder, 'fitting_results', ...
            'MIMO_Fit_Results.csv');
        write_fit_csv(csv_fit, fit_results);
        fprintf('CSV saved: %s\n', csv_fit);

        % LaTeX
        latex_path = fullfile(config.output_folder, 'fitting_results', ...
            'transfer_function_latex.txt');
        write_latex(latex_path, fit_results, config);
        fprintf('LaTeX saved: %s\n', latex_path);
    end

    fprintf('\nStage 2 complete.\n');
end

%% === Local Functions ===

function [H_mag, H_phase, frequencies] = read_mimo_csv(csv_path)
    T = readtable(csv_path);
    frequencies = T.Frequency_Hz';
    num_freq = length(frequencies);
    H_mag = zeros(6, 6, num_freq);
    H_phase = zeros(6, 6, num_freq);

    for i = 1:6
        for j = 1:6
            mag_col = sprintf('H_%d%d_Mag', i, j);
            phase_col = sprintf('H_%d%d_Phase_deg', i, j);
            H_mag(i, j, :) = T.(mag_col);
            H_phase(i, j, :) = T.(phase_col);
        end
    end
end

function write_mimo_csv(csv_path, H_mag, H_phase, frequencies)
    num_freq = length(frequencies);
    header = {'Frequency_Hz'};
    for i = 1:6
        for j = 1:6
            header{end+1} = sprintf('H_%d%d_Mag', i, j); %#ok<AGROW>
            header{end+1} = sprintf('H_%d%d_Phase_deg', i, j); %#ok<AGROW>
        end
    end

    fid = fopen(csv_path, 'w');
    fprintf(fid, '%s', header{1});
    for c = 2:length(header)
        fprintf(fid, ',%s', header{c});
    end
    fprintf(fid, '\n');

    for k = 1:num_freq
        fprintf(fid, '%.6f', frequencies(k));
        for i = 1:6
            for j = 1:6
                fprintf(fid, ',%.10e,%.6f', H_mag(i, j, k), H_phase(i, j, k));
            end
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end

function write_fit_csv(csv_path, fr)
    fid = fopen(csv_path, 'w');

    % Shared parameters
    fprintf(fid, 'Parameter,Value\n');
    fprintf(fid, 'A1,%.10e\n', fr.A1);
    fprintf(fid, 'A2,%.10e\n', fr.A2);
    fprintf(fid, 'p,%.2f\n', fr.fitting_params.p);
    fprintf(fid, 'wc_Hz,%.4f\n', fr.fitting_params.wc_Hz);
    fprintf(fid, 'CV_a1,%.4f\n', fr.batch_single.cv_a1);
    fprintf(fid, 'CV_a2,%.4f\n', fr.batch_single.cv_a2);
    fprintf(fid, '\n');

    % B_modified matrix
    fprintf(fid, 'B_modified\n');
    for i = 1:6
        for j = 1:6
            if j > 1, fprintf(fid, ','); end
            fprintf(fid, '%.10e', fr.B_modified(i, j));
        end
        fprintf(fid, '\n');
    end
    fprintf(fid, '\n');

    % Discrete parameters
    fprintf(fid, 'Discrete_Parameters\n');
    fprintf(fid, 'T_sample,%.10e\n', fr.discrete.T_sample);
    fprintf(fid, 'num_z_b0,%.10e\n', fr.discrete.num_z(2));
    fprintf(fid, 'num_z_b1,%.10e\n', fr.discrete.num_z(3));
    fprintf(fid, 'den_z_a1,%.10e\n', fr.discrete.den_z(2));
    fprintf(fid, 'den_z_a2,%.10e\n', fr.discrete.den_z(3));
    fprintf(fid, 'pole_z1_real,%.10e\n', real(fr.discrete.poles_z(1)));
    fprintf(fid, 'pole_z1_imag,%.10e\n', imag(fr.discrete.poles_z(1)));
    fprintf(fid, 'pole_z2_real,%.10e\n', real(fr.discrete.poles_z(2)));
    fprintf(fid, 'pole_z2_imag,%.10e\n', imag(fr.discrete.poles_z(2)));

    fclose(fid);
end

function write_latex(latex_path, fr, config)
    fid = fopen(latex_path, 'w');

    fprintf(fid, '%% ============================================\n');
    fprintf(fid, '%% Transfer Function LaTeX Output\n');
    fprintf(fid, '%% Generated: %s\n', datestr(now)); %#ok<TNOW1,DATST>
    fprintf(fid, '%% ============================================\n\n');

    % 1. Continuous-time H(s)
    A1_exp = floor(log10(abs(fr.A1)));
    A1_man = fr.A1 / 10^A1_exp;
    A2_exp = floor(log10(abs(fr.A2)));
    A2_man = fr.A2 / 10^A2_exp;

    fprintf(fid, '%% === Continuous-Time Transfer Function ===\n');
    fprintf(fid, '\\mathbf{H}(s) = \\frac{%.4f \\times 10^{%d}}{', A2_man, A2_exp);
    fprintf(fid, 's^2 + %.4f \\times 10^{%d} s + %.4f \\times 10^{%d}', ...
        A1_man, A1_exp, A2_man, A2_exp);
    fprintf(fid, '} \\mathbf{B}\n\n');

    % 2. Discrete-time H(z^-1)
    b0 = fr.discrete.num_z(2);
    b1 = fr.discrete.num_z(3);
    b0_exp = floor(log10(abs(b0)));
    b0_man = b0 / 10^b0_exp;
    b1_over_b0 = b1 / b0;

    a1_z = fr.discrete.den_z(2);
    a2_z = fr.discrete.den_z(3);
    z1 = fr.discrete.poles_z(1);
    z2 = fr.discrete.poles_z(2);

    fprintf(fid, '%% === Discrete-Time Transfer Function (ZOH) ===\n');
    fprintf(fid, '%% Sampling Time: T = %.0e s\n', fr.discrete.T_sample);

    if abs(imag(z1)) > 1e-6
        fprintf(fid, '%% Complex poles, using quadratic form\n');
        fprintf(fid, ['\\mathbf{H}(z^{-1}) = z^{-1} \\frac{' ...
            '%.4f \\times 10^{%d} \\times (1 + %.4f z^{-1})' ...
            '}{' ...
            '1 + %.6f z^{-1} + %.6f z^{-2}' ...
            '} \\mathbf{B}\n'], ...
            b0_man, b0_exp, b1_over_b0, a1_z, a2_z);
        fprintf(fid, ['%% Complex factorization: ' ...
            '(1 - (%.6f%+.6fi) z^{-1})(1 - (%.6f%+.6fi) z^{-1})\n'], ...
            real(z1), imag(z1), real(z2), imag(z2));
    else
        fprintf(fid, '%% Real poles, factored form\n');
        fprintf(fid, ['\\mathbf{H}(z^{-1}) = z^{-1} \\frac{' ...
            '%.4f \\times 10^{%d} \\times (1 + %.4f z^{-1})' ...
            '}{' ...
            '(1 - %.6f z^{-1})(1 - %.6f z^{-1})' ...
            '} \\mathbf{B}\n'], ...
            b0_man, b0_exp, b1_over_b0, real(z1), real(z2));
    end

    fprintf(fid, '%% Z-domain poles: z1 = %.8f %+.8fi, z2 = %.8f %+.8fi\n', ...
        real(z1), imag(z1), real(z2), imag(z2));
    fprintf(fid, '%% Pole magnitudes: |z1| = %.8f, |z2| = %.8f\n\n', ...
        abs(z1), abs(z2));

    % 3. B matrix
    fprintf(fid, '%% === B Matrix (off-diagonal elements negated) ===\n');
    fprintf(fid, '\\mathbf{B} = \\begin{bmatrix}\n');
    for i = 1:6
        for j = 1:6
            if j > 1, fprintf(fid, ' & '); end
            fprintf(fid, '%.4f', fr.B_modified(i, j));
        end
        if i < 6
            fprintf(fid, ' \\\\\n');
        else
            fprintf(fid, '\n');
        end
    end
    fprintf(fid, '\\end{bmatrix}\n\n');

    % 4. k_A matrix
    fprintf(fid, '%% === Amplifier Gain Matrix ===\n');
    fprintf(fid, 'k_A = \\begin{bmatrix}\n');
    k_A = diag(config.mimo.k_A_diag);
    for i = 1:6
        for j = 1:6
            if j > 1, fprintf(fid, ' & '); end
            fprintf(fid, '%.4f', k_A(i, j));
        end
        if i < 6
            fprintf(fid, ' \\\\\n');
        else
            fprintf(fid, '\n');
        end
    end
    fprintf(fid, '\\end{bmatrix}\n');

    fclose(fid);
end
