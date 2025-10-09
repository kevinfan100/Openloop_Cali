% example_run_PI.m
% 完整的 PI 控制器測試範例
%
% 這個腳本展示完整的工作流程：
%   1. 設定 PI 控制器參數
%   2. 將控制器整合到系統框架
%   3. 執行模擬
%   4. 分析性能指標
%   5. 儲存結果
%
% Usage:
%   直接執行此腳本：example_run_PI
%   或在函數模式：example_run_PI()
%
% Author: Claude Code
% Date: 2025-10-09

%% ========================================
%  清除環境
%  ========================================
clear; clc; close all;

fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║         PI Controller Simulation - Complete Workflow       ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

%% ========================================
%  Step 1: 參數設定
%  ========================================
fprintf('▶ Step 1: Setting PI Parameters\n');
fprintf('───────────────────────────────────────────────────────────\n');

% PI 增益（6×6 對角矩陣，每個通道獨立）
% 注意：這些參數可能需要根據系統特性調整
Kp = diag([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]);  % 比例增益
Ki = diag([10, 10, 10, 10, 10, 10]);         % 積分增益
Ts_controller = 1e-5;                        % 採樣時間 10 μs

% 參考訊號
Vd_ref = [1; 1; 1; 1; 1; 1];                 % 目標電壓

% 模擬時間
sim_time = 0.01;  % 10 ms (可根據需要調整)

