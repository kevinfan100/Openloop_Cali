% W: 1x19 frequency vector (Hz)
% H_mag: 6x6x19 linear magnitude matrix
% H_phase: 6x6x19 phase matrix
%
% This version compares original vs phase-offset-removed curve fitting

clear; clc;

%% Control Switches
PLOT_COMPARISON = true;  % true: show comparison plots, false: terminal output only

%% Data Loading
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
clear file_idx script_name num_files num_channels ME

%% Frequency vector (rad/s) & number of frequency points

w_k = W(:) * 2 * pi;  % (rad/s)
n = num_freq;

%% Reshape data to 36x19 format

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

%% Phase Offset Removal - NEW FEATURE

phi_Lk_offset_removed = zeros(36, num_freq);
[~, min_freq_idx] = min(w_k);

fprintf('\n=== Phase Offset Removal ===\n');
fprintf('Reference frequency: %.2f Hz\n', W(min_freq_idx));

for L = 1:36
    % Extract phase at lowest frequency
    phase_offset = phi_Lk(L, min_freq_idx);

    % Subtract offset from all frequency points
    phi_Lk_offset_removed(L, :) = phi_Lk(L, :) - phase_offset;

    % Display offset removal info for selected transfer functions
    if mod(L-1, 7) == 0  % Display for diagonal elements
        [ch_out, ch_in] = ind2sub([6, 6], L);
        fprintf('  H_%d%d: Phase offset = %.2f deg (removed)\n', ...
            ch_out, ch_in, phase_offset * 180/pi);
    end
end

%% Multiple Curve Fitting - ORIGINAL DATA

fprintf('\n=== Fitting with ORIGINAL Phase Data ===\n');

sin_phi_Lk_orig = sin(phi_Lk);
cos_phi_Lk_orig = cos(phi_Lk);

A_orig = zeros(38, 38);
Y_orig = zeros(38, 1);

% Build A matrix
for L = 1:36
    for k = 1:num_freq
        A_orig(1, 1) = A_orig(1, 1) + h_Lk(L, k)^2 * w_k(k)^2;
    end
end

A_orig(1, 2) = 0;

