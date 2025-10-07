% generate_simulink_framework.m
% 建立完整的數位控制系統框架（不含控制器）
%
% Purpose:
%   建立包含以下元件的完整控制系統：
%     - 參考訊號 Vd (6×1)
%     - 誤差計算 e = Vd - Vm
%     - 控制器接口（輸入 e，輸出 u）
%     - DAC + Plant + ADC
%     - 輸出訊號 Vm (6×1)
%     - 監測訊號（u, e, Vm, Vm_analog）
%
% Usage:
%   1. Run Model_6_6_Continuous_Weighted.m to generate one_curve_36_results.mat
%   2. Run this script: generate_simulink_framework
%   3. Open model: open_system('Control_System_Framework')
%   4. Add controller block and connect e_out → Controller → u_in
%
% Output:
%   Control_System_Framework.slx - Complete control system framework
%
% Signal Naming:
%   Vd - 參考電壓 (Desired voltage)
%   Vm - 測量電壓 (Measured voltage)
%   e  - 誤差 (error)
%   u  - 控制訊號 (control signal)
%
% Author: Claude Code
% Date: 2025-10-07

function generate_simulink_framework()
    %% Load transfer function data
    if ~exist('one_curve_36_results.mat', 'file')
        error(['one_curve_36_results.mat not found!\n' ...
               'Please run Model_6_6_Continuous_Weighted.m first.']);
    end

    load('one_curve_36_results.mat', 'one_curve_results');

    a1_matrix = one_curve_results.a1_matrix;
    a2_matrix = one_curve_results.a2_matrix;
    b_matrix = one_curve_results.b_matrix;

    fprintf('=== Generate Control System Framework ===\n');
    fprintf('Loaded TF parameters from: one_curve_36_results.mat\n\n');

    %% System parameters
    Ts = 1e-5;  % 採樣時間 10 μs

    fprintf('System Configuration:\n');
    fprintf('  - Sample Time: %.0f μs (%.0f kHz)\n', Ts*1e6, 1/Ts/1000);
    fprintf('  - Transfer Functions: 36 (6×6 MIMO)\n');
    fprintf('  - Control Interface: e_out → [Controller] → u_in\n');
    fprintf('\n');

    %% Model configuration
    model_name = 'Control_System_Framework';

    % Close model if already open
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end

    % Create new model
    new_system(model_name);
    open_system(model_name);

    %% ========================================
    %  Layout Parameters
    %  ========================================

    % 水平位置
    vd_x = 50;                  % 參考訊號 Vd
    sum_x = 250;                % 誤差計算 Sum
    e_out_x = 400;              % 誤差輸出埠 e_out
    u_in_x = 600;               % 控制訊號輸入埠 u_in
    dac_x = 800;                % DAC
    plant_x = 1100;             % 受控體
    adc_x = 1500;               % ADC
    vm_x = 1700;                % 輸出 Vm

    % 垂直位置
    main_y = 200;               % 主訊號鏈
    monitor_y = 500;            % 監測訊號區

    %% ========================================
    %  Section 1: 參考訊號 Vd
    %  ========================================

    fprintf('Creating reference signal Vd...\n');

    % Constant block for Vd
    add_block('simulink/Sources/Constant', [model_name '/Vd']);
    set_param([model_name '/Vd'], ...
        'Value', '[1; 1; 1; 1; 1; 1]', ...
        'SampleTime', num2str(Ts), ...
        'Position', [vd_x, main_y-20, vd_x+50, main_y+20]);

    %% ========================================
    %  Section 2: 誤差計算 (e = Vd - Vm)
    %  ========================================

    fprintf('Creating error calculation (e = Vd - Vm)...\n');

    % Sum block: e = Vd - Vm
    add_block('simulink/Math Operations/Sum', [model_name '/Error_Sum']);
    set_param([model_name '/Error_Sum'], ...
        'Inputs', '+-', ...
        'IconShape', 'rectangular', ...
        'Position', [sum_x, main_y-20, sum_x+40, main_y+20]);

    % 連接 Vd → Sum
    add_line(model_name, 'Vd/1', 'Error_Sum/1', 'autorouting', 'on');

    %% ========================================
    %  Section 3: 控制器接口 - 誤差輸出 e_out
    %  ========================================

    fprintf('Creating controller interface (e_out)...\n');

    % 輸出埠：e_out (誤差訊號，6×1)
    add_block('simulink/Sinks/Out1', [model_name '/e_out']);
    set_param([model_name '/e_out'], ...
        'Position', [e_out_x, main_y-10, e_out_x+30, main_y+10]);

    % 連接 Error_Sum → e_out
    add_line(model_name, 'Error_Sum/1', 'e_out/1', 'autorouting', 'on');

    %% ========================================
    %  Section 4: 控制器接口 - 控制訊號輸入 u_in
    %  ========================================

    fprintf('Creating controller interface (u_in)...\n');

    % 輸入埠：u_in (控制訊號，6×1)
    add_block('simulink/Sources/In1', [model_name '/u_in']);
    set_param([model_name '/u_in'], ...
        'Position', [u_in_x, main_y-10, u_in_x+30, main_y+10]);

    %% ========================================
    %  Section 5: DAC (Zero-Order Hold × 6)
    %  ========================================

    fprintf('Creating DAC subsystem...\n');

    % Demux: 拆分控制訊號
    add_block('simulink/Signal Routing/Demux', [model_name '/Demux_u']);
    set_param([model_name '/Demux_u'], ...
        'Outputs', '6', ...
        'Position', [dac_x-100, main_y-60, dac_x-90, main_y+300]);

    add_line(model_name, 'u_in/1', 'Demux_u/1', 'autorouting', 'on');

    % 建立 6 個 DAC
    row_spacing = 60;
    for i = 1:6
        block_name = sprintf('%s/DAC_%d', model_name, i);
        add_block('simulink/Discrete/Zero-Order Hold', block_name);

        y_pos = main_y - 60 + (i-1)*row_spacing;
        set_param(block_name, ...
            'SampleTime', num2str(Ts), ...
            'Position', [dac_x, y_pos-10, dac_x+50, y_pos+10]);

        add_line(model_name, sprintf('Demux_u/%d', i), sprintf('DAC_%d/1', i), 'autorouting', 'on');
    end

    % Mux: 合併 DAC 輸出
    add_block('simulink/Signal Routing/Mux', [model_name '/Mux_DAC']);
    set_param([model_name '/Mux_DAC'], ...
        'Inputs', '6', ...
        'Position', [dac_x+100, main_y-60, dac_x+110, main_y+300]);

    for i = 1:6
        add_line(model_name, sprintf('DAC_%d/1', i), sprintf('Mux_DAC/%d', i), 'autorouting', 'on');
    end

    %% ========================================
    %  Section 6: Plant Subsystem (36 TF)
    %  ========================================

    fprintf('Creating plant subsystem...\n');

    plant_subsys = [model_name '/Plant_Subsystem'];
    add_block('built-in/Subsystem', plant_subsys);
    set_param(plant_subsys, ...
        'Position', [plant_x, main_y-60, plant_x+150, main_y+300]);

    % 刪除預設埠（安全刪除）
    try
        delete_block([plant_subsys '/In1']);
    catch
        try
            delete_block([plant_subsys '/In']);
        catch
        end
    end

    try
        delete_block([plant_subsys '/Out1']);
    catch
        try
            delete_block([plant_subsys '/Out']);
        catch
        end
    end

    % 建立 Plant 內部結構
    create_plant_internals(plant_subsys, a1_matrix, a2_matrix, b_matrix);

    % 連接 Mux_DAC → Plant
    add_line(model_name, 'Mux_DAC/1', 'Plant_Subsystem/1', 'autorouting', 'on');

    %% ========================================
    %  Section 7: ADC (Zero-Order Hold × 6)
    %  ========================================

    fprintf('Creating ADC subsystem...\n');

    % Demux: 拆分 Plant 輸出
    add_block('simulink/Signal Routing/Demux', [model_name '/Demux_Plant']);
    set_param([model_name '/Demux_Plant'], ...
        'Outputs', '6', ...
        'Position', [adc_x-100, main_y-60, adc_x-90, main_y+300]);

    add_line(model_name, 'Plant_Subsystem/1', 'Demux_Plant/1', 'autorouting', 'on');

    % 建立 6 個 ADC
    for i = 1:6
        block_name = sprintf('%s/ADC_%d', model_name, i);
        add_block('simulink/Discrete/Zero-Order Hold', block_name);

        y_pos = main_y - 60 + (i-1)*row_spacing;
        set_param(block_name, ...
            'SampleTime', num2str(Ts), ...
            'Position', [adc_x, y_pos-10, adc_x+50, y_pos+10]);

        add_line(model_name, sprintf('Demux_Plant/%d', i), sprintf('ADC_%d/1', i), 'autorouting', 'on');
    end

    % Mux: 合併為 Vm
    add_block('simulink/Signal Routing/Mux', [model_name '/Mux_Vm']);
    set_param([model_name '/Mux_Vm'], ...
        'Inputs', '6', ...
        'Position', [vm_x-100, main_y-60, vm_x-90, main_y+300]);

    for i = 1:6
        add_line(model_name, sprintf('ADC_%d/1', i), sprintf('Mux_Vm/%d', i), 'autorouting', 'on');
    end

    %% ========================================
    %  Section 8: 輸出 Vm
    %  ========================================

    fprintf('Creating output Vm...\n');

    % 輸出埠：Vm (測量電壓，6×1)
    add_block('simulink/Sinks/Out1', [model_name '/Vm']);
    set_param([model_name '/Vm'], ...
        'Position', [vm_x, main_y-10, vm_x+30, main_y+10]);

    add_line(model_name, 'Mux_Vm/1', 'Vm/1', 'autorouting', 'on');

    %% ========================================
    %  Section 9: 回授連線 (Vm → Error_Sum)
    %  ========================================

    fprintf('Creating feedback loop (Vm → Error_Sum)...\n');

    % Vm → Error_Sum 的第 2 個輸入（負回授）
    add_line(model_name, 'Mux_Vm/1', 'Error_Sum/2', 'autorouting', 'on');

    %% ========================================
    %  Section 10: 監測訊號 (Scopes & To Workspace)
    %  ========================================

    fprintf('Creating monitoring signals...\n');

    % 監測訊號 1: u (控制訊號)
    add_block('simulink/Sinks/Scope', [model_name '/Scope_u']);
    set_param([model_name '/Scope_u'], ...
        'Position', [u_in_x+50, monitor_y, u_in_x+100, monitor_y+40]);
    add_line(model_name, 'u_in/1', 'Scope_u/1', 'autorouting', 'on');

    add_block('simulink/Sinks/To Workspace', [model_name '/u_log']);
    set_param([model_name '/u_log'], ...
        'VariableName', 'u', ...
        'Position', [u_in_x+50, monitor_y+60, u_in_x+100, monitor_y+90]);
    add_line(model_name, 'u_in/1', 'u_log/1', 'autorouting', 'on');

    % 監測訊號 2: e (誤差)
    add_block('simulink/Sinks/Scope', [model_name '/Scope_e']);
    set_param([model_name '/Scope_e'], ...
        'Position', [e_out_x+50, monitor_y, e_out_x+100, monitor_y+40]);
    add_line(model_name, 'Error_Sum/1', 'Scope_e/1', 'autorouting', 'on');

    add_block('simulink/Sinks/To Workspace', [model_name '/e_log']);
    set_param([model_name '/e_log'], ...
        'VariableName', 'e', ...
        'Position', [e_out_x+50, monitor_y+60, e_out_x+100, monitor_y+90]);
    add_line(model_name, 'Error_Sum/1', 'e_log/1', 'autorouting', 'on');

    % 監測訊號 3: Vm (輸出)
    add_block('simulink/Sinks/Scope', [model_name '/Scope_Vm']);
    set_param([model_name '/Scope_Vm'], ...
        'Position', [vm_x+50, monitor_y, vm_x+100, monitor_y+40]);
    add_line(model_name, 'Mux_Vm/1', 'Scope_Vm/1', 'autorouting', 'on');

    add_block('simulink/Sinks/To Workspace', [model_name '/Vm_log']);
    set_param([model_name '/Vm_log'], ...
        'VariableName', 'Vm', ...
        'Position', [vm_x+50, monitor_y+60, vm_x+100, monitor_y+90]);
    add_line(model_name, 'Mux_Vm/1', 'Vm_log/1', 'autorouting', 'on');

    % 監測訊號 4: Vm_analog (類比輸出，從 Plant 直接取)
    add_block('simulink/Signal Routing/Mux', [model_name '/Mux_Vm_analog']);
    set_param([model_name '/Mux_Vm_analog'], ...
        'Inputs', '6', ...
        'Position', [plant_x+200, monitor_y+120, plant_x+210, monitor_y+380]);

    for i = 1:6
        add_line(model_name, sprintf('Demux_Plant/%d', i), sprintf('Mux_Vm_analog/%d', i), 'autorouting', 'on');
    end

    add_block('simulink/Sinks/To Workspace', [model_name '/Vm_analog_log']);
    set_param([model_name '/Vm_analog_log'], ...
        'VariableName', 'Vm_analog', ...
        'Position', [plant_x+250, monitor_y+230, plant_x+300, monitor_y+270]);
    add_line(model_name, 'Mux_Vm_analog/1', 'Vm_analog_log/1', 'autorouting', 'on');

    %% ========================================
    %  Section 11: 標註與文件
    %  ========================================

    % 主標註
    annotation_text = sprintf(['Control System Framework (Controller Interface)\n' ...
                               'Generated: %s\n\n' ...
                               '=== SIGNAL FLOW ===\n' ...
                               'Vd (6×1) → [Sum] → e_out → [CONTROLLER] → u_in → [DAC] → [Plant] → [ADC] → Vm (6×1)\n' ...
                               '                    ↑                                                        │\n' ...
                               '                    └────────────────────────────────────────────────────────┘\n\n' ...
                               '=== INTERFACE ===\n' ...
                               'OUTPUT: e_out (6×1) - Error signal to controller\n' ...
                               'INPUT:  u_in  (6×1) - Control signal from controller\n\n' ...
                               '=== MONITORING ===\n' ...
                               '- Scope_u, u_log:         Control signal\n' ...
                               '- Scope_e, e_log:         Error signal\n' ...
                               '- Scope_Vm, Vm_log:       Measured output (digital)\n' ...
                               '- Vm_analog_log:          Analog output\n\n' ...
                               'Sample Time: %.0f μs (Fs = %.0f kHz)'], ...
                               datestr(now), Ts*1e6, 1/Ts/1000);

    add_block('built-in/Note', [model_name '/Info'], ...
              'Position', [50, 700], ...
              'Text', annotation_text, ...
              'FontSize', '10', ...
              'FontWeight', 'bold');

    % 區域標註
    add_block('built-in/Note', [model_name '/Label_Ref'], ...
              'Position', [vd_x, main_y-80], ...
              'Text', 'Reference: Vd', ...
              'FontSize', '12', ...
              'ForegroundColor', 'blue');

    add_block('built-in/Note', [model_name '/Label_Error'], ...
              'Position', [sum_x, main_y-80], ...
              'Text', 'Error: e = Vd - Vm', ...
              'FontSize', '12', ...
              'ForegroundColor', 'blue');

    add_block('built-in/Note', [model_name '/Label_Controller'], ...
              'Position', [(e_out_x + u_in_x)/2 - 50, main_y-80], ...
              'Text', '>>> INSERT CONTROLLER HERE <<<', ...
              'FontSize', '14', ...
              'FontWeight', 'bold', ...
              'ForegroundColor', 'red');

    add_block('built-in/Note', [model_name '/Label_Plant'], ...
              'Position', [plant_x+50, main_y-80], ...
              'Text', 'Plant (36 TF)', ...
              'FontSize', '12', ...
              'ForegroundColor', 'blue');

    add_block('built-in/Note', [model_name '/Label_Output'], ...
              'Position', [vm_x, main_y-80], ...
              'Text', 'Output: Vm', ...
              'FontSize', '12', ...
              'ForegroundColor', 'blue');

    add_block('built-in/Note', [model_name '/Label_Monitor'], ...
              'Position', [50, monitor_y-50], ...
              'Text', '=== MONITORING SIGNALS ===', ...
              'FontSize', '14', ...
              'FontWeight', 'bold', ...
              'ForegroundColor', 'green');

    %% Save model
    save_system(model_name);

    fprintf('\n✓ Control system framework created: %s.slx\n', model_name);
    fprintf('\n=== Model Structure ===\n');
    fprintf('  INPUTS:\n');
    fprintf('    - Vd:    Reference signal (Constant, 6×1)\n');
    fprintf('    - u_in:  Control signal from controller (6×1)\n');
    fprintf('\n');
    fprintf('  OUTPUTS:\n');
    fprintf('    - e_out: Error signal to controller (6×1)\n');
    fprintf('    - Vm:    Measured output (6×1)\n');
    fprintf('\n');
    fprintf('  MONITORING:\n');
    fprintf('    - Scope_u, u_log:      Control signal u\n');
    fprintf('    - Scope_e, e_log:      Error signal e\n');
    fprintf('    - Scope_Vm, Vm_log:    Digital output Vm\n');
    fprintf('    - Vm_analog_log:       Analog output Vm_analog\n');
    fprintf('\n');
    fprintf('=== Next Steps ===\n');
    fprintf('  1. Open model: open_system(''%s'')\n', model_name);
    fprintf('  2. Add controller: Connect e_out → [Controller] → u_in\n');
    fprintf('  3. Configure solver and run simulation\n');
    fprintf('\n');
    fprintf('=== Controller Interface ===\n');
    fprintf('  To add a simple proportional controller:\n');
    fprintf('    add_block(''simulink/Math Operations/Gain'', ''%s/Controller'');\n', model_name);
    fprintf('    set_param(''%s/Controller'', ''Gain'', ''eye(6)*0.5'');\n', model_name);
    fprintf('    add_line(''%s'', ''e_out/1'', ''Controller/1'');\n', model_name);
    fprintf('    add_line(''%s'', ''Controller/1'', ''u_in/1'');\n', model_name);
    fprintf('\n');
