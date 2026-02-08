function step_compare(experiment_names, varargin)
%STEP_COMPARE 多實驗 Bode 比較圖
%
% Usage:
%   step_compare({'Hung', 'Hung_noring', 'NTU'})
%   step_compare({'Hung', 'NTU'}, 'SaveFigure', true)
%
% Input:
%   experiment_names - cell array of experiment names
%
% 順序固定: Hung → Hung(NoRing) → NTU (Hung 系列相鄰)
% 各自除以自己的 H(ω_ref) 正規化

    %% Parse options
    p = inputParser;
    addParameter(p, 'Verbose', true, @islogical);
    addParameter(p, 'SaveFigure', true, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.Verbose;
    save_fig = p.Results.SaveFigure;

    if verbose
        fprintf('\n========================================\n');
        fprintf('  step_compare: %s\n', strjoin(experiment_names, ' vs '));
        fprintf('========================================\n\n');
    end

    %% Get colors and markers
    colors = get_experiment_colors();

    %% Fixed display order: Hung → Hung_noring → NTU
    display_order = {'Hung', 'Hung_noring', 'NTU'};
    ordered_names = {};
    for k = 1:length(display_order)
        if any(strcmp(experiment_names, display_order{k}))
            ordered_names{end+1} = display_order{k}; %#ok<AGROW>
        end
    end
    % Append any remaining (non-standard) experiments
    for k = 1:length(experiment_names)
        if ~any(strcmp(ordered_names, experiment_names{k}))
            ordered_names{end+1} = experiment_names{k}; %#ok<AGROW>
        end
    end

    %% Load CSV data for each experiment
    n_exp = length(ordered_names);
    exp_data = cell(1, n_exp);
    project_root = fileparts(fileparts(mfilename('fullpath')));

    for i = 1:n_exp
        name = ordered_names{i};
        csv_path = fullfile(project_root, 'results', name, 'diagnostics', 'Raw_Bode_Data.csv');
        if ~exist(csv_path, 'file')
            error('step_compare:no_csv', 'CSV not found for %s: %s', name, csv_path);
        end
        exp_data{i} = readtable(csv_path);
        if verbose
            fprintf('Loaded: %s (%d points)\n', name, height(exp_data{i}));
        end
    end

    %% Normalization: each by its own H(ω_ref)
    H_ref = zeros(1, n_exp);
    phase_ref = zeros(1, n_exp);
    for i = 1:n_exp
        [~, idx] = min(abs(exp_data{i}.Frequency_Hz - 0.1));
        H_ref(i) = exp_data{i}.Magnitude_Linear(idx);
        phase_ref(i) = exp_data{i}.Phase_deg(idx);
        if verbose
            fprintf('  %s: H(0.1Hz) = %.4f, Phase(0.1Hz) = %.2f deg\n', ...
                ordered_names{i}, H_ref(i), phase_ref(i));
        end
    end

    %% Create Bode comparison plot
    fig = figure('Position', [100, 100, 900, 720], 'Name', 'Bode Comparison');

    freq_max = 2000;
    log_ticks = 10.^(-1:3);
    lw = 3.5;
    ms = 12;

    %% Magnitude subplot
    subplot(2, 1, 1);
    hold on;

    for i = 1:n_exp
        name = ordered_names{i};
        freq = exp_data{i}.Frequency_Hz;
        mag_dB = 20*log10(exp_data{i}.Magnitude_Linear / H_ref(i));

        c = colors.(name);
        semilogx(freq, mag_dB, [c.marker '-'], 'Color', c.rgb, ...
            'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none', ...
            'DisplayName', sprintf('%s (H(0.1)=%.4f)', c.display_name, H_ref(i)));
    end

    ylabel('Magnitude (dB)', 'FontWeight', 'bold', 'FontSize', 40);
    legend('Location', 'southwest', 'FontWeight', 'bold', 'FontSize', 22);
    set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks);
    ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
    box on;

    %% Phase subplot
    subplot(2, 1, 2);
    hold on;

    for i = 1:n_exp
        name = ordered_names{i};
        freq = exp_data{i}.Frequency_Hz;
        phase = exp_data{i}.Phase_deg - phase_ref(i);

        c = colors.(name);
        semilogx(freq, phase, [c.marker '-'], 'Color', c.rgb, ...
            'LineWidth', lw, 'MarkerSize', ms, 'MarkerFaceColor', 'none');
    end

    xlabel('Frequency (Hz)', 'FontWeight', 'bold', 'FontSize', 40);
    ylabel('Phase (deg)', 'FontWeight', 'bold', 'FontSize', 40);
    set(gca, 'FontWeight', 'bold', 'FontSize', 24, 'LineWidth', 2);
    set(gca, 'XScale', 'log', 'XLim', [0.1, freq_max], 'XTick', log_ticks);
    ax = gca; ax.XAxis.LineWidth = 3; ax.YAxis.LineWidth = 3;
    box on;

    %% Save
    if save_fig
        out_folder = fullfile(project_root, 'results');
        if ~exist(out_folder, 'dir'), mkdir(out_folder); end
        out_file = fullfile(out_folder, 'Comparison_Bode.png');
        exportgraphics(fig, out_file, 'Resolution', 150);
        if verbose, fprintf('\nSaved: %s\n', out_file); end
    end

    if verbose
        fprintf('\nstep_compare complete.\n');
    end
end
