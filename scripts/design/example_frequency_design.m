% example_frequency_design.m
% 完整的頻域 PI 控制器設計範例
%
% 工作流程：
%   1. 分析 Plant 頻率響應
%   2. 基於頻域規格設計 PI 控制器
%   3. 在 Simulink 中驗證性能
%   4. 比較設計結果與時域性能
%
% Author: Claude Code
% Date: 2025-10-09

clear; clc; close all;

fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║       Frequency-Domain PI Controller Design Example        ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

%% ========================================
%  Step 1: 分析 Plant 特性
%  ========================================
fprintf('▶ Step 1: Analyzing Plant Frequency Response\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 選擇要分析的通道（這裡使用對角通道 1,1）
ch_out = 1;
ch_in = 1;

% 執行 Plant 分析
plant_info = analyze_plant_frequency(ch_out, ch_in);

fprintf('\nPress Enter to continue to design step...\n');
pause;

%% ========================================
%  Step 2: 頻域規格設定
%  ========================================
fprintf('\n▶ Step 2: Setting Design Specifications\n');
fprintf('───────────────────────────────────────────────────────────\n');

% === 設計參數選擇 ===
%
% 方案 1: 保守設計（穩定優先）
%   wc_desired = plant_info.frequency.w_nominal / 2;  % 較低的截止頻率
%   PM_desired = 70;                                   % 高相位裕度

% 方案 2: 標稱設計（平衡性能）
wc_desired = plant_info.frequency.w_nominal;          % 等於系統自然頻率
PM_desired = 60;                                       % 中等相位裕度

% 方案 3: 激進設計（速度優先）
%   wc_desired = plant_info.frequency.w_nominal * 1.5;
%   PM_desired = 45;

fprintf('\nDesign Specifications:\n');
fprintf('  Target Crossover Frequency: %.2f rad/s  (%.2f Hz)\n', ...
        wc_desired, wc_desired/(2*pi));
fprintf('  Target Phase Margin:        %.1f deg\n', PM_desired);
fprintf('\n');

% 預期性能估計
if PM_desired >= 70
    overshoot_estimate = 5;
elseif PM_desired >= 60
    overshoot_estimate = 10;
elseif PM_desired >= 45
    overshoot_estimate = 20;
else
    overshoot_estimate = 30;
end

% 估計穩定時間（2% 誤差帶）
% 對於二階系統：ts ≈ 4/(ζ·ωn)，其中 ζ 與 PM 相關
zeta_estimate = PM_desired / 100;  % 粗略估計
settling_time_estimate = 4 / (zeta_estimate * wc_desired);

fprintf('Estimated Closed-Loop Performance:\n');
fprintf('  Overshoot:      ~%.0f%%\n', overshoot_estimate);
fprintf('  Settling time:  ~%.4f s\n', settling_time_estimate);
fprintf('\n');

%% ========================================
%  Step 3: 設計 PI 控制器
%  ========================================
fprintf('▶ Step 3: Designing PI Controller\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 設計選項
design_options.show_plot = true;
design_options.verbose = true;
design_options.method = 'analytical';  % 'analytical' 或 'iterative'

% 執行設計
[Kp_single, Ki_single, design_info] = design_PI_frequency(plant_info, wc_desired, PM_desired, design_options);

fprintf('\nPress Enter to continue to simulation...\n');
pause;

%% ========================================
%  Step 4: 構建完整的 6×6 控制器參數
%  ========================================
fprintf('\n▶ Step 4: Building 6×6 Controller Parameters\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 策略 1: 所有通道使用相同參數（解耦設計）
Kp = diag([Kp_single, Kp_single, Kp_single, Kp_single, Kp_single, Kp_single]);
Ki = diag([Ki_single, Ki_single, Ki_single, Ki_single, Ki_single, Ki_single]);
Ts_controller = 1e-5;  % 採樣時間 10 μs

fprintf('Controller Parameters (Diagonal Design):\n');
fprintf('  Kp = diag([%.4e, %.4e, ..., %.4e])\n', Kp_single, Kp_single, Kp_single);
fprintf('  Ki = diag([%.4e, %.4e, ..., %.4e])\n', Ki_single, Ki_single, Ki_single);
fprintf('  Ts = %.0e s\n', Ts_controller);
fprintf('\n');

% 注意：如果不同通道的 Plant 特性差異很大，應該分別設計
% 可以從 one_curve_36_results.mat 讀取每個通道的參數，分別設計

%% ========================================
%  Step 5: Simulink 模擬驗證
%  ========================================
fprintf('▶ Step 5: Simulink Simulation\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 準備參數
params.Kp = Kp;
params.Ki = Ki;
params.Ts_controller = Ts_controller;

% 整合控制器
addpath('scripts');
setup_controller('PI_controller', params);

% 設定參考訊號
Vd_ref = [1; 1; 1; 1; 1; 1];

% 模擬時間（根據預期穩定時間設定）
sim_time = max(0.01, settling_time_estimate * 5);  % 至少 5 倍穩定時間

fprintf('Running simulation (%.3f s)...\n', sim_time);

% 執行模擬
solver_options.Solver = 'ode45';
solver_options.MaxStep = 1e-6;
solver_options.RelTol = 1e-3;

sim_results = run_simulation('Control_System_Framework', sim_time, solver_options);

%% ========================================
%  Step 6: 性能分析與比較
%  ========================================
fprintf('\n▶ Step 6: Performance Analysis\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 分析結果
plot_options.show_plot = true;
plot_options.save_fig = true;
plot_options.fig_name = 'results/PI_frequency_design.fig';

performance = analyze_results(sim_results, Vd_ref, plot_options);

%% ========================================
%  Step 7: 設計驗證與比較
%  ========================================
fprintf('\n▶ Step 7: Design Verification\n');
fprintf('───────────────────────────────────────────────────────────\n');

fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║              Frequency Design vs Actual Performance         ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');

fprintf('\n%-30s | %-15s | %-15s\n', 'Metric', 'Predicted', 'Actual (Ch1)');
fprintf('─────────────────────────────────────────────────────────────────\n');

fprintf('%-30s | %-15.1f | %-15.2f\n', 'Overshoot (%)', ...
        overshoot_estimate, performance.overshoot(1));

fprintf('%-30s | %-15.4f | %-15.4f\n', 'Settling Time (s)', ...
        settling_time_estimate, performance.settling_time(1));

fprintf('%-30s | %-15.1f | %-15s\n', 'Phase Margin (deg)', ...
        design_info.achieved.PM_actual, 'N/A (time domain)');

fprintf('%-30s | %-15.2f | %-15.2f\n', 'Crossover Freq (Hz)', ...
        wc_desired/(2*pi), design_info.achieved.wc_actual/(2*pi));

fprintf('\n');

% 顯示所有通道的統計
fprintf('All Channels Performance:\n');
fprintf('  Average overshoot:      %.2f %%\n', mean(performance.overshoot));
fprintf('  Average settling time:  %.4f s\n', mean(performance.settling_time));
fprintf('  Max settling time:      %.4f s\n', max(performance.settling_time));
fprintf('  Max steady-state error: %.5f\n', max(performance.steady_state_error));
fprintf('\n');

%% ========================================
%  Step 8: 儲存設計結果
%  ========================================
fprintf('▶ Step 8: Saving Design Results\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 確保 results 資料夾存在
if ~exist('results', 'dir')
    mkdir('results');
end

% 儲存完整設計資料
design_results.plant_info = plant_info;
design_results.design_info = design_info;
design_results.controller_params = params;
design_results.sim_results = sim_results;
design_results.performance = performance;
design_results.specs.wc_desired = wc_desired;
design_results.specs.PM_desired = PM_desired;
design_results.specs.overshoot_estimate = overshoot_estimate;
design_results.specs.settling_time_estimate = settling_time_estimate;
design_results.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

save('results/frequency_design_results.mat', 'design_results');
fprintf('  ✓ Results saved: results/frequency_design_results.mat\n');

% 產生設計報告
fid = fopen('results/frequency_design_report.txt', 'w');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, '    Frequency-Domain PI Controller Design Report\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Generated: %s\n\n', design_results.timestamp);

fprintf(fid, '1. DESIGN SPECIFICATIONS\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, 'Target Crossover Frequency: %.2f rad/s  (%.2f Hz)\n', wc_desired, wc_desired/(2*pi));
fprintf(fid, 'Target Phase Margin:        %.1f deg\n', PM_desired);
fprintf(fid, 'Design Method:              %s\n\n', design_options.method);

fprintf(fid, '2. DESIGNED CONTROLLER PARAMETERS\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, 'Proportional Gain (Kp):     %.6e\n', Kp_single);
fprintf(fid, 'Integral Gain (Ki):         %.6e\n', Ki_single);
fprintf(fid, 'Integral Time (Ti = Kp/Ki): %.6e s\n', Kp_single/Ki_single);
fprintf(fid, 'Sample Time (Ts):           %.0e s\n\n', Ts_controller);

fprintf(fid, '3. ACHIEVED FREQUENCY-DOMAIN PERFORMANCE\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, 'Actual Crossover Frequency: %.2f rad/s  (%.2f Hz)\n', ...
        design_info.achieved.wc_actual, design_info.achieved.wc_actual/(2*pi));
fprintf(fid, 'Actual Phase Margin:        %.2f deg\n', design_info.achieved.PM_actual);
fprintf(fid, 'Gain Margin:                %.2f dB\n\n', design_info.achieved.GM_actual_dB);

fprintf(fid, '4. TIME-DOMAIN PERFORMANCE (from Simulink)\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, 'Channel | Rise Time | Settling Time | Overshoot | SS Error\n');
fprintf(fid, '--------|-----------|---------------|-----------|----------\n');
for ch = 1:6
    fprintf(fid, '  %d     | %7.4f s | %10.4f s | %8.2f %% | %8.5f\n', ...
        ch, ...
        performance.rise_time(ch), ...
        performance.settling_time(ch), ...
        performance.overshoot(ch), ...
        performance.steady_state_error(ch));
end

fprintf(fid, '\n5. SUMMARY\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, 'Average Settling Time:  %.4f s  (Predicted: %.4f s)\n', ...
        mean(performance.settling_time), settling_time_estimate);
fprintf(fid, 'Average Overshoot:      %.2f %%  (Predicted: %.0f %%)\n', ...
        mean(performance.overshoot), overshoot_estimate);
fprintf(fid, 'Max SS Error:           %.5f\n', max(performance.steady_state_error));

if abs(mean(performance.overshoot) - overshoot_estimate) < 10
    fprintf(fid, '\n✓ Design prediction matches simulation well!\n');
else
    fprintf(fid, '\n! Design prediction deviates from simulation. Consider:\n');
    fprintf(fid, '  - Nonlinear effects (DAC/ADC)\n');
    fprintf(fid, '  - Channel coupling (MIMO interaction)\n');
    fprintf(fid, '  - Model uncertainty\n');
end

fclose(fid);
fprintf('  ✓ Report saved: results/frequency_design_report.txt\n');

%% ========================================
%  完成
%  ========================================
fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                ✓ Frequency Design Complete!                ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');

fprintf('\nGenerated Files:\n');
fprintf('  📊 Plant Bode plot (Figure 1)\n');
fprintf('  📊 Controller design plots (Figure 2)\n');
fprintf('  📊 results/PI_frequency_design.fig\n');
fprintf('  💾 results/frequency_design_results.mat\n');
fprintf('  📄 results/frequency_design_report.txt\n');

fprintf('\nController Parameters to Use:\n');
fprintf('  Kp = %.6e\n', Kp_single);
fprintf('  Ki = %.6e\n', Ki_single);

fprintf('\nNext Steps:\n');
fprintf('  • Review frequency domain plots (Figure 2)\n');
fprintf('  • Check time-domain performance plots\n');
fprintf('  • If needed, adjust ωc or PM and re-run\n');
fprintf('  • Compare with other design methods\n');

fprintf('\n════════════════════════════════════════════════════════════\n');
