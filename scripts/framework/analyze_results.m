% analyze_results.m
% 分析控制系統性能並繪圖
%
% Usage:
%   performance = analyze_results(sim_results)
%   performance = analyze_results(sim_results, reference)
%   performance = analyze_results(sim_results, reference, plot_options)
%
% Inputs:
%   sim_results  - 模擬結果結構（由 run_simulation 產生）
%   reference    - 參考值（預設 1），可以是標量或 6×1 向量
%   plot_options - 繪圖選項結構（可選）
%                  .show_plot   - 是否顯示圖表（預設 true）
%                  .save_fig    - 是否儲存圖表（預設 false）
%                  .fig_name    - 圖表檔名（預設 'results/controller_performance.fig'）
%
% Outputs:
%   performance - 性能指標結構
%     .settling_time       - 穩定時間 (6×1)
%     .rise_time          - 上升時間 (6×1)
%     .overshoot          - 超調量 (%) (6×1)
%     .steady_state_error - 穩態誤差 (6×1)
%     .peak_time          - 峰值時間 (6×1)
%     .peak_value         - 峰值 (6×1)
%
% Example:
%   sim_results = run_simulation('Control_System_Framework', 0.01);
%   performance = analyze_results(sim_results);
%
% Author: Claude Code
% Date: 2025-10-09

