function generate_report_figures()
%GENERATE_REPORT_FIGURES Create publication figures for charge calibration report
%
% Generates:
%   NEW-5: Linearized fit (1/sqrt(H) vs x) with residuals
%   NEW-7: Yokeless (b=1979) vs yoke (b=405) H(x) overlay
%
% Output: charge_cali/docs/figures/
%
% Usage:
%   cd charge_cali
%   generate_report_figures

    %% Setup paths
    charge_root = fileparts(mfilename('fullpath'));
    addpath(fullfile(charge_root, '..', 'functions'));

    fig_out = fullfile(charge_root, 'docs', 'figures');
    if ~exist(fig_out, 'dir'), mkdir(fig_out); end

    %% Load data
    csv_path = fullfile(charge_root, 'results', 'Charge_NTU', ...
        'diagnostics', 'Charge_Data.csv');
    mat_path = fullfile(charge_root, 'results', 'Charge_NTU', ...
        'fitting_results', 'charge_fit_results.mat');

    T = readtable(csv_path);
    distances = T{:, 1};       % [um]
    H_01Hz = T{:, 2};         % H at 0.1 Hz (first data column)

    loaded = load(mat_path, 'charge_fit_results');
    res = loaded.charge_fit_results;

    % Get 0.1 Hz fit parameters
    fits = res.fits;
    idx_01 = find(abs([fits.frequency] - 0.1) < 1e-6, 1);
    a = fits(idx_01).a;
    b = fits(idx_01).b;
    R2 = fits(idx_01).R_squared;

    fprintf('Using 0.1 Hz fit: a = %.4f, b = %.2f um, R^2 = %.6f\n', a, b, R2);

    %% ============================================================
    %  NEW-5: Linearized Fit
    %  ============================================================
    generate_linearized_fit(distances, H_01Hz, a, b, R2, fig_out);

    %% ============================================================
    %  NEW-7: Yokeless vs Yoke Comparison
    %  ============================================================
    generate_yoke_comparison(a, b, fig_out);

    fprintf('\nAll report figures saved to: %s\n', fig_out);
end

%% ============================================================
function generate_linearized_fit(distances, H_data, a, b, R2, fig_out)
%GENERATE_LINEARIZED_FIT  1/sqrt(H) vs x with regression + residuals

    %% Linearize data
    valid = H_data > 0 & isfinite(H_data);
    x = distances(valid);
    H = H_data(valid);
    y = 1 ./ sqrt(H);

    %% Regression line
    slope = 1 / a;
    intercept = b / a;
    y_fit = slope * x + intercept;
    residuals = y - y_fit;

    %% Dense line for plotting
    x_line = linspace(0, max(x) * 1.05, 200);
    y_line = slope * x_line + intercept;

    %% Figure
    fig = figure('Visible', 'off', 'Position', [100, 100, 800, 700]);

    % --- Top: Linearized data + regression ---
    ax1 = subplot(2, 1, 1);
    plot(x, y, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5, ...
        'MarkerFaceColor', [0.3, 0.3, 0.3]);
    hold on;
    plot(x_line, y_line, 'r-', 'LineWidth', 2);
    hold off;
    ylabel('$1/\sqrt{H}$', 'Interpreter', 'latex', ...
        'FontSize', 18, 'FontWeight', 'bold');
    title(sprintf('Linearized Inverse-Square Fit (0.1 Hz, R^2 = %.4f)', R2), ...
        'FontSize', 14, 'FontWeight', 'bold');
    legend({'Data', sprintf('Fit: slope = %.4e, intercept = %.4f', slope, intercept)}, ...
        'Location', 'northwest', 'FontSize', 12);
    set(ax1, 'FontSize', 14, 'FontWeight', 'bold', ...
        'LineWidth', 1.5, 'Box', 'on');
    grid on;

    % --- Bottom: Residuals ---
    ax2 = subplot(2, 1, 2);
    stem(x, residuals, 'k', 'LineWidth', 1.5, 'MarkerSize', 6, ...
        'MarkerFaceColor', [0.3, 0.3, 0.3]);
    hold on;
    yline(0, 'r--', 'LineWidth', 1.5);
    hold off;
    xlabel('Distance (\mum)', 'FontSize', 18, 'FontWeight', 'bold');
    ylabel('Residual', 'FontSize', 18, 'FontWeight', 'bold');
    title('Residuals', 'FontSize', 14, 'FontWeight', 'bold');
    set(ax2, 'FontSize', 14, 'FontWeight', 'bold', ...
        'LineWidth', 1.5, 'Box', 'on');
    grid on;

    %% Save
    out_path = fullfile(fig_out, 'linearized_fit.png');
    exportgraphics(fig, out_path, 'Resolution', 300);
    close(fig);
    fprintf('Saved: %s\n', out_path);
end

%% ============================================================
function generate_yoke_comparison(~, b_ntu, fig_out)
%GENERATE_YOKE_COMPARISON  H(x) overlay: yokeless (this work) vs yoke (Menq)

    %% Parameters
    % This work: yokeless hexapole
    % b_ntu already in um

    % Menq (2010) quadrupole with yoke: l = 405 um
    b_menq = 405;   % [um]
    % Menq a is unknown, but we normalize both to 1 at x=0 for comparison
    % H(x) / H(0) = b^2 / (x + b)^2

    %% Distance axis
    x = linspace(0, 2500, 500);   % [um]

    % Normalized decay curves
    H_ntu_norm  = b_ntu^2  ./ (x + b_ntu).^2;
    H_menq_norm = b_menq^2 ./ (x + b_menq).^2;

    %% Figure
    fig = figure('Visible', 'off', 'Position', [100, 100, 800, 500]);
    semilogy(x, H_ntu_norm, 'b-', 'LineWidth', 2.5);
    hold on;
    semilogy(x, H_menq_norm, 'r--', 'LineWidth', 2.5);

    % Mark key distances
    xline(b_ntu, 'b:', 'LineWidth', 1.5);
    xline(b_menq, 'r:', 'LineWidth', 1.5);
    hold off;

    xlabel('Distance (\mum)', 'FontSize', 18, 'FontWeight', 'bold');
    ylabel('H(x) / H(0)', 'FontSize', 18, 'FontWeight', 'bold');
    title('Magnetic Field Decay: Yokeless vs Yoke Design', ...
        'FontSize', 14, 'FontWeight', 'bold');
    legend({sprintf('This work (b = %d \\mum, no yoke)', round(b_ntu)), ...
            sprintf('Menq 2010 (b = %d \\mum, with yoke)', b_menq), ...
            sprintf('x = b_{NTU} = %d \\mum', round(b_ntu)), ...
            sprintf('x = b_{Menq} = %d \\mum', b_menq)}, ...
        'Location', 'northeast', 'FontSize', 12);
    set(gca, 'FontSize', 14, 'FontWeight', 'bold', ...
        'LineWidth', 1.5, 'Box', 'on');
    grid on;
    xlim([0, 2500]);

    %% Save
    out_path = fullfile(fig_out, 'yoke_comparison.png');
    exportgraphics(fig, out_path, 'Resolution', 300);
    close(fig);
    fprintf('Saved: %s\n', out_path);
end
