% Z Domain 根軌跡分析
% H(z^-1) = z^-1 * [5.6695×10^-4 × (1 + 0.97822z^-1)] / [1 - 1.934848z^-1 + 0.935970z^-2]

clear all;
close all;
clc;

% 定義取樣時間 (假設為 0.01 秒，可依實際情況調整)
Ts = 0.01;

% 方法 1: 使用 z^-1 形式直接定義
% 先將 z^-1 轉換為 z 的形式
% H(z^-1) = z^-1 * [5.6695e-4 * (1 + 0.97822z^-1)] / [1 - 1.934848z^-1 + 0.935970z^-2]
% 
% 分子乘以 z^-1: z^-1 * (5.6695e-4 + 5.6695e-4*0.97822*z^-1)
%                = 5.6695e-4*z^-1 + 5.5449e-4*z^-2
% 
% 轉換為 z 的正次方 (分子分母同乘 z^2):
% 分子: 5.6695e-4*z + 5.5449e-4
% 分母: z^2 - 1.934848*z + 0.935970

% 定義係數
num = [5.6695e-4, 5.5449e-4];  % 分子係數 [z^1, z^0]
den = [1, -1.934848, 0.935970]; % 分母係數 [z^2, z^1, z^0]

% 建立離散傳遞函數
H = tf(num, den, Ts);

% 顯示傳遞函數
disp('離散傳遞函數:');
disp(H);

% 計算極點和零點
poles = pole(H);
zeros = zero(H);

disp('極點 (Poles):');
disp(poles);
disp('零點 (Zeros):');
disp(zeros);

% 繪製根軌跡
figure('Position', [100, 100, 1200, 500]);

% 子圖 1: 根軌跡
subplot(1, 2, 1);
rlocus(H);
grid on;
hold on;

% 繪製單位圓 (穩定邊界)
theta = linspace(0, 2*pi, 100);
plot(cos(theta), sin(theta), 'r--', 'LineWidth', 2);

% 標記極點和零點
plot(real(poles), imag(poles), 'rx', 'MarkerSize', 12, 'LineWidth', 2);
plot(real(zeros), imag(zeros), 'go', 'MarkerSize', 12, 'LineWidth', 2);

% 添加 zgrid (等阻尼比和等自然頻率線)
zgrid;

title('Z Domain 根軌跡圖', 'FontSize', 14);
xlabel('Real Axis', 'FontSize', 12);
ylabel('Imaginary Axis', 'FontSize', 12);
legend('Root Locus', '單位圓 (穩定邊界)', 'Poles', 'Zeros', 'Location', 'best');
axis equal;
xlim([-1.5, 1.5]);
ylim([-1.5, 1.5]);

% 子圖 2: 極點-零點圖
subplot(1, 2, 2);
pzmap(H);
grid on;
hold on;

% 繪製單位圓
plot(cos(theta), sin(theta), 'r--', 'LineWidth', 2);
zgrid;

title('極點-零點圖', 'FontSize', 14);
xlabel('Real Axis', 'FontSize', 12);
ylabel('Imaginary Axis', 'FontSize', 12);
legend('Poles', 'Zeros', '單位圓', 'Location', 'best');
axis equal;
xlim([-1.5, 1.5]);
ylim([-1.5, 1.5]);

% 分析穩定性
disp(' ');
disp('穩定性分析:');
pole_magnitudes = abs(poles);
disp(['極點幅值: ', num2str(pole_magnitudes')]);

if all(pole_magnitudes < 1)
    disp('系統穩定 (所有極點都在單位圓內)');
else
    disp('系統不穩定 (有極點在單位圓外或單位圓上)');
end

% 計算一些特定增益下的閉迴路極點
K_values = [0.1, 0.5, 1, 2, 5];
disp(' ');
disp('不同增益 K 下的閉迴路極點:');
for K = K_values
    sys_cl = feedback(K*H, 1);
    cl_poles = pole(sys_cl);
    fprintf('K = %.1f: poles = [%.4f%+.4fi, %.4f%+.4fi]\n', ...
            K, real(cl_poles(1)), imag(cl_poles(1)), ...
            real(cl_poles(2)), imag(cl_poles(2)));
end