function run_analysis(experiment, step, varargin)
%RUN_ANALYSIS 統一分析入口
%
% Usage:
%   run_analysis('Hung', 'all')                    % 完整 pipeline
%   run_analysis('Hung', 'fft')                    % 從 FFT 開始 (需先跑 read)
%   run_analysis('Hung', 'fit')                    % 自動載入 CSV
%   run_analysis('Hung', 'fit', 'wc_Hz', 50)       % 覆寫參數
%   run_analysis('Hung', 'plot')                   % 只畫圖
%   run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare')  % 多實驗比較
%
% Steps:
%   'all'     - read → steady_state → fft → fit → plot
%   'read'    - 只讀取
%   'fft'     - read → steady_state → fft
%   'fit'     - 從 CSV fitting (不需 .dat)
%   'plot'    - 從 CSV 或 fit_results 畫圖
%   'compare' - 多實驗比較 (experiment 需為 cell array)
%
% MIMO modes (experiment='MIMO'):
%   'mimo_fft'  - Stage 1: 數據 → 原始 CSV
%   'mimo_fit'  - Stage 2: 相位修正 → 擬合 → 圖
%   'mimo_all'  - 兩階段完整流程
%   'mimo_plot' - 從 .mat 重新畫圖
%
% Optional Name-Value pairs (forward to step_fit):
%   'wc_Hz'    - 覆寫截止頻率
%   'p_weight' - 覆寫加權指數

    %% Handle 'compare' mode
    if iscell(experiment) || strcmpi(step, 'compare')
        if ~iscell(experiment)
            experiment = {experiment};
        end
        setup_paths();
        step_compare(experiment, varargin{:});
        return;
    end

    %% Load config
    setup_paths();
    config = load_config(experiment);

    %% Ensure output directories exist
    dirs = {config.output_folder; ...
        fullfile(config.output_folder, 'diagnostics'); ...
        fullfile(config.output_folder, 'figures'); ...
        fullfile(config.output_folder, 'fitting_results')};
    for i = 1:length(dirs)
        if ~exist(dirs{i}, 'dir'), mkdir(dirs{i}); end
    end

    %% Execute pipeline
    switch lower(step)
        case 'all'
            read_results = step_read(config, varargin{:});
            ss_results = step_steady_state(config, read_results, varargin{:});
            bode_table = step_fft(config, ss_results, varargin{:});
            fit_results = step_fit(config, bode_table, varargin{:});
            step_plot(config, fit_results, varargin{:});

        case 'read'
            step_read(config, varargin{:});

        case 'fft'
            read_results = step_read(config, varargin{:});
            ss_results = step_steady_state(config, read_results, varargin{:});
            step_fft(config, ss_results, varargin{:});

        case 'fit'
            fit_results = step_fit(config, [], 'FromCSV', true, varargin{:});
            step_plot(config, fit_results, varargin{:});

        case 'plot'
            % Try to load existing fit_results, otherwise data-only
            fit_mat = fullfile(config.output_folder, 'fitting_results', 'fit_results.mat');
            if exist(fit_mat, 'file')
                loaded = load(fit_mat);
                step_plot(config, loaded.fit_results, varargin{:});
            else
                step_plot(config, [], 'DataOnly', true, 'FromCSV', true, varargin{:});
            end

        case 'mimo_fft'
            step_mimo_fft(config, varargin{:});

        case 'mimo_fit'
            fit_results = step_mimo_fit(config, [], [], [], varargin{:});
            step_mimo_plot(config, fit_results, varargin{:});

        case 'mimo_all'
            [H_mag, H_phase_raw, frequencies] = step_mimo_fft(config, varargin{:});
            fit_results = step_mimo_fit(config, H_mag, H_phase_raw, frequencies, varargin{:});
            step_mimo_plot(config, fit_results, varargin{:});

        case 'mimo_plot'
            fit_mat = fullfile(config.output_folder, 'fitting_results', 'mimo_fit_results.mat');
            if ~exist(fit_mat, 'file')
                error('run_analysis:mimo_mat_not_found', ...
                    'File not found: %s\nRun mimo_all or mimo_fit first.', fit_mat);
            end
            loaded = load(fit_mat);
            step_mimo_plot(config, loaded.fit_results, varargin{:});

        otherwise
            error('run_analysis:unknown_step', ...
                'Unknown step: %s\nValid: all, read, fft, fit, plot, compare, mimo_fft, mimo_fit, mimo_all, mimo_plot', step);
    end

    fprintf('\n========================================\n');
    fprintf('  run_analysis complete: %s / %s\n', experiment, step);
    fprintf('========================================\n\n');
end

function setup_paths()
    project_root = fileparts(mfilename('fullpath'));
    addpath(fullfile(project_root, 'functions'));
    addpath(fullfile(project_root, 'configs'));
    addpath(fullfile(project_root, 'pipeline'));
end

function config = load_config(experiment_name)
    config_func = str2func([experiment_name '_config']);
    try
        config = config_func();
    catch ME
        error('run_analysis:config_not_found', ...
            'Config not found: %s_config.m\nError: %s', experiment_name, ME.message);
    end
end