function performance = analyze_results(sim_results, reference, plot_options)
    %% Input validation
    if nargin < 1
        error('Usage: analyze_results(sim_results, [reference], [plot_options])');
    end

    if nargin < 2 || isempty(reference)
        reference = 1;  % Default reference
    end

    if nargin < 3
        plot_options = struct();
    end

    % Default plot options
    if ~isfield(plot_options, 'show_plot')
        plot_options.show_plot = true;
    end
    if ~isfield(plot_options, 'save_fig')
        plot_options.save_fig = false;
    end
    if ~isfield(plot_options, 'fig_name')
        plot_options.fig_name = 'results/controller_performance.fig';
    end

    % Convert reference to vector if scalar
    if isscalar(reference)
        reference = reference * ones(6, 1);
    end

    fprintf('=== Analyzing Performance ===\n');

    %% Extract data
    t = sim_results.t;
    Vm = sim_results.Vm;
    e = sim_results.e;
    u = sim_results.u;

    %% Calculate performance metrics
    fprintf('\nCalculating performance metrics...\n');

    for ch = 1:6
        y = Vm(:, ch);
        ref = reference(ch);

        % Final value
        final_val = y(end);

        % === Settling Time (2% error band) ===
        settling_idx = find(abs(y - final_val) > 0.02*abs(final_val), 1, 'last');
        if isempty(settling_idx)
            performance.settling_time(ch) = 0;
        else
            performance.settling_time(ch) = t(settling_idx);
        end

        % === Rise Time (10% → 90%) ===
        idx_10 = find(y >= 0.1*final_val, 1);
        idx_90 = find(y >= 0.9*final_val, 1);
        if ~isempty(idx_10) && ~isempty(idx_90) && idx_90 > idx_10
            performance.rise_time(ch) = t(idx_90) - t(idx_10);
        else
            performance.rise_time(ch) = NaN;
        end

        % === Overshoot ===
        if final_val ~= 0
            peak_val = max(y);
            performance.overshoot(ch) = (peak_val - final_val) / abs(final_val) * 100;
            performance.peak_value(ch) = peak_val;

            % Peak time
            peak_idx = find(y == peak_val, 1);
            performance.peak_time(ch) = t(peak_idx);
        else
            performance.overshoot(ch) = 0;
            performance.peak_value(ch) = 0;
            performance.peak_time(ch) = 0;
        end

        % === Steady-State Error ===
        performance.steady_state_error(ch) = abs(ref - final_val);
    end

    fprintf('  ✓ Performance metrics calculated\n');

    %% Display performance table
    fprintf('\n=== Performance Summary ===\n');
    fprintf('Channel | Rise Time | Settling Time | Overshoot | SS Error  | Peak Value\n');
    fprintf('--------|-----------|---------------|-----------|-----------|------------\n');
    for ch = 1:6
        fprintf('  %d     | %7.4f s | %10.4f s | %8.2f %% | %9.5f | %10.4f\n', ...
            ch, ...
            performance.rise_time(ch), ...
            performance.settling_time(ch), ...
            performance.overshoot(ch), ...
            performance.steady_state_error(ch), ...
            performance.peak_value(ch));
    end

    %% Calculate aggregate metrics
    fprintf('\n=== Aggregate Metrics ===\n');
    fprintf('Average settling time: %.4f s\n', mean(performance.settling_time));
    fprintf('Max settling time:     %.4f s\n', max(performance.settling_time));
    fprintf('Average overshoot:     %.2f %%\n', mean(performance.overshoot));
    fprintf('Max overshoot:         %.2f %%\n', max(performance.overshoot));
    fprintf('Max SS error:          %.5f\n', max(performance.steady_state_error));

    % Control effort
    u_max = max(abs(u), [], 1);
    u_rms = sqrt(mean(u.^2, 1));
    fprintf('\nControl Effort:\n');
    fprintf('  Max |u|: ');
    for ch = 1:6
        fprintf('%.2f  ', u_max(ch));
    end
    fprintf('\n');
    fprintf('  RMS u:   ');
    for ch = 1:6
        fprintf('%.2f  ', u_rms(ch));
    end
    fprintf('\n');

    %% Plotting
    if plot_options.show_plot
        fprintf('\nGenerating plots...\n');

        fig = figure('Position', [100, 100, 1400, 900]);
        fig.Name = 'Controller Performance Analysis';

        % === Row 1: Output Response ===
        for ch = 1:6
            subplot(3, 6, ch);
            plot(t, Vm(:,ch), 'b-', 'LineWidth', 1.5);
            hold on;
            yline(reference(ch), 'r--', 'LineWidth', 1, 'DisplayName', 'Reference');

            % Mark settling time
            if performance.settling_time(ch) > 0
                xline(performance.settling_time(ch), 'g--', 'LineWidth', 0.5, ...
                      'DisplayName', sprintf('Ts=%.3fs', performance.settling_time(ch)));
            end

            xlabel('Time (s)');
            ylabel(sprintf('V_m[%d]', ch));
            title(sprintf('Ch%d: Output', ch));
            grid on;
            legend('Location', 'best', 'FontSize', 7);
        end

        % === Row 2: Error ===
        for ch = 1:6
            subplot(3, 6, 6+ch);
            plot(t, e(:,ch), 'r-', 'LineWidth', 1.5);
            hold on;
            yline(0, 'k--', 'LineWidth', 0.5);
            xlabel('Time (s)');
            ylabel(sprintf('e[%d]', ch));
            title(sprintf('Ch%d: Error', ch));
            grid on;
        end

        % === Row 3: Control Signal ===
        for ch = 1:6
            subplot(3, 6, 12+ch);
            plot(t, u(:,ch), 'g-', 'LineWidth', 1.5);
            hold on;
            yline(0, 'k--', 'LineWidth', 0.5);
            xlabel('Time (s)');
            ylabel(sprintf('u[%d]', ch));
            title(sprintf('Ch%d: Control', ch));
            grid on;
        end

        sgtitle('MIMO Control System Performance', 'FontSize', 16, 'FontWeight', 'bold');

        fprintf('  ✓ Plots generated\n');

        % Save figure
        if plot_options.save_fig
            % Ensure results folder exists
            if ~exist('results', 'dir')
                mkdir('results');
            end

            savefig(fig, plot_options.fig_name);
            fprintf('  ✓ Figure saved: %s\n', plot_options.fig_name);

            % Also save as PNG
            png_name = strrep(plot_options.fig_name, '.fig', '.png');
            saveas(fig, png_name);
            fprintf('  ✓ Figure saved: %s\n', png_name);
        end
    end

    fprintf('\n=== Analysis Complete ===\n');
    fprintf('Performance metrics stored in performance structure.\n');
    fprintf('\n');
end
