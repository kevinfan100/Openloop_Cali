% run_simulation.m
% 執行 Simulink 模擬並回傳結果
%
% Usage:
%   sim_results = run_simulation(model_name, sim_time)
%   sim_results = run_simulation(model_name, sim_time, solver_options)
%
% Inputs:
%   model_name      - 模型名稱（例如 'Control_System_Framework'）
%   sim_time        - 模擬時間（秒）
%   solver_options  - 求解器選項結構（可選）
%                     .Solver    - 求解器類型（預設 'ode45'）
%                     .MaxStep   - 最大步長（預設 1e-6）
%                     .RelTol    - 相對誤差容忍度（預設 1e-3）
%
% Outputs:
%   sim_results - 結構，包含模擬結果
%     .t          - 時間向量 (N×1)
%     .u          - 控制訊號 (N×6)
%     .e          - 誤差訊號 (N×6)
%     .Vm         - 測量輸出（數位）(N×6)
%     .Vm_analog  - 測量輸出（類比）(N×6)
%     .Vm_final   - 最終輸出值 (6×1)
%     .e_final    - 最終誤差值 (6×1)
%
% Example:
%   sim_results = run_simulation('Control_System_Framework', 0.01);
%   plot(sim_results.t, sim_results.Vm(:,1));
%
% Author: Claude Code
% Date: 2025-10-09

function sim_results = run_simulation(model_name, sim_time, solver_options)
    %% Input validation
    if nargin < 2
        error('Usage: run_simulation(model_name, sim_time, [solver_options])');
    end

    if nargin < 3
        solver_options = struct();
    end

    % Default solver options
    if ~isfield(solver_options, 'Solver')
        solver_options.Solver = 'ode45';
    end
    if ~isfield(solver_options, 'MaxStep')
        solver_options.MaxStep = 1e-6;  % 1 μs (1/10 of sample time)
    end
    if ~isfield(solver_options, 'RelTol')
        solver_options.RelTol = 1e-3;
    end

    fprintf('=== Running Simulation ===\n');
    fprintf('Model: %s\n', model_name);
    fprintf('Simulation time: %.4f s\n', sim_time);
    fprintf('Solver: %s\n', solver_options.Solver);
    fprintf('Max step: %.2e s\n', solver_options.MaxStep);
    fprintf('\n');

    %% Check if model exists
    if ~exist([model_name '.slx'], 'file')
        error('Model not found: %s.slx', model_name);
    end

    %% Load model
    if ~bdIsLoaded(model_name)
        load_system(model_name);
        fprintf('Model loaded.\n');
    end

    %% Configure simulation parameters
    fprintf('Configuring solver...\n');

    set_param(model_name, 'Solver', solver_options.Solver);
    set_param(model_name, 'MaxStep', num2str(solver_options.MaxStep));
    set_param(model_name, 'RelTol', num2str(solver_options.RelTol));
    set_param(model_name, 'StopTime', num2str(sim_time));

    % Enable fast restart for faster subsequent simulations
    set_param(model_name, 'FastRestart', 'off');  % Ensure clean simulation

    fprintf('  ✓ Solver configured\n');

    %% Run simulation
    fprintf('\nStarting simulation...\n');
    tic;

    try
        sim_out = sim(model_name);
        elapsed = toc;
        fprintf('  ✓ Simulation completed in %.2f seconds\n', elapsed);
    catch ME
        fprintf('  ✗ Simulation failed!\n');
        fprintf('Error: %s\n', ME.message);
        rethrow(ME);
    end

    %% Extract results from workspace
    fprintf('\nExtracting results...\n');

    try
        % Get data from workspace (To Workspace blocks)
        u_data = evalin('base', 'u');
        e_data = evalin('base', 'e');
        Vm_data = evalin('base', 'Vm');
        Vm_analog_data = evalin('base', 'Vm_analog');

        % Extract time and data
        sim_results.t = u_data.time;
        sim_results.u = u_data.Data;
        sim_results.e = e_data.Data;
        sim_results.Vm = Vm_data.Data;
        sim_results.Vm_analog = Vm_analog_data.Data;

        % Calculate final values
        sim_results.Vm_final = sim_results.Vm(end, :)';
        sim_results.e_final = sim_results.e(end, :)';

        fprintf('  ✓ Results extracted\n');
    catch ME
        fprintf('  ✗ Failed to extract results!\n');
        fprintf('Error: %s\n', ME.message);
        fprintf('\nPlease check:\n');
        fprintf('  - To Workspace blocks exist in model\n');
        fprintf('  - Variable names: u, e, Vm, Vm_analog\n');
        rethrow(ME);
    end

    %% Display summary
    fprintf('\n=== Simulation Summary ===\n');
    fprintf('Time points: %d\n', length(sim_results.t));
    fprintf('Time range: [%.4f, %.4f] s\n', sim_results.t(1), sim_results.t(end));
    fprintf('\nFinal values:\n');
    fprintf('  Channel | Vm_final | e_final\n');
    fprintf('  --------|----------|--------\n');
    for ch = 1:6
        fprintf('    %d     | %8.4f | %7.4f\n', ...
            ch, sim_results.Vm_final(ch), sim_results.e_final(ch));
    end

    % Calculate max control effort
    u_max = max(abs(sim_results.u), [], 1);
    fprintf('\nMax control effort |u|:\n');
    fprintf('  ');
    for ch = 1:6
        fprintf('Ch%d: %.2f  ', ch, u_max(ch));
    end
    fprintf('\n');

    fprintf('\n=== Simulation Complete ===\n');
    fprintf('Results stored in sim_results structure.\n');
    fprintf('\n');
end
