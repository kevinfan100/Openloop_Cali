function [H_mag, H_phase_raw, freq_out] = load_dat_pdata(config, varargin)
%LOAD_DAT_PDATA 從 .dat 檔案載入 6x6 頻率響應數據
%
% 從 6 個激勵通道資料夾讀取 .dat 檔案，對所有 6 個 Vm 通道做 FFT，
% 組裝為 6x6xN tensor。等效於 load_legacy_pdata 但直接處理原始數據。
%
% 使用方式:
%   [H_mag, H_phase_raw, frequencies] = load_dat_pdata(config)
%
% 輸入:
%   config - MIMO config struct (需有 config.mimo.dat_* 欄位)
%
% 選項:
%   'Verbose' - 顯示處理資訊 (default: true)
%
% 輸出:
%   H_mag         - 6 x 6 x N magnitude (linear)
%   H_phase_raw   - 6 x 6 x N phase (deg, 原始未修正)
%   freq_out      - 1 x N Hz

    %% 解析參數
    pr = inputParser;
    pr.KeepUnmatched = true;
    addRequired(pr, 'config', @isstruct);
    addParameter(pr, 'Verbose', true, @islogical);
    parse(pr, config, varargin{:});
    opts = pr.Results;

    %% 設定
    num_ch = config.mimo.num_channels;
    base_folder = config.mimo.dat_base_folder;
    subfolders = config.mimo.dat_subfolder;
    prefixes = config.mimo.dat_prefix;
    freq_out = config.expected_frequencies;
    num_freq = length(freq_out);

    H_mag = zeros(num_ch, num_ch, num_freq);
    H_phase_raw = zeros(num_ch, num_ch, num_freq);

    %% 逐激勵通道處理
    for p_idx = 1:num_ch
        excite_ch = p_idx;
        data_folder = fullfile(base_folder, subfolders{p_idx});
        data_files = build_data_files(prefixes{p_idx}, freq_out);

        if opts.Verbose
            fprintf('\n--- P%d: excite ch%d (%s) ---\n', ...
                p_idx, excite_ch, subfolders{p_idx});
        end

        for k = 1:num_freq
            freq = freq_out(k);
            filepath = fullfile(data_folder, data_files{k});

            if opts.Verbose
                fprintf('  [%d/%d] %.1f Hz ... ', k, num_freq, freq);
            end

            try
                %% 1. Read binary
                data = read_hsdata(filepath);
                fs = data.sampling_rate;

                %% 2. DAC -> Voltage (激勵通道)
                da_volt = (double(data.da) - config.dac.zero_offset) * ...
                          (config.dac.voltage_range / config.dac.resolution);

                %% 3. Steady-state detection (用對角通道 Vm)
                Vm_diag = data.Vm(:, excite_ch);
                period_samples = round(fs / freq);
                actual_check_pts = min( ...
                    config.steady_state.check_points, period_samples);

                steady_info = detect_steady_state_relative( ...
                    Vm_diag, freq, fs, ...
                    'RelativeThreshold', config.steady_state.relative_threshold, ...
                    'ConsecutivePeriods', config.steady_state.consecutive_periods, ...
                    'CheckPoints', actual_check_pts, ...
                    'Verbose', false);

                if steady_info.index > 0
                    steady_start = steady_info.index;
                else
                    % Low-frequency fallback: use last periods
                    min_periods = config.steady_state.min_periods_for_fft;
                    total_samples = size(data.Vm, 1);
                    steady_start = max(1, ...
                        total_samples - min_periods * period_samples + 1);
                    if opts.Verbose
                        fprintf('(fallback) ');
                    end
                end

                %% 4. Super-period & FFT length
                [sp_samples, ~] = compute_super_period(freq, fs);
                available_samples = size(data.Vm, 1) - steady_start + 1;
                available_super = floor(available_samples / sp_samples);

                if available_super > 0
                    fft_length = available_super * sp_samples;
                else
                    available_periods = floor(available_samples / period_samples);
                    fft_length = available_periods * period_samples;
                end

                %% 5. FFT on all 6 Vm channels + DA excitation channel
                da_steady = da_volt( ...
                    steady_start : steady_start + fft_length - 1, excite_ch);
                DA_fft = fft(da_steady);
                N = fft_length;
                freq_axis = (0:N-1) * fs / N;
                [~, fundamental_bin] = min(abs(freq_axis - freq));

                for out_ch = 1:num_ch
                    Vm_steady = data.Vm( ...
                        steady_start : steady_start + fft_length - 1, out_ch);
                    Vm_fft = fft(Vm_steady);

                    H_complex = Vm_fft(fundamental_bin) / DA_fft(fundamental_bin);
                    H_mag(out_ch, p_idx, k) = abs(H_complex);
                    H_phase_raw(out_ch, p_idx, k) = ...
                        angle(H_complex) * 180 / pi;
                end

                if opts.Verbose
                    fprintf('OK\n');
                end

            catch ME
                if opts.Verbose
                    fprintf('ERROR: %s\n', ME.message);
                end
            end
        end
    end

    %% Summary
    if opts.Verbose
        n_nonzero = nnz(H_mag);
        n_total = numel(H_mag);
        fprintf('\nDAT P-data loaded:\n');
        fprintf('  Source: %s\n', base_folder);
        fprintf('  Excitation channels: %d folders x %d frequencies\n', ...
            num_ch, num_freq);
        fprintf('  Tensor: %d x %d x %d\n', num_ch, num_ch, num_freq);
        fprintf('  Non-zero entries: %d/%d (%.1f%%)\n', ...
            n_nonzero, n_total, n_nonzero / n_total * 100);
    end
end
