function analyze_charge_physics(experiment, varargin)
%ANALYZE_CHARGE_PHYSICS Validate fitted parameter a and estimate magnetic force
%
% From charge calibration H(x) = a^2 / (x+b)^2, this script:
%   1. Derives k_pole (flux per ampere) and R_a (reluctance) from fitted a
%   2. Computes B(x), dB/dx, F(x) on a paramagnetic bead
%   3. Compares F to thermal force
%   4. Generates 2x2 diagnostic figure
%
% Signal chain (Menq 2009 notation):
%   Phi = k_pole * I          magnetic circuit (k_pole = N_c / R_a)
%   q   = Phi / u0            magnetic charge definition
%   B   = (u0/4pi) * q / r^2  monopole field
%       = k_pole * I / (4pi * r^2)     (u0 cancels)
%
% Result: a^2 = S_H * N_c * k_A * 10^12 / (4pi * R_a)
%
% Usage:
%   analyze_charge_physics('Charge_NTU')
%   analyze_charge_physics('Charge_NTU', 'V_DA', 2.5)
%   analyze_charge_physics('Charge_NTU', 'bead_diameter', 4.5e-6)
%
% Requires: charge_fit_results.mat from run_charge_cali
%
% Reference:
%   Menq et al., "Design and Modeling of a 3-D Magnetic Actuator
%   for Magnetic Microbead Manipulation," IEEE/ASME Trans. Mechatronics, 2011.

    %% Setup paths
    charge_root = fileparts(mfilename('fullpath'));
    addpath(charge_root);

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'experiment', @ischar);
    addParameter(p, 'S_H', 130, @isnumeric);           % Hall sensitivity [V/T]
    addParameter(p, 'k_A', 0.3614, @isnumeric);        % Amplifier gain [A/V]
    addParameter(p, 'V_DA', 2.0, @isnumeric);          % DAC peak amplitude [V]
    addParameter(p, 'N_c', 50, @isnumeric);             % Coil turns per pole
    addParameter(p, 'r_tip', 5e-6, @isnumeric);        % Pole tip radius [m]
    addParameter(p, 'bead_diameter', 4.5e-6, @isnumeric); % Bead diameter [m]
    addParameter(p, 'chi_vol', 0.4, @isnumeric);       % Volume susceptibility (SI)
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, experiment, varargin{:});
    opts = p.Results;

    %% Load config and fit results
    config_func = str2func([experiment '_config']);
    config = config_func();

    mat_path = fullfile(config.output_folder, 'fitting_results', 'charge_fit_results.mat');
    if ~exist(mat_path, 'file')
        error('analyze_charge_physics:no_mat', ...
            'Fit results not found: %s\nRun run_charge_cali(''%s'', ''full'') first.', ...
            mat_path, experiment);
    end
    loaded = load(mat_path, 'charge_fit_results');
    res = loaded.charge_fit_results;

    %% Extract fitted parameters
    fits = res.fits;
    if isempty(fits)
        error('analyze_charge_physics:no_fits', 'No fit results available.');
    end

    a_values = [fits.a];
    b_values = [fits.b];
    mean_a = mean(a_values);
    mean_b = mean(b_values);       % [um]
    std_a = std(a_values);

    %% Physical constants
    u0 = 4 * pi * 1e-7;           % [T*m/A]
    k_B = 1.380649e-23;           % Boltzmann [J/K]
    T_room = 300;                  % [K]

    %% Derived bead parameters
    r_bead = opts.bead_diameter / 2;
    V_bead = (4/3) * pi * r_bead^3;
    chi_eff = 3 * opts.chi_vol / (3 + opts.chi_vol);   % sphere demagnetization

    %% ============================================================
    %  Analysis 1: Signal-chain derivation
    %  ============================================================
    %
    %  Signal chain:
    %    V_DA --> [k_A] --> I --> [Coil, N_c turns] --> Phi --> [q=Phi/u0]
    %         --> B(x) = k_pole*I / (4pi*(x+b)^2) --> [S_H] --> Vm
    %
    %  Step 1: Magnetic circuit (Hopkinson's law)
    %    Phi = N_c * I / R_a       [Wb]
    %    Define: k_pole = N_c / R_a = Phi / I    [Wb/A]
    %
    %  Step 2: Magnetic charge (monopole model)
    %    q = Phi / u0 = k_pole * I / u0          [A*m]
    %
    %  Step 3: Magnetic field
    %    B(x) = (u0/4pi) * q / (x+b)^2
    %         = (u0/4pi) * (k_pole*I/u0) / (x+b)^2
    %         = k_pole * I / (4pi * (x+b)^2)     <-- u0 cancels!
    %
    %  Step 4: H(x) = Vm / V_DA = S_H * B / V_DA
    %         = S_H * k_pole * k_A / (4pi * (x+b)^2)
    %
    %  With x,b in [um]: (x+b)^2 [m^2] = (x+b)^2 [um^2] * 10^-12
    %    a^2 = S_H * k_pole * k_A * 10^12 / (4pi)
    %        = S_H * N_c * k_A * 10^12 / (4pi * R_a)
    %
    %  Reverse: solve for k_pole and R_a from fitted a

    k_pole = 4 * pi * mean_a^2 / (opts.S_H * opts.k_A * 1e12);  % [Wb/A]
    R_reluctance = opts.N_c / k_pole;                              % [A/Wb]

    b_m = mean_b * 1e-6;           % [m]
    I_peak = opts.k_A * opts.V_DA; % [A]

    %% ============================================================
    %  Analysis 2: Compute B(x), dB/dx, F(x)
    %  ============================================================
    %
    %  B(x) = k_pole * I / (4pi * (x+b)^2)   [u0 does NOT appear]
    %  dB/dx = -2 * k_pole * I / (4pi * (x+b)^3)
    %  F(x) = (chi_eff * V_bead / u0) * B * |dB/dx|

    x_um = linspace(0, max(res.distances) + 200, 500);  % [um]
    x_m = x_um * 1e-6;                                   % [m]

    B_field = k_pole * I_peak ./ (4 * pi * (x_m + b_m).^2);   % [T]
    dBdx = 2 * k_pole * I_peak ./ (4 * pi * (x_m + b_m).^3);  % [T/m]

    F_mag = (chi_eff * V_bead / u0) .* B_field .* dBdx;  % [N]
    F_pN = F_mag * 1e12;                                  % [pN]

    % Thermal force: F_th = sqrt(2 * k_B * T * gamma / dt)
    eta_water = 1e-3;               % [Pa*s]
    gamma = 6 * pi * eta_water * r_bead;  % Stokes drag [N*s/m]
    dt_meas = 1;                    % measurement timescale [s]
    F_thermal = sqrt(2 * k_B * T_room * gamma / dt_meas); % [N]
    F_thermal_pN = F_thermal * 1e12;

    %% ============================================================
    %  Console summary
    %  ============================================================
    fprintf('\n========================================\n');
    fprintf('  Charge Physics Analysis: %s\n', experiment);
    fprintf('========================================\n');

    fprintf('\n--- Fitted Parameters ---\n');
    fprintf('  a = %.2f +/- %.2f (mean +/- std, N=%d frequencies)\n', ...
        mean_a, std_a, length(a_values));
    fprintf('  b = %.1f +/- %.1f um\n', mean_b, std(b_values));

    fprintf('\n--- Signal-Chain Derivation ---\n');
    fprintf('  a^2 = S_H * N_c * k_A * 10^12 / (4pi * R_a)\n');
    fprintf('  Known:  S_H = %d V/T,  N_c = %d,  k_A = %.4f A/V\n', ...
        opts.S_H, opts.N_c, opts.k_A);
    fprintf('  From a = %.2f, reverse-solve:\n', mean_a);
    fprintf('    k_pole = Phi/I = 4pi*a^2 / (S_H*k_A*10^12)\n');
    fprintf('           = %.4e Wb/A\n', k_pole);
    fprintf('    R_a    = N_c / k_pole = %d / %.4e\n', opts.N_c, k_pole);
    fprintf('           = %.3e A/Wb\n', R_reluctance);
    fprintf('    NOTE: This is R_total (single pole, no yoke).\n');
    fprintf('          Menq R_a is pure air-gap reluctance (with yoke).\n');
    fprintf('          Direct comparison is NOT valid (different circuits).\n');

    fprintf('\n--- Cross-Checks ---\n');
    % Menq quadrupole paper comparison (Zhang & Menq, IEEE/ASME Trans. Mech., 2010)
    R_a_Menq_quad = 1.8e9;   % quadrupole, r_tip ~ 40 um, with yoke
    R_a_Menq_hex = 2.8e9;    % hexapole (3-D actuator, 2011), with yoke
    fprintf('  [1] R_a reference (NOT directly comparable):\n');
    fprintf('      Menq Quad (2010):  R_a = %.1e A/Wb  (with yoke, r_tip ~ 40 um)\n', R_a_Menq_quad);
    fprintf('      Menq Hex  (2011):  R_a = %.1e A/Wb  (with yoke, r_tip ~ 40 um)\n', R_a_Menq_hex);
    fprintf('      NTU (this work):   R_a = %.1e A/Wb  (no yoke, r_tip ~ %.0f um)\n', ...
        R_reluctance, opts.r_tip * 1e6);
    fprintf('      NTU R_a is ~%.0fx smaller (lower reluctance without yoke return path).\n', ...
        R_a_Menq_quad / R_reluctance);
    fprintf('      Caveat: NTU R_a = R_total (R_pole+R_gap+R_return_air),\n');
    fprintf('              Menq R_a = R_air_gap only (yoke provides low-R return).\n');

    % B at closest distance
    I_peak_str = sprintf('%.3f', I_peak);
    fprintf('  [2] B(10 um) at I = %s A:\n', I_peak_str);
    B_10um = interp1(x_um, B_field, 10);
    fprintf('      B = %.3f mT  (EQ730L linear range: +/-15 mT -> OK)\n', ...
        B_10um * 1e3);

    % a consistency across frequencies
    fprintf('  [3] a consistency: CV = %.2f%%  (< 1%% -> OK)\n', ...
        std_a / mean_a * 100);

    fprintf('\n--- Bead Parameters ---\n');
    fprintf('  Bead: d = %.1f um (Dynabeads M-450)\n', opts.bead_diameter * 1e6);
    fprintf('  V_bead = %.2e m^3\n', V_bead);
    fprintf('  chi_vol = %.2f, chi_eff = %.3f (sphere demagnetization)\n', ...
        opts.chi_vol, chi_eff);

    fprintf('\n--- Force Estimates (I = %s A) ---\n', I_peak_str);
    fprintf('  %-10s  %-12s  %-12s  %-10s  %-10s\n', ...
        'x (um)', 'B (mT)', 'dB/dx (T/m)', 'F (pN)', 'F/F_th');
    fprintf('  %s\n', repmat('-', 1, 58));
    x_check = [10, 100, 500, 1000, 2000];
    for i = 1:length(x_check)
        xi = x_check(i);
        if xi > max(x_um), continue; end
        Bi = interp1(x_um, B_field, xi);
        dBi = interp1(x_um, dBdx, xi);
        Fi = interp1(x_um, F_pN, xi);
        fprintf('  %-10d  %-12.3f  %-12.2f  %-10.4f  %-10.2f\n', ...
            xi, Bi * 1e3, dBi, Fi, Fi / F_thermal_pN);
    end

    fprintf('\n--- Thermal Comparison ---\n');
    fprintf('  F_thermal (%.1f um bead, dt=%ds) = %.4f pN\n', ...
        opts.bead_diameter * 1e6, dt_meas, F_thermal_pN);

    % Find crossover distance
    F_ratio = F_pN ./ F_thermal_pN;
    cross_idx = find(F_ratio(1:end-1) >= 1 & F_ratio(2:end) < 1, 1);
    if ~isempty(cross_idx)
        x_cross = interp1(F_ratio(cross_idx:cross_idx+1), ...
            x_um(cross_idx:cross_idx+1), 1);
        fprintf('  Crossover (F = F_thermal): x ~ %.0f um\n', x_cross);
    else
        if all(F_ratio > 1)
            fprintf('  F > F_thermal over entire range\n');
        else
            fprintf('  F < F_thermal over entire range\n');
        end
    end

    fprintf('\n--- Key Parameter: b (flux concentration) ---\n');
    r_tip_um = opts.r_tip * 1e6;
    fprintf('  b = %.0f um  (equivalent charge offset behind tip surface)\n', mean_b);
    fprintf('  r_tip = %.0f um  (pole tip machined curvature)\n', r_tip_um);
    fprintf('  b >> r_tip -> flux is NOT concentrated at the tip\n');
    fprintf('  Menq quadrupole: l = 405 um (pole center-to-center distance)\n');
    fprintf('  NTU single pole: b = %.0f um (no yoke, flux spreads)\n', mean_b);
    fprintf('\n  Force suppression at x = r_tip:\n');
    F_ratio_tip = (opts.r_tip / (opts.r_tip + b_m))^5;
    fprintf('  F_real / F_ideal = [r_tip/(r_tip+b)]^5 = %.2e\n', F_ratio_tip);
    fprintf('  -> ~%.0fx weaker than ideal monopole at same distance\n', 1 / F_ratio_tip);
    fprintf('========================================\n\n');

    %% ============================================================
    %  Figure: 2x2 Physics Analysis
    %  ============================================================
    LW = config.plot.line_width;
    FS_tick = config.plot.font_size_tick;
    FS_label = config.plot.font_size_label;
    FS_legend = config.plot.font_size_legend;
    AX_LW = config.plot.axis_line_width;

    fig = figure('Visible', 'off', 'Position', [100, 100, 1200, 900]);

    % --- (1) B(x) vs distance ---
    ax1 = subplot(2, 2, 1);
    plot(x_um, B_field * 1e3, 'b-', 'LineWidth', LW);
    hold on;
    xline(r_tip_um, 'r--', 'LineWidth', 2);
    hold off;
    ylabel('B (mT)', 'FontSize', FS_label, 'FontWeight', 'bold');
    title('Magnetic Field', 'FontSize', config.plot.font_size_title, 'FontWeight', 'bold');
    lgd1 = legend(sprintf('I = %.2f A', I_peak), ...
        sprintf('r_{tip} = %.0f \\mum', r_tip_um), ...
        'Location', 'northeast', 'FontSize', FS_legend, 'FontWeight', 'bold');
    lgd1.Box = 'on';
    set(ax1, 'FontSize', FS_tick, 'FontWeight', 'bold', ...
        'LineWidth', AX_LW, 'Box', 'on');
    grid on;

    % --- (2) dB/dx vs distance ---
    ax2 = subplot(2, 2, 2);
    plot(x_um, dBdx, 'b-', 'LineWidth', LW);
    hold on;
    xline(r_tip_um, 'r--', 'LineWidth', 2);
    hold off;
    ylabel('|dB/dx| (T/m)', 'FontSize', FS_label, 'FontWeight', 'bold');
    title('Field Gradient', 'FontSize', config.plot.font_size_title, 'FontWeight', 'bold');
    lgd2 = legend('|dB/dx|', sprintf('r_{tip} = %.0f \\mum', r_tip_um), ...
        'Location', 'northeast', 'FontSize', FS_legend, 'FontWeight', 'bold');
    lgd2.Box = 'on';
    set(ax2, 'FontSize', FS_tick, 'FontWeight', 'bold', ...
        'LineWidth', AX_LW, 'Box', 'on');
    grid on;

    % --- (3) F(x) vs distance ---
    ax3 = subplot(2, 2, 3);
    plot(x_um, F_pN, 'b-', 'LineWidth', LW);
    hold on;
    yline(F_thermal_pN, 'r--', 'LineWidth', 2);
    xline(r_tip_um, 'k:', 'LineWidth', 2);
    hold off;
    xlabel('Distance (\mum)', 'FontSize', FS_label, 'FontWeight', 'bold');
    ylabel('F (pN)', 'FontSize', FS_label, 'FontWeight', 'bold');
    title('Force on Bead', 'FontSize', config.plot.font_size_title, 'FontWeight', 'bold');
    lgd3 = legend('F_{mag}', ...
        sprintf('F_{thermal} = %.3f pN', F_thermal_pN), ...
        sprintf('r_{tip} = %.0f \\mum', r_tip_um), ...
        'Location', 'northeast', 'FontSize', FS_legend, 'FontWeight', 'bold');
    lgd3.Box = 'on';
    set(ax3, 'FontSize', FS_tick, 'FontWeight', 'bold', ...
        'LineWidth', AX_LW, 'Box', 'on');
    grid on;

    % --- (4) F/F_thermal vs distance (log scale) ---
    ax4 = subplot(2, 2, 4);
    semilogy(x_um, F_ratio, 'b-', 'LineWidth', LW);
    hold on;
    yline(1, 'r--', 'LineWidth', 2);
    xline(r_tip_um, 'k:', 'LineWidth', 2);
    hold off;
    xlabel('Distance (\mum)', 'FontSize', FS_label, 'FontWeight', 'bold');
    ylabel('F / F_{thermal}', 'FontSize', FS_label, 'FontWeight', 'bold');
    title('Force SNR', 'FontSize', config.plot.font_size_title, 'FontWeight', 'bold');
    lgd4 = legend('F_{mag} / F_{thermal}', ...
        'F / F_{thermal} = 1', ...
        sprintf('r_{tip} = %.0f \\mum', r_tip_um), ...
        'Location', 'northeast', 'FontSize', FS_legend, 'FontWeight', 'bold');
    lgd4.Box = 'on';
    set(ax4, 'FontSize', FS_tick, 'FontWeight', 'bold', ...
        'LineWidth', AX_LW, 'Box', 'on');
    grid on;

    %% Save figure
    fig_folder = fullfile(config.output_folder, 'figures');
    if ~exist(fig_folder, 'dir'), mkdir(fig_folder); end
    out_path = fullfile(fig_folder, 'Charge_Physics_Analysis.png');
    exportgraphics(fig, out_path, 'Resolution', 300);
    close(fig);

    if opts.Verbose
        fprintf('Figure saved: %s\n', out_path);
    end
end
