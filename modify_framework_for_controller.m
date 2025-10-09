% modify_framework_for_controller.m
% 修改 Control_System_Framework.slx 的控制器接口
%
% 修改內容：
%   原本：e_out (6×1) → [控制器] → u_in (6×1)
%   修改：Vd (6×1), Vm (6×1) → [控制器] → u (6×1)
%
% 原因：
%   - 讓控制器可以接收參考訊號 Vd（用於前饋控制）
%   - 讓控制器可以接收測量輸出 Vm（用於狀態估測）
%   - 誤差計算移到控制器內部，控制器架構更靈活
%
% Author: Claude Code
% Date: 2025-10-09

function modify_framework_for_controller()
    %% 載入模型
    model_name = 'Control_System_Framework';

    fprintf('=== Modifying Control System Framework ===\n');
    fprintf('Loading model: %s.slx\n', model_name);

    if ~exist([model_name '.slx'], 'file')
        error('Model file not found: %s.slx', model_name);
    end

    % 關閉模型（如果已開啟）
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end

    % 載入模型
    load_system(model_name);

    %% 刪除舊的控制器接口（e_out 輸出埠）
    fprintf('\nStep 1: Removing old controller interface (e_out)...\n');

    try
        % 刪除連接到 e_out 的監測訊號
        delete_line(model_name, 'Error_Sum/1', 'Scope_e/1');
        delete_line(model_name, 'Error_Sum/1', 'e_log/1');
        fprintf('  ✓ Deleted monitoring connections to e_out\n');
    catch ME
        fprintf('  ! Warning: %s\n', ME.message);
    end

    try
        % 刪除 Error_Sum → e_out 連線
        delete_line(model_name, 'Error_Sum/1', 'e_out/1');
        fprintf('  ✓ Deleted Error_Sum → e_out connection\n');
    catch ME
        fprintf('  ! Warning: %s\n', ME.message);
    end

    try
        % 刪除 e_out block
        delete_block([model_name '/e_out']);
        fprintf('  ✓ Deleted e_out output port\n');
    catch ME
        fprintf('  ! Warning: %s\n', ME.message);
    end

    %% 修改 u_in 輸入埠為普通 block（準備給控制器輸出連接）
    fprintf('\nStep 2: Preparing control signal interface...\n');

    % u_in 保留不變，仍然是輸入埠，控制器的輸出會連到這裡
    fprintf('  ✓ Control signal input (u_in) ready for controller output\n');

    %% 建立控制器輸入訊號接口
    fprintf('\nStep 3: Creating controller input signal taps...\n');

    % 位置參數
    controller_area_x = 500;
    main_y = 200;

    % 3.1 從 Vd 拉出訊號（用 Goto/From 或直接連線）
    % 這裡我們添加標註點，之後控制器會從這些點讀取訊號

    % 添加標註：Vd 供控制器使用
    try
        add_block('built-in/Note', [model_name '/Label_Vd_to_Controller'], ...
                  'Position', [150, main_y-100], ...
                  'Text', 'Vd → Controller Input 1', ...
                  'FontSize', '10', ...
                  'ForegroundColor', 'green');
        fprintf('  ✓ Added label for Vd signal\n');
    catch ME
        fprintf('  ! Label already exists or error: %s\n', ME.message);
    end

    % 添加標註：Vm 供控制器使用
    try
        add_block('built-in/Note', [model_name '/Label_Vm_to_Controller'], ...
                  'Position', [1650, main_y-100], ...
                  'Text', 'Vm → Controller Input 2', ...
                  'FontSize', '10', ...
                  'ForegroundColor', 'green');
        fprintf('  ✓ Added label for Vm signal\n');
    catch ME
        fprintf('  ! Label already exists or error: %s\n', ME.message);
    end

    %% 更新主標註
    fprintf('\nStep 4: Updating model documentation...\n');

    try
        delete_block([model_name '/Label_Controller']);
    catch
        % 如果不存在就忽略
    end

    add_block('built-in/Note', [model_name '/Label_Controller_New'], ...
              'Position', [controller_area_x - 50, main_y-80], ...
              'Text', ['>>> INSERT CONTROLLER HERE <<<\n' ...
                       'Inputs: Vd (ref), Vm (measured)\n' ...
                       'Output: u (control)'], ...
              'FontSize', '12', ...
              'FontWeight', 'bold', ...
              'ForegroundColor', 'red');
    fprintf('  ✓ Updated controller interface label\n');

    % 更新主要資訊標註
    try
        delete_block([model_name '/Info']);
    catch
    end

    Ts = 1e-5;
    annotation_text = sprintf(['Control System Framework (Modified Controller Interface)\n' ...
                               'Modified: 2025-10-09\n\n' ...
                               '=== SIGNAL FLOW ===\n' ...
                               'Vd (6×1) ──┬──→ [Sum] ──→ (internal e)\n' ...
                               '           │\n' ...
                               '           └──→ [CONTROLLER] ──→ u ──→ [DAC] ──→ [Plant] ──→ [ADC] ──→ Vm (6×1)\n' ...
                               '                     ↑                                              │\n' ...
                               '                     └──────────────────────────────────────────────┘\n\n' ...
                               '=== CONTROLLER INTERFACE (MODIFIED) ===\n' ...
                               'INPUT 1:  Vd (6×1) - Reference signal\n' ...
                               'INPUT 2:  Vm (6×1) - Measured output\n' ...
                               'OUTPUT:   u  (6×1) - Control signal\n\n' ...
                               '=== MONITORING ===\n' ...
                               '- Scope_u, u_log:         Control signal\n' ...
                               '- Scope_e, e_log:         Error signal (from controller)\n' ...
                               '- Scope_Vm, Vm_log:       Measured output (digital)\n' ...
                               '- Vm_analog_log:          Analog output\n\n' ...
                               'Sample Time: %.0f μs (Fs = %.0f kHz)\n\n' ...
                               'NOTE: Error calculation (e = Vd - Vm) should be done inside controller'], ...
                               Ts*1e6, 1/Ts/1000);

    add_block('built-in/Note', [model_name '/Info'], ...
              'Position', [50, 700], ...
              'Text', annotation_text, ...
              'FontSize', '10', ...
              'FontWeight', 'bold');
    fprintf('  ✓ Updated model information annotation\n');

    %% 儲存模型
    fprintf('\nStep 5: Saving modified model...\n');
    save_system(model_name);
    fprintf('  ✓ Model saved: %s.slx\n', model_name);

    fprintf('\n=== Modification Complete ===\n');
    fprintf('\nController Interface Summary:\n');
    fprintf('  INPUT 1: Vd (6×1) - Reference signal (from Constant block "Vd")\n');
    fprintf('  INPUT 2: Vm (6×1) - Measured output (from "Mux_Vm")\n');
    fprintf('  OUTPUT:  u  (6×1) - Control signal (connect to "u_in")\n');
    fprintf('\nNext Steps:\n');
    fprintf('  1. Create controller model (e.g., PI_controller.slx)\n');
    fprintf('  2. Use setup_controller.m to integrate controller\n');
    fprintf('  3. Run simulation with example_run_PI.m\n');
    fprintf('\n');
end