fprintf('PI Controller Parameters:\n');
fprintf('  Kp = diag([%.2f, %.2f, %.2f, %.2f, %.2f, %.2f])\n', diag(Kp)');
fprintf('  Ki = diag([%.1f, %.1f, %.1f, %.1f, %.1f, %.1f])\n', diag(Ki)');
fprintf('  Ts = %.0f μs (%.0f kHz)\n', Ts_controller*1e6, 1/Ts_controller/1000);
fprintf('\nSimulation Parameters:\n');
fprintf('  Simulation time: %.3f s\n', sim_time);
fprintf('  Reference: Vd = [%.1f, %.1f, %.1f, %.1f, %.1f, %.1f]''\n', Vd_ref');
fprintf('\n');

%% ========================================
%  Step 2: 整合控制器到框架
%  ========================================
fprintf('▶ Step 2: Integrating Controller to Framework\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 準備參數結構
params.Kp = Kp;
params.Ki = Ki;
params.Ts_controller = Ts_controller;

% 呼叫 setup_controller
addpath('scripts');  % 確保腳本在路徑中
setup_controller('PI_controller', params);

fprintf('\n');

%% ========================================
%  Step 3: 設定參考訊號
%  ========================================
fprintf('▶ Step 3: Setting Reference Signal\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 設定框架中的 Vd 值
try
    set_param('Control_System_Framework/Vd', 'Value', mat2str(Vd_ref));
    fprintf('  ✓ Reference signal Vd set to [%.1f, %.1f, %.1f, %.1f, %.1f, %.1f]''\n', Vd_ref');
catch ME
    fprintf('  ! Warning: Could not set Vd value: %s\n', ME.message);
end

fprintf('\n');

%% ========================================
%  Step 4: 執行模擬
%  ========================================
fprintf('▶ Step 4: Running Simulation\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 求解器選項
solver_options.Solver = 'ode45';
solver_options.MaxStep = 1e-6;    % 1 μs
solver_options.RelTol = 1e-3;

% 執行模擬
sim_results = run_simulation('Control_System_Framework', sim_time, solver_options);

fprintf('\n');

%% ========================================
%  Step 5: 分析結果
%  ========================================
fprintf('▶ Step 5: Analyzing Results\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 繪圖選項
plot_options.show_plot = true;
plot_options.save_fig = true;
plot_options.fig_name = 'results/PI_controller_performance.fig';

% 分析性能
performance = analyze_results(sim_results, Vd_ref, plot_options);

fprintf('\n');

%% ========================================
%  Step 6: 儲存結果
%  ========================================
fprintf('▶ Step 6: Saving Results\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 確保 results 資料夾存在
if ~exist('results', 'dir')
    mkdir('results');
    fprintf('  ✓ Created results/ folder\n');
end

% 準備儲存的資料
results_data.params = params;
results_data.sim_time = sim_time;
results_data.reference = Vd_ref;
results_data.sim_results = sim_results;
results_data.performance = performance;
results_data.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

% 儲存 .mat 檔案
save('results/PI_controller_results.mat', 'results_data');
fprintf('  ✓ Results saved: results/PI_controller_results.mat\n');

% 儲存性能報告（文字檔）
fid = fopen('results/PI_controller_report.txt', 'w');
fprintf(fid, '=== PI Controller Performance Report ===\n');
fprintf(fid, 'Generated: %s\n\n', results_data.timestamp);

fprintf(fid, 'Parameters:\n');
fprintf(fid, '  Kp = diag([%.2f, %.2f, %.2f, %.2f, %.2f, %.2f])\n', diag(Kp)');
fprintf(fid, '  Ki = diag([%.1f, %.1f, %.1f, %.1f, %.1f, %.1f])\n', diag(Ki)');
fprintf(fid, '  Ts = %.2e s\n', Ts_controller);
fprintf(fid, '  Simulation time = %.3f s\n\n', sim_time);

fprintf(fid, 'Performance Metrics:\n');
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

fprintf(fid, '\nAggregate Metrics:\n');
fprintf(fid, '  Average settling time: %.4f s\n', mean(performance.settling_time));
fprintf(fid, '  Max settling time:     %.4f s\n', max(performance.settling_time));
fprintf(fid, '  Average overshoot:     %.2f %%\n', mean(performance.overshoot));
fprintf(fid, '  Max overshoot:         %.2f %%\n', max(performance.overshoot));
fprintf(fid, '  Max SS error:          %.5f\n', max(performance.steady_state_error));

fclose(fid);
fprintf('  ✓ Report saved: results/PI_controller_report.txt\n');

fprintf('\n');

%% ========================================
%  完成
%  ========================================
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    ✓ All Steps Completed!                  ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\nGenerated Files:\n');
fprintf('  📊 results/PI_controller_performance.fig (plot)\n');
fprintf('  📊 results/PI_controller_performance.png (plot)\n');
fprintf('  💾 results/PI_controller_results.mat (data)\n');
fprintf('  📄 results/PI_controller_report.txt (report)\n');
fprintf('\nNext Steps:\n');
fprintf('  • Review the plots to check system response\n');
fprintf('  • Adjust Kp, Ki if needed and re-run\n');
fprintf('  • Compare with other controllers (feedback linearization, sliding mode, etc.)\n');
fprintf('\n');

%% ========================================
%  顯示關鍵結果
%  ========================================
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                      Key Results                           ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');

fprintf('\nFinal Output Values:\n');
fprintf('  Channel:  ');
for ch = 1:6
    fprintf('%7d  ', ch);
end
fprintf('\n  Vm:       ');
for ch = 1:6
    fprintf('%7.4f  ', sim_results.Vm_final(ch));
end
fprintf('\n  Error:    ');
for ch = 1:6
    fprintf('%7.4f  ', sim_results.e_final(ch));
end
fprintf('\n');

fprintf('\nPerformance Summary:\n');
fprintf('  Best settling time:  Ch%d (%.4f s)\n', ...
    find(performance.settling_time == min(performance.settling_time), 1), ...
    min(performance.settling_time));
fprintf('  Worst settling time: Ch%d (%.4f s)\n', ...
    find(performance.settling_time == max(performance.settling_time), 1), ...
    max(performance.settling_time));
fprintf('  Best overshoot:      Ch%d (%.2f %%)\n', ...
    find(performance.overshoot == min(performance.overshoot), 1), ...
    min(performance.overshoot));
fprintf('  Worst overshoot:     Ch%d (%.2f %%)\n', ...
    find(performance.overshoot == max(performance.overshoot), 1), ...
    max(performance.overshoot));

fprintf('\n');
fprintf('════════════════════════════════════════════════════════════\n');
fprintf('   Simulation complete! Check the figure window for plots.\n');
fprintf('════════════════════════════════════════════════════════════\n');
