% setup_controller.m
% 將控制器模型整合到 Control_System_Framework
%
% Usage:
%   setup_controller(controller_name, params)
%
% Inputs:
%   controller_name - 控制器模型名稱（不含 .slx），例如 'PI_controller'
%   params          - 控制器參數結構（可選）
%                     例如: params.Kp, params.Ki, params.Ts
%
% Example:
%   params.Kp = diag([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]);
%   params.Ki = diag([10, 10, 10, 10, 10, 10]);
%   params.Ts = 1e-5;
%   setup_controller('PI_controller', params);
%
% Author: Claude Code
% Date: 2025-10-09

function setup_controller(controller_name, params)
    %% Input validation
    if nargin < 1
        error('Usage: setup_controller(controller_name, params)');
    end

    if nargin < 2
        params = struct();
    end

    fprintf('=== Setting Up Controller ===\n');
    fprintf('Controller: %s.slx\n', controller_name);

    %% Check if controller model exists
    controller_path = fullfile('controllers', [controller_name '.slx']);

    if ~exist(controller_path, 'file')
        error('Controller model not found: %s\nPlease check controllers/ folder.', controller_path);
    end

    fprintf('  ✓ Controller model found: %s\n', controller_path);

    %% Load main framework
    main_model = 'Control_System_Framework';

    fprintf('\nLoading framework: %s.slx\n', main_model);

    if ~exist([main_model '.slx'], 'file')
        error('Framework model not found: %s.slx', main_model);
    end

    % Close if already loaded
    if bdIsLoaded(main_model)
        close_system(main_model, 0);
    end

    load_system(main_model);
    fprintf('  ✓ Framework loaded\n');

    %% Remove old controller (if exists)
    fprintf('\nRemoving old controller (if exists)...\n');

    try
        % Delete connections
        delete_line(main_model, 'Vd/1', 'Controller/1');
        delete_line(main_model, 'Mux_Vm/1', 'Controller/2');
        delete_line(main_model, 'Controller/1', 'u_in/1');
        fprintf('  ✓ Old controller connections deleted\n');
    catch
        % No old connections, that's fine
    end

    try
        % Delete controller block
        delete_block([main_model '/Controller']);
        fprintf('  ✓ Old controller block deleted\n');
    catch
        fprintf('  • No old controller found\n');
    end

    %% Add new controller using Model Reference
    fprintf('\nAdding new controller...\n');

    % Add Model Reference block
    add_block('simulink/Ports & Subsystems/Model', ...
              [main_model '/Controller']);

    % Set controller model name
    set_param([main_model '/Controller'], ...
              'ModelName', controller_name, ...
              'Position', [500, 180, 600, 220]);

    fprintf('  ✓ Controller block added (Model Reference)\n');

    %% Connect signals
    fprintf('\nConnecting signals...\n');

    % Vd → Controller input 1
    add_line(main_model, 'Vd/1', 'Controller/1', 'autorouting', 'on');
    fprintf('  ✓ Vd → Controller/1\n');

    % Mux_Vm → Controller input 2
    add_line(main_model, 'Mux_Vm/1', 'Controller/2', 'autorouting', 'on');
    fprintf('  ✓ Mux_Vm → Controller/2\n');

    % Controller output → u_in
    add_line(main_model, 'Controller/1', 'u_in/1', 'autorouting', 'on');
    fprintf('  ✓ Controller/1 → u_in\n');

    %% Update monitoring connections for error signal
    fprintf('\nUpdating error monitoring...\n');

    try
        % Connect controller error output (port 2) to Scope_e and e_log
        add_line(main_model, 'Controller/2', 'Scope_e/1', 'autorouting', 'on');
        add_line(main_model, 'Controller/2', 'e_log/1', 'autorouting', 'on');
        fprintf('  ✓ Error monitoring connected (Controller/2 → Scope_e, e_log)\n');
    catch ME
        fprintf('  ! Warning: Could not connect error monitoring: %s\n', ME.message);
    end

    %% Set parameters to workspace
    if ~isempty(fieldnames(params))
        fprintf('\nSetting parameters to workspace...\n');

        param_names = fieldnames(params);
        for i = 1:length(param_names)
            param_name = param_names{i};
            param_value = params.(param_name);

            assignin('base', param_name, param_value);
            fprintf('  ✓ %s: ', param_name);

            % Display parameter info
            if isscalar(param_value)
                fprintf('%.2e\n', param_value);
            elseif isvector(param_value)
                fprintf('[%d×1]\n', length(param_value));
            elseif ismatrix(param_value)
                fprintf('[%d×%d]\n', size(param_value, 1), size(param_value, 2));
            else
                fprintf('(set)\n');
            end
        end
    end

    %% Save framework
    fprintf('\nSaving framework...\n');
    save_system(main_model);
    fprintf('  ✓ Framework saved: %s.slx\n', main_model);

    %% Summary
    fprintf('\n=== Setup Complete ===\n');
    fprintf('Controller "%s" has been integrated into framework.\n', controller_name);
    fprintf('\nSignal Flow:\n');
    fprintf('  Vd (6×1) ────→ Controller/1\n');
    fprintf('  Mux_Vm (6×1) → Controller/2\n');
    fprintf('  Controller/1 → u_in (6×1)\n');
    fprintf('  Controller/2 → error monitoring\n');
    fprintf('\nNext Steps:\n');
    fprintf('  1. Run simulation: run_simulation(''%s'', sim_time)\n', main_model);
    fprintf('  2. Or use: example_run_PI.m for complete workflow\n');
    fprintf('\n');
end
