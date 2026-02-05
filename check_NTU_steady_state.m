%% Check NTU 10Hz and 50Hz Steady-State Detection
clear; clc;

% Add functions path
addpath('functions');

% Configuration
config = struct();
config.data_folder = 'NTU_tweezer\single_raw_data';
config.excitation_channel = 2;
RELATIVE_THRESHOLD_PERCENT = 0.2;

% Files to check
files_to_check = {
    'NTU_single_10hz.dat', 10;
    'NTU_single_50hz.dat', 50
};

fprintf('\n========================================================================\n');
fprintf('  NTU Steady-State Detection Check\n');
fprintf('========================================================================\n\n');

for i = 1:size(files_to_check, 1)
    filename = files_to_check{i, 1};
    target_freq = files_to_check{i, 2};

    fprintf('--- %s (%.0f Hz) ---\n', filename, target_freq);

    try
        % Read data
        filepath = fullfile(config.data_folder, filename);
        data = read_hsdata(filepath);

        % DAC to voltage conversion
        da_volt = (double(data.da) - 32768) * (20.0 / 65536);
        vm = data.vm;
        fs = data.sampling_rate;
        excite_ch = data.channel;

        vm_ch2 = vm(:, excite_ch);
        da_ch2 = da_volt(:, excite_ch);

        fprintf('  Total samples: %d\n', length(vm_ch2));
        fprintf('  Duration: %.2f seconds\n', length(vm_ch2) / fs);
        fprintf('  Expected periods: %.1f\n', length(vm_ch2) / (fs / target_freq));

        % Steady-state detection with verbose output
        fprintf('\n  Running steady-state detection...\n');
        steady_info = detect_steady_state_relative(...
            vm_ch2, target_freq, fs, ...
            'RelativeThreshold', RELATIVE_THRESHOLD_PERCENT / 100, ...
            'ConsecutivePeriods', 3, ...
            'CheckPoints', 25, ...
            'Verbose', true);

        if steady_info.index > 0
            fprintf('\n  ✓ STEADY-STATE DETECTED\n');
            fprintf('    Start index: %d\n', steady_info.index);
            fprintf('    Start period: %d\n', steady_info.period);
            fprintf('    Period samples: %d\n', steady_info.period_samples);
            fprintf('    Available periods: %d\n', steady_info.max_periods);
            fprintf('    Signal amplitude: %.4f V\n', steady_info.signal_amplitude);
            fprintf('    Threshold: %.4e V (%.2f%%)\n', ...
                steady_info.absolute_threshold, steady_info.relative_threshold_percent);

            % FFT analysis
            period_samples = steady_info.period_samples;
            steady_start = steady_info.index;
            available_samples = length(vm_ch2) - steady_start + 1;
            available_periods = floor(available_samples / period_samples);
            fft_length = available_periods * period_samples;

            fprintf('    FFT will use: %d periods (%d samples)\n', ...
                available_periods, fft_length);

            vm_steady = vm_ch2(steady_start : steady_start + fft_length - 1);
            da_steady = da_ch2(steady_start : steady_start + fft_length - 1);

            VM_fft = fft(vm_steady);
            DA_fft = fft(da_steady);
            N = length(vm_steady);
            freq_axis = (0:N-1) * fs / N;

            % Find fundamental
            [~, fundamental_bin] = min(abs(freq_axis - target_freq));
            actual_freq = freq_axis(fundamental_bin);
            H_complex = VM_fft(fundamental_bin) / DA_fft(fundamental_bin);
            H_magnitude = abs(H_complex);
            H_phase = angle(H_complex) * 180 / pi;

            fprintf('\n  FFT Results:\n');
            fprintf('    Fundamental bin: %d\n', fundamental_bin);
            fprintf('    Actual frequency: %.4f Hz (target: %.0f Hz)\n', actual_freq, target_freq);
            fprintf('    H(jω) magnitude: %.6f [V/V]\n', H_magnitude);
            fprintf('    H(jω) phase: %.2f deg\n', H_phase);
        else
            fprintf('\n  ✗ NO STEADY-STATE DETECTED\n');
        end

    catch ME
        fprintf('  ✗ ERROR: %s\n', ME.message);
    end

    fprintf('\n');
end

fprintf('========================================================================\n');
fprintf('  Check Complete\n');
fprintf('========================================================================\n\n');
