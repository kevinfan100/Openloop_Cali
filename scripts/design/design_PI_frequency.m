% design_PI_frequency.m
% 基於頻域規格設計 PI 控制器
%
% 設計方法：Loop Shaping (開環整形法)
%   1. 給定期望的截止頻率 ωc 和相位裕度 PM
%   2. 反推 PI 控制器參數 Kp 和 Ki
%   3. 驗證閉環性能
%
% PI 控制器傳遞函數：
%   C(s) = Kp + Ki/s = Kp·(1 + 1/(Ti·s))
%   其中 Ti = Kp/Ki 為積分時間常數
%
% 開環傳遞函數：
%   L(s) = C(s)·G(s)
%
% 頻域設計目標：
%   |L(jωc)| = 1  (0 dB)        → 決定響應速度
%   ∠L(jωc) = -180° + PM        → 決定穩定性和超調
%
% 使用方法：
%   [Kp, Ki] = design_PI_frequency(plant_info, wc_desired, PM_desired)
%   [Kp, Ki] = design_PI_frequency(plant_info, wc_desired, PM_desired, options)
%
% 輸入：
%   plant_info    - Plant 分析結果（來自 analyze_plant_frequency.m）
%   wc_desired    - 期望截止頻率 [rad/s]
%   PM_desired    - 期望相位裕度 [deg]（預設 60°）
%   options       - 選項結構（可選）
%
% 輸出：
%   Kp, Ki        - PI 控制器參數
%   design_info   - 設計資訊結構
%
% Author: Claude Code
% Date: 2025-10-09

