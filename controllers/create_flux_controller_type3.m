% create_flux_controller_type3.m
% 自動建立 Type 3 磁通控制器 Simulink 模型
%
% Type 3: 一階擾動模型（最簡單版本）
%   擾動模型: wT[k+1] = wT[k]
%   估測器增益: l1, l2, l3
%
% Controller Architecture:
%   Inputs:  Vd (6×1) - 參考訊號
%            Vm (6×1) - 測量輸出
%   Outputs: u  (6×1) - 控制訊號
%            e  (6×1) - 誤差訊號 δv[k] (監控用)
%
% Control Law:
%   u[k] = B⁻¹{vff[k] + δvfb[k] - ŵT[k]}
%
% Feedforward:
%   vff[k] = vd[k] - a1·vd[k-1] - a2·vd[k-2]
%
% Feedback:
%   δvfb[k] = (a1 - λc)·δv̂[k] + a2·δv̂[k-1]
%
% Estimator:
%   innovation[k] = δv[k] - ŝ₁[k]
%   ŝ₁[k+1] = λc·ŝ₁[k] + l1·innovation[k]
%   ŝ₂[k+1] = ŝ₁[k] + l2·innovation[k]
%   ŵT[k+1] = ŵT[k] + l3·innovation[k]
%
% Error:
%   δv[k] = vd[k-1] - vm[k]
%
% Parameters (from workspace):
%   a1, a2           - 系統參數
%   B_inv            - 控制矩陣的逆 (6×6)
%   lambda_c         - 控制特徵值
%   l1, l2, l3       - 估測器增益
%   fb_coeff_1       - 反饋係數 (a1 - λc)
%   fb_coeff_2       - 反饋係數 a2
%
% Usage:
%   create_flux_controller_type3()
%
% Author: Claude Code
% Date: 2025-10-11

