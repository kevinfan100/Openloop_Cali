function [magnitudes, phases, magnitudes_db] = perform_fft(Vm_clean, da_volt, steady_info, excite_ch, excite_freq, sampling_rate, varargin)
%PERFORM_FFT 執行 FFT 分析計算轉移函數
%
% 計算轉移函數：H(jω) = Vm(jω) / DA(jω)
%
% 使用方式:
%   [magnitudes, phases, magnitudes_db] = perform_fft(Vm_clean, da_volt, steady_info, excite_ch, excite_freq, sampling_rate)
%   [magnitudes, phases, magnitudes_db] = perform_fft(..., 'Name', 'Value', ...)
%
% 輸入:
%   Vm_clean      - 清理後的 Vm 數據 (6 x N)
%   da_volt       - DA 電壓數據 (6 x N)
%   steady_info   - 穩態信息結構體
%   excite_ch     - 激勵通道索引 (1-6)
%   excite_freq   - 激勵頻率 [Hz]
%   sampling_rate - 取樣頻率 [Hz]
%
% 選項 (Name-Value pairs):
%   'Mode'         - FFT 模式 'full' | 'averaged' (default: 'full')
%   'MinThreshold' - 最小 DA 閾值 (default: 1e-10)
%   'Verbose'      - 顯示處理信息 (default: true)
%
% 輸出:
%   magnitudes    - 線性幅值 (6 x 1)
%   phases        - 相位 [deg] (6 x 1)
%   magnitudes_db - dB 幅值 (6 x 1)

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'Vm_clean', @isnumeric);
    addRequired(p, 'da_volt', @isnumeric);
    addRequired(p, 'steady_info', @isstruct);
    addRequired(p, 'excite_ch', @isnumeric);
    addRequired(p, 'excite_freq', @isnumeric);
    addRequired(p, 'sampling_rate', @isnumeric);
    addParameter(p, 'Mode', 'full', @(x) ismember(x, {'full', 'averaged'}));
    addParameter(p, 'MinThreshold', 1e-10, @isnumeric);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, Vm_clean, da_volt, steady_info, excite_ch, excite_freq, sampling_rate, varargin{:});
    opts = p.Results;

    %% 初始化輸出
    magnitudes = zeros(6, 1);
    magnitudes_db = zeros(6, 1);
    phases = zeros(6, 1);

    %% 提取穩態參數
    period_samples = steady_info.period_samples;
    steady_start = steady_info.index;
    available_length = size(Vm_clean, 2) - steady_start + 1;
    available_periods = floor(available_length / period_samples);

    if available_periods < 1
        if opts.Verbose
            fprintf('    Warning: Insufficient data for one complete period\n');
        end
        return;
    end

    if opts.Verbose
        fprintf('  FFT analysis (%s mode):\n', opts.Mode);
        fprintf('    Available periods: %d\n', available_periods);
    end

    %% 執行 FFT 分析
    if strcmp(opts.Mode, 'averaged')
        % --- 週期平均模式 ---
        da_signal = da_volt(excite_ch, :);

        % 提取並平均所有週期
        Vm_periods = zeros(6, available_periods, period_samples);
        da_periods = zeros(available_periods, period_samples);

        for p_idx = 1:available_periods
            start_idx = steady_start + (p_idx-1) * period_samples;
            end_idx = start_idx + period_samples - 1;

            for ch = 1:6
                Vm_periods(ch, p_idx, :) = Vm_clean(ch, start_idx:end_idx);
            end
            da_periods(p_idx, :) = da_signal(start_idx:end_idx);
        end

        % 計算平均週期
        Vm_avg_periods = squeeze(mean(Vm_periods, 2));  % 6 x period_samples
        da_avg_period = mean(da_periods, 1);            % 1 x period_samples

        % 對每個通道進行 FFT
        for ch = 1:6
            Vm_fft = fft(Vm_avg_periods(ch, :));
            da_fft = fft(da_avg_period);

            % 動態計算目標頻率 bin
            N_avg = period_samples;
            freq_resolution_avg = sampling_rate / N_avg;
            target_bin = round(excite_freq / freq_resolution_avg) + 1;

            % 計算轉移函數
            Vm_complex = Vm_fft(target_bin);
            da_complex = da_fft(target_bin);

            if abs(da_complex) > opts.MinThreshold
                transfer_function = Vm_complex / da_complex;
                magnitudes(ch) = abs(transfer_function);
                magnitudes_db(ch) = 20 * log10(magnitudes(ch));
                phases(ch) = angle(transfer_function) * 180 / pi;
            else
                magnitudes(ch) = 0;
                magnitudes_db(ch) = -Inf;
                phases(ch) = 0;
            end
        end

    else
        % --- 完整 FFT 模式 ---
        for ch = 1:6
            Vm_signal = Vm_clean(ch, :);
            da_signal = da_volt(excite_ch, :);

            % 提取完整週期（帶邊界檢查）
            max_index = size(Vm_clean, 2);
            end_index = steady_start + available_periods * period_samples - 1;

            if end_index > max_index
                end_index = max_index;
            end

            % 確保至少有一個完整週期
            actual_length = end_index - steady_start + 1;
            if actual_length < period_samples
                magnitudes(ch) = 0;
                magnitudes_db(ch) = -Inf;
                phases(ch) = 0;
                continue;
            end

            Vm_period_data = Vm_signal(steady_start:end_index);
            da_period_data = da_signal(steady_start:end_index);

            % 執行 FFT
            Vm_fft = fft(Vm_period_data);
            da_fft = fft(da_period_data);

            % 找到目標頻率 bin
            N = length(Vm_period_data);
            freq_axis = (0:N-1) * sampling_rate / N;
            freq_resolution = freq_axis(2) - freq_axis(1);
            target_bin = round(excite_freq / freq_resolution) + 1;

            % 計算轉移函數
            Vm_complex = Vm_fft(target_bin);
            da_complex = da_fft(target_bin);

            if abs(da_complex) > opts.MinThreshold
                transfer_function = Vm_complex / da_complex;
                magnitudes(ch) = abs(transfer_function);
                magnitudes_db(ch) = 20 * log10(magnitudes(ch));
                phases(ch) = angle(transfer_function) * 180 / pi;
            else
                magnitudes(ch) = 0;
                magnitudes_db(ch) = -Inf;
                phases(ch) = 0;
            end
        end
    end

    if opts.Verbose
        fprintf('    FFT completed\n');
    end
end
