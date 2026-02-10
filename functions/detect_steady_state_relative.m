function steady_info = detect_steady_state_relative(Vm_signal, target_freq, sampling_rate, varargin)
% DETECT_STEADY_STATE_RELATIVE Improved steady-state detection with relative threshold
%
% This function wraps detect_steady_state.m and uses a relative threshold
% based on signal amplitude instead of a fixed absolute threshold.
%
% Syntax:
%   steady_info = detect_steady_state_relative(Vm_signal, target_freq, sampling_rate)
%   steady_info = detect_steady_state_relative(..., 'Name', Value)
%
% Inputs:
%   Vm_signal      - Vm signal vector (N x 1)
%   target_freq    - Target frequency [Hz]
%   sampling_rate  - Sampling rate [Hz]
%
% Name-Value Parameters:
%   'RelativeThreshold'   - Relative threshold (0~1, default: 0.002 = 0.2%)
%   'ConsecutivePeriods'  - Number of consecutive stable periods (default: 3)
%   'CheckPoints'         - Number of check points per period (default: 25)
%   'Verbose'             - Display detailed information (default: true)
%
% Output:
%   steady_info - Structure with fields:
%       .index                      - Steady-state start index
%       .period                     - Steady-state start period number
%       .period_samples             - Samples per period
%       .max_periods                - Available complete periods
%       .signal_amplitude           - Signal peak-to-peak amplitude [V]
%       .relative_threshold_percent - Relative threshold [%]
%       .absolute_threshold         - Calculated absolute threshold [V]
%
% Example:
%   steady_info = detect_steady_state_relative(Vm, 100, 20000, ...
%       'RelativeThreshold', 0.002, 'Verbose', true);
%
% Key Advantage:
%   Adaptive threshold that works for both:
%   - Low-freq high-amplitude signals (0.1 Hz, ~0.2V) → higher threshold
%   - High-freq low-amplitude signals (2000 Hz, ~0.02V) → lower threshold
%
% See also: detect_steady_state

% Author: Claude Code
% Date: 2026-02-04

    %% Parse input arguments
    p = inputParser;
    addRequired(p, 'Vm_signal', @(x) isnumeric(x) && isvector(x));
    addRequired(p, 'target_freq', @(x) isnumeric(x) && isscalar(x) && x > 0);
    addRequired(p, 'sampling_rate', @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'RelativeThreshold', 0.002, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'ConsecutivePeriods', 3, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'CheckPoints', 25, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, Vm_signal, target_freq, sampling_rate, varargin{:});
    opts = p.Results;

    % Ensure Vm_signal is a column vector
    Vm_signal = Vm_signal(:);

    %% Calculate signal amplitude (peak-to-peak)
    signal_amplitude = max(Vm_signal) - min(Vm_signal);

    %% Calculate absolute threshold from relative percentage
    absolute_threshold = signal_amplitude * opts.RelativeThreshold;

    if opts.Verbose
        fprintf('  Relative threshold detection:\n');
        fprintf('    Signal amplitude: %.4e V (peak-to-peak)\n', signal_amplitude);
        fprintf('    Relative threshold: %.2f%%\n', opts.RelativeThreshold * 100);
        fprintf('    Absolute threshold: %.4e V\n', absolute_threshold);
    end

    %% Call original detect_steady_state with calculated threshold
    steady_info = detect_steady_state(Vm_signal, target_freq, sampling_rate, ...
        'StabilityThreshold', absolute_threshold, ...
        'ConsecutivePeriods', opts.ConsecutivePeriods, ...
        'CheckPoints', opts.CheckPoints, ...
        'Verbose', opts.Verbose);

    %% Append additional information to output
    steady_info.signal_amplitude = signal_amplitude;
    steady_info.relative_threshold_percent = opts.RelativeThreshold * 100;
    steady_info.absolute_threshold = absolute_threshold;

end
