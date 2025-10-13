% PI Controller Root Locus Analysis - Multiple Zero Comparison
% H(s) = 1.1592×10^7 / (s^2 + 6.6172×10^3*s + 1.1592×10^7)
% Compare root locus for different PI zero locations

clear all;
close all;
clc;

% ========== Plant Definition ==========
a1 = 6.6172e3;
a2 = 1.1592e7;
H = tf(a2, [1, a1, a2]);

fprintf('Plant: H(s) = %.4e / (s^2 + %.4e*s + %.4e)\n', a2, a1, a2);

% Plant poles
poles_plant = pole(H);
fprintf('\nPlant Poles:\n');
fprintf('  s1 = %.2f + %.2fj\n', real(poles_plant(1)), imag(poles_plant(1)));
fprintf('  s2 = %.2f - %.2fj\n', real(poles_plant(2)), imag(poles_plant(2)));

% ========== PI Controller Zero Locations ==========
% Define multiple zeros to compare
zc_array = [1000, 2000, 2500, 3500];  % You can modify this array

% Optional: Mark closed-loop poles at specific Kp value (set to 0 to disable)
Kp_mark = 4;  % Change to desired Kp value (e.g., 5, 10) to mark poles

fprintf('\n========== Comparing %d PI Zero Locations ==========\n', length(zc_array));
for i = 1:length(zc_array)
    fprintf('  Design %d: zc = %.0f\n', i, zc_array(i));
end

% ========== Create Subplots for Comparison ==========
n_designs = length(zc_array);

% Determine subplot layout (rows x cols)
if n_designs <= 2
    n_rows = 1;
    n_cols = n_designs;
elseif n_designs <= 4
    n_rows = 2;
    n_cols = 2;
elseif n_designs <= 6
    n_rows = 2;
    n_cols = 3;
else
    n_rows = 3;
    n_cols = ceil(n_designs / 3);
end

% Create figure with white background
figure('Position', [50, 50, 400*n_cols, 350*n_rows], 'Color', 'w');

% Plot root locus for each zero design
for idx = 1:n_designs
    zc = zc_array(idx);

    % PI transfer function (Kp=1, varies in root locus)
    C = tf([1, zc], [1, 0]);

    % Open-loop transfer function
    G = C * H;

    poles_open = pole(G);
    zeros_open = zero(G);

    % Create subplot
    subplot(n_rows, n_cols, idx);

    % Plot root locus
    rlocus(G);
    hold on;

    % Mark open-loop poles and zeros
    h1 = plot(real(poles_open), imag(poles_open), 'rx', 'MarkerSize', 12, 'LineWidth', 2.5);
    h2 = plot(real(zeros_open), imag(zeros_open), 'go', 'MarkerSize', 12, 'LineWidth', 2.5);

    % Mark closed-loop poles at specific Kp if requested
    if Kp_mark > 0
        G_cl = feedback(Kp_mark * G, 1);
        poles_cl = pole(G_cl);
        h3 = plot(real(poles_cl), imag(poles_cl), 'bs', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'LineWidth', 2);
    end

    % Zoom to key region
    min_pole = min(real(poles_open));

    % Adaptive x-axis limits
    if zc < abs(min_pole)
        xlim([min_pole*1.2, -zc*0.3]);
    else
        xlim([min_pole*1.2, max(real(poles_open))*0.5]);
    end

    % Y-axis limits
    max_imag = max(abs(imag(poles_open)));
    if max_imag < 1e-6
        ylim_val = abs(min_pole) * 0.3;
    else
        ylim_val = max_imag * 1.3;
    end
    ylim([-ylim_val, ylim_val]);

    % Labels and title
    if Kp_mark > 0
        title(sprintf('Zero z_c = %.0f, Kp = %.1f', zc, Kp_mark), 'FontSize', 12, 'FontWeight', 'bold');
    else
        title(sprintf('Zero z_c = %.0f', zc), 'FontSize', 12, 'FontWeight', 'bold');
    end
    xlabel('Real Axis (rad/s)', 'FontSize', 10);
    ylabel('Imaginary Axis (rad/s)', 'FontSize', 10);

    % Legend
    if Kp_mark > 0
        legend([h1(1), h2(1), h3(1)], {'Poles', 'Zero', sprintf('CL Poles (Kp=%.1f)', Kp_mark)}, 'Location', 'best', 'FontSize', 9);
    else
        legend([h1(1), h2(1)], {'Poles', 'Zero'}, 'Location', 'best', 'FontSize', 9);
    end

    % No grid
    grid off;

    fprintf('\nDesign %d (zc = %.0f):\n', idx, zc);
    fprintf('  Open-loop Poles:\n');
    for i = 1:length(poles_open)
        if abs(imag(poles_open(i))) < 1e-6
            fprintf('    s = %.2f\n', real(poles_open(i)));
        else
            fprintf('    s = %.2f %+.2fj\n', real(poles_open(i)), imag(poles_open(i)));
        end
    end
    fprintf('  Open-loop Zero: s = %.2f\n', zeros_open);
end

% Overall title
sgtitle('PI Controller Root Locus Comparison for Different Zero Locations', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('\n========== Analysis Complete ==========\n');
fprintf('Compare the root locus plots to select the best zero location.\n');
fprintf('\nConsiderations:\n');
fprintf('  - Closed-loop poles should remain in left-half plane (stable)\n');
fprintf('  - Faster decay (more negative real part) → faster response\n');
fprintf('  - Lower imaginary part → less oscillation\n');

if Kp_mark > 0
    fprintf('\nClosed-loop poles marked at Kp = %.1f\n', Kp_mark);
end

fprintf('\n========== How to Choose Best Design ==========\n');
fprintf('1. Compare Y-axis ranges: Smaller range = less oscillation\n');
fprintf('2. Look for root locus staying close to real axis\n');
fprintf('3. Avoid designs where locus goes far into complex plane\n');
fprintf('4. From your plots:\n');
fprintf('   - zc=1000: Root locus near origin, slower response\n');
fprintf('   - zc=2000-2500: Balanced design (RECOMMENDED)\n');
fprintf('   - zc=3500: Large oscillations (high imaginary axis range)\n');
