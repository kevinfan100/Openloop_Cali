function results = step_read(config, varargin)
%STEP_READ 讀取 .dat 檔案 + DAC 轉換 + Sanity Check
%
% Usage:
%   results = step_read(config)
%   results = step_read(config, 'Verbose', true)
%
% Input:
%   config - experiment config struct (from configs/)
%
% Output:
%   results - struct array (1 per frequency) with fields:
%       .frequency      - target frequency [Hz]
%       .filename       - source filename
%       .vm             - [N x 6] VM data (float)
%       .da_volt        - [N x 6] DAC converted to voltage
%       .fs             - sampling rate [Hz]
%       .excite_ch      - excitation channel
%       .header         - header info (if available)
%       .success        - logical

    %% Parse options
    p = inputParser;
    p.KeepUnmatched = true;
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_read: %s\n', config.experiment_name);
        fprintf('========================================\n\n');
    end

    n_files = length(config.data_files);
    results = struct('frequency', {}, 'filename', {}, 'vm', {}, 'da_volt', {}, ...
                     'fs', {}, 'excite_ch', {}, 'analysis_ch', {}, 'header', {}, 'success', {});

    for i = 1:n_files
        filepath = fullfile(config.data_folder, config.data_files{i});
        target_freq = config.expected_frequencies(i);

        if verbose
            fprintf('[%d/%d] %.1f Hz ... ', i, n_files, target_freq);
        end

        try
            %% Read binary
            data = read_hsdata(filepath);

            %% DAC → Voltage
            da_volt = (double(data.da) - config.dac.zero_offset) * ...
                      (config.dac.voltage_range / config.dac.resolution);

            %% Sanity checks (L1)
            fs = data.sampling_rate;
            if abs(fs - config.expected_sampling_rate) > 1
                warning('step_read:fs_mismatch', ...
                    'Sampling rate mismatch: header=%.0f, expected=%.0f', ...
                    fs, config.expected_sampling_rate);
            end

            if isfield(data, 'channel') && data.channel ~= config.excitation_channel
                warning('step_read:channel_mismatch', ...
                    'Excitation channel mismatch: header=%d, expected=%d', ...
                    data.channel, config.excitation_channel);
            end

            if isfield(data, 'loop_mode') && data.loop_mode ~= config.expected_loop_mode
                warning('step_read:loop_mode', ...
                    'Loop mode mismatch: header=%d, expected=%d', ...
                    data.loop_mode, config.expected_loop_mode);
            end

            if isfield(data, 'frequency')
                freq_err = abs(data.frequency - target_freq) / max(target_freq, 0.01);
                if freq_err > 0.05
                    warning('step_read:freq_mismatch', ...
                        'Frequency mismatch: header=%.2f, expected=%.2f', ...
                        data.frequency, target_freq);
                end
            end

            %% Bad point repair (100kHz only)
            if config.enable_bad_point_repair && fs >= 100000
                [vm_clean, da_clean] = repair_bad_points(data.vm, da_volt, ...
                    'BadPointInterval', config.bad_point_interval);
            else
                vm_clean = data.vm;
                da_clean = da_volt;
            end

            %% Store result
            r = struct();
            r.frequency = target_freq;
            r.filename = config.data_files{i};
            r.vm = vm_clean;
            r.da_volt = da_clean;
            r.fs = fs;
            r.excite_ch = data.channel;
            r.analysis_ch = config.analysis_channel;
            r.header = rmfield(data, {'vm', 'vd', 'da', 'debug'});
            r.success = true;
            results(end+1) = r; %#ok<AGROW>

            if verbose, fprintf('OK (%d samples)\n', size(vm_clean, 1)); end

        catch ME
            if verbose, fprintf('ERROR: %s\n', ME.message); end

            r = struct();
            r.frequency = target_freq;
            r.filename = config.data_files{i};
            r.vm = [];
            r.da_volt = [];
            r.fs = 0;
            r.excite_ch = 0;
            r.analysis_ch = 0;
            r.header = struct();
            r.success = false;
            results(end+1) = r; %#ok<AGROW>
        end
    end

    %% Summary
    n_success = sum([results.success]);
    if verbose
        fprintf('\nstep_read complete: %d/%d files loaded.\n', n_success, n_files);
    end
end
