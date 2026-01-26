function fig = plot_comparison(frequencies, H_mag, H_phase, A1_multi, A2_multi, B_multi, varargin)
%PLOT_COMPARISON 擬合對比圖繪製
%
% 繪製 One-Curve vs Multi-Curve 擬合結果對比
%
% 使用方式:
%   fig = plot_comparison(frequencies, H_mag, H_phase, A1_multi, A2_multi, B_multi)
%   fig = plot_comparison(..., 'Name', 'Value', ...)
%
% 輸入:
%   frequencies - 頻率向量 [Hz] (1 x N)
%   H_mag       - 幅值矩陣 (6 x 6 x N)
%   H_phase     - 相位矩陣 [deg] (6 x 6 x N)，已移除相位偏移
%   A1_multi    - Multi-curve 分母 A1
%   A2_multi    - Multi-curve 分母 A2
%   B_multi     - Multi-curve B 矩陣 (6 x 6)
%
% 選項 (Name-Value pairs):
%   'OneCurveResults' - 結構體包含 a1_matrix, a2_matrix, b_matrix (6x6 各)
%   'ExcitedChannels' - 要繪製的激勵通道 (default: 1:6)
%   'PlotType'        - 'grouped' | 'grid' | 'dc_gain' (default: 'grouped')
%   'SavePath'        - 保存路徑前綴 (default: '', 不保存)
%   'Resolution'      - 保存解析度 DPI (default: 300)
%
% 輸出:
%   fig - figure handle 或 figure handles 陣列

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'frequencies', @isnumeric);
    addRequired(p, 'H_mag', @isnumeric);
    addRequired(p, 'H_phase', @isnumeric);
    addRequired(p, 'A1_multi', @isnumeric);
    addRequired(p, 'A2_multi', @isnumeric);
    addRequired(p, 'B_multi', @isnumeric);
    addParameter(p, 'OneCurveResults', [], @(x) isempty(x) || isstruct(x));
    addParameter(p, 'ExcitedChannels', 1:6, @isnumeric);
    addParameter(p, 'PlotType', 'grouped', @(x) ismember(x, {'grouped', 'grid', 'dc_gain'}));
    addParameter(p, 'SavePath', '', @ischar);
    addParameter(p, 'Resolution', 300, @isnumeric);

    parse(p, frequencies, H_mag, H_phase, A1_multi, A2_multi, B_multi, varargin{:});
    opts = p.Results;

    %% 樣式配置
    channel_colors = [
        0.0000, 0.0000, 0.5000;  % P1: 深藍色
        0.0000, 0.0000, 1.0000;  % P2: 藍色
        0.0000, 0.5000, 0.0000;  % P3: 綠色
        1.0000, 0.0000, 0.0000;  % P4: 紅色
        0.8000, 0.0000, 0.8000;  % P5: 粉紫色
        0.0000, 0.7500, 0.7500;  % P6: 青色
    ];

    one_curve_color = [0.5, 0.5, 0.5];   % 灰色 (One-curve)
    multi_curve_color = [0, 0, 0];        % 黑色 (Multi-curve)

    unified_linewidth = 3.0;
    unified_markersize = 8;

    %% 準備數據
    freq_smooth = logspace(log10(min(frequencies)), log10(max(frequencies)), 200);
    s_smooth = 1j * 2 * pi * freq_smooth;
    w_k = frequencies(:) * 2 * pi;

    %% 根據繪圖類型執行
    switch opts.PlotType

        case 'grouped'
            %% ===== 分組波德圖對比 =====
            fig = gobjects(length(opts.ExcitedChannels), 1);

            for fig_idx = 1:length(opts.ExcitedChannels)
                excited_ch = opts.ExcitedChannels(fig_idx);

                fig(fig_idx) = figure('Name', sprintf('Comparison: P%d Excitation', excited_ch), ...
                                      'Position', [100 + (fig_idx-1)*100, 100, 1000, 800]);

                % === 幅值圖 ===
                subplot(2, 1, 1);
                hold on;

                % Multi-curve 模型曲線 (黑色)
                H_multi_smooth = A2_multi ./ (s_smooth.^2 + A1_multi*s_smooth + A2_multi);
                semilogx(freq_smooth, 20*log10(abs(H_multi_smooth)), '-', ...
                    'Color', multi_curve_color, 'LineWidth', unified_linewidth + 0.5, ...
                    'DisplayName', 'Multi-Curve');

                % One-curve 模型曲線 (灰色，如果有)
                if ~isempty(opts.OneCurveResults)
                    for out_ch = 1:6
                        a1_one = opts.OneCurveResults.a1_matrix(out_ch, excited_ch);
                        a2_one = opts.OneCurveResults.a2_matrix(out_ch, excited_ch);
                        b_one = opts.OneCurveResults.b_matrix(out_ch, excited_ch);

                        H_one_smooth = b_one ./ (s_smooth.^2 + a1_one*s_smooth + a2_one);
                        dc_gain_one = b_one / a2_one;
                        H_one_norm = H_one_smooth / dc_gain_one;

                        if out_ch == 1
                            semilogx(freq_smooth, 20*log10(abs(H_one_norm)), '-', ...
                                'Color', one_curve_color, 'LineWidth', unified_linewidth - 0.5, ...
                                'DisplayName', 'One-Curve');
                        else
                            semilogx(freq_smooth, 20*log10(abs(H_one_norm)), '-', ...
                                'Color', one_curve_color, 'LineWidth', unified_linewidth - 0.5, ...
                                'HandleVisibility', 'off');
                        end
                    end
                end

                % 實驗數據點
                for out_ch = 1:6
                    h_meas = squeeze(H_mag(out_ch, excited_ch, :));
                    dc_gain_B = B_multi(out_ch, excited_ch);

                    if abs(dc_gain_B) > 1e-10
                        h_meas_norm = h_meas / abs(dc_gain_B);
                        semilogx(frequencies, 20*log10(h_meas_norm), 'o', ...
                            'Color', channel_colors(out_ch, :), ...
                            'MarkerSize', unified_markersize, ...
                            'LineWidth', 2, ...
                            'DisplayName', sprintf('P%d', out_ch));
                    end
                end

                xlabel('Frequency (Hz)', 'FontSize', 18, 'FontWeight', 'bold');
                ylabel('Magnitude (dB)', 'FontSize', 18, 'FontWeight', 'bold');
                title(sprintf('P%d Excitation - Magnitude', excited_ch), 'FontSize', 16, 'FontWeight', 'bold');
                legend('Location', 'southwest', 'FontSize', 12);

                ax = gca;
                ax.XScale = 'log';
                ax.FontSize = 14;
                ax.FontWeight = 'bold';
                ax.LineWidth = 2;
                ax.Box = 'on';
                xlim([min(frequencies), max(frequencies)]);
                ylim([-30, 5]);
                grid on;

                % === 相位圖 ===
                subplot(2, 1, 2);
                hold on;

                % Multi-curve 模型相位
                H_multi_smooth = A2_multi ./ (s_smooth.^2 + A1_multi*s_smooth + A2_multi);
                semilogx(freq_smooth, angle(H_multi_smooth)*180/pi, '-', ...
                    'Color', multi_curve_color, 'LineWidth', unified_linewidth + 0.5, ...
                    'DisplayName', 'Multi-Curve');

                % One-curve 模型相位 (如果有)
                if ~isempty(opts.OneCurveResults)
                    for out_ch = 1:6
                        a1_one = opts.OneCurveResults.a1_matrix(out_ch, excited_ch);
                        a2_one = opts.OneCurveResults.a2_matrix(out_ch, excited_ch);
                        b_one = opts.OneCurveResults.b_matrix(out_ch, excited_ch);

                        H_one_smooth = b_one ./ (s_smooth.^2 + a1_one*s_smooth + a2_one);

                        if out_ch == 1
                            semilogx(freq_smooth, angle(H_one_smooth)*180/pi, '-', ...
                                'Color', one_curve_color, 'LineWidth', unified_linewidth - 0.5, ...
                                'DisplayName', 'One-Curve');
                        else
                            semilogx(freq_smooth, angle(H_one_smooth)*180/pi, '-', ...
                                'Color', one_curve_color, 'LineWidth', unified_linewidth - 0.5, ...
                                'HandleVisibility', 'off');
                        end
                    end
                end

                % 實驗相位數據
                for out_ch = 1:6
                    phi_meas = squeeze(H_phase(out_ch, excited_ch, :));
                    semilogx(frequencies, phi_meas, 'o', ...
                        'Color', channel_colors(out_ch, :), ...
                        'MarkerSize', unified_markersize, ...
                        'LineWidth', 2, ...
                        'DisplayName', sprintf('P%d', out_ch));
                end

                xlabel('Frequency (Hz)', 'FontSize', 18, 'FontWeight', 'bold');
                ylabel('Phase (deg)', 'FontSize', 18, 'FontWeight', 'bold');
                title(sprintf('P%d Excitation - Phase', excited_ch), 'FontSize', 16, 'FontWeight', 'bold');

                ax = gca;
                ax.XScale = 'log';
                ax.FontSize = 14;
                ax.FontWeight = 'bold';
                ax.LineWidth = 2;
                ax.Box = 'on';
                xlim([min(frequencies), max(frequencies)]);
                ylim([-180, 10]);
                grid on;

                % 保存圖片
                if ~isempty(opts.SavePath)
                    save_file = sprintf('%s_P%d.png', opts.SavePath, excited_ch);
                    exportgraphics(fig(fig_idx), save_file, 'Resolution', opts.Resolution);
                    fprintf('  Saved: %s\n', save_file);
                end
            end


        case 'dc_gain'
            %% ===== 穩態增益對比 =====
            fig = figure('Name', 'DC Gain Comparison', 'Position', [100, 100, 1200, 500]);

            if ~isempty(opts.OneCurveResults)
                % One-curve DC 增益
                DC_one = opts.OneCurveResults.b_matrix ./ opts.OneCurveResults.a2_matrix;

                % 對非對角元素取反
                for i = 1:6
                    for j = 1:6
                        if i ~= j
                            DC_one(i,j) = -DC_one(i,j);
                        end
                    end
                end

                % Subplot 1: One-Curve
                subplot(1, 2, 1);
                imagesc(ones(6, 6) * 0.9);
                colormap('gray');
                title('One-Curve DC Gains', 'FontWeight', 'bold', 'FontSize', 16);
                xlabel('Input Pole', 'FontWeight', 'bold', 'FontSize', 14);
                ylabel('Output Pole', 'FontWeight', 'bold', 'FontSize', 14);
                set(gca, 'XTick', 1:6, 'YTick', 1:6, 'FontSize', 12);
                axis equal tight;

                for i = 1:6
                    for j = 1:6
                        text(j, i, sprintf('%.3f', DC_one(i,j)), ...
                            'HorizontalAlignment', 'center', 'FontSize', 11, ...
                            'Color', 'k', 'FontWeight', 'bold');
                    end
                end

                % Subplot 2: Multi-Curve
                subplot(1, 2, 2);
            else
                % 只繪製 Multi-Curve
            end

            imagesc(ones(6, 6) * 0.9);
            colormap('gray');
            title('Multi-Curve DC Gains (B Matrix)', 'FontWeight', 'bold', 'FontSize', 16);
            xlabel('Input Pole', 'FontWeight', 'bold', 'FontSize', 14);
            ylabel('Output Pole', 'FontWeight', 'bold', 'FontSize', 14);
            set(gca, 'XTick', 1:6, 'YTick', 1:6, 'FontSize', 12);
            axis equal tight;

            for i = 1:6
                for j = 1:6
                    text(j, i, sprintf('%.3f', B_multi(i,j)), ...
                        'HorizontalAlignment', 'center', 'FontSize', 11, ...
                        'Color', 'k', 'FontWeight', 'bold');
                end
            end

            if ~isempty(opts.OneCurveResults)
                sgtitle('DC Gain Comparison: One-Curve vs Multi-Curve', ...
                        'FontWeight', 'bold', 'FontSize', 18);
            else
                sgtitle('Multi-Curve DC Gains (B Matrix)', ...
                        'FontWeight', 'bold', 'FontSize', 18);
            end

            % 保存圖片
            if ~isempty(opts.SavePath)
                save_file = sprintf('%s_dc_gain.png', opts.SavePath);
                exportgraphics(fig, save_file, 'Resolution', opts.Resolution);
                fprintf('  Saved: %s\n', save_file);
            end


        case 'grid'
            %% ===== 36 通道網格圖 =====
            fig = figure('Name', '36-Channel Bode Grid', 'Position', [50, 50, 1600, 1000]);

            for i = 1:6
                for j = 1:6
                    subplot(6, 6, (i-1)*6 + j);
                    hold on;

                    % 實驗數據
                    h_meas = squeeze(H_mag(i, j, :));
                    dc_gain_B = B_multi(i, j);

                    if abs(dc_gain_B) > 1e-10
                        h_meas_norm = h_meas / abs(dc_gain_B);
                        semilogx(frequencies, 20*log10(h_meas_norm), 'o', ...
                            'Color', channel_colors(j, :), 'MarkerSize', 4, 'LineWidth', 1);
                    end

                    % Multi-curve 模型
                    H_multi_smooth = A2_multi ./ (s_smooth.^2 + A1_multi*s_smooth + A2_multi);
                    semilogx(freq_smooth, 20*log10(abs(H_multi_smooth)), 'k-', 'LineWidth', 1.5);

                    % One-curve 模型 (如果有)
                    if ~isempty(opts.OneCurveResults)
                        a1_one = opts.OneCurveResults.a1_matrix(i, j);
                        a2_one = opts.OneCurveResults.a2_matrix(i, j);
                        b_one = opts.OneCurveResults.b_matrix(i, j);

                        H_one_smooth = b_one ./ (s_smooth.^2 + a1_one*s_smooth + a2_one);
                        dc_gain_one = b_one / a2_one;
                        H_one_norm = H_one_smooth / dc_gain_one;
                        semilogx(freq_smooth, 20*log10(abs(H_one_norm)), '--', ...
                            'Color', one_curve_color, 'LineWidth', 1);
                    end

                    % 格式化
                    set(gca, 'XScale', 'log', 'FontSize', 8);
                    xlim([min(frequencies), max(frequencies)]);
                    ylim([-30, 5]);

                    if i == 6
                        xlabel('Hz', 'FontSize', 8);
                    end
                    if j == 1
                        ylabel('dB', 'FontSize', 8);
                    end

                    title(sprintf('H_{%d%d}', i, j), 'FontSize', 9);
                    grid on;
                    box on;
                end
            end

            sgtitle('36-Channel Bode Comparison (Black: Multi, Gray: One)', ...
                    'FontWeight', 'bold', 'FontSize', 14);

            % 保存圖片
            if ~isempty(opts.SavePath)
                save_file = sprintf('%s_grid.png', opts.SavePath);
                exportgraphics(fig, save_file, 'Resolution', opts.Resolution);
                fprintf('  Saved: %s\n', save_file);
            end

    end
end
