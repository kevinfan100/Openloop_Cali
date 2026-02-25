function run_charge_cali(experiment, mode, varargin)
%RUN_CHARGE_CALI Charge calibration entry point
%
% Usage:
%   run_charge_cali('Charge_Hung', 'full')                        % complete pipeline
%   run_charge_cali('Charge_Hung', 'full', 'fit_frequencies', [0.1, 1])
%   run_charge_cali('Charge_Hung', 'fit')                         % from CSV
%   run_charge_cali('Charge_Hung', 'plot')                        % from .mat
%
% Modes:
%   'full' - read .dat -> CSV -> fit -> plot
%   'fit'  - from CSV  -> fit -> plot
%   'plot' - from .mat -> plot

    %% Setup paths
    charge_root = fileparts(mfilename('fullpath'));
    project_root = fileparts(charge_root);

    % Add parent functions/ (read_hsdata, detect_steady_state_relative, compute_super_period)
    addpath(fullfile(project_root, 'functions'));
    % Add charge_cali/ itself (config, step_charge, fit_charge_model)
    addpath(charge_root);

    %% Load config
    config_func = str2func([experiment '_config']);
    try
        config = config_func();
    catch ME
        error('run_charge_cali:config_not_found', ...
            'Config not found: %s_config.m\nError: %s', experiment, ME.message);
    end

    %% Ensure output directories exist
    dirs = {config.output_folder; ...
        fullfile(config.output_folder, 'diagnostics'); ...
        fullfile(config.output_folder, 'figures'); ...
        fullfile(config.output_folder, 'fitting_results')};
    for i = 1:length(dirs)
        if ~exist(dirs{i}, 'dir'), mkdir(dirs{i}); end
    end

    %% Execute pipeline
    fprintf('\n========================================\n');
    fprintf('  Charge Calibration: %s / %s\n', experiment, mode);
    fprintf('========================================\n\n');

    step_charge(config, mode, varargin{:});

    fprintf('\n========================================\n');
    fprintf('  run_charge_cali complete: %s / %s\n', experiment, mode);
    fprintf('========================================\n\n');
end