function create_flux_controller_type3()
    %% Configuration
    model_name = 'Flux_Controller_Type3';

    fprintf('╔════════════════════════════════════════════════════════════╗\n');
    fprintf('║        Creating Flux Controller Type 3 Model              ║\n');
    fprintf('╚════════════════════════════════════════════════════════════╝\n');
    fprintf('\n');
    fprintf('Model: %s.slx\n', model_name);
    fprintf('Type: 一階擾動模型（最簡單版本）\n\n');

    %% Close and delete existing model
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
        fprintf('✓ 已關閉現有模型\n');
    end

    if exist([model_name '.slx'], 'file')
        delete([model_name '.slx']);
        fprintf('✓ 已刪除舊模型文件\n');
    end

    %% Create new model
    new_system(model_name);
    open_system(model_name);
    fprintf('✓ 建立新模型\n\n');

    %% Layout parameters - 使用 layout_template
    % 載入佈局模板（基於手動調整的 Flux_Controller_Type3）
    layout = layout_template();

    fprintf('✓ 載入佈局模板\n');

    %% Section 1: Input ports
    fprintf('▶ 建立輸入端口...\n');

    add_block('simulink/Sources/In1', [model_name '/Vd']);
    set_param([model_name '/Vd'], ...
        'Port', '1', ...
        'Position', [layout.x.input, layout.y.input_vd-10, ...
                     layout.x.input+30, layout.y.input_vd+10]);

    add_block('simulink/Sources/In1', [model_name '/Vm']);
    set_param([model_name '/Vm'], ...
        'Port', '2', ...
        'Position', [layout.x.input, layout.y.input_vm-10, ...
                     layout.x.input+30, layout.y.input_vm+10]);

    fprintf('  ✓ Vd, Vm\n');

    %% Section 2: Error calculation δv[k] = vd[k-1] - vm[k]
    fprintf('▶ 建立誤差計算...\n');

    % Vd 延遲一步
    add_block('simulink/Discrete/Unit Delay', [model_name '/Vd_Delay']);
    set_param([model_name '/Vd_Delay'], ...
        'SampleTime', 'Ts', ...
        'Position', [layout.x.delays, layout.y.ff_vd_delay-15, ...
                     layout.x.delays+30, layout.y.ff_vd_delay+15]);

    % 誤差計算 δv = vd[k-1] - vm[k]
    add_block('simulink/Math Operations/Sum', [model_name '/Error_Calc']);
    set_param([model_name '/Error_Calc'], ...
        'Inputs', '+-', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.error_calc, layout.y.error-15, ...
                     layout.x.error_calc+30, layout.y.error+15]);

    % 連接
    add_line(model_name, 'Vd/1', 'Vd_Delay/1', 'autorouting', 'on');
    add_line(model_name, 'Vd_Delay/1', 'Error_Calc/1', 'autorouting', 'on');
    add_line(model_name, 'Vm/1', 'Error_Calc/2', 'autorouting', 'on');

    fprintf('  ✓ δv[k] = vd[k-1] - vm[k]\n');

    %% Section 3: Feedforward term vff[k] = vd[k] - a1·vd[k-1] - a2·vd[k-2]
    fprintf('▶ 建立前饋項...\n');

    % Vd[k-1] 再延遲一步得到 Vd[k-2]
    add_block('simulink/Discrete/Unit Delay', [model_name '/Vd_Delay2']);
    set_param([model_name '/Vd_Delay2'], ...
        'SampleTime', 'Ts', ...
        'Position', [layout.x.delays_2nd, layout.y.ff_vd_delay-15, ...
                     layout.x.delays_2nd+30, layout.y.ff_vd_delay+15]);

    % Gain: -a1
    add_block('simulink/Math Operations/Gain', [model_name '/Gain_a1']);
    set_param([model_name '/Gain_a1'], ...
        'Gain', '-a1', ...
        'Position', [layout.x.ff_gain_a1, layout.y.ff_gain_a1-15, ...
                     layout.x.ff_gain_a1+30, layout.y.ff_gain_a1+15]);

    % Gain: -a2
    add_block('simulink/Math Operations/Gain', [model_name '/Gain_a2']);
    set_param([model_name '/Gain_a2'], ...
        'Gain', '-a2', ...
        'Position', [layout.x.ff_gain_a2, layout.y.ff_gain_a2-15, ...
                     layout.x.ff_gain_a2+30, layout.y.ff_gain_a2+15]);

    % Sum: vd[k] + (-a1)·vd[k-1] + (-a2)·vd[k-2]
    add_block('simulink/Math Operations/Sum', [model_name '/FF_Sum']);
    set_param([model_name '/FF_Sum'], ...
        'Inputs', '+++', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.ff_fb_sum, layout.y.ff_sum-15, ...
                     layout.x.ff_fb_sum+30, layout.y.ff_sum+15]);

    % 連接
    add_line(model_name, 'Vd_Delay/1', 'Vd_Delay2/1', 'autorouting', 'on');
    add_line(model_name, 'Vd_Delay/1', 'Gain_a1/1', 'autorouting', 'on');
    add_line(model_name, 'Vd_Delay2/1', 'Gain_a2/1', 'autorouting', 'on');
    add_line(model_name, 'Vd/1', 'FF_Sum/1', 'autorouting', 'on');
    add_line(model_name, 'Gain_a1/1', 'FF_Sum/2', 'autorouting', 'on');
    add_line(model_name, 'Gain_a2/1', 'FF_Sum/3', 'autorouting', 'on');

    fprintf('  ✓ vff[k] = vd[k] - a1·vd[k-1] - a2·vd[k-2]\n');

    %% Section 4: Estimator
    fprintf('▶ 建立估測器...\n');

    % Innovation: δv[k] - ŝ₁[k]
    add_block('simulink/Math Operations/Sum', [model_name '/Innovation']);
    set_param([model_name '/Innovation'], ...
        'Inputs', '+-', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.innovation, layout.y.innovation-15, ...
                     layout.x.innovation+30, layout.y.innovation+15]);

    % ŝ₁[k] 估測器
    % ŝ₁[k+1] = λc·ŝ₁[k] + l1·innovation[k]
    add_block('simulink/Math Operations/Gain', [model_name '/Gain_l1']);
    set_param([model_name '/Gain_l1'], ...
        'Gain', 'l1', ...
        'Position', [layout.x.est_gains, layout.y.est_l1-15, ...
                     layout.x.est_gains+30, layout.y.est_l1+15]);

    add_block('simulink/Math Operations/Gain', [model_name '/Gain_lambda_c']);
    set_param([model_name '/Gain_lambda_c'], ...
        'Gain', 'lambda_c', ...
        'Position', [layout.x.est_gains, layout.y.est_lambda_c-15, ...
                     layout.x.est_gains+30, layout.y.est_lambda_c+15]);

    add_block('simulink/Math Operations/Sum', [model_name '/S1_Sum']);
    set_param([model_name '/S1_Sum'], ...
        'Inputs', '++', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.est_sum, layout.y.s1_center-18, ...
                     layout.x.est_sum+30, layout.y.s1_center+13]);

    add_block('simulink/Discrete/Unit Delay', [model_name '/S1_Delay']);
    set_param([model_name '/S1_Delay'], ...
        'SampleTime', 'Ts', ...
        'InitialCondition', 'zeros(6,1)', ...
        'Position', [layout.x.est_delay, layout.y.s1_center-15, ...
                     layout.x.est_delay+30, layout.y.s1_center+15]);

    % ŝ₂[k] 估測器
    % ŝ₂[k+1] = ŝ₁[k] + l2·innovation[k]
    add_block('simulink/Math Operations/Gain', [model_name '/Gain_l2']);
    set_param([model_name '/Gain_l2'], ...
        'Gain', 'l2', ...
        'Position', [layout.x.est_gains, layout.y.est_l2-15, ...
                     layout.x.est_gains+30, layout.y.est_l2+15]);

    add_block('simulink/Math Operations/Sum', [model_name '/S2_Sum']);
    set_param([model_name '/S2_Sum'], ...
        'Inputs', '++', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.est_sum, layout.y.s2_center-18, ...
                     layout.x.est_sum+30, layout.y.s2_center+13]);

    add_block('simulink/Discrete/Unit Delay', [model_name '/S2_Delay']);
    set_param([model_name '/S2_Delay'], ...
        'SampleTime', 'Ts', ...
        'InitialCondition', 'zeros(6,1)', ...
        'Position', [layout.x.est_delay, layout.y.s2_center-15, ...
                     layout.x.est_delay+30, layout.y.s2_center+15]);

    % ŵT[k] 估測器
    % ŵT[k+1] = ŵT[k] + l3·innovation[k]
    add_block('simulink/Math Operations/Gain', [model_name '/Gain_l3']);
    set_param([model_name '/Gain_l3'], ...
        'Gain', 'l3', ...
        'Position', [layout.x.est_gains, layout.y.est_l3-15, ...
                     layout.x.est_gains+30, layout.y.est_l3+15]);

    add_block('simulink/Math Operations/Sum', [model_name '/WT_Sum']);
    set_param([model_name '/WT_Sum'], ...
        'Inputs', '++', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.est_sum, layout.y.wt_center-18, ...
                     layout.x.est_sum+30, layout.y.wt_center+13]);

    add_block('simulink/Discrete/Unit Delay', [model_name '/WT_Delay']);
    set_param([model_name '/WT_Delay'], ...
        'SampleTime', 'Ts', ...
        'InitialCondition', 'zeros(6,1)', ...
        'Position', [layout.x.est_delay, layout.y.wt_center-15, ...
                     layout.x.est_delay+30, layout.y.wt_center+15]);

    % 連接估測器
    add_line(model_name, 'Error_Calc/1', 'Innovation/1', 'autorouting', 'on');
    add_line(model_name, 'Innovation/1', 'Gain_l1/1', 'autorouting', 'on');
    add_line(model_name, 'Innovation/1', 'Gain_l2/1', 'autorouting', 'on');
    add_line(model_name, 'Innovation/1', 'Gain_l3/1', 'autorouting', 'on');

    % ŝ₁ 迴路
    add_line(model_name, 'Gain_l1/1', 'S1_Sum/1', 'autorouting', 'on');
    add_line(model_name, 'S1_Delay/1', 'Gain_lambda_c/1', 'autorouting', 'on');
    add_line(model_name, 'Gain_lambda_c/1', 'S1_Sum/2', 'autorouting', 'on');
    add_line(model_name, 'S1_Sum/1', 'S1_Delay/1', 'autorouting', 'on');
    add_line(model_name, 'S1_Delay/1', 'Innovation/2', 'autorouting', 'on');

    % ŝ₂ 迴路
    add_line(model_name, 'S1_Delay/1', 'S2_Sum/1', 'autorouting', 'on');
    add_line(model_name, 'Gain_l2/1', 'S2_Sum/2', 'autorouting', 'on');
    add_line(model_name, 'S2_Sum/1', 'S2_Delay/1', 'autorouting', 'on');

    % ŵT 迴路
    add_line(model_name, 'WT_Delay/1', 'WT_Sum/1', 'autorouting', 'on');
    add_line(model_name, 'Gain_l3/1', 'WT_Sum/2', 'autorouting', 'on');
    add_line(model_name, 'WT_Sum/1', 'WT_Delay/1', 'autorouting', 'on');

    fprintf('  ✓ 估測器: ŝ₁[k], ŝ₂[k], ŵT[k]\n');

    %% Section 5: Feedback term δvfb[k] = (a1-λc)·ŝ₁[k] + a2·ŝ₂[k]
    fprintf('▶ 建立反饋項...\n');

    add_block('simulink/Math Operations/Gain', [model_name '/FB_Gain1']);
    set_param([model_name '/FB_Gain1'], ...
        'Gain', 'fb_coeff_1', ...
        'Position', [layout.x.fb_gain_1, layout.y.fb_gain_1-15, ...
                     layout.x.fb_gain_1+30, layout.y.fb_gain_1+15]);

    add_block('simulink/Math Operations/Gain', [model_name '/FB_Gain2']);
    set_param([model_name '/FB_Gain2'], ...
        'Gain', 'fb_coeff_2', ...
        'Position', [layout.x.fb_gain_2, layout.y.fb_gain_2-15, ...
                     layout.x.fb_gain_2+30, layout.y.fb_gain_2+15]);

    add_block('simulink/Math Operations/Sum', [model_name '/FB_Sum']);
    set_param([model_name '/FB_Sum'], ...
        'Inputs', '++', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.ff_fb_sum, layout.y.fb_sum-15, ...
                     layout.x.ff_fb_sum+30, layout.y.fb_sum+15]);

    % 連接
    add_line(model_name, 'S1_Delay/1', 'FB_Gain1/1', 'autorouting', 'on');
    add_line(model_name, 'S2_Delay/1', 'FB_Gain2/1', 'autorouting', 'on');
    add_line(model_name, 'FB_Gain1/1', 'FB_Sum/1', 'autorouting', 'on');
    add_line(model_name, 'FB_Gain2/1', 'FB_Sum/2', 'autorouting', 'on');

    fprintf('  ✓ δvfb[k] = (a1-λc)·ŝ₁[k] + a2·ŝ₂[k]\n');

    %% Section 6: Control law u[k] = B⁻¹{vff + δvfb - ŵT}
    fprintf('▶ 建立控制律...\n');

    % Sum: vff + δvfb - ŵT
    add_block('simulink/Math Operations/Sum', [model_name '/Control_Sum']);
    set_param([model_name '/Control_Sum'], ...
        'Inputs', '++-', ...
        'IconShape', 'rectangular', ...
        'Position', [layout.x.control_sum, layout.y.control-15, ...
                     layout.x.control_sum+30, layout.y.control+15]);

    % Gain: B⁻¹
    add_block('simulink/Math Operations/Gain', [model_name '/B_inv_Gain']);
    set_param([model_name '/B_inv_Gain'], ...
        'Gain', 'B_inv', ...
        'Multiplication', 'Matrix(K*u)', ...
        'Position', [layout.x.b_inv, layout.y.control-15, ...
                     layout.x.b_inv+30, layout.y.control+15]);

    % 連接
    add_line(model_name, 'FF_Sum/1', 'Control_Sum/1', 'autorouting', 'on');
    add_line(model_name, 'FB_Sum/1', 'Control_Sum/2', 'autorouting', 'on');
    add_line(model_name, 'WT_Delay/1', 'Control_Sum/3', 'autorouting', 'on');
    add_line(model_name, 'Control_Sum/1', 'B_inv_Gain/1', 'autorouting', 'on');

    fprintf('  ✓ u[k] = B⁻¹{vff + δvfb - ŵT}\n');

    %% Section 7: Output ports
    fprintf('▶ 建立輸出端口...\n');

    % Output 1: u (control signal)
    add_block('simulink/Sinks/Out1', [model_name '/u']);
    set_param([model_name '/u'], ...
        'Port', '1', ...
        'Position', [layout.x.output, layout.y.output_u-10, ...
                     layout.x.output+30, layout.y.output_u+10]);

    % Output 2: e (error signal δv)
    add_block('simulink/Sinks/Out1', [model_name '/e']);
    set_param([model_name '/e'], ...
        'Port', '2', ...
        'Position', [layout.x.output, layout.y.output_e-10, ...
                     layout.x.output+30, layout.y.output_e+10]);

    % 連接
    add_line(model_name, 'B_inv_Gain/1', 'u/1', 'autorouting', 'on');
    add_line(model_name, 'Error_Calc/1', 'e/1', 'autorouting', 'on');

    fprintf('  ✓ u, e\n');

    %% Section 8: Annotations
    fprintf('▶ 添加註解...\n');

    annotation_text = sprintf(['Flux Controller Type 3 (一階擾動模型)\n' ...
                               'Created: 2025-10-11\n\n' ...
                               'INPUTS:\n' ...
                               '  Vd (6×1) - 參考訊號\n' ...
                               '  Vm (6×1) - 測量輸出\n\n' ...
                               'OUTPUTS:\n' ...
                               '  u (6×1) - 控制訊號\n' ...
                               '  e (6×1) - 誤差訊號 δv[k]\n\n' ...
                               'CONTROL LAW:\n' ...
                               '  u[k] = B⁻¹{vff[k] + δvfb[k] - ŵT[k]}\n\n' ...
                               'PARAMETERS (from workspace):\n' ...
                               '  a1, a2, B_inv, lambda_c, Ts\n' ...
                               '  l1, l2, l3 (estimator gains)\n' ...
                               '  fb_coeff_1, fb_coeff_2']);

    add_block('built-in/Note', [model_name '/Info'], ...
              'Position', [50, 50], ...
              'Text', annotation_text, ...
              'FontSize', '9');

    fprintf('  ✓ 註解\n');

    %% Save model
    fprintf('\n▶ 儲存模型...\n');
    save_system(model_name);

    fprintf('\n');
    fprintf('╔════════════════════════════════════════════════════════════╗\n');
    fprintf('║                   模型建立完成！                           ║\n');
    fprintf('╚════════════════════════════════════════════════════════════╝\n');
    fprintf('\n');
    fprintf('模型檔案: %s.slx\n', model_name);
    fprintf('\n');
    fprintf('結構摘要:\n');
    fprintf('  • 輸入: Vd (6×1), Vm (6×1)\n');
    fprintf('  • 輸出: u (6×1), e (6×1)\n');
    fprintf('  • 估測器狀態: ŝ₁, ŝ₂, ŵT\n');
    fprintf('  • 擾動模型: 一階 (wT[k+1] = wT[k])\n');
    fprintf('\n');
    fprintf('下一步:\n');
    fprintf('  1. 執行 calculate_flux_controller_params.m 計算參數\n');
    fprintf('  2. 使用 example_flux_controller_type3.m 測試控制器\n');
    fprintf('  3. 整合到 Control_System_Framework.slx\n');
    fprintf('\n');
end