for L = 1:36
    A_orig(1, 2+L) = sum(h_Lk(L, :) .* sin_phi_Lk_orig(L, :) .* w_k');
end

A_orig(2, 1) = 0;

for L = 1:36
    for k = 1:num_freq
        A_orig(2, 2) = A_orig(2, 2) + h_Lk(L, k)^2;
    end
end

for L = 1:36
    A_orig(2, 2+L) = -sum(h_Lk(L, :) .* cos_phi_Lk_orig(L, :));
end

for L = 1:36
    A_orig(2+L, 1) = A_orig(1, 2+L);
    A_orig(2+L, 2) = A_orig(2, 2+L);
    A_orig(2+L, 2+L) = num_freq;
end

% Build Y vector
Y_orig(1) = 0;

for k = 1:num_freq
    for L = 1:36
        Y_orig(2) = Y_orig(2) + h_Lk(L, k)^2 * w_k(k)^2;
    end
end

for L = 1:36
    for k = 1:num_freq
        Y_orig(2+L) = Y_orig(2+L) - h_Lk(L, k) * cos_phi_Lk_orig(L, k) * w_k(k)^2;
    end
end

% Solve
X_orig = A_orig \ Y_orig;

A1_orig = X_orig(1);
A2_orig = X_orig(2);

B_orig = zeros(6, 6);
for i = 1:6
    for j = 1:6
        L = (i-1)*6 + j;
        b_ij = X_orig(2 + L);
        B_orig(i, j) = b_ij / A2_orig;
    end
end

fprintf('Transfer Function: G(s) = (%.4f/(s^2 + %.4f*s + %.4f)) * B\n', ...
    A2_orig, A1_orig, A2_orig);
fprintf('B matrix (Original):\n');
disp(B_orig);

%% Multiple Curve Fitting - PHASE-OFFSET-REMOVED DATA

fprintf('\n=== Fitting with Phase-Offset-Removed Data ===\n');

sin_phi_Lk_norm = sin(phi_Lk_offset_removed);
cos_phi_Lk_norm = cos(phi_Lk_offset_removed);

A_norm = zeros(38, 38);
Y_norm = zeros(38, 1);

% Build A matrix
for L = 1:36
    for k = 1:num_freq
        A_norm(1, 1) = A_norm(1, 1) + h_Lk(L, k)^2 * w_k(k)^2;
    end
end

A_norm(1, 2) = 0;

for L = 1:36
    A_norm(1, 2+L) = sum(h_Lk(L, :) .* sin_phi_Lk_norm(L, :) .* w_k');
end

A_norm(2, 1) = 0;

for L = 1:36
    for k = 1:num_freq
        A_norm(2, 2) = A_norm(2, 2) + h_Lk(L, k)^2;
    end
end

for L = 1:36
    A_norm(2, 2+L) = -sum(h_Lk(L, :) .* cos_phi_Lk_norm(L, :));
end

for L = 1:36
    A_norm(2+L, 1) = A_norm(1, 2+L);
    A_norm(2+L, 2) = A_norm(2, 2+L);
    A_norm(2+L, 2+L) = num_freq;
end

% Build Y vector
Y_norm(1) = 0;

for k = 1:num_freq
    for L = 1:36
        Y_norm(2) = Y_norm(2) + h_Lk(L, k)^2 * w_k(k)^2;
    end
end

for L = 1:36
    for k = 1:num_freq
        Y_norm(2+L) = Y_norm(2+L) - h_Lk(L, k) * cos_phi_Lk_norm(L, k) * w_k(k)^2;
    end
end

% Solve
X_norm = A_norm \ Y_norm;

A1_norm = X_norm(1);
A2_norm = X_norm(2);

B_norm = zeros(6, 6);
for i = 1:6
    for j = 1:6
        L = (i-1)*6 + j;
        b_ij = X_norm(2 + L);
        B_norm(i, j) = b_ij / A2_norm;
    end
end

fprintf('Transfer Function: G(s) = (%.4f/(s^2 + %.4f*s + %.4f)) * B\n', ...
    A2_norm, A1_norm, A2_norm);
fprintf('B matrix (Normalized):\n');
disp(B_norm);

%% Comparison Results - Terminal Output

fprintf('\n========================================\n');
fprintf('       COMPARISON RESULTS\n');
fprintf('========================================\n\n');

fprintf('--- Transfer Function Parameters ---\n');
fprintf('Parameter     Original      Offset-Removed    Difference    Percent Change\n');
fprintf('--------------------------------------------------------------------------------\n');
fprintf('A1            %.6f      %.6f          %.6f      %.2f%%\n', ...
    A1_orig, A1_norm, A1_norm - A1_orig, ...
    (A1_norm - A1_orig) / A1_orig * 100);
fprintf('A2            %.6f      %.6f          %.6f      %.2f%%\n', ...
    A2_orig, A2_norm, A2_norm - A2_orig, ...
    (A2_norm - A2_orig) / A2_orig * 100);

fprintf('\n--- B Matrix Comparison ---\n');
fprintf('Maximum absolute difference: %.6f\n', max(abs(B_norm(:) - B_orig(:))));
fprintf('Mean absolute difference: %.6f\n', mean(abs(B_norm(:) - B_orig(:))));
fprintf('RMS difference: %.6f\n', sqrt(mean((B_norm(:) - B_orig(:)).^2)));

fprintf('\nB Matrix Difference (Offset-Removed - Original):\n');
disp(B_norm - B_orig);

fprintf('\nB Matrix Percent Change:\n');
B_percent_change = (B_norm - B_orig) ./ B_orig * 100;
for i = 1:6
    fprintf('  ');
    for j = 1:6
        fprintf('%8.2f%% ', B_percent_change(i, j));
    end
    fprintf('\n');
end

%% Plot Comparison - Side-by-side Bode plots

if PLOT_COMPARISON
    fprintf('\n=== Generating Comparison Plots ===\n');

    freq_max = max(W);
    log_ticks = 10.^((0:ceil(log10(freq_max))));
    font_props = {'FontWeight', 'bold', 'FontSize', 18, 'LineWidth', 2};
    axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};
    channel_colors = ['k','b','g','r','m','c'];

    freq_smooth = logspace(log10(min(W)), log10(max(W)), 200);
    s_smooth = 1j * 2 * pi * freq_smooth;

    for excited_ch = 1:6
        figure('Name', sprintf('P%d Comparison: Original vs Phase-Offset-Removed', excited_ch), ...
               'Position', [50 + (excited_ch-1)*80, 50, 1800, 900]);

        %% LEFT SIDE - ORIGINAL DATA

        % Magnitude - Original
        subplot(2, 2, 1);
        hold on;

        for ch = 1:6
            h_meas = squeeze(H_mag(ch, excited_ch, :));
            dc_gain = B_orig(ch, excited_ch);
            h_meas_norm = h_meas / dc_gain;
            h_db_norm = 20*log10(h_meas_norm);

            semilogx(W, h_db_norm, 'o-', 'Color', channel_colors(ch), ...
                'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('Ch%d', ch));
        end

        H_model_orig = A2_orig ./ (s_smooth.^2 + A1_orig*s_smooth + A2_orig);
        semilogx(freq_smooth, 20*log10(abs(H_model_orig)), 'k-', 'LineWidth', 2.5, ...
            'DisplayName', 'Model');

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 28);
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 28);
        title('Original Data', 'FontSize', 22, 'FontWeight', 'bold');

        set(gca, axis_props{:}, font_props{:});
        ylim([-10, 10]);
        grid off;
        ax = gca;
        ax.XAxis.LineWidth = 2;
        ax.YAxis.LineWidth = 2;
        box on;

        % Phase - Original
        subplot(2, 2, 3);
        hold on;

        for ch = 1:6
            phi = squeeze(H_phase(ch, excited_ch, :));
            semilogx(W, phi, 'o-', 'Color', channel_colors(ch), ...
                'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('Ch%d', ch));
        end

        H_model_phase_orig = angle(H_model_orig) * 180/pi;
        semilogx(freq_smooth, H_model_phase_orig, 'k-', 'LineWidth', 2.5, ...
            'DisplayName', 'Model');

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 28);
        ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 28);
        legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 16);

        set(gca, axis_props{:}, font_props{:});
        ylim([-180, 5]);
        grid off;
        ax = gca;
        ax.XAxis.LineWidth = 2;
        ax.YAxis.LineWidth = 2;
        box on;

        %% RIGHT SIDE - PHASE-OFFSET-REMOVED DATA

        % Magnitude - Normalized
        subplot(2, 2, 2);
        hold on;

        for ch = 1:6
            h_meas = squeeze(H_mag(ch, excited_ch, :));
            dc_gain = B_norm(ch, excited_ch);
            h_meas_norm = h_meas / dc_gain;
            h_db_norm = 20*log10(h_meas_norm);

            semilogx(W, h_db_norm, 'o-', 'Color', channel_colors(ch), ...
                'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('Ch%d', ch));
        end

        H_model_norm = A2_norm ./ (s_smooth.^2 + A1_norm*s_smooth + A2_norm);
        semilogx(freq_smooth, 20*log10(abs(H_model_norm)), 'k-', 'LineWidth', 2.5, ...
            'DisplayName', 'Model');

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 28);
        ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 28);
        title('Phase-Offset-Removed Data', 'FontSize', 22, 'FontWeight', 'bold');

        set(gca, axis_props{:}, font_props{:});
        ylim([-10, 10]);
        grid off;
        ax = gca;
        ax.XAxis.LineWidth = 2;
        ax.YAxis.LineWidth = 2;
        box on;

        % Phase - Normalized (need to reconstruct normalized phase for plotting)
        subplot(2, 2, 4);
        hold on;

        for ch = 1:6
            % Get phase offset that was removed
            L = (ch-1)*6 + excited_ch;
            phase_offset = phi_Lk(L, min_freq_idx) * 180/pi;

            % Original phase minus offset
            phi = squeeze(H_phase(ch, excited_ch, :)) - phase_offset;
            semilogx(W, phi, 'o-', 'Color', channel_colors(ch), ...
                'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'none', ...
                'DisplayName', sprintf('Ch%d', ch));
        end

        H_model_phase_norm = angle(H_model_norm) * 180/pi;
        semilogx(freq_smooth, H_model_phase_norm, 'k-', 'LineWidth', 2.5, ...
            'DisplayName', 'Model');

        xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 28);
        ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 28);
        legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 16);

        set(gca, axis_props{:}, font_props{:});
        ylim([-180, 5]);
        grid off;
        ax = gca;
        ax.XAxis.LineWidth = 2;
        ax.YAxis.LineWidth = 2;
        box on;

        % Overall title
        sgtitle(sprintf('P%d Excitation: Original vs Phase-Offset-Removed Fitting', excited_ch), ...
            'FontWeight', 'bold', 'FontSize', 26);
    end

    fprintf('Plots generated for all 6 excitation channels\n');
else
    fprintf('\nPlot generation skipped (PLOT_COMPARISON = false)\n');
end

fprintf('\n=== Analysis Complete ===\n');
fprintf('Frequency range: %.2f - %.2f Hz\n', min(W), max(W));