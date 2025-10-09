% analyze_plant_frequency.m
% 分析 Plant 的頻率響應特性
%
% 功能：
%   1. 繪製 Plant 的 Bode 圖
%   2. 計算關鍵頻域參數（截止頻率、相位裕度等）
%   3. 為 PI 控制器設計提供依據
%
% 使用方法：
%   analyze_plant_frequency()         % 使用預設通道 (1,1)
%   analyze_plant_frequency(ch_out, ch_in)  % 指定通道
%
% Author: Claude Code
% Date: 2025-10-09

function plant_info = analyze_plant_frequency(ch_out, ch_in)
    %% 參數設定
    if nargin < 1
        ch_out = 1;  % 預設輸出通道
    end
    if nargin < 2
        ch_in = 1;   % 預設輸入通道
    end

    fprintf('╔════════════════════════════════════════════════════════════╗\n');
    fprintf('║         Plant Frequency Response Analysis                  ║\n');
    fprintf('╚════════════════════════════════════════════════════════════╝\n');
    fprintf('\nAnalyzing Channel: Output=%d, Input=%d\n\n', ch_out, ch_in);

    %% 載入系統模型參數
    fprintf('▶ Step 1: Loading Plant Model Parameters\n');
    fprintf('───────────────────────────────────────────────────────────\n');

    % 檢查是否有 36 通道擬合結果
    if exist('one_curve_36_results.mat', 'file')
        load('one_curve_36_results.mat', 'one_curve_results');
        a1 = one_curve_results.a1_matrix(ch_out, ch_in);
        a2 = one_curve_results.a2_matrix(ch_out, ch_in);
        b  = one_curve_results.b_matrix(ch_out, ch_in);
        fprintf('  ✓ Loaded from one_curve_36_results.mat\n');
    else
        % 如果沒有，執行 Model_6_6_Continuous_Weighted.m
        fprintf('  ! one_curve_36_results.mat not found\n');
        fprintf('  ⚙ Running Model_6_6_Continuous_Weighted.m to generate data...\n');

        % 暫存當前變數
        current_vars = who;

        % 執行主腳本（需要修改為生成單通道結果）
        run('Model_6_6_Continuous_Weighted.m');

        % 從結果中提取參數
        if exist('one_curve_results', 'var')
            a1 = one_curve_results.a1_matrix(ch_out, ch_in);
            a2 = one_curve_results.a2_matrix(ch_out, ch_in);
            b  = one_curve_results.b_matrix(ch_out, ch_in);
        else
            error('Failed to load plant parameters. Please run Model_6_6_Continuous_Weighted.m first.');
        end
    end

    % 建立 Plant 傳遞函數
    G = tf(b, [1, a1, a2]);

    fprintf('\nPlant Transfer Function G(s):\n');
    fprintf('  G(s) = %.6e / (s² + %.6e·s + %.6e)\n', b, a1, a2);

    %% 計算系統特性參數
    fprintf('\n▶ Step 2: Computing System Characteristics\n');
    fprintf('───────────────────────────────────────────────────────────\n');

    % 自然頻率和阻尼比
    wn = sqrt(a2);                  % 自然頻率 [rad/s]
    zeta = a1 / (2 * wn);          % 阻尼比

    % DC 增益
    dc_gain = b / a2;
    dc_gain_dB = 20*log10(abs(dc_gain));

    % 極點
    poles = roots([1, a1, a2]);

    fprintf('System Parameters:\n');
    fprintf('  Natural frequency (ωn):    %.4f rad/s  (%.4f Hz)\n', wn, wn/(2*pi));
    fprintf('  Damping ratio (ζ):         %.4f\n', zeta);
    fprintf('  DC gain:                   %.4e  (%.2f dB)\n', dc_gain, dc_gain_dB);
    fprintf('  Poles:                     %.4f ± %.4fj\n', real(poles(1)), abs(imag(poles(1))));

    % 判斷系統類型
    if zeta < 1
        fprintf('  System type:               Underdamped (振盪系統)\n');
    elseif zeta == 1
        fprintf('  System type:               Critically damped (臨界阻尼)\n');
    else
        fprintf('  System type:               Overdamped (過阻尼)\n');
    end

    %% Bode 圖分析
    fprintf('\n▶ Step 3: Frequency Response Analysis (Bode Plot)\n');
    fprintf('───────────────────────────────────────────────────────────\n');

    % 頻率範圍（從 0.1 Hz 到 10 kHz）
    freq_range = logspace(-1, 4, 1000);  % Hz
    w_range = 2*pi*freq_range;           % rad/s

    % 計算頻率響應
    [mag, phase, wout] = bode(G, w_range);
    mag = squeeze(mag);
    phase = squeeze(phase);
    mag_dB = 20*log10(mag);

    % 找到關鍵頻率點
    % 1. -3dB 頻寬（截止頻率的定義之一）
    idx_3dB = find(mag_dB <= (dc_gain_dB - 3), 1, 'first');
    if ~isempty(idx_3dB)
        w_3dB = wout(idx_3dB);
        f_3dB = w_3dB / (2*pi);
        fprintf('  -3dB Bandwidth:            %.4f rad/s  (%.4f Hz)\n', w_3dB, f_3dB);
    else
        w_3dB = NaN;
        fprintf('  -3dB Bandwidth:            Not found in range\n');
    end

    % 2. 0 dB 截止頻率（如果 DC gain > 0 dB）
    if dc_gain_dB > 0
        idx_0dB = find(mag_dB <= 0, 1, 'first');
        if ~isempty(idx_0dB)
            w_0dB = wout(idx_0dB);
            f_0dB = w_0dB / (2*pi);
            phase_at_0dB = phase(idx_0dB);
            fprintf('  0 dB Crossover:            %.4f rad/s  (%.4f Hz)\n', w_0dB, f_0dB);
            fprintf('  Phase at 0 dB:             %.2f deg\n', phase_at_0dB);
        else
            fprintf('  0 dB Crossover:            Not found (DC gain too low)\n');
        end
    else
        fprintf('  0 dB Crossover:            N/A (DC gain < 0 dB)\n');
    end

    % 3. -180° 相位穿越頻率
    idx_180 = find(phase <= -180, 1, 'first');
    if ~isempty(idx_180)
        w_180 = wout(idx_180);
        f_180 = w_180 / (2*pi);
        mag_at_180 = mag_dB(idx_180);
        fprintf('  -180° Phase crossover:     %.4f rad/s  (%.4f Hz)\n', w_180, f_180);
        fprintf('  Gain at -180°:             %.2f dB\n', mag_at_180);
    else
        fprintf('  -180° Phase crossover:     Not found in range\n');
    end

    %% 繪製 Bode 圖
    fprintf('\n▶ Step 4: Plotting Bode Diagram\n');
    fprintf('───────────────────────────────────────────────────────────\n');

    figure('Name', sprintf('Plant Bode Plot - Ch(%d,%d)', ch_out, ch_in), ...
           'Position', [100, 100, 1000, 800]);

    % 幅度圖
    subplot(2, 1, 1);
    semilogx(freq_range, mag_dB, 'b-', 'LineWidth', 2.5);
    hold on;
    grid on;

    % 標記關鍵點
    if ~isnan(w_3dB)
        semilogx(f_3dB, dc_gain_dB - 3, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        text(f_3dB*1.3, dc_gain_dB - 3, sprintf('  -3dB: %.2f Hz', f_3dB), ...
             'FontSize', 12, 'Color', 'r');
    end

    % 0 dB 線
    yline(0, 'k--', 'LineWidth', 1.5);

    xlabel('Frequency (Hz)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Magnitude (dB)', 'FontSize', 14, 'FontWeight', 'bold');
    title(sprintf('Plant G(s) - Channel (%d,%d) - Magnitude', ch_out, ch_in), ...
          'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);

    % 相位圖
    subplot(2, 1, 2);
    semilogx(freq_range, phase, 'b-', 'LineWidth', 2.5);
    hold on;
    grid on;

    % -180° 線
    yline(-180, 'k--', 'LineWidth', 1.5);

    % 標記關鍵點
    if ~isempty(idx_180)
        semilogx(f_180, -180, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        text(f_180*1.3, -180, sprintf('  -180°: %.2f Hz', f_180), ...
             'FontSize', 12, 'Color', 'r');
    end

    xlabel('Frequency (Hz)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Phase (deg)', 'FontSize', 14, 'FontWeight', 'bold');
    title('Phase Response', 'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);
    ylim([-200, 0]);

    %% 控制器設計建議
    fprintf('\n▶ Step 5: Controller Design Recommendations\n');
    fprintf('───────────────────────────────────────────────────────────\n');

    fprintf('\nBased on plant characteristics:\n\n');

    % 建議的截止頻率範圍
    wc_min = wn / 5;      % 保守：自然頻率的 1/5
    wc_max = wn * 2;      % 激進：自然頻率的 2 倍
    wc_nominal = wn;      % 標稱值：等於自然頻率

    fprintf('1. Crossover Frequency (ωc) Selection:\n');
    fprintf('   Conservative: ωc = %.2f rad/s  (%.2f Hz)\n', wc_min, wc_min/(2*pi));
    fprintf('   Nominal:      ωc = %.2f rad/s  (%.2f Hz)  ← Recommended\n', wc_nominal, wc_nominal/(2*pi));
    fprintf('   Aggressive:   ωc = %.2f rad/s  (%.2f Hz)\n', wc_max, wc_max/(2*pi));

    fprintf('\n2. Phase Margin (PM) Target:\n');
    fprintf('   PM = 45° → Overshoot ~20%%\n');
    fprintf('   PM = 60° → Overshoot ~10%%  ← Recommended\n');
    fprintf('   PM = 70° → Overshoot ~5%%\n');

    fprintf('\n3. Design Guidelines:\n');
    fprintf('   • 選擇 ωc 使得閉環響應比開環快 2~5 倍\n');
    fprintf('   • PI 控制器在 ωc 處提供足夠的相位補償\n');
    fprintf('   • 檢查增益裕度 GM > 6 dB\n');

    %% 儲存結果
    plant_info.transfer_function = G;
    plant_info.params.a1 = a1;
    plant_info.params.a2 = a2;
    plant_info.params.b = b;
    plant_info.params.wn = wn;
    plant_info.params.zeta = zeta;
    plant_info.params.dc_gain = dc_gain;
    plant_info.params.poles = poles;

    plant_info.frequency.w_3dB = w_3dB;
    plant_info.frequency.w_nominal = wc_nominal;
    plant_info.frequency.w_min = wc_min;
    plant_info.frequency.w_max = wc_max;

    plant_info.bode.freq = freq_range;
    plant_info.bode.mag_dB = mag_dB;
    plant_info.bode.phase = phase;

    fprintf('\n✓ Analysis complete! Plant info stored in output structure.\n');
    fprintf('\nNext Step: Use design_PI_frequency.m to design controller\n');
    fprintf('───────────────────────────────────────────────────────────\n');
end
