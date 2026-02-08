function bode_table = step_fft(config, ss_results, varargin)
%STEP_FFT FFT + THD + CSV 輸出
%
% Usage:
%   bode_table = step_fft(config, ss_results)
%   bode_table = step_fft(config, ss_results, 'SaveCSV', true)
%
% Input:
%   config     - experiment config struct
%   ss_results - step_steady_state 的輸出
%
% Output:
%   bode_table - MATLAB table with columns:
%       Frequency_Hz, Magnitude_Linear, Magnitude_dB, Phase_deg, THD_percent

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'SaveCSV', true, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;
    save_csv = p.Results.SaveCSV;

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_fft: %s\n', config.experiment_name);
        fprintf('========================================\n\n');
    end

    bode_table = table();

    for i = 1:length(ss_results)
        if ~ss_results(i).success || ~ss_results(i).steady_ok
            continue;
        end

        freq = ss_results(i).frequency;
        fs = ss_results(i).fs;
        excite_ch = ss_results(i).excite_ch;

        if verbose
            fprintf('[%d/%d] %.1f Hz ... ', i, length(ss_results), freq);
        end

        try
            %% Extract steady-state segments
            vm_ch = ss_results(i).vm(:, excite_ch);
            da_ch = ss_results(i).da_volt(:, excite_ch);
            period_samples = ss_results(i).steady_info.period_samples;
            steady_start = ss_results(i).steady_info.index;

            available_samples = length(vm_ch) - steady_start + 1;
            available_periods = floor(available_samples / period_samples);
            fft_length = available_periods * period_samples;

            vm_steady = vm_ch(steady_start : steady_start + fft_length - 1);
            da_steady = da_ch(steady_start : steady_start + fft_length - 1);

            %% FFT
            VM_fft = fft(vm_steady);
            DA_fft = fft(da_steady);
            N = length(vm_steady);
            freq_axis = (0:N-1) * fs / N;

            %% Find fundamental bin
            [~, fundamental_bin] = min(abs(freq_axis - freq));

            %% H(jω) = VM / DA
            H_complex = VM_fft(fundamental_bin) / DA_fft(fundamental_bin);
            H_magnitude_linear = abs(H_complex);
            H_magnitude_dB = 20 * log10(H_magnitude_linear);
            H_phase_deg = angle(H_complex) * 180 / pi;

            %% THD calculation
            half_N = floor(N/2) + 1;
            VM_magnitude = abs(VM_fft(1:half_N)) / N * 2;
            VM_magnitude(1) = VM_magnitude(1) / 2;
            fundamental_amplitude = VM_magnitude(fundamental_bin);

            harmonic_sum_sq = 0;
            nyquist = fs / 2;
            for h = config.fft.thd_harmonics
                harmonic_freq = freq * h;
                if harmonic_freq > nyquist * config.fft.thd_max_freq_ratio
                    break;
                end
                [~, harmonic_bin] = min(abs(freq_axis(1:half_N) - harmonic_freq));
                harmonic_sum_sq = harmonic_sum_sq + VM_magnitude(harmonic_bin)^2;
            end
            THD_percent = sqrt(harmonic_sum_sq) / fundamental_amplitude * 100;

            %% Append to table
            new_row = table(freq, H_magnitude_linear, H_magnitude_dB, H_phase_deg, THD_percent, ...
                'VariableNames', {'Frequency_Hz', 'Magnitude_Linear', 'Magnitude_dB', 'Phase_deg', 'THD_percent'});
            bode_table = [bode_table; new_row]; %#ok<AGROW>

            if verbose, fprintf('OK (THD=%.2f%%)\n', THD_percent); end

        catch ME
            if verbose, fprintf('ERROR: %s\n', ME.message); end
        end
    end

    %% Save CSV
    if save_csv && height(bode_table) > 0
        diag_folder = fullfile(config.output_folder, 'diagnostics');
        if ~exist(diag_folder, 'dir'), mkdir(diag_folder); end
        csv_path = fullfile(diag_folder, 'Raw_Bode_Data.csv');
        writetable(bode_table, csv_path);
        if verbose
            fprintf('\nCSV saved: %s\n', csv_path);
        end
    end

    %% Summary
    if verbose
        fprintf('\nstep_fft complete: %d frequency points.\n', height(bode_table));
        if height(bode_table) > 0
            fprintf('  THD: mean=%.2f%%, max=%.2f%%, min=%.2f%%\n', ...
                mean(bode_table.THD_percent), max(bode_table.THD_percent), min(bode_table.THD_percent));
        end
    end
end
