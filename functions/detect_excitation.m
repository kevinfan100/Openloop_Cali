function [excite_ch, excite_freq] = detect_excitation(da_voltage, sampling_rate, varargin)
%DETECT_EXCITATION 檢測激勵通道和頻率
%
% 使用 FFT 分析找出具有最大能量的通道及其主頻率
%
% 使用方式:
%   [excite_ch, excite_freq] = detect_excitation(da_voltage, sampling_rate)
%   [excite_ch, excite_freq] = detect_excitation(..., 'Name', 'Value', ...)
%
% 輸入:
%   da_voltage    - DA 電壓數據 (6 x N)
%   sampling_rate - 取樣頻率 [Hz]
%
% 選項 (Name-Value pairs):
%   'MinEnergy' - 最小能量閾值 (default: 0.1)
%   'Verbose'   - 顯示處理信息 (default: true)
%
% 輸出:
%   excite_ch   - 激勵通道索引 (1-6)
%   excite_freq - 主頻率 [Hz]

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'da_voltage', @isnumeric);
    addRequired(p, 'sampling_rate', @isnumeric);
    addParameter(p, 'MinEnergy', 0.1, @isnumeric);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, da_voltage, sampling_rate, varargin{:});
    opts = p.Results;

    %% 初始化
    best_channel = 0;
    max_energy = 0;
    best_freq = 0;

    %% 對每個通道進行 FFT 分析
    for ch = 1:6
        signal_data = da_voltage(ch, :);
        signal_energy = sqrt(mean(signal_data.^2));

        % 只處理有足夠能量的通道
        if signal_energy > opts.MinEnergy
            N = length(signal_data);
            fft_result = fft(signal_data);
            freq_axis = (0:N-1) * sampling_rate / N;

            % 只取正頻率部分
            positive_freqs = freq_axis(2:floor(N/2));
            positive_fft = abs(fft_result(2:floor(N/2)));

            % 找到最大振幅對應的頻率
            [max_amplitude, max_idx] = max(positive_fft);
            dominant_freq = positive_freqs(max_idx);

            % 更新最佳通道
            if max_amplitude > max_energy
                max_energy = max_amplitude;
                best_channel = ch;
                best_freq = dominant_freq;
            end
        end
    end

    %% 驗證結果
    if best_channel == 0
        error('No valid excitation channel detected (all channels below energy threshold)');
    end

    excite_ch = best_channel;
    excite_freq = best_freq;

    %% 顯示結果
    if opts.Verbose
        fprintf('  Excitation detected:\n');
        fprintf('    Channel: P%d\n', excite_ch);
        fprintf('    Frequency: %.2f Hz\n', excite_freq);
    end
end
