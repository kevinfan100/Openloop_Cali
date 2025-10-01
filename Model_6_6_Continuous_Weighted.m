% W: 1x19 frequency vector (Hz)
% H_mag: 6x6x19 linear magnitude matrix
% H_phase: 6x6x19 phase matrix

clear; clc;

%% ========== CURVE FITTING PARAMETERS ==========

% Single curve fitting - Parameter Comparison
ENABLE_PARAM_COMPARISON = true;  % true: compare multiple parameters, false: single parameter

% If ENABLE_PARAM_COMPARISON = false, use these parameters:
p_single = 1;                 % Weighting exponent (0.5 or 1)
wc_single_Hz = 5;             % Cutoff frequency (Hz) for low-pass weighting

% If ENABLE_PARAM_COMPARISON = true, define parameter sets to compare:
% Each row: [p, wc_Hz]
param_sets_single = [
    0.5, 1e10;   % Almost no weighting (baseline)
    0.5, 50;     
    0.5, 100;    
    0.5, 200;    
];

excited_channel = 5;          % Input channel (excitation applied at this channel)
channel = 5;                  % Output channel (response measured at this channel)

% Multiple curve fitting weighting
p_multi = 1;                  % Weighting exponent (0.5 or 1)
wc_multi_Hz = 5;              % Cutoff frequency (Hz) for low-pass weighting

% Plot control switches
PLOT_ONE_CURVE = true;       % Plot single curve Bode
PLOT_MULTI_CURVE = false;      % Plot multiple curves Bode

% ================================================

num_files = 6;
num_channels = 6;
num_freq = 19;     % 19 frequency points

H_mag = zeros(num_channels, num_files, num_freq);
H_phase = zeros(num_channels, num_files, num_freq);
W = [];

% Read data from each file
for file_idx = 1:num_files

    script_name = sprintf('P%d', file_idx);

    fprintf('Reading file: %s.m\n', script_name);

    try
        eval(script_name);

        if isempty(W)
            W = frequencies;
        end

        H_mag(:, file_idx, :) = magnitudes_linear;
        H_phase(:, file_idx, :) = phases_processed;

    catch ME
        fprintf('Error reading %s.m: %s\n', script_name, ME.message);
    end

    % Clear variables
    clear magnitudes_linear phases phases_processed frequencies
end

% Clear temporary variables
clear file_idx script_name num_files ME

%% frequence vector (rad/s) & number of frequency points

w_k = W(:) * 2 * pi;  % (rad/s)
n = num_freq;

%% Convert cutoff frequency for multiple curves from Hz to rad/s
wc_multi = wc_multi_Hz * 2 * pi;    % rad/s

%% One curve fitting

h_k = squeeze(H_mag(channel, excited_channel, :));
phi_k = squeeze(H_phase(channel, excited_channel, :)) * pi / 180;

sin_phi_k = sin(phi_k);
cos_phi_k = cos(phi_k);