end

%% ========================================
%  Helper Function: Create Plant Internals
%  ========================================

function create_plant_internals(subsys_name, a1_matrix, a2_matrix, b_matrix)
    % 在受控體子系統內部建立 36 個轉移函數

    % 輸入埠
    add_block('simulink/Sources/In1', [subsys_name '/u_in']);
    set_param([subsys_name '/u_in'], 'Position', [50, 300, 80, 320]);

    % Demux 輸入
    add_block('simulink/Signal Routing/Demux', [subsys_name '/Demux_Input']);
    set_param([subsys_name '/Demux_Input'], ...
        'Outputs', '6', ...
        'Position', [150, 200, 160, 400]);

    add_line(subsys_name, 'u_in/1', 'Demux_Input/1', 'autorouting', 'on');

    % 版面參數
    tf_base_x = 300;
    sum_x = 900;
    row_spacing = 80;

    % 建立 36 個轉移函數和 6 個加法器
    for i = 1:6  % Output channel
        % 加法器
        sum_block = sprintf('%s/Sum_Ch%d', subsys_name, i);
        add_block('simulink/Math Operations/Sum', sum_block);
        sum_y = 200 + (i-1)*row_spacing;
        set_param(sum_block, ...
            'Inputs', '++++++', ...
            'Position', [sum_x, sum_y-10, sum_x+20, sum_y+10]);

        for j = 1:6  % Input channel
            % 轉移函數
            a1_ij = a1_matrix(i, j);
            a2_ij = a2_matrix(i, j);
            b_ij = b_matrix(i, j);

            tf_block = sprintf('%s/TF_H%d%d', subsys_name, i, j);
            add_block('simulink/Continuous/Transfer Fcn', tf_block);

            tf_x = tf_base_x + (j-1)*80;
            tf_y = 200 + (i-1)*row_spacing;
            set_param(tf_block, ...
                'Numerator', sprintf('[%.12e]', b_ij), ...
                'Denominator', sprintf('[1, %.12e, %.12e]', a1_ij, a2_ij), ...
                'Position', [tf_x, tf_y-15, tf_x+60, tf_y+15]);

            % 連接 Demux → TF
            add_line(subsys_name, sprintf('Demux_Input/%d', j), sprintf('TF_H%d%d/1', i, j), 'autorouting', 'on');

            % 連接 TF → Sum
            add_line(subsys_name, sprintf('TF_H%d%d/1', i, j), sprintf('Sum_Ch%d/%d', i, j), 'autorouting', 'on');
        end
    end

    % Mux 輸出
    add_block('simulink/Signal Routing/Mux', [subsys_name '/Mux_Output']);
    set_param([subsys_name '/Mux_Output'], ...
        'Inputs', '6', ...
        'Position', [1050, 200, 1060, 400]);

    % 連接 Sum → Mux
    for i = 1:6
        add_line(subsys_name, sprintf('Sum_Ch%d/1', i), sprintf('Mux_Output/%d', i), 'autorouting', 'on');
    end

    % 輸出埠
    add_block('simulink/Sinks/Out1', [subsys_name '/y_out']);
    set_param([subsys_name '/y_out'], 'Position', [1150, 290, 1180, 310]);

    add_line(subsys_name, 'Mux_Output/1', 'y_out/1', 'autorouting', 'on');
end
