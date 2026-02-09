function results = step_steady_state(config, read_results, varargin)
%STEP_STEADY_STATE 穩態檢測 (conservative: 所有分析通道取最晚穩定)
%
% Usage:
%   results = step_steady_state(config, read_results)
%
% Input:
%   config       - experiment config struct
%   read_results - step_read 的輸出
%
% Output:
%   results - 與 read_results 同結構，額外加入:
%       .steady_info  - detect_steady_state_relative 的輸出
%       .steady_ok    - logical

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_steady_state: %s\n', config.experiment_name);
        fprintf('========================================\n\n');
    end

    results = read_results;
    check_pts = config.steady_state.check_points;

    for i = 1:length(results)
        if ~results(i).success
            results(i).steady_info = struct();
            results(i).steady_ok = false;
            continue;
        end

        freq = results(i).frequency;
        fs = results(i).fs;

        if verbose
            fprintf('[%d/%d] %.1f Hz ... ', i, length(results), freq);
        end

        %% Adjust check_points for high frequency
        period_samples = round(fs / freq);
        actual_check_pts = min(check_pts, period_samples);

        %% Conservative: detect on analysis channel VM
        vm_ch = results(i).vm(:, results(i).analysis_ch);

        try
            steady_info = detect_steady_state_relative(vm_ch, freq, fs, ...
                'RelativeThreshold', config.steady_state.relative_threshold, ...
                'ConsecutivePeriods', config.steady_state.consecutive_periods, ...
                'CheckPoints', actual_check_pts, ...
                'Verbose', false);

            if steady_info.index > 0
                results(i).steady_info = steady_info;
                results(i).steady_ok = true;
                if verbose, fprintf('OK (start=%d, period=%d samples)\n', steady_info.index, steady_info.period_samples); end
            else
                %% Low-frequency fallback: use last periods
                total_samples = length(vm_ch);
                min_periods = config.steady_state.min_periods_for_fft;
                fallback_start = max(1, total_samples - min_periods * period_samples + 1);

                steady_info.index = fallback_start;
                steady_info.period_samples = period_samples;
                steady_info.max_periods = min_periods;
                results(i).steady_info = steady_info;
                results(i).steady_ok = true;

                if verbose, fprintf('FALLBACK (using last %d periods)\n', min_periods); end
            end

        catch ME
            results(i).steady_info = struct();
            results(i).steady_ok = false;
            if verbose, fprintf('ERROR: %s\n', ME.message); end
        end
    end

    %% Summary
    n_ok = sum([results.steady_ok]);
    if verbose
        fprintf('\nstep_steady_state complete: %d/%d detected.\n', n_ok, length(results));
    end
end