if ENABLE_PARAM_COMPARISON
    % === Compare multiple parameter sets ===
    num_params = size(param_sets_single, 1);

    % Storage for each parameter set
    a1_all = zeros(num_params, 1);
    a2_all = zeros(num_params, 1);
    b_all = zeros(num_params, 1);
    H_fitted_all = cell(num_params, 1);

    fprintf('\n=== One Curve Fitting - Parameter Comparison ===\n');

    % Fit for each parameter set
    for idx = 1:num_params
        p_test = param_sets_single(idx, 1);
        wc_test_Hz = param_sets_single(idx, 2);
        wc_test = wc_test_Hz * 2 * pi;

        % Weighting function
        weight_k = 1 ./ (1 + (w_k.^2 / wc_test^2)).^p_test;

        % Build matrices
        sum_hk2_wk2 = sum(weight_k .* h_k.^2 .* w_k.^2);
        sum_hk2 = sum(weight_k .* h_k.^2);
        sum_hk_sin_wk = sum(weight_k .* h_k .* sin_phi_k .* w_k);
        sum_hk_cos = sum(weight_k .* h_k .* cos_phi_k);
        sum_hk_cos_wk2 = sum(weight_k .* h_k .* cos_phi_k .* w_k.^2);
        sum_weight = sum(weight_k);

        a = [
            sum_hk2_wk2,        0,              sum_hk_sin_wk;
            0,                  sum_hk2,       -sum_hk_cos;
            sum_hk_sin_wk,     -sum_hk_cos,     sum_weight;
        ];

        y = [
            0;
            sum_hk2_wk2;
           -sum_hk_cos_wk2;
        ];

        x = a \ y;

        a1_all(idx) = x(1);
        a2_all(idx) = x(2);
        b_all(idx) = x(3);

        s = 1j * w_k;
        H_fitted_all{idx} = b_all(idx) ./ (s.^2 + a1_all(idx)*s + a2_all(idx));

        fprintf('\n--- Param %d: p=%.1f, wc=%.1f Hz ---\n', idx, p_test, wc_test_Hz);
        fprintf('a1 = %.6f\n', a1_all(idx));
        fprintf('a2 = %.6f\n', a2_all(idx));
        fprintf('b  = %.6f\n', b_all(idx));
    end

else
    % === Single parameter fitting ===
    wc_single = wc_single_Hz * 2 * pi;
    weight_k = 1 ./ (1 + (w_k.^2 / wc_single^2)).^p_single;

    sum_hk2_wk2 = sum(weight_k .* h_k.^2 .* w_k.^2);
    sum_hk2 = sum(weight_k .* h_k.^2);
    sum_hk_sin_wk = sum(weight_k .* h_k .* sin_phi_k .* w_k);
    sum_hk_cos = sum(weight_k .* h_k .* cos_phi_k);
    sum_hk_cos_wk2 = sum(weight_k .* h_k .* cos_phi_k .* w_k.^2);
    sum_weight = sum(weight_k);

    a = [
        sum_hk2_wk2,        0,              sum_hk_sin_wk;
        0,                  sum_hk2,       -sum_hk_cos;
        sum_hk_sin_wk,     -sum_hk_cos,     sum_weight;
    ];

    y = [
        0;
        sum_hk2_wk2;
       -sum_hk_cos_wk2;
    ];

    x = a \ y;

    a1 = x(1);
    a2 = x(2);
    b  = x(3);

    s = 1j * w_k;
    H_fitted = b ./ (s.^2 + a1*s + a2);

    fprintf('\n=== One Curve Fitting ===\n');
    fprintf('Weighting: w(ω) = 1/(1+(ω²/ωc²))^p, ωc=%.2f rad/s (%.2f Hz), p=%.1f\n', ...
            wc_single, wc_single_Hz, p_single);
    fprintf('a1 = %.6f\n', a1);
    fprintf('a2 = %.6f\n', a2);
    fprintf('b  = %.6f\n', b);
end

%% Multiple curve fitting with 2x2 block matrix (PDF Page 3)

% Reshape H_mag from 6x6x19 to 36x19
h_Lk = zeros(36, num_freq);
for i = 1:6
    for j = 1:6
        idx = (i-1)*6 + j;
        h_Lk(idx, :) = squeeze(H_mag(i, j, :));
    end
end

% Reshape H_phase from 6x6x19 to 36x19
phi_Lk = zeros(36, num_freq);
for i = 1:6
    for j = 1:6
        idx = (i-1)*6 + j;
        phi_Lk(idx, :) = squeeze(H_phase(i, j, :)) * pi / 180;
    end
end

sin_phi_Lk = sin(phi_Lk);
cos_phi_Lk = cos(phi_Lk);

% === Weighting function ===
weight_k = 1 ./ (1 + (w_k.^2 / wc_multi^2)).^p_multi;

