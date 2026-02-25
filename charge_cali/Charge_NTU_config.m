function config = Charge_NTU_config()
%CHARGE_NTU_CONFIG Charge calibration (NTU) configuration
%
% Standalone config — does not depend on default_config.
% Data layout: data_folder/<distance>um/<prefix>_<dist>um_<freq>hz.dat
% 10 distances (50~500 um) x 15 frequencies, V8 format, 20kHz

    charge_root = fileparts(mfilename('fullpath'));

    %% Experiment identity
    config.experiment_name = 'Charge_NTU';
    config.display_name = 'Charge Calibration (NTU)';
    config.data_prefix = 'charge_cali';

    %% Hardware (same as default_config)
    config.expected_sampling_rate = 20000;      % Hz
    config.excitation_channel = 2;
    config.analysis_channel = 2;
    config.dac.zero_offset = 32768;
    config.dac.voltage_range = 20.0;            % +/-10V
    config.dac.resolution = 65536;              % 16-bit

    %% 15-point frequency table
    config.expected_frequencies = [0.1, 1, 10, 50, 100, 200, 500, 1000, ...
                                   1200, 1250, 1500, 1600, 2000, 2500, 3000];

    %% Paths
    config.data_folder = fullfile(charge_root, 'data', 'charge_cali_NTU', 'NTU_charge_cali');
    config.output_folder = fullfile(charge_root, 'results', 'Charge_NTU');

    %% Steady-state detection
    config.steady_state.relative_threshold = 0.002;   % 0.2%
    config.steady_state.consecutive_periods = 3;
    config.steady_state.check_points = 25;
    config.steady_state.min_periods_for_fft = 2;

    %% FFT
    config.fft.thd_harmonics = 2:10;
    config.fft.thd_max_freq_ratio = 0.8;

    %% Charge calibration specific
    config.charge.fit_frequencies = [0.1, 1, 10];     % Hz subset for fitting
    config.charge.distance_unit = 'um';

    %% Plot style (same as default_config)
    config.plot.line_width = 3.5;
    config.plot.marker_size = 12;
    config.plot.font_size_tick = 24;
    config.plot.font_size_label = 40;
    config.plot.font_size_legend = 22;
    config.plot.font_size_title = 24;
    config.plot.axis_line_width = 3;
end