function [Kp, Ki, design_info] = design_PI_frequency(plant_info, wc_desired, PM_desired, options)
    %% 參數處理
    if nargin < 3
        PM_desired = 60;  % 預設相位裕度 60°
    end

    if nargin < 4
        options = struct();
    end

    % 設定預設選項
    if ~isfield(options, 'show_plot')
        options.show_plot = true;
    end
    if ~isfield(options, 'verbose')
        options.verbose = true;
    end
    if ~isfield(options, 'method')
        options.method = 'analytical';  % 'analytical' 或 'iterative'
    end

    %% 顯示設計規格
    if options.verbose
        fprintf('╔════════════════════════════════════════════════════════════╗\n');
        fprintf('║         PI Controller Frequency Domain Design              ║\n');
        fprintf('╚════════════════════════════════════════════════════════════╝\n');
        fprintf('\nDesign Specifications:\n');
        fprintf('  Crossover Frequency (ωc): %.2f rad/s  (%.2f Hz)\n', ...
                wc_desired, wc_desired/(2*pi));
        fprintf('  Phase Margin (PM):        %.1f deg\n', PM_desired);
        fprintf('  Design Method:            %s\n', options.method);
        fprintf('\n');
    end

    %% 提取 Plant 資訊
    G = plant_info.transfer_function;
    a1 = plant_info.params.a1;
    a2 = plant_info.params.a2;
    b  = plant_info.params.b;

    %% 計算 Plant 在 ωc 處的頻率響應
    s_wc = 1j * wc_desired;
    G_wc = freqresp(G, wc_desired);
    G_wc = G_wc(1);  % 提取標量值

    mag_G_wc = abs(G_wc);
    phase_G_wc = angle(G_wc) * 180/pi;  % 轉為角度

    if options.verbose
        fprintf('▶ Step 1: Plant Response at ωc\n');
        fprintf('───────────────────────────────────────────────────────────\n');
        fprintf('  G(jωc):    %.4e ∠ %.2f°\n', mag_G_wc, phase_G_wc);
        fprintf('  |G(jωc)|:  %.4e  (%.2f dB)\n', mag_G_wc, 20*log10(mag_G_wc));
        fprintf('\n');
    end

    %% PI 控制器設計
    if strcmp(options.method, 'analytical')
        %% === 方法 1: 解析法 ===
        %
        % PI 控制器： C(s) = Kp + Ki/s = Kp·(s + Ki/Kp)/s
        %
        % 設計步驟：
        % 1. 期望相位： phase_C_wc + phase_G_wc = -180° + PM
        % 2. 期望增益： |C(jωc)|·|G(jωc)| = 1
        %
        % PI 相位公式：
        %   ∠C(jω) = atan(Ki/(Kp·ω)) - 90°
        %          = atan(1/(Ti·ω)) - 90°    (Ti = Kp/Ki)
        %
        % 從相位條件求 Ti：
        %   atan(1/(Ti·ωc)) - 90° = (-180° + PM) - phase_G_wc
        %   atan(1/(Ti·ωc)) = -90° + PM - phase_G_wc

        if options.verbose
            fprintf('▶ Step 2: Analytical PI Design\n');
            fprintf('───────────────────────────────────────────────────────────\n');
        end

        % 計算所需的 PI 相位
        phase_C_needed = (-180 + PM_desired) - phase_G_wc;  % deg

        if options.verbose
            fprintf('  Required phase from PI:  %.2f deg\n', phase_C_needed);
        end

        % 從相位求積分時間常數 Ti
        % atan(1/(Ti·ωc)) = phase_C_needed + 90°
        angle_rad = (phase_C_needed + 90) * pi/180;

        if abs(angle_rad) > pi/2 - 0.01
            warning('Required phase compensation exceeds PI capability!');
            fprintf('  ! Warning: phase_C_needed = %.2f° is too large\n', phase_C_needed);
            fprintf('  ! Consider reducing PM or increasing ωc\n\n');
        end

        Ti = 1 / (wc_desired * tan(angle_rad));

        if Ti < 0
            error('Negative Ti computed! Design infeasible. Reduce PM or ωc.');
        end

        if options.verbose
            fprintf('  Integral time (Ti):      %.4e s\n', Ti);
        end

        % 從幅度條件求 Kp
        % |C(jωc)|·|G(jωc)| = 1
        % |C(jωc)| = |Kp + Ki/jωc| = |Kp - j·Kp/Ti/ωc|
        %          = Kp·sqrt(1 + 1/(Ti·ωc)²)

        mag_C_wc = sqrt(1 + 1/(Ti * wc_desired)^2);
        Kp = 1 / (mag_G_wc * mag_C_wc);

        if Kp < 0
            error('Negative Kp computed! Design error.');
        end

        % 計算 Ki
        Ki = Kp / Ti;

        if options.verbose
            fprintf('  Proportional gain (Kp):  %.4e\n', Kp);
            fprintf('  Integral gain (Ki):      %.4e\n', Ki);
            fprintf('\n');
        end

    else
        %% === 方法 2: 迭代法 (Numerical Optimization) ===
        if options.verbose
            fprintf('▶ Step 2: Iterative PI Design (Optimization)\n');
            fprintf('───────────────────────────────────────────────────────────\n');
        end

        % 定義目標函數
        % 目標：最小化 (|L(jωc)| - 1)² + (∠L(jωc) - (-180° + PM))²
        objective = @(x) pi_design_objective(x, G, wc_desired, PM_desired);

        % 初始猜測（使用簡化公式）
        Kp0 = 1 / mag_G_wc;
        Ki0 = Kp0 * wc_desired / 10;  % Ti ≈ 10/ωc
        x0 = [Kp0; Ki0];

        % 約束：Kp > 0, Ki > 0
        lb = [1e-6; 1e-6];
        ub = [1e6; 1e6];

        % 優化選項
        opt_options = optimoptions('fmincon', ...
            'Display', 'off', ...
            'MaxFunctionEvaluations', 5000);

        % 執行優化
        [x_opt, fval] = fmincon(objective, x0, [], [], [], [], lb, ub, [], opt_options);

        Kp = x_opt(1);
        Ki = x_opt(2);

        if options.verbose
            fprintf('  Optimization converged with cost = %.4e\n', fval);
            fprintf('  Proportional gain (Kp):  %.4e\n', Kp);
            fprintf('  Integral gain (Ki):      %.4e\n', Ki);
            fprintf('\n');
        end
    end

    %% 驗證設計結果
    if options.verbose
        fprintf('▶ Step 3: Design Verification\n');
        fprintf('───────────────────────────────────────────────────────────\n');
    end

    % 建立 PI 控制器
    C = tf([Kp, Ki], [1, 0]);  % C(s) = (Kp·s + Ki)/s

    % 開環傳遞函數
    L = C * G;

    % 計算實際的頻域特性
    [Gm, Pm, Wcg, Wcp] = margin(L);

    Gm_dB = 20*log10(Gm);

    % 在 ωc 處的實際值
    L_wc = freqresp(L, wc_desired);
    L_wc = L_wc(1);
    mag_L_wc = abs(L_wc);
    mag_L_wc_dB = 20*log10(mag_L_wc);
    phase_L_wc = angle(L_wc) * 180/pi;

    % 實際相位裕度（在實際截止頻率處）
    PM_actual = 180 + phase_L_wc;

    if options.verbose
        fprintf('Achieved Performance:\n');
        fprintf('  At ωc = %.2f rad/s:\n', wc_desired);
        fprintf('    |L(jωc)|:           %.4f  (%.2f dB) [Target: 0 dB]\n', ...
                mag_L_wc, mag_L_wc_dB);
        fprintf('    ∠L(jωc):           %.2f deg [Target: %.2f deg]\n', ...
                phase_L_wc, -180 + PM_desired);
        fprintf('    Phase Margin:      %.2f deg [Target: %.2f deg]\n', ...
                PM_actual, PM_desired);
        fprintf('\n');

        fprintf('Stability Margins (from MATLAB margin()):\n');
        fprintf('  Gain Margin (GM):      %.2f dB  (at %.2f rad/s)\n', Gm_dB, Wcg);
        fprintf('  Phase Margin (PM):     %.2f deg  (at %.2f rad/s)\n', Pm, Wcp);
        fprintf('\n');

        % 性能預測（基於相位裕度）
        if Pm >= 60
            fprintf('  Expected overshoot:    < 10%% (Good)\n');
        elseif Pm >= 45
            fprintf('  Expected overshoot:    10~20%% (Acceptable)\n');
        else
            fprintf('  Expected overshoot:    > 20%% (May need tuning)\n');
        end
    end

    %% 繪製 Bode 圖
    if options.show_plot
        if options.verbose
            fprintf('\n▶ Step 4: Plotting Frequency Response\n');
            fprintf('───────────────────────────────────────────────────────────\n');
        end

        figure('Name', 'PI Controller - Frequency Domain Design', ...
               'Position', [100, 100, 1200, 900]);

        % 頻率範圍
        freq_range = logspace(-2, 4, 1000);  % 0.01 Hz ~ 10 kHz

        % === 子圖 1: Plant G(s) ===
        subplot(3, 2, 1);
        bode(G, 2*pi*freq_range);
        grid on;
        title('Plant G(s)', 'FontSize', 14, 'FontWeight', 'bold');

        % === 子圖 2: Controller C(s) ===
        subplot(3, 2, 2);
        bode(C, 2*pi*freq_range);
        grid on;
        title('PI Controller C(s)', 'FontSize', 14, 'FontWeight', 'bold');

        % === 子圖 3 & 4: Open-loop L(s) = C(s)·G(s) ===
        subplot(3, 2, [3, 4]);
        h = bodeplot(L, 2*pi*freq_range);
        grid on;
        setoptions(h, 'FreqUnits', 'Hz');

        % 標記截止頻率
        hold on;

        title('Open-Loop L(s) = C(s)·G(s)', 'FontSize', 14, 'FontWeight', 'bold');

        % === 子圖 5 & 6: Closed-loop T(s) = L(s)/(1+L(s)) ===
        T = feedback(L, 1);
        subplot(3, 2, [5, 6]);
        bode(T, 2*pi*freq_range);
        grid on;
        title('Closed-Loop T(s) = L(s)/(1+L(s))', 'FontSize', 14, 'FontWeight', 'bold');

        % 總標題
        sgtitle(sprintf('PI Design: Kp=%.3e, Ki=%.3e | ωc=%.2f Hz, PM=%.1f°', ...
                Kp, Ki, wc_desired/(2*pi), Pm), ...
                'FontSize', 16, 'FontWeight', 'bold');
    end

    %% 儲存設計結果
    design_info.controller = C;
    design_info.open_loop = L;
    design_info.closed_loop = feedback(L, 1);

    design_info.params.Kp = Kp;
    design_info.params.Ki = Ki;
    design_info.params.Ti = Kp / Ki;

    design_info.specs.wc_desired = wc_desired;
    design_info.specs.PM_desired = PM_desired;

    design_info.achieved.wc_actual = Wcp;
    design_info.achieved.PM_actual = Pm;
    design_info.achieved.GM_actual_dB = Gm_dB;
    design_info.achieved.Wcg = Wcg;

    design_info.plant = plant_info;

    if options.verbose
        fprintf('\n✓ PI Controller Design Complete!\n');
        fprintf('───────────────────────────────────────────────────────────\n');
        fprintf('\nDesigned Parameters:\n');
        fprintf('  Kp = %.6e\n', Kp);
        fprintf('  Ki = %.6e\n', Ki);
        fprintf('  Ti = Kp/Ki = %.6e s\n', Kp/Ki);
        fprintf('\nNext: Test with run_simulation() or example_run_PI.m\n');
    end
end

%% Helper Function: Optimization Objective
function cost = pi_design_objective(x, G, wc, PM_target)
    % 目標函數：最小化開環響應與期望規格的偏差
    Kp = x(1);
    Ki = x(2);

    % 建立 PI 控制器
    C = tf([Kp, Ki], [1, 0]);
    L = C * G;

    % 計算 L(jωc)
    L_wc = freqresp(L, wc);
    L_wc = L_wc(1);

    mag_error = (abs(L_wc) - 1)^2;              % |L(jωc)| = 1
    phase_error = (angle(L_wc)*180/pi + 180 - PM_target)^2;  % ∠L = -180° + PM

    % 總代價
    cost = mag_error + 0.01 * phase_error;  % 加權
end