fprintf('\n=== Multiple Curve Fitting (2x2 Block Matrix, Weighted) ===\n');
fprintf('Weighting: w(ω) = 1/(1+(ω²/ωc²))^p, ωc=%.2f rad/s (%.2f Hz), p=%.1f\n', ...
        wc_multi, wc_multi_Hz, p_multi);

% === Build elements for 2x2 block matrix ===
% a11: Σ_k w(ω_k) (Σ_ℓ h²_ℓk) ω²_k
a11 = 0;
for k = 1:num_freq
    sum_h2 = sum(h_Lk(:, k).^2);  % Σ_ℓ h²_ℓk
    a11 = a11 + weight_k(k) * sum_h2 * w_k(k)^2;
end

% a22: Σ_k w(ω_k) (Σ_ℓ h²_ℓk)
a22 = 0;
for k = 1:num_freq
    sum_h2 = sum(h_Lk(:, k).^2);
    a22 = a22 + weight_k(k) * sum_h2;
end

% v1: [a13, a14, ..., a1(2+m)]', where a1(2+ℓ) = Σ_k w(ω_k) h_ℓk s_ℓk ω_k
v1 = zeros(36, 1);
for L = 1:36
    for k = 1:num_freq
        v1(L) = v1(L) + weight_k(k) * h_Lk(L, k) * sin_phi_Lk(L, k) * w_k(k);
    end
end

% v2: [a23, a24, ..., a2(2+m)]', where a2(2+ℓ) = -Σ_k w(ω_k) h_ℓk c_ℓk
v2 = zeros(36, 1);
for L = 1:36
    for k = 1:num_freq
        v2(L) = v2(L) - weight_k(k) * h_Lk(L, k) * cos_phi_Lk(L, k);
    end
end

% yb: [y3, y4, ..., y(2+m)]', where y(2+ℓ) = -Σ_k w(ω_k) h_ℓk c_ℓk ω²_k
yb = zeros(36, 1);
for L = 1:36
    for k = 1:num_freq
        yb(L) = yb(L) - weight_k(k) * h_Lk(L, k) * cos_phi_Lk(L, k) * w_k(k)^2;
    end
end

% y1, y2
y1 = 0;
y2 = 0;
for k = 1:num_freq
    sum_h2 = sum(h_Lk(:, k).^2);
    y2 = y2 + weight_k(k) * sum_h2 * w_k(k)^2;
end

% === Build 2x2 block matrix (PDF Page 3 highlighted equation) ===
A_2x2 = [
    a11 - (1/n)*v1'*v1,     -(1/n)*v1'*v2;
    -(1/n)*v2'*v1,          a22 - (1/n)*v2'*v2
];

Y_2x2 = [
    y1 - (1/n)*v1'*yb;
    y2 - (1/n)*v2'*yb
];

% Check matrix condition (optional)
if cond(A_2x2) > 1e12
    warning('Matrix may be ill-conditioned (cond=%.2e)', cond(A_2x2));
end

% === Solve for a1, a2 ===
X_2x2 = A_2x2 \ Y_2x2;
A1 = X_2x2(1);
A2 = X_2x2(2);

% === Solve for b vector and B matrix ===
b_vec = (1/n) * (yb - A1*v1 - A2*v2);  % 36x1

B = zeros(6, 6);
for i = 1:6
    for j = 1:6
        L = (i-1)*6 + j;
        b_ij = b_vec(L);
        B(i, j) = b_ij / A2;
    end
end

fprintf('\nTransfer Function Matrix:\n');
fprintf('G(s) = (%.4f/(s^2 + %.4f*s + %.4f)) * B\n', A2, A1, A2);
fprintf('\nB Matrix:\n');
disp(B);



