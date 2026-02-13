function fig = plot_bode(frequencies, magnitudes, phases, varargin)
%PLOT_BODE 標準化波德圖繪製公版
%
% 繪製風格參考 run_inner_loop_bode.m，適用於 6 通道系統
%
% 使用方式:
%   fig = plot_bode(frequencies, magnitudes, phases)
%   fig = plot_bode(frequencies, magnitudes, phases, 'Name', 'Value', ...)
%
% 輸入:
%   frequencies   - 頻率向量 [Hz] (1 x N)
%   magnitudes    - 線性幅值矩陣 (6 x N) 或 (1 x N)
%   phases        - 相位矩陣 [deg] (6 x N) 或 (1 x N)
%
% 選項 (Name-Value pairs):
%   'Title'           - 圖標題 (default: '')
%   'ExcitedChannel'  - 激勵通道 1-6 (default: 0, 不標記)
%   'ShowTheory'      - 是否顯示理論曲線 (default: false)
%   'TheoryMag'       - 理論幅值向量 (requires ShowTheory)
%   'TheoryPhase'     - 理論相位向量 (requires ShowTheory)
%   'TheoryFreq'      - 理論頻率向量 (requires ShowTheory)
%   'MagRange'        - 幅值 Y 軸範圍 [min, max] (default: [0, 1.25])
%   'LogScale'        - 使用對數頻率軸 (default: true)
%   'SavePath'        - 保存路徑 (default: '', 不保存)
%   'Resolution'      - 保存解析度 DPI (default: 300)
%   'FigPosition'     - 圖形位置 [x, y, w, h] (default: [100, 100, 1200, 800])
%
% 輸出:
%   fig - figure handle
%
% 繪圖風格特點:
%   - 線寬: 3.5
%   - 標記大小: 9
%   - 字體大小: 18-22
%   - 座標軸線寬: 2.5
%   - X 軸刻度: 10^0, 10^1, 10^2, ...
%   - 圖例: 上方水平排列

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'frequencies', @isnumeric);
    addRequired(p, 'magnitudes', @isnumeric);
    addRequired(p, 'phases', @isnumeric);
    addParameter(p, 'Title', '', @ischar);
    addParameter(p, 'ExcitedChannel', 0, @(x) isnumeric(x) && x >= 0 && x <= 6);
    addParameter(p, 'ShowTheory', false, @islogical);
    addParameter(p, 'TheoryMag', [], @isnumeric);
    addParameter(p, 'TheoryPhase', [], @isnumeric);
    addParameter(p, 'TheoryFreq', [], @isnumeric);
    addParameter(p, 'MagRange', [0, 1.25], @(x) isnumeric(x) && length(x) == 2);
    addParameter(p, 'LogScale', true, @islogical);
    addParameter(p, 'SavePath', '', @ischar);
    addParameter(p, 'Resolution', 300, @isnumeric);
    addParameter(p, 'FigPosition', [100, 100, 1200, 800], @(x) isnumeric(x) && length(x) == 4);

    parse(p, frequencies, magnitudes, phases, varargin{:});
    opts = p.Results;

    %% 顏色和樣式配置 (參考 run_inner_loop_bode.m)

    % 通道顏色 (P1-P6)
    channel_colors = [
        0.0000, 0.0000, 0.5000;  % P1: 深藍色
        0.0000, 0.0000, 1.0000;  % P2: 藍色
        0.0000, 0.5000, 0.0000;  % P3: 綠色
        1.0000, 0.0000, 0.0000;  % P4: 紅色
        0.8000, 0.0000, 0.8000;  % P5: 粉紫色
        0.0000, 0.7500, 0.7500;  % P6: 青色
    ];

    % 理論/擬合曲線顏色
    theory_color = [0.5, 0.5, 0.5];  % 中灰色

    % 標記符號
    markers = {'o', 's', '^', 'd', 'v', 'p'};  % P1-P6: 圓形、方形、上三角、菱形、下三角、五角星

    % 統一樣式參數
    unified_linewidth = 3.5;
    unified_markersize = 9;

    %% 確定通道數量
    [num_channels, num_freq] = size(magnitudes);
    if num_channels == 1
        % 單通道數據，轉置確保正確維度
        if length(frequencies) ~= num_freq
            magnitudes = magnitudes';
            phases = phases';
            [num_channels, num_freq] = size(magnitudes);
        end
    end

    % 限制最多 6 通道
    num_channels = min(num_channels, 6);

    %% 創建圖形
    fig = figure('Name', 'Bode Plot', 'Position', opts.FigPosition);

    %% ===== 上圖：Magnitude =====
    subplot('Position', [0.1, 0.55, 0.85, 0.35]);
    hold on; grid off;

    % 儲存 plot handles 以便圖例
    plot_handles_mag = gobjects(num_channels, 1);
    legend_labels = cell(num_channels, 1);

    % 先畫理論曲線（底層）
    plot_handle_theory = [];
    if opts.ShowTheory && ~isempty(opts.TheoryMag)
        theory_freq = opts.TheoryFreq;
        if isempty(theory_freq)
            theory_freq = frequencies;
        end

        if opts.LogScale
            plot_handle_theory = semilogx(theory_freq, opts.TheoryMag, '-', ...
                'LineWidth', unified_linewidth, ...
                'Color', theory_color, ...
                'DisplayName', 'Theory/Fitted');
        else
            plot_handle_theory = plot(theory_freq, opts.TheoryMag, '-', ...
                'LineWidth', unified_linewidth, ...
                'Color', theory_color, ...
                'DisplayName', 'Theory/Fitted');
        end
    end

    % 畫實驗曲線
    for ch = 1:num_channels
        mag = magnitudes(ch, :);

        % 設定圖例標籤
        if ch == opts.ExcitedChannel
            legend_labels{ch} = sprintf('P%d (Excited)', ch);
        else
            legend_labels{ch} = sprintf('P%d', ch);
        end

        % 繪製（虛線 + 標記）
        if opts.LogScale
            plot_handles_mag(ch) = semilogx(frequencies, mag, ['--' markers{ch}], ...
                'LineWidth', unified_linewidth, ...
                'Color', channel_colors(ch, :), ...
                'MarkerFaceColor', 'none', ...
                'MarkerEdgeColor', channel_colors(ch, :), ...
                'MarkerSize', unified_markersize, ...
                'DisplayName', legend_labels{ch});
        else
            plot_handles_mag(ch) = plot(frequencies, mag, ['--' markers{ch}], ...
                'LineWidth', unified_linewidth, ...
                'Color', channel_colors(ch, :), ...
                'MarkerFaceColor', 'none', ...
                'MarkerEdgeColor', channel_colors(ch, :), ...
                'MarkerSize', unified_markersize, ...
                'DisplayName', legend_labels{ch});
        end
    end

    % 設定 Y 軸
    ylim(opts.MagRange);
    yticks(linspace(opts.MagRange(1), opts.MagRange(2), 6));
    ylabel('Magnitude', 'FontSize', 22, 'FontWeight', 'bold');

    % 設定 X 軸
    xlim([frequencies(1), frequencies(end)]);

    % 設定座標軸格式
    ax1 = gca;
    if opts.LogScale
        ax1.XScale = 'log';
        ax1.XTick = [1, 10, 100, 1000, 10000];
        ax1.XTickLabel = {'10^0', '10^1', '10^2', '10^3', '10^4'};
    end
    ax1.FontSize = 18;
    ax1.FontWeight = 'bold';
    ax1.LineWidth = 2.5;
    ax1.Box = 'on';

    % 添加圖例
    if opts.ShowTheory && ~isempty(plot_handle_theory)
        legend_labels_all = [legend_labels; {'Theory/Fitted'}];
        all_handles = [plot_handles_mag; plot_handle_theory];
        leg = legend(all_handles, legend_labels_all, ...
            'Location', 'northoutside', 'NumColumns', num_channels + 1, ...
            'FontSize', 12, 'FontWeight', 'bold', 'Orientation', 'horizontal');
    else
        leg = legend(plot_handles_mag, legend_labels, ...
            'Location', 'northoutside', 'NumColumns', num_channels, ...
            'FontSize', 13, 'FontWeight', 'bold', 'Orientation', 'horizontal');
    end
    leg.EdgeColor = [0 0 0];
    leg.LineWidth = 2.0;

    %% ===== 下圖：Phase =====
    subplot('Position', [0.1, 0.1, 0.85, 0.35]);
    hold on; grid off;

    % 畫理論相位曲線（如果有）
    if opts.ShowTheory && ~isempty(opts.TheoryPhase)
        theory_freq = opts.TheoryFreq;
        if isempty(theory_freq)
            theory_freq = frequencies;
        end

        if opts.LogScale
            semilogx(theory_freq, opts.TheoryPhase, '-', ...
                'LineWidth', unified_linewidth, ...
                'Color', theory_color, ...
                'DisplayName', 'Theory/Fitted');
        else
            plot(theory_freq, opts.TheoryPhase, '-', ...
                'LineWidth', unified_linewidth, ...
                'Color', theory_color, ...
                'DisplayName', 'Theory/Fitted');
        end
    end

    % 決定繪製哪些通道的相位
    if opts.ExcitedChannel > 0 && opts.ExcitedChannel <= num_channels
        % 只繪製激勵通道
        channels_to_plot = opts.ExcitedChannel;
    else
        % 繪製所有通道
        channels_to_plot = 1:num_channels;
    end

    % 畫實驗相位曲線
    for ch = channels_to_plot
        phase_ch = phases(ch, :);

        if opts.LogScale
            semilogx(frequencies, phase_ch, ['--' markers{ch}], ...
                'LineWidth', unified_linewidth, ...
                'Color', channel_colors(ch, :), ...
                'MarkerSize', unified_markersize, ...
                'MarkerFaceColor', 'none', ...
                'MarkerEdgeColor', channel_colors(ch, :), ...
                'DisplayName', legend_labels{ch});
        else
            plot(frequencies, phase_ch, ['--' markers{ch}], ...
                'LineWidth', unified_linewidth, ...
                'Color', channel_colors(ch, :), ...
                'MarkerSize', unified_markersize, ...
                'MarkerFaceColor', 'none', ...
                'MarkerEdgeColor', channel_colors(ch, :), ...
                'DisplayName', legend_labels{ch});
        end
    end

    % 設定標籤和軸
    xlabel('Frequency (Hz)', 'FontSize', 22, 'FontWeight', 'bold');
    ylabel('Phase (deg)', 'FontSize', 22, 'FontWeight', 'bold');
    xlim([frequencies(1), frequencies(end)]);

    % 設定座標軸格式
    ax2 = gca;
    if opts.LogScale
        ax2.XScale = 'log';
        ax2.XTick = [1, 10, 100, 1000, 10000];
        ax2.XTickLabel = {'10^0', '10^1', '10^2', '10^3', '10^4'};
    end
    ax2.FontSize = 18;
    ax2.FontWeight = 'bold';
    ax2.LineWidth = 2.5;
    ax2.Box = 'on';

    %% 添加標題（如果有）
    if ~isempty(opts.Title)
        sgtitle(opts.Title, 'FontSize', 16, 'FontWeight', 'bold');
    end

    %% 保存圖片（如果指定路徑）
    if ~isempty(opts.SavePath)
        exportgraphics(fig, opts.SavePath, 'Resolution', opts.Resolution);
        fprintf('  Bode plot saved to: %s (%d DPI)\n', opts.SavePath, opts.Resolution);
    end
end
