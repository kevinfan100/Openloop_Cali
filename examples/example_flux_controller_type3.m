% example_flux_controller_type3.m
% 完整的 Flux Controller Type 3 測試範例
%
% 這個腳本展示完整的工作流程：
%   1. 建立 Simulink 控制器模型
%   2. 計算控制器參數
%   3. 整合到系統框架（可選）
%   4. 執行模擬
%   5. 分析結果
%
% Type 3: 一階擾動模型（最簡單版本）
%   擾動模型: wT[k+1] = wT[k]
%   適合: 常數型擾動
%
% Usage:
%   直接執行此腳本: example_flux_controller_type3
%   或在函數模式: example_flux_controller_type3()
%
% Author: Claude Code
% Date: 2025-10-11

%% ========================================
%  清除環境
%  ========================================
clear; clc; close all;

fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║   Flux Controller Type 3 - Complete Workflow Example      ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

%% ========================================
%  Step 1: 建立控制器模型
%  ========================================
fprintf('▶ Step 1: 建立 Flux Controller Type 3 模型\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 檢查模型是否已存在
if exist('Flux_Controller_Type3.slx', 'file')
    fprintf('  模型已存在: Flux_Controller_Type3.slx\n');
    user_input = input('  是否重新建立? (y/n): ', 's');
    if strcmpi(user_input, 'y')
        fprintf('  重新建立模型...\n');
        addpath('controllers');
        create_flux_controller_type3();
    else
        fprintf('  使用現有模型\n');
    end
else
    fprintf('  模型不存在，開始建立...\n');
    addpath('controllers');
    create_flux_controller_type3();
end

fprintf('\n');

%% ========================================
%  Step 2: 設定系統參數
%  ========================================
fprintf('▶ Step 2: 設定系統參數\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 系統參數 (這些應該從你的系統辨識得來)
% 對於離散系統: vm[k+1] = a1·vm[k] + a2·vm[k-1] + B{u[k] + w[k]}
system_params.a1 = 1.8;    % 系統係數 (範例值，請根據實際系統調整)
system_params.a2 = -0.85;  % 系統係數 (範例值，請根據實際系統調整)
system_params.B = eye(6);  % 控制矩陣 (6×6 單位矩陣，實際可能不同)
system_params.Ts = 1e-4;   % 採樣時間 100 μs (10 kHz)

fprintf('系統參數:\n');
fprintf('  a1 = %.6f\n', system_params.a1);
fprintf('  a2 = %.6f\n', system_params.a2);
fprintf('  B = %d×%d 矩陣\n', size(system_params.B));
fprintf('  Ts = %.2e s (%.1f kHz)\n', system_params.Ts, 1/system_params.Ts/1000);
fprintf('\n');

fprintf('注意: 這些是範例參數！\n');
fprintf('      請根據你的實際系統辨識結果調整 a1, a2, B\n');
fprintf('\n');

%% ========================================
%  Step 3: 設定控制器設計參數
%  ========================================
fprintf('▶ Step 3: 設定控制器設計參數\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 設計參數
design_params.lambda_c = 0.5;  % 控制特徵值 (0 < λc < 1)
                               % 越小收斂越快，但可能過於激進
                               % 建議: 0.3 ~ 0.7

design_params.lambda_e = 0.3;  % 估測器特徵值 (0 < λe < 1)
                               % 越小估測器收斂越快
                               % 通常比 λc 小，建議: 0.2 ~ 0.5

fprintf('設計參數:\n');
fprintf('  λc (控制) = %.4f\n', design_params.lambda_c);
fprintf('  λe (估測器) = %.4f\n', design_params.lambda_e);
fprintf('\n');

fprintf('參數調整建議:\n');
fprintf('  • λc 太小 → 響應快但可能震盪\n');
fprintf('  • λc 太大 → 響應慢但穩定\n');
fprintf('  • λe 應該比 λc 小，讓估測器更快收斂\n');
fprintf('\n');

%% ========================================
%  Step 4: 計算控制器參數
%  ========================================
fprintf('▶ Step 4: 計算控制器參數\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 添加腳本路徑
addpath('scripts/design');

% 計算參數（自動寫入 workspace）
controller_params = calculate_flux_controller_params(system_params, design_params, 3);

fprintf('\n');

%% ========================================
%  Step 5: 設定參考訊號
%  ========================================
fprintf('▶ Step 5: 設定參考訊號\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 參考訊號 (6×1 向量)
Vd_ref = [1.0; 1.0; 1.0; 1.0; 1.0; 1.0];  % 目標值

% 寫入 workspace
assignin('base', 'Vd_ref', Vd_ref);

fprintf('參考訊號 Vd:\n');
fprintf('  [%.2f, %.2f, %.2f, %.2f, %.2f, %.2f]''\n', Vd_ref);
fprintf('\n');

%% ========================================
%  Step 6: 模擬參數設定
%  ========================================
fprintf('▶ Step 6: 設定模擬參數\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 模擬時間
sim_time = 0.05;  % 50 ms (可根據需要調整)

fprintf('模擬時間: %.3f s\n', sim_time);
fprintf('\n');

%% ========================================
%  Step 7: 執行簡單測試 (單獨測試控制器)
%  ========================================
fprintf('▶ Step 7: 執行簡單測試\n');
fprintf('───────────────────────────────────────────────────────────\n');

fprintf('測試控制器模型: Flux_Controller_Type3.slx\n');
fprintf('建立簡單的測試環境...\n');

% 建立簡單的測試模型
test_model = 'Test_Flux_Controller_Type3';

if bdIsLoaded(test_model)
    close_system(test_model, 0);
end

if exist([test_model '.slx'], 'file')
    delete([test_model '.slx']);
end

% 建立測試模型
new_system(test_model);
open_system(test_model);

% 添加模組
% 常數輸入 Vd
add_block('simulink/Sources/Constant', [test_model '/Vd']);
set_param([test_model '/Vd'], ...
    'Value', 'Vd_ref', ...
    'Position', [100, 100, 130, 130]);

% 初始值為 0 的 Vm (模擬測量)
add_block('simulink/Sources/Constant', [test_model '/Vm']);
set_param([test_model '/Vm'], ...
    'Value', 'zeros(6,1)', ...
    'Position', [100, 200, 130, 230]);

% 控制器 (使用 Model Reference)
add_block('simulink/Ports & Subsystems/Model', [test_model '/Controller']);
set_param([test_model '/Controller'], ...
    'ModelName', 'Flux_Controller_Type3', ...
    'Position', [200, 140, 300, 180]);

% 輸出顯示
add_block('simulink/Sinks/Scope', [test_model '/Scope_u']);
set_param([test_model '/Scope_u'], ...
    'Position', [350, 135, 380, 165]);

add_block('simulink/Sinks/Scope', [test_model '/Scope_e']);
set_param([test_model '/Scope_e'], ...
    'Position', [350, 185, 380, 215]);

% 連接
add_line(test_model, 'Vd/1', 'Controller/1', 'autorouting', 'on');
add_line(test_model, 'Vm/1', 'Controller/2', 'autorouting', 'on');
add_line(test_model, 'Controller/1', 'Scope_u/1', 'autorouting', 'on');
add_line(test_model, 'Controller/2', 'Scope_e/1', 'autorouting', 'on');

% 配置求解器
set_param(test_model, 'Solver', 'FixedStepDiscrete');
set_param(test_model, 'FixedStep', num2str(system_params.Ts));
set_param(test_model, 'StopTime', num2str(sim_time));

% 儲存測試模型
save_system(test_model);

fprintf('✓ 測試模型建立完成: %s.slx\n', test_model);
fprintf('\n');

fprintf('開始模擬...\n');
tic;
sim_output = sim(test_model);
sim_duration = toc;

fprintf('✓ 模擬完成 (耗時: %.2f s)\n', sim_duration);
fprintf('\n');

%% ========================================
%  Step 8: 結果顯示
%  ========================================
fprintf('▶ Step 8: 顯示結果\n');
fprintf('───────────────────────────────────────────────────────────\n');

% 提取輸出
try
    u_out = sim_output.get('yout').get(1).Values.Data;
    e_out = sim_output.get('yout').get(2).Values.Data;
    t_out = sim_output.get('tout');

    fprintf('✓ 成功提取模擬輸出\n');

    % 繪圖
    figure('Name', 'Flux Controller Type 3 Results', 'Position', [100, 100, 1200, 600]);

    % 控制訊號
    subplot(2,1,1);
    plot(t_out, u_out);
    grid on;
    xlabel('Time (s)');
    ylabel('Control Signal u');
    title('Control Signal u[k]');
    legend('Ch1','Ch2','Ch3','Ch4','Ch5','Ch6', 'Location', 'best');

    % 誤差訊號
    subplot(2,1,2);
    plot(t_out, e_out);
    grid on;
    xlabel('Time (s)');
    ylabel('Error δv');
    title('Tracking Error δv[k] = vd[k-1] - vm[k]');
    legend('Ch1','Ch2','Ch3','Ch4','Ch5','Ch6', 'Location', 'best');

    fprintf('✓ 繪圖完成\n');
    fprintf('\n');

    % 顯示最終值
    fprintf('最終控制訊號 u:\n');
    fprintf('  [');
    for i = 1:6
        fprintf('%.4f', u_out(end, i));
        if i < 6
            fprintf(', ');
        end
    end
    fprintf(']\n\n');

    fprintf('最終誤差 δv:\n');
    fprintf('  [');
    for i = 1:6
        fprintf('%.4f', e_out(end, i));
        if i < 6
            fprintf(', ');
        end
    end
    fprintf(']\n\n');

catch ME
    fprintf('! 無法提取輸出: %s\n', ME.message);
    fprintf('  請檢查 Scope 設定\n\n');
end

%% ========================================
%  Step 9: 整合到主框架 (可選)
%  ========================================
fprintf('▶ Step 9: 整合到主框架 (可選)\n');
fprintf('───────────────────────────────────────────────────────────\n');

fprintf('如果你想整合到 Control_System_Framework.slx:\n');
fprintf('  1. 確保主框架存在\n');
fprintf('  2. 執行以下命令:\n');
fprintf('     addpath(''scripts/framework'');\n');
fprintf('     setup_controller(''Flux_Controller_Type3'', controller_params);\n');
fprintf('\n');

user_input = input('  是否現在整合到主框架? (y/n): ', 's');

if strcmpi(user_input, 'y')
    if exist('Control_System_Framework.slx', 'file')
        fprintf('  開始整合...\n');
        addpath('scripts/framework');
        try
            setup_controller('Flux_Controller_Type3', controller_params);
            fprintf('  ✓ 整合完成！\n');
        catch ME
            fprintf('  ! 整合失敗: %s\n', ME.message);
        end
    else
        fprintf('  ! 主框架不存在: Control_System_Framework.slx\n');
    end
else
    fprintf('  跳過整合\n');
end

fprintf('\n');

%% ========================================
%  完成
%  ========================================
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    ✓ 測試完成！                            ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

fprintf('生成的檔案:\n');
fprintf('  • Flux_Controller_Type3.slx - 控制器模型\n');
fprintf('  • %s.slx - 測試模型\n', test_model);
fprintf('\n');

fprintf('下一步:\n');
fprintf('  • 調整 λc, λe 參數觀察性能變化\n');
fprintf('  • 更新系統參數 a1, a2, B 為實際值\n');
fprintf('  • 整合到完整的控制框架進行閉迴路測試\n');
fprintf('  • 對比 Type 2 和 Type 1 控制器性能\n');
fprintf('\n');