%% Plot Bode for one curve fitting
if PLOT_ONE_CURVE
    figure('Name', 'Bode Plot', 'Position', [100, 100, 900, 720]);

    freq_max = max(W);
    log_ticks = 10.^((0:ceil(log10(freq_max))));
    font_props = {'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2};
    axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};

    freq_smooth = logspace(log10(min(W)), log10(max(W)), 200);
    s_smooth = 1j * 2 * pi * freq_smooth;

    if ENABLE_PARAM_COMPARISON
        % === Parameter Comparison Mode (No normalization) ===

        % Raw measured data (dB)
        h_db_raw = 20*log10(h_k);

        % === Magnitude plot ===
        subplot(2, 1, 1);
        hold on;

        % Plot measured data
        semilogx(W, h_db_raw, 'ko', 'MarkerSize', 12, 'LineWidth', 2, ...
            'MarkerFaceColor', 'w', 'DisplayName', 'Measured');

        % Plot each parameter's model
        colors = {[1 0 0], [0 0.7 0], [0 0 1], [1 0 1]};
        line_styles = {'-', '--', '-.', ':'};

        for idx = 1:num_params
            H_model_smooth = b_all(idx) ./ (s_smooth.^2 + a1_all(idx)*s_smooth + a2_all(idx));
            H_model_db = 20*log10(abs(H_model_smooth));

            semilogx(freq_smooth, H_model_db, ...
                'Color', colors{idx}, 'LineStyle', line_styles{idx}, 'LineWidth', 2.5, ...
                'DisplayName', sprintf('p=%.1f,ωc=%g', param_sets_single(idx,:)));
        end

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
        legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 18);

        set(gca, axis_props{:}, font_props{:});
        y_min = min(h_db_raw) - 5;
        ylim([y_min, 5]);

        ax = gca;
        ax.XAxis.LineWidth = 3;
        ax.YAxis.LineWidth = 3;
        box on;

        % === Phase plot ===
        subplot(2, 1, 2);
        hold on;

        % Plot measured phase
        semilogx(W, phi_k*180/pi, 'ko', 'MarkerSize', 12, 'LineWidth', 2, 'MarkerFaceColor', 'w');

        % Plot each parameter's phase
        for idx = 1:num_params
            H_model_smooth = b_all(idx) ./ (s_smooth.^2 + a1_all(idx)*s_smooth + a2_all(idx));
            H_model_phase = angle(H_model_smooth) * 180/pi;

            semilogx(freq_smooth, H_model_phase, ...
                'Color', colors{idx}, 'LineStyle', line_styles{idx}, 'LineWidth', 2.5);
        end

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);

        set(gca, axis_props{:}, font_props{:});
        ylim([-180, 5]);

        ax = gca;
        ax.XAxis.LineWidth = 3;
        ax.YAxis.LineWidth = 3;
        box on;

        sgtitle(sprintf('H_{%d%d}(s) - Parameter Comparison', channel, excited_channel), ...
            'FontWeight', 'bold', 'FontSize', 24);

    else
        % === Single Parameter Mode (Normalized) ===

        % Normalize by DC gain (H(s=0) = b/a2)
        dc_gain = b / a2;
        h_k_norm = h_k / dc_gain;
        h_db_norm = 20*log10(h_k_norm);

        % === Magnitude plot ===
        subplot(2, 1, 1);
        hold on;
        semilogx(W, h_db_norm, 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, ...
            'MarkerFaceColor', 'none', 'DisplayName', sprintf('Ch%d', channel));

        H_model_smooth = b ./ (s_smooth.^2 + a1*s_smooth + a2);
        H_model_norm = H_model_smooth / dc_gain;
        semilogx(freq_smooth, 20*log10(abs(H_model_norm)), 'k-', 'LineWidth', 3, 'DisplayName', 'Model');

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
        legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 24);

        set(gca, axis_props{:}, font_props{:});
        y_min = min(h_db_norm) - 5;
        ylim([y_min, 5]);

        ax = gca;
        ax.XAxis.LineWidth = 3;
        ax.YAxis.LineWidth = 3;
        box on;

        % === Phase plot ===
        subplot(2, 1, 2);
        hold on;
        semilogx(W, phi_k*180/pi, 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, 'MarkerFaceColor', 'none');

        H_model_smooth = b ./ (s_smooth.^2 + a1*s_smooth + a2);
        semilogx(freq_smooth, angle(H_model_smooth)*180/pi, 'k-', 'LineWidth', 3);

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);

        set(gca, axis_props{:}, font_props{:});
        ylim([-180, 5]);

        ax = gca;
        ax.XAxis.LineWidth = 3;
        ax.YAxis.LineWidth = 3;
        box on;

        sgtitle(sprintf('H_{%d%d}(s), p=%.1f, ωc=%.1f Hz', channel, excited_channel, p_single, wc_single_Hz), ...
            'FontWeight', 'bold', 'FontSize', 24);
    end
