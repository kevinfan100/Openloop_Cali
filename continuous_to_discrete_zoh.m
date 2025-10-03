% 連續轉移函數轉換為離散轉移函數 (使用 ZOH)
clear; clc;

% 定義連續轉移函數 H(s)
num = 1.4848e7;
den = [1, 8.1877e3, 1.4848e7];
H_s = tf(num, den);

% 顯示連續轉移函數
disp('連續轉移函數 H(s):');
H_s

% 設定取樣時間 (請根據需求調整)
Ts = 1e-5;  % 取樣時間 (秒)

% 使用 ZOH 方法轉換為離散轉移函數
H_z = c2d(H_s, Ts, 'zoh');

% 顯示離散轉移函數
disp(['離散轉移函數 H(z) (Ts = ', num2str(Ts), ' s):']);
H_z

% 顯示離散轉移函數的分子和分母係數
[num_z, den_z] = tfdata(H_z, 'v');
disp('分子係數:');
disp(num_z);
disp('分母係數:');
disp(den_z);
