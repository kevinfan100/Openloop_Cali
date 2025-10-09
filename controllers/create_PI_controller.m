% create_PI_controller.m
% 建立離散 PI 控制器模型
%
% Controller Architecture:
%   Inputs:  Vd (6×1) - Reference signal
%            Vm (6×1) - Measured output
%   Outputs: u  (6×1) - Control signal
%            e  (6×1) - Error signal (for monitoring)
%
% Control Law (for each channel):
%   e[k] = Vd[k] - Vm[k]
%   u[k] = Kp * e[k] + Ki * Ts * Σe[i]  (i=0 to k)
%
% Parameters (from workspace):
%   Kp - Proportional gain (6×6 diagonal matrix)
%   Ki - Integral gain (6×6 diagonal matrix)
%   Ts_controller - Sample time (scalar, default 1e-5)
%
% Author: Claude Code
% Date: 2025-10-09

function create_PI_controller()
    %% Configuration
    model_name = 'PI_controller';

    fprintf('=== Creating PI Controller Model ===\n');
    fprintf('Model name: %s.slx\n\n', model_name);

    %% Close and delete existing model
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end

    if exist([model_name '.slx'], 'file')
        delete([model_name '.slx']);
        fprintf('Deleted existing model file.\n');
    end

    %% Create new model
    new_system(model_name);
    open_system(model_name);

    %% Layout parameters
    input_x = 100;
    demux_x = 250;
    error_x = 400;
    pid_x = 600;
    mux_x = 850;
    output_x = 1000;

    main_y = 300;
    spacing = 60;

    %% Section 1: Input ports
    fprintf('Creating input ports...\n');

    % Input 1: Vd (reference)
    add_block('simulink/Sources/In1', [model_name '/Vd']);
    set_param([model_name '/Vd'], ...
        'Port', '1', ...
        'Position', [input_x, main_y-spacing-10, input_x+30, main_y-spacing+10]);

    % Input 2: Vm (measured output)
    add_block('simulink/Sources/In1', [model_name '/Vm']);
    set_param([model_name '/Vm'], ...
        'Port', '2', ...
        'Position', [input_x, main_y+spacing-10, input_x+30, main_y+spacing+10]);

    %% Section 2: Demux input signals
    fprintf('Creating demux blocks...\n');

    % Demux Vd
    add_block('simulink/Signal Routing/Demux', [model_name '/Demux_Vd']);
    set_param([model_name '/Demux_Vd'], ...
        'Outputs', '6', ...
        'Position', [demux_x, main_y-spacing-60, demux_x+10, main_y-spacing+240]);
    add_line(model_name, 'Vd/1', 'Demux_Vd/1', 'autorouting', 'on');

    % Demux Vm
    add_block('simulink/Signal Routing/Demux', [model_name '/Demux_Vm']);
    set_param([model_name '/Demux_Vm'], ...
        'Outputs', '6', ...
        'Position', [demux_x, main_y+spacing-60, demux_x+10, main_y+spacing+240]);
    add_line(model_name, 'Vm/1', 'Demux_Vm/1', 'autorouting', 'on');

    %% Section 3: Error calculation and PI controllers
    fprintf('Creating 6 error calculation and PI controller blocks...\n');

    for i = 1:6
        % Y position for this channel
        y_pos = main_y - 150 + (i-1)*spacing;

        % Sum block for error calculation (e = Vd - Vm)
        sum_name = sprintf('%s/Error_Ch%d', model_name, i);
        add_block('simulink/Math Operations/Sum', sum_name);
        set_param(sum_name, ...
            'Inputs', '+-', ...
            'IconShape', 'rectangular', ...
            'Position', [error_x, y_pos-10, error_x+30, y_pos+10]);

        % Connect Demux_Vd → Error
        add_line(model_name, sprintf('Demux_Vd/%d', i), sprintf('Error_Ch%d/1', i), 'autorouting', 'on');

        % Connect Demux_Vm → Error
        add_line(model_name, sprintf('Demux_Vm/%d', i), sprintf('Error_Ch%d/2', i), 'autorouting', 'on');

        % Discrete PID Controller (D = 0 → PI only)
        pid_name = sprintf('%s/PI_Ch%d', model_name, i);
        add_block('simulink/Discrete/Discrete PID Controller', pid_name);
        set_param(pid_name, ...
            'P', sprintf('Kp(%d,%d)', i, i), ...  % Read from diagonal
            'I', sprintf('Ki(%d,%d)', i, i), ...  % Read from diagonal
            'D', '0', ...                          % No derivative
            'N', '100', ...                        % Filter coefficient (not used)
            'SampleTime', 'Ts_controller', ...     % Sample time from workspace
            'InitialConditionForIntegrator', '0', ...
            'Position', [pid_x, y_pos-20, pid_x+60, y_pos+20]);

        % Connect Error → PI
        add_line(model_name, sprintf('Error_Ch%d/1', i), sprintf('PI_Ch%d/1', i), 'autorouting', 'on');
    end

    %% Section 4: Mux outputs
    fprintf('Creating mux blocks...\n');

    % Mux for control signal u
    add_block('simulink/Signal Routing/Mux', [model_name '/Mux_u']);
    set_param([model_name '/Mux_u'], ...
        'Inputs', '6', ...
        'Position', [mux_x, main_y-150, mux_x+10, mux_x-main_y+450]);

    for i = 1:6
        add_line(model_name, sprintf('PI_Ch%d/1', i), sprintf('Mux_u/%d', i), 'autorouting', 'on');
    end

    % Mux for error signal e (monitoring)
    add_block('simulink/Signal Routing/Mux', [model_name '/Mux_e']);
    set_param([model_name '/Mux_e'], ...
        'Inputs', '6', ...
        'Position', [mux_x, main_y+200, mux_x+10, mux_x-main_y+800]);

    for i = 1:6
        add_line(model_name, sprintf('Error_Ch%d/1', i), sprintf('Mux_e/%d', i), 'autorouting', 'on');
    end

    %% Section 5: Output ports
    fprintf('Creating output ports...\n');

    % Output 1: u (control signal)
    add_block('simulink/Sinks/Out1', [model_name '/u']);
    set_param([model_name '/u'], ...
        'Port', '1', ...
        'Position', [output_x, main_y-10, output_x+30, main_y+10]);
    add_line(model_name, 'Mux_u/1', 'u/1', 'autorouting', 'on');

    % Output 2: e (error signal, for monitoring)
    add_block('simulink/Sinks/Out1', [model_name '/e']);
    set_param([model_name '/e'], ...
        'Port', '2', ...
        'Position', [output_x, main_y+440-10, output_x+30, main_y+440+10]);
    add_line(model_name, 'Mux_e/1', 'e/1', 'autorouting', 'on');

    %% Section 6: Annotations
    fprintf('Adding annotations...\n');

    annotation_text = sprintf(['PI Controller (6 Independent Channels)\n' ...
                               'Created: 2025-10-09\n\n' ...
                               'INPUTS:\n' ...
                               '  Vd (6×1) - Reference signal\n' ...
                               '  Vm (6×1) - Measured output\n\n' ...
                               'OUTPUTS:\n' ...
                               '  u (6×1) - Control signal\n' ...
                               '  e (6×1) - Error signal (monitoring)\n\n' ...
                               'CONTROL LAW (each channel):\n' ...
                               '  e[k] = Vd[k] - Vm[k]\n' ...
                               '  u[k] = Kp*e[k] + Ki*Ts*Σe[i]\n\n' ...
                               'PARAMETERS (from workspace):\n' ...
                               '  Kp - Proportional gain (6×6 diagonal)\n' ...
                               '  Ki - Integral gain (6×6 diagonal)\n' ...
                               '  Ts_controller - Sample time (default 1e-5)']);

    add_block('built-in/Note', [model_name '/Info'], ...
              'Position', [50, 50], ...
              'Text', annotation_text, ...
              'FontSize', '10', ...
              'FontWeight', 'bold');

    % Labels
    add_block('built-in/Note', [model_name '/Label_Input'], ...
              'Position', [input_x, main_y-150], ...
              'Text', 'INPUTS', ...
              'FontSize', '12', ...
              'FontWeight', 'bold', ...
              'ForegroundColor', 'blue');

    add_block('built-in/Note', [model_name '/Label_PI'], ...
              'Position', [pid_x+30, main_y-180], ...
              'Text', 'PI CONTROLLERS', ...
              'FontSize', '12', ...
              'FontWeight', 'bold', ...
              'ForegroundColor', 'green');

    add_block('built-in/Note', [model_name '/Label_Output'], ...
              'Position', [output_x, main_y-150], ...
              'Text', 'OUTPUTS', ...
              'FontSize', '12', ...
              'FontWeight', 'bold', ...
              'ForegroundColor', 'blue');

    %% Save model
    save_system(model_name, model_name);

    fprintf('\n✓ PI Controller model created: %s.slx\n', model_name);
    fprintf('\nModel Summary:\n');
    fprintf('  Inputs:  Vd (6×1), Vm (6×1)\n');
    fprintf('  Outputs: u (6×1), e (6×1)\n');
    fprintf('  Controllers: 6 independent discrete PI\n');
    fprintf('  Parameters: Kp, Ki (6×6 diagonal), Ts_controller\n');
    fprintf('\nNext Steps:\n');
    fprintf('  1. Use setup_controller.m to integrate into framework\n');
    fprintf('  2. Set Kp, Ki, Ts_controller in workspace\n');
    fprintf('  3. Run simulation with example_run_PI.m\n');
    fprintf('\n');
end