end

fprintf('\nFrequency range: %.2f - %.2f Hz\n', min(W), max(W));

%% Plot Bode for multiple curve fitting

if PLOT_MULTI_CURVE
    freq_max = max(W);
    log_ticks = 10.^((0:ceil(log10(freq_max))));
    font_props = {'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2};
    axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};
    channel_colors = ['k','b','g','r','m','c'];

    freq_smooth = logspace(log10(min(W)), log10(max(W)), 200);
    s_smooth = 1j * 2 * pi * freq_smooth;

    for excited_ch = 1:6
        figure('Name', sprintf('P%d Excitation - Weighted (ωc=%.1f Hz, p=%.1f)', excited_ch, wc_multi_Hz, p_multi), ...
               'Position', [100 + (excited_ch-1)*150, 100, 900, 720]);

        % === Magnitude Plot ===
        subplot(2, 1, 1);
        hold on;

        % Plot measured data (normalized by B matrix)
        for ch = 1:6
            h_meas = squeeze(H_mag(ch, excited_ch, :));
            dc_gain_theoretical = B(ch, excited_ch);

            % Normalize by B matrix
            h_meas_norm = h_meas / dc_gain_theoretical;
            h_db_norm = 20*log10(h_meas_norm);

            semilogx(W, h_db_norm, 'o-', 'Color', channel_colors(ch), ...
                'LineWidth', 3.5, 'MarkerSize', 12, 'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('Channel %d', ch));
        end

        % Plot single model curve (normalized)
        H_model = A2 ./ (s_smooth.^2 + A1*s_smooth + A2);
        H_model_norm = H_model / (A2/A2);
        semilogx(freq_smooth, 20*log10(abs(H_model_norm)), 'k-', 'LineWidth', 3, ...
            'DisplayName', 'Model');

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);

        set(gca, axis_props{:}, font_props{:});
        ylim([-10, 10]);

        ax = gca;
        ax.XAxis.LineWidth = 3;
        ax.YAxis.LineWidth = 3;
        box on;

        % === Phase Plot ===
        subplot(2, 1, 2);
        hold on;

        % Plot measured phase
        for ch = 1:6
            phi = squeeze(H_phase(ch, excited_ch, :));
            semilogx(W, phi, 'o-', 'Color', channel_colors(ch), ...
                'LineWidth', 3.5, 'MarkerSize', 12, 'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('Channel %d', ch));
        end

        % Plot single model phase
        H_model = A2 ./ (s_smooth.^2 + A1*s_smooth + A2);
        H_model_phase = angle(H_model) * 180/pi;
        semilogx(freq_smooth, H_model_phase, 'k-', 'LineWidth', 3, ...
            'DisplayName', 'Model');

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
        ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);
        legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);

        set(gca, axis_props{:}, font_props{:});
        ylim([-180, 5]);

        ax = gca;
        ax.XAxis.LineWidth = 3;
        ax.YAxis.LineWidth = 3;
        box on;

        % Title
        sgtitle(sprintf('P%d Excitation - Weighted (ωc=%.1f Hz, p=%.1f)', ...
            excited_ch, wc_multi_Hz, p_multi), 'FontWeight', 'bold', 'FontSize', 24);
    end

    fprintf('\n=== Plots Generated ===\n');
    fprintf('Generated 6 figures (P1-P6) with weighted fitting results\n');
end