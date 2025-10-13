% PI Controller Root Locus Analysis
% H(s) = 1.4848×10^7 / (s^2 + 8.1877×10^3*s + 1.4848×10^7)
% PI Zero: zc = 2500

clear all;
close all;
clc;

% ========== Plant Definition ==========
a1 = 8.1877e3;
a2 = 1.4848e7;
H = tf(a2, [1, a1, a2]);

fprintf('Plant: H(s) = %.4e / (s^2 + %.4e*s + %.4e)\n', a2, a1, a2);

% Plant poles
poles_plant = pole(H);
fprintf('\nPlant Poles:\n');
fprintf('  s1 = %.2f + %.2fj\n', real(poles_plant(1)), imag(poles_plant(1)));
fprintf('  s2 = %.2f - %.2fj\n', real(poles_plant(2)), imag(poles_plant(2)));

% ========== PI Controller ==========
zc = 2500;  % PI zero location
fprintf('\nPI Controller:\n');
fprintf('  C(s) = Kp * (s + %.0f) / s\n', zc);
fprintf('  Zero at: s = -%.0f\n', zc);

% PI transfer function (Kp=1, varies in root locus)
C = tf([1, zc], [1, 0]);

% Open-loop transfer function
G = C * H;

fprintf('\nOpen-loop System: G(s) = C(s) * H(s)\n');
poles_open = pole(G);
zeros_open = zero(G);

fprintf('Open-loop Poles (Root locus starting points, Kp=0):\n');
for i = 1:length(poles_open)
    if imag(poles_open(i)) ~= 0
        fprintf('  s = %.2f %+.2fj\n', real(poles_open(i)), imag(poles_open(i)));
    else
        fprintf('  s = %.2f\n', real(poles_open(i)));
    end
end

fprintf('\nOpen-loop Zeros (Root locus ending point):\n');
fprintf('  s = %.2f\n', zeros_open);

% ========== Root Locus Plot ==========
figure('Position', [100, 100, 800, 600], 'Color', 'w');

rlocus(G);
hold on;

% Mark open-loop poles and zeros
h1 = plot(real(poles_open), imag(poles_open), 'rx', 'MarkerSize', 14, 'LineWidth', 3);
h2 = plot(real(zeros_open), imag(zeros_open), 'go', 'MarkerSize', 14, 'LineWidth', 3);

% Calculate and mark closed-loop poles at Kp=8
Kp_test = 8;
G_test = feedback(Kp_test * G, 1);
poles_cl = pole(G_test);
h3 = plot(real(poles_cl), imag(poles_cl), 'bs', 'MarkerSize', 12, 'MarkerFaceColor', 'b', 'LineWidth', 2);

% Annotate closed-loop pole locations
for i = 1:length(poles_cl)
    if abs(imag(poles_cl(i))) < 10
        text(real(poles_cl(i))+100, imag(poles_cl(i))+100, sprintf('s=%.1f', real(poles_cl(i))), 'FontSize', 9, 'Color', 'b');
    else
        text(real(poles_cl(i))+100, imag(poles_cl(i))+100, sprintf('s=%.1f%+.1fj', real(poles_cl(i)), imag(poles_cl(i))), 'FontSize', 9, 'Color', 'b');
    end
end

% Zoom to key region
min_pole = min(real(poles_open));
max_pole = max(real(poles_open));
xlim([min_pole*1.2, -zc*0.3]);

% Check if poles have imaginary parts
max_imag = max(abs(imag(poles_open)));
if max_imag < 1e-6
    % If poles are real, use fixed y-axis range
    ylim_val = abs(min_pole) * 0.3;
else
    ylim_val = max_imag * 1.3;
end
ylim([-ylim_val, ylim_val]);

% Labels and title
title(sprintf('Root Locus of PI Controller (Zero z_c = %.0f, Kp = %.0f)', zc, Kp_test), 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Real Axis', 'FontSize', 12);
ylabel('Imaginary Axis', 'FontSize', 12);

% Simplified legend to avoid MATLAB internal errors
legend([h1(1), h2(1), h3(1)], {'Open-loop Poles', 'Open-loop Zero', sprintf('Closed-loop Poles (Kp=%.0f)', Kp_test)}, 'Location', 'best');

% No grid
grid off;
