% W: 1x19 frequency vector (Hz)
% H_mag: 6x6x19 linear magnitude matrix
% H_phase: 6x6x19 phase matrix

clear; clc;

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

%% frequence vector (rad/s) & number of frequency points

w_k = W(:) * 2 * pi;  % (rad/s)
n = num_freq;

%% One curve fitting

% Plot control switch
PLOT_ONE_CURVE = false;  % Set to false to skip plotting one curve fitting Bode plot

excited_channel = 5;  % Input channel (excitation applied at this channel)
channel = 5;          % Output channel (response measured at this channel)

h_k = squeeze(H_mag(channel, excited_channel, :));
phi_k = squeeze(H_phase(channel, excited_channel, :)) * pi / 180;

sin_phi_k = sin(phi_k);
cos_phi_k = cos(phi_k);

sum_hk2_wk2 = sum(h_k.^2 .* w_k.^2);
sum_hk2 = sum(h_k.^2);
sum_hk_sin_wk = sum(h_k .* sin_phi_k .* w_k);
sum_hk_cos = sum(h_k .* cos_phi_k);
sum_hk_cos_wk2 = sum(h_k .* cos_phi_k .* w_k.^2);

a = [
    sum_hk2_wk2,        0,                  sum_hk_sin_wk;
    0,                  sum_hk2,           -sum_hk_cos;
    sum_hk_sin_wk,      -sum_hk_cos,        n;
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

fprintf('\n=== One curve fitting Results ===\n');
fprintf('a1 = %.6f\n', a1);
fprintf('a2 = %.6f\n', a2);
fprintf('b  = %.6f\n', b);

s = 1j * w_k;  % s = jω
H_fitted = b ./ (s.^2 + a1*s + a2);

%% Multiple curve fitting

% Plot control switch
PLOT_MULTI_CURVE = true;  % Set to false to skip plotting six Bode plots (P1~P6)

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
A = zeros(38, 38);
Y = zeros(38, 1);
B = zeros(6, 6);

% A matrix
for L = 1:36
    for k = 1:num_freq
        A(1, 1) = A(1, 1) + h_Lk(L, k)^2 * w_k(k)^2;
    end
end

A(1, 2) = 0;

for L = 1:36
        A(1, 2+L) = sum(h_Lk(L, :) .* sin_phi_Lk(L, :) .* w_k');
end

A(2, 1) = 0;

for L = 1:36
    for k = 1:num_freq
        A(2, 2) = A(2, 2) + h_Lk(L, k)^2;
    end
end

for L = 1:36
    A(2, 2+L) = -sum(h_Lk(L, :) .* cos_phi_Lk(L, :));
end

for L = 1:36
    A(2+L, 1) = A(1, 2+L);

    A(2+L, 2) = A(2, 2+L);

    A(2+L, 2+L) = num_freq;

end

% Y vector
Y(1) = 0;

for k = 1:num_freq
    for L = 1:36
        Y(2) = Y(2) + h_Lk(L, k)^2 * w_k(k)^2;
    end
end

for L = 1:36
    for k = 1:num_freq
        Y(2+L) = Y(2+L) - h_Lk(L, k) * cos_phi_Lk(L, k) * w_k(k)^2;
    end
end

X = A \ Y;

A1 = X(1);
A2 = X(2);


for i = 1:6
    for j = 1:6
        L = (i-1)*6 + j;  
        b_ij = X(2 + L);
        B(i, j) = b_ij / A2;
    end
end

fprintf('\n=== Multiple Curve Fitting Results ===\n');
% Transfer Function Matrix: G(s) = (A2/(s^2 + A1*s + A2)) * B
fprintf('\nTransfer Function Matrix:\n');
fprintf('G(s) = (%.4f/(s^2 + %.4f*s + %.4f)) * B\n', A2, A1, A2);
disp(B);



%% Plot Bode for one curve fitting
if PLOT_ONE_CURVE
    figure('Name', 'Bode Plot', 'Position', [100, 100, 900, 720]);

freq_max = max(W);
log_ticks = 10.^((0:ceil(log10(freq_max))));
font_props = {'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2};
axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};

% Magnitude plot
subplot(2, 1, 1);
hold on;
semilogx(W, 20*log10(h_k), 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, ...
    'MarkerFaceColor', 'none', 'DisplayName', sprintf('Ch%d', channel));
semilogx(W, 20*log10(abs(H_fitted)), 'k-', 'LineWidth', 3, 'DisplayName', 'Model');

xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 24);

set(gca, axis_props{:}, font_props{:});
ylim([min(20*log10(h_k))-5, max(20*log10(h_k))+5]);

ax = gca;
ax.XAxis.LineWidth = 3;
ax.YAxis.LineWidth = 3;
box on;

% Phase plot
subplot(2, 1, 2);
hold on;
semilogx(W, phi_k*180/pi, 'o-b', 'LineWidth', 3.5, 'MarkerSize', 12, 'MarkerFaceColor', 'none');
semilogx(W, angle(H_fitted)*180/pi, 'k-', 'LineWidth', 3);

xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);

