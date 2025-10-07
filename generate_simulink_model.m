% generate_simulink_model.m
% Auto-generate Simulink model with 36 independent transfer functions
%
% Purpose:
%   Create a 6×6 MIMO Simulink model where each input-output pair has
%   its own second-order transfer function H_ij(s) = b(i,j)/(s²+a1(i,j)s+a2(i,j))
%
% Usage:
%   1. Run Model_6_6_Continuous_Weighted.m to generate one_curve_36_results.mat
%   2. Run this script: generate_simulink_model
%   3. Open the generated model: open_system('MIMO_36Channel_Model.slx')
%
% Output:
%   MIMO_36Channel_Model.slx - Simulink model file

function generate_simulink_model()
    %% Load transfer function data
    if ~exist('one_curve_36_results.mat', 'file')
        error(['one_curve_36_results.mat not found!\n' ...
               'Please run Model_6_6_Continuous_Weighted.m first.']);
    end

    load('one_curve_36_results.mat', 'one_curve_results');

    a1_matrix = one_curve_results.a1_matrix;
    a2_matrix = one_curve_results.a2_matrix;
    b_matrix = one_curve_results.b_matrix;

    fprintf('Loaded transfer function parameters from one_curve_36_results.mat\n');
    fprintf('Building Simulink model with 36 transfer functions...\n\n');

    %% Model configuration
    model_name = 'MIMO_36Channel_Model';

    % Close model if already open
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end

    % Create new model
    new_system(model_name);
    open_system(model_name);

    %% Layout parameters
    input_x = 100;
    output_x = 900;
    tf_base_x = 400;

    row_spacing = 120;
    col_spacing = 250;

    sum_y_offset = 60;

    %% Add input ports (6 inputs: P1~P6)
    input_blocks = cell(6, 1);
    for i = 1:6
        block_name = sprintf('%s/Input_P%d', model_name, i);
        add_block('simulink/Sources/In1', block_name);
        set_param(block_name, 'Position', [input_x, 50 + (i-1)*row_spacing, input_x+30, 65 + (i-1)*row_spacing]);
        input_blocks{i} = block_name;
    end

    %% Add output ports (6 outputs: Ch1~Ch6)
    output_blocks = cell(6, 1);
    for i = 1:6
        block_name = sprintf('%s/Output_Ch%d', model_name, i);
        add_block('simulink/Sinks/Out1', block_name);
        set_param(block_name, 'Position', [output_x, 50 + (i-1)*row_spacing, output_x+30, 65 + (i-1)*row_spacing]);
        output_blocks{i} = block_name;
    end

    %% Add transfer functions and sum blocks
    fprintf('Creating transfer function blocks:\n');

    for i = 1:6  % Output channel
        % Create sum block for output i (sums contributions from all 6 inputs)
        sum_block_name = sprintf('%s/Sum_Ch%d', model_name, i);
        add_block('simulink/Math Operations/Sum', sum_block_name);
        sum_pos_y = 50 + (i-1)*row_spacing + sum_y_offset;
        set_param(sum_block_name, 'Position', [output_x-120, sum_pos_y, output_x-100, sum_pos_y+20]);
        set_param(sum_block_name, 'Inputs', '++++++');  % 6 inputs

        % Connect sum block to output port
        add_line(model_name, sprintf('Sum_Ch%d/1', i), sprintf('Output_Ch%d/1', i), 'autorouting', 'on');

        for j = 1:6  % Input channel
            % Transfer function H_ij(s) = b(i,j) / (s² + a1(i,j)·s + a2(i,j))
            a1_ij = a1_matrix(i, j);
            a2_ij = a2_matrix(i, j);
            b_ij = b_matrix(i, j);

            % Create transfer function block
            tf_block_name = sprintf('%s/TF_H%d%d', model_name, i, j);
            add_block('simulink/Continuous/Transfer Fcn', tf_block_name);

            % Position: stagger based on input and output indices
            tf_x = tf_base_x + (j-1)*30;
            tf_y = 50 + (i-1)*row_spacing + (j-1)*15;
            set_param(tf_block_name, 'Position', [tf_x, tf_y, tf_x+60, tf_y+30]);

            % Set transfer function coefficients
            % Numerator: [b]
            % Denominator: [1, a1, a2]
            set_param(tf_block_name, 'Numerator', sprintf('[%.12e]', b_ij));
            set_param(tf_block_name, 'Denominator', sprintf('[1, %.12e, %.12e]', a1_ij, a2_ij));

            % Connect input port to TF block
            add_line(model_name, sprintf('Input_P%d/1', j), sprintf('TF_H%d%d/1', i, j), 'autorouting', 'on');

            % Connect TF block to sum block
            add_line(model_name, sprintf('TF_H%d%d/1', i, j), sprintf('Sum_Ch%d/%d', i, j), 'autorouting', 'on');

            fprintf('  H_%d%d: b=%.4e, a1=%.4e, a2=%.4e\n', i, j, b_ij, a1_ij, a2_ij);
        end
    end

    %% Add annotations
    annotation_text = sprintf(['MIMO 6×6 Transfer Function Model\n' ...
                               'Generated from: one_curve_36_results.mat\n' ...
                               'Date: %s\n\n' ...
                               'Each H_ij(s) = b(i,j) / (s² + a1(i,j)·s + a2(i,j))\n' ...
                               'Total: 36 independent transfer functions'], ...
                               datestr(now));

    add_block('built-in/Note', sprintf('%s/Annotation', model_name), ...
              'Position', [50, 800], ...
              'Text', annotation_text, ...
              'FontSize', '12');

    %% Save model
    save_system(model_name);
    fprintf('\n✓ Simulink model created: %s.slx\n', model_name);
    fprintf('  - 6 input ports (P1~P6)\n');
    fprintf('  - 6 output ports (Ch1~Ch6)\n');
    fprintf('  - 36 transfer function blocks\n');
    fprintf('  - 6 sum blocks (one per output)\n\n');

    fprintf('To use the model:\n');
    fprintf('  1. Open: open_system(''%s'')\n', model_name);
    fprintf('  2. Configure solver settings (see simulink_usage_guide.txt)\n');
    fprintf('  3. Add input sources (e.g., step, sine wave)\n');
    fprintf('  4. Add output scopes or logging\n');
    fprintf('  5. Run simulation\n\n');
end
