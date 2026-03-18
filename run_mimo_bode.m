function run_mimo_bode(data_folder, output_folder, varargin)
%RUN_MIMO_BODE 從 .dat 檔產生 MIMO 6-channel Raw Bode + B Matrix
%
% 讀取指定資料夾下的 hx_p1~hx_p6 子資料夾，計算每個 excitation 的
% 6-channel 頻率響應 (Raw Bode plot)，以及 6x6 B Matrix (DC gain)。
%
% Usage:
%   run_mimo_bode('data/3.18', 'results/3.18')
%   run_mimo_bode('data/3.18', 'results/3.18', 'Channels', [3, 5])
%   run_mimo_bode('data/3.18', 'results/3.18', 'Frequencies', [0.1 1 10 50 100])
%
% Input:
%   data_folder   - 包含 hx_p1~hx_p6 子資料夾的路徑
%   output_folder - 輸出圖片的資料夾 (自動建立)
%
% Optional Parameters:
%   'Channels'    - 要跑的 excitation channels (default: 自動偵測)
%   'Frequencies' - 頻率點 (default: 15-point NTU list)
%
% Output:
%   Raw_Bode_hx_pN.png - 每個 excitation 的 6-channel Bode plot
%   B_Matrix_6x6.png   - B Matrix heatmap (direct real(H))
%
% B Matrix 邏輯:
%   直接取 real(H) at 0.1 Hz，不做相位修正、不做 off-diagonal negation。
%   正負號反映實際相位: ~0° → 正, ~180° → 負。

    %% Parse inputs
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'data_folder', @ischar);
    addRequired(p, 'output_folder', @ischar);
    addParameter(p, 'Channels', [], @isnumeric);
    addParameter(p, 'Frequencies', ...
        [0.1, 1, 10, 50, 100, 200, 500, 1000, 1200, 1250, 1500, 1600, 2000, 2500, 3000], ...
        @isnumeric);
    parse(p, data_folder, output_folder, varargin{:});

    frequencies = p.Results.Frequencies;
    nf = length(frequencies);
    fs = 20000;

    %% Auto-detect available channels
    if isempty(p.Results.Channels)
        channels = [];
        for ch = 1:6
            folder_name = sprintf('hx_p%d', ch);
            if exist(fullfile(data_folder, folder_name), 'dir')
                channels(end+1) = ch; %#ok<AGROW>
            end
        end
    else
        channels = p.Results.Channels;
    end

    if isempty(channels)
        error('run_mimo_bode:no_data', 'No hx_pN folders found in %s', data_folder);
    end

    fprintf('=== run_mimo_bode ===\n');
    fprintf('Data:   %s\n', data_folder);
    fprintf('Output: %s\n', output_folder);
    fprintf('Channels: [%s]\n', num2str(channels));
    fprintf('Frequencies: %d points\n\n', nf);

    %% Create output folder
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    %% Colors for 6 channels
    ch_colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.929 0.694 0.125; ...
                 0.494 0.184 0.556; 0.466 0.674 0.188; 0.301 0.745 0.933];

    %% B Matrix storage
    B = NaN(6, 6);

    %% Process each excitation channel
    for ci = 1:length(channels)
        exc_ch = channels(ci);
        folder_name = sprintf('hx_p%d', exc_ch);
        data_dir = fullfile(data_folder, folder_name);
        prefix = sprintf('NTU_%s_', folder_name);

        H_mag_dB = zeros(6, nf);
        H_phase  = zeros(6, nf);

        fprintf('Processing %s (excite ch%d)...\n', folder_name, exc_ch);

        for k = 1:nf
            f = frequencies(k);
            freq_str = format_freq(f);
            fname = fullfile(data_dir, sprintf('%s_%shz.dat', prefix, freq_str));

            if ~exist(fname, 'file')
                warning('File not found: %s', fname);
                continue;
            end

            data = read_hsdata(fname);

            %% Steady-state: use last 80%
            N_total = size(data.Vm, 1);
            start_idx = round(N_total * 0.2) + 1;
            period_samples = round(fs / f);
            available = N_total - start_idx + 1;
            n_periods = floor(available / period_samples);
            fft_len = n_periods * period_samples;
            seg = start_idx : (start_idx + fft_len - 1);

            %% DAC excitation voltage
            da_volt = (double(data.da(seg, exc_ch)) - 32768) * 20.0 / 65536;
            DA_fft = fft(da_volt);
            freq_axis = (0:fft_len-1) * fs / fft_len;
            [~, fbin] = min(abs(freq_axis - f));

            %% All 6 sensor channels
            for ch = 1:6
                Vm_fft = fft(data.Vm(seg, ch));
                H = Vm_fft(fbin) / DA_fft(fbin);
                H_mag_dB(ch, k) = 20 * log10(abs(H));
                H_phase(ch, k) = angle(H) * 180 / pi;

                %% B Matrix: direct real(H) at lowest frequency
                if k == 1
                    B(ch, exc_ch) = real(H);
                end
            end
        end

        %% --- Raw Bode Plot ---
        fig = figure('Position', [100 100 1200 800], 'Color', 'w');

        subplot(2,1,1); hold on;
        for ch = 1:6
            semilogx(frequencies, H_mag_dB(ch,:), '-o', ...
                'Color', ch_colors(ch,:), 'LineWidth', 2.5, 'MarkerSize', 8, ...
                'MarkerFaceColor', 'none', 'DisplayName', sprintf('ch%d', ch));
        end
        hold off;
        set(gca, 'XScale', 'log', 'FontSize', 18, 'FontWeight', 'bold');
        ax = gca; ax.XAxis.LineWidth = 2; ax.YAxis.LineWidth = 2;
        ylabel('Magnitude (dB)', 'FontSize', 28, 'FontWeight', 'bold');
        title(sprintf('Raw Bode - %s (excite ch%d)', folder_name, exc_ch), ...
            'FontSize', 20, 'FontWeight', 'bold');
        legend('Location', 'northoutside', 'Orientation', 'horizontal', 'FontSize', 16);
        grid on; box on; xlim([0.08, max(frequencies)*1.3]);

        subplot(2,1,2); hold on;
        for ch = 1:6
            semilogx(frequencies, H_phase(ch,:), '-o', ...
                'Color', ch_colors(ch,:), 'LineWidth', 2.5, 'MarkerSize', 8, ...
                'MarkerFaceColor', 'none', 'DisplayName', sprintf('ch%d', ch));
        end
        hold off;
        set(gca, 'XScale', 'log', 'FontSize', 18, 'FontWeight', 'bold');
        ax = gca; ax.XAxis.LineWidth = 2; ax.YAxis.LineWidth = 2;
        xlabel('Frequency (Hz)', 'FontSize', 28, 'FontWeight', 'bold');
        ylabel('Phase (deg)', 'FontSize', 28, 'FontWeight', 'bold');
        grid on; box on; xlim([0.08, max(frequencies)*1.3]);

        saveas(fig, fullfile(output_folder, sprintf('Raw_Bode_%s.png', folder_name)));
        fprintf('  Saved: Raw_Bode_%s.png\n', folder_name);
        close(fig);
    end

    %% --- B Matrix Plot ---
    fprintf('\nGenerating B Matrix...\n');

    % Determine display size
    has_data = ~all(isnan(B), 1);  % which columns have data

    % Colormap: blue(neg) → white(0) → red(pos)
    n = 256; half = floor(n/2);
    r_ch = [linspace(0.2, 1, half), ones(1, n-half)];
    g_ch = [linspace(0.2, 1, half), linspace(1, 0.2, n-half)];
    b_ch = [ones(1, half), linspace(1, 0.2, n-half)];
    rb_cmap = [r_ch(:), g_ch(:), b_ch(:)];

    % Replace NaN with 0 for display
    B_display = B;
    B_display(isnan(B_display)) = 0;
    cmax = max(abs(B(~isnan(B))));

    fig = figure('Position', [100 100 900 750], 'Color', 'w');
    imagesc(B_display);
    colormap(rb_cmap);
    caxis([-cmax, cmax]);
    cb = colorbar; cb.FontSize = 14; cb.FontWeight = 'bold';

    set(gca, 'XTick', 1:6, 'XTickLabel', {'1','2','3','4','5','6'}, ...
             'YTick', 1:6, 'YTickLabel', {'1','2','3','4','5','6'}, ...
             'FontSize', 20, 'FontWeight', 'bold', 'TickLength', [0 0]);
    xlabel('Input Channel (Excitation)', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel('Output Channel (Sensor)', 'FontSize', 24, 'FontWeight', 'bold');
    title('B Matrix (direct real(H))', 'FontSize', 20, 'FontWeight', 'bold');

    % Text annotations
    for i = 1:6
        for j = 1:6
            if isnan(B(i,j))
                text(j, i, 'N/A', 'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', 'FontSize', 14, ...
                    'FontWeight', 'bold', 'Color', [0.5 0.5 0.5]);
            else
                val = B(i,j);
                if abs(val) > cmax * 0.5, txt_color = 'w';
                else, txt_color = 'k'; end
                text(j, i, sprintf('%.4f', val), 'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', 'FontSize', 14, ...
                    'FontWeight', 'bold', 'Color', txt_color);
            end
        end
    end

    % Grid lines
    hold on;
    for k = 0.5:1:6.5
        plot([0.5, 6.5], [k, k], 'k-', 'LineWidth', 1);
        plot([k, k], [0.5, 6.5], 'k-', 'LineWidth', 1);
    end
    hold off;

    saveas(fig, fullfile(output_folder, 'B_Matrix_6x6.png'));
    fprintf('Saved: B_Matrix_6x6.png\n');
    close(fig);

    %% Print B Matrix
    fprintf('\nB Matrix (direct real(H)):\n');
    fprintf('      ');
    for ei = 1:6
        if has_data(ei), fprintf('  excite%d ', ei);
        else, fprintf('    N/A   '); end
    end
    fprintf('\n');
    for si = 1:6
        fprintf('sen%d: ', si);
        for ei = 1:6
            if isnan(B(si,ei)), fprintf('    N/A   ');
            else, fprintf('%+8.4f ', B(si,ei)); end
        end
        fprintf('\n');
    end

    fprintf('\n=== run_mimo_bode complete ===\n');
end

%% === Helper: format frequency string ===
function freq_str = format_freq(f)
    if f == floor(f)
        freq_str = sprintf('%d', f);
    else
        freq_str = sprintf('%g', f);
    end
end