set(gca, axis_props{:}, font_props{:});
y_min = min([phi_k*180/pi; angle(H_fitted)*180/pi]);
ylim([max(y_min-10, -180), 5]);  % Max at 5 deg

ax = gca;
ax.XAxis.LineWidth = 3;
ax.YAxis.LineWidth = 3;

box on;

    % Title and output
    sgtitle(sprintf('H_{%.0f%.0f}(s) = %.4f / (s^2 + %.4f*s + %.4f)', ...
        channel, excited_channel, b, a1, a2), 'FontWeight', 'bold', 'FontSize', 24);
end 

fprintf('\nFrequency range: %.2f - %.2f Hz\n', min(W), max(W));

%% Plot Bode for multiple curve fitting

if PLOT_MULTI_CURVE
    freq_max = max(W);
    log_ticks = 10.^((0:ceil(log10(freq_max))));
    font_props = {'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2};
    axis_props = {'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks};
    channel_colors = ['k','b','g','r','m','c'];

    [~, min_freq_idx] = min(W);
    freq_smooth = logspace(log10(min(W)), log10(max(W)), 200);
    s_smooth = 1j * 2 * pi * freq_smooth;

    % 計算模型的DC增益矩陣 (6x6)
    DC_gain_model = B / A2;

    for excited_ch = 1:6
    figure('Name', sprintf('P%d Excitation - Normalized by B matrix', excited_ch), ...
           'Position', [100 + (excited_ch-1)*150, 100, 900, 720]);

    % === Magnitude Plot ===
    subplot(2, 1, 1);
    hold on;

    % Plot measured data (normalized by B matrix)
    for ch = 1:6
        h_meas = squeeze(H_mag(ch, excited_ch, :));

        dc_gain_theoretical = B(ch, excited_ch);

        h_meas_norm = h_meas / dc_gain_theoretical;
        h_db_norm = 20*log10(h_meas_norm);

        semilogx(W, h_db_norm, 'o-', 'Color', channel_colors(ch), ...
            'LineWidth', 3.5, 'MarkerSize', 12, 'MarkerFaceColor', 'none', ...
            'DisplayName', sprintf('Channel %d', ch));
    end

    % Plot single model curve (pure dynamics, should be 0dB after normalization)
    H_model = A2 ./ (s_smooth.^2 + A1*s_smooth + A2);
    H_model_norm = H_model / (A2/A2);  % 正規化後應該是1 (0dB)
    semilogx(freq_smooth, 20*log10(abs(H_model_norm)), 'k-', 'LineWidth', 3, ...
        'DisplayName', 'Model');

    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);

    set(gca, axis_props{:}, font_props{:});
    ylim([-10, 10]);  % 正規化後的合理範圍

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

    % Plot single model phase (pure dynamics)
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
        sgtitle(sprintf('P%d Excitation - Normalized by B matrix', ...
            excited_ch), 'FontWeight', 'bold', 'FontSize', 24);
    end
end