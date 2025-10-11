% layout_template.m
% Flux Controller 佈局模板
%
% 基於 Flux_Controller_Type3 的手動調整佈局
% 用於 Type 1, Type 2, Type 3 控制器的一致性佈局
%
% Author: Kevin (手動調整), Claude Code (記錄)
% Date: 2025-10-11

function layout = layout_template()
    % 定義佈局參數

    %% X 座標（水平分層）
    layout.x.input = 105;              % Layer 1: 輸入端口
    layout.x.error_calc = 290;         % Layer 2: 誤差計算
    layout.x.delays = 450;             % Layer 3: 延遲鏈起點
    layout.x.delays_2nd = 550;         % Layer 3: 第二級延遲
    layout.x.innovation = 470;         % Layer 3: 估測器創新項
    layout.x.est_gains = 565;          % Layer 4: 估測器增益
    layout.x.est_sum = 720;            % Layer 5: 估測器 Sum
    layout.x.est_delay = 780;          % Layer 5: 估測器 Delay
    layout.x.fb_gain_1 = 685;          % Layer 6: 反饋增益1
    layout.x.fb_gain_2 = 855;          % Layer 6: 反饋增益2
    layout.x.ff_gain_a1 = 820;         % Layer 6: 前饋增益 a1
    layout.x.ff_gain_a2 = 765;         % Layer 6: 前饋增益 a2
    layout.x.ff_fb_sum = 915;          % Layer 6: 前饋/反饋求和
    layout.x.control_sum = 1000;       % Layer 7: 控制律求和
    layout.x.b_inv = 1090;             % Layer 7: B⁻¹ 增益
    layout.x.output = 1185;            % Layer 8: 輸出端口

    %% Y 座標（垂直分區）
    % 輸入層
    layout.y.input_vd = 100;           % Vd 輸入
    layout.y.input_vm = 160;           % Vm 輸入

    % 誤差計算層（中央偏上）
    layout.y.error = 152;              % 誤差計算中心 Y

    % 前饋層（上方）
    layout.y.ff_vd_delay = 100;        % Vd 延遲鏈
    layout.y.ff_gain_a1 = 210;         % a1 增益
    layout.y.ff_gain_a2 = 280;         % a2 增益
    layout.y.ff_sum = 210;             % 前饋求和

    % 估測器層（中央）
    layout.y.innovation = 337;         % 創新項
    layout.y.est_l1 = 340;             % l1 增益
    layout.y.est_lambda_c = 390;       % λc 增益
    layout.y.est_l2 = 455;             % l2 增益
    layout.y.est_l3 = 540;             % l3 增益

    % 估測器狀態（垂直排列，間隔 100）
    layout.y.s1_center = 350;          % ŝ₁ 中心
    layout.y.s2_center = 450;          % ŝ₂ 中心
    layout.y.wt_center = 535;          % ŵT 中心

    % 反饋層（下方）
    layout.y.fb_gain_1 = 585;          % 反饋增益1
    layout.y.fb_gain_2 = 625;          % 反饋增益2
    layout.y.fb_sum = 592;             % 反饋求和

    % 控制律（中央）
    layout.y.control = 420;            % 控制律中心

    % 輸出層
    layout.y.output_u = 420;           % u 輸出（與控制律對齊）
    layout.y.output_e = 155;           % e 輸出（與誤差對齊）

    %% Block 尺寸標準
    % 小型 block (Gain, Sum, Delay)
    layout.size.small_width = 30;
    layout.size.small_height = 30;

    % 輸入/輸出端口
    layout.size.port_width = 30;
    layout.size.port_height = 20;

    %% 輔助函數：計算 block position
    % 使用方式：pos = get_block_position(center_x, center_y, width, height)

    %% 間隔標準
    layout.spacing.vertical_gap = 100;     % 估測器狀態間垂直間隔
    layout.spacing.horizontal_gap = 60;    % Sum → Delay 水平間隔
    layout.spacing.gain_vertical = 50;     % 增益模組垂直間隔

    %% 註解位置
    layout.annotation.info_x = 50;
    layout.annotation.info_y = 50;

    %% 說明
    fprintf('佈局模板已載入\n');
    fprintf('基於 Flux_Controller_Type3 的手動調整\n');
    fprintf('水平範圍: X = 105 ~ 1215\n');
    fprintf('垂直範圍: Y = 85 ~ 640\n');
    fprintf('\n');
    fprintf('使用方式:\n');
    fprintf('  layout = layout_template();\n');
    fprintf('  pos = [layout.x.input, layout.y.input_vd-10, ...];\n');
    fprintf('\n');
end

% 輔助函數：從中心點和尺寸計算 Position
function pos = center_to_position(center_x, center_y, width, height)
    % Simulink Position: [left, top, right, bottom]
    left = center_x - width/2;
    top = center_y - height/2;
    right = center_x + width/2;
    bottom = center_y + height/2;
    pos = [left, top, right, bottom];
end
