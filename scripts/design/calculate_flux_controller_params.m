% calculate_flux_controller_params.m
% 計算磁通控制器的所有參數並寫入 workspace
%
% 這個函數會計算估測器增益以及控制器需要的所有參數
% 並直接寫入 MATLAB workspace，供 Simulink 使用
%
% Usage:
%   params = calculate_flux_controller_params(system_params, design_params, controller_type)
%
% Inputs:
%   system_params   - 系統參數結構
%                     .a1  - 系統係數 a1
%                     .a2  - 系統係數 a2
%                     .B   - 控制矩陣 (6×6)
%                     .Ts  - 採樣時間
%                     .beta - 擾動參數（僅 Type 1 需要）
%
%   design_params   - 設計參數結構
%                     .lambda_c - 控制特徵值 (0 < λc < 1)
%                     .lambda_e - 估測器特徵值 (0 < λe < 1)
%
%   controller_type - 控制器類型 (1, 2, 或 3)
%                     3: 一階擾動模型（最簡單，推薦起步）
%                     2: 二階擾動模型（積分型）
%                     1: 二階擾動模型（參數化，需要 beta）
%
% Outputs:
%   params - 完整的參數結構，同時寫入 base workspace
%
% Example:
%   % 設定系統參數
%   sys.a1 = 0.95;
%   sys.a2 = -0.1;
%   sys.B = eye(6);
%   sys.Ts = 1e-4;
%
%   % 設定設計參數
%   design.lambda_c = 0.5;  % 控制收斂速度
%   design.lambda_e = 0.3;  % 估測器收斂速度
%
%   % 計算 Type 3 控制器參數
%   params = calculate_flux_controller_params(sys, design, 3);
%
% Author: Claude Code
% Date: 2025-10-11
% Reference: Flux_Control_B_merged.pdf

function params = calculate_flux_controller_params(system_params, design_params, controller_type)
    %% Input validation
    if nargin < 3
        error('需要 3 個輸入參數：system_params, design_params, controller_type');
    end

    % 檢查系統參數
    required_fields = {'a1', 'a2', 'B', 'Ts'};
    for i = 1:length(required_fields)
        if ~isfield(system_params, required_fields{i})
            error('system_params 缺少必要欄位: %s', required_fields{i});
        end
    end

    % 檢查設計參數
    required_fields = {'lambda_c', 'lambda_e'};
    for i = 1:length(required_fields)
        if ~isfield(design_params, required_fields{i})
            error('design_params 缺少必要欄位: %s', required_fields{i});
        end
    end

    % 檢查控制器類型
    if ~ismember(controller_type, [1, 2, 3])
        error('controller_type 必須是 1, 2, 或 3');
    end

    % Type 1 需要 beta
    if controller_type == 1 && ~isfield(system_params, 'beta')
        error('Type 1 控制器需要在 system_params 中提供 beta 參數');
    end

    %% 顯示資訊
    fprintf('╔════════════════════════════════════════════════════════════╗\n');
    fprintf('║     Flux Controller Parameters Calculation (Type %d)       ║\n', controller_type);
    fprintf('╚════════════════════════════════════════════════════════════╝\n');
    fprintf('\n');

    fprintf('▶ 系統參數:\n');
    fprintf('  a1 = %.6f\n', system_params.a1);
    fprintf('  a2 = %.6f\n', system_params.a2);
    fprintf('  B size = %d × %d\n', size(system_params.B, 1), size(system_params.B, 2));
    fprintf('  Ts = %.2e s (%.1f kHz)\n', system_params.Ts, 1/system_params.Ts/1000);
    if controller_type == 1
        fprintf('  β = %.4f\n', system_params.beta);
    end
    fprintf('\n');

    fprintf('▶ 設計參數:\n');
    fprintf('  λc = %.4f (控制收斂速度)\n', design_params.lambda_c);
    fprintf('  λe = %.4f (估測器收斂速度)\n', design_params.lambda_e);
    fprintf('\n');

    %% 計算估測器增益
    fprintf('▶ 計算估測器增益...\n');

    a1 = system_params.a1;
    a2 = system_params.a2;
    lambda_e = design_params.lambda_e;

    switch controller_type
        case 3
            % Type 3: 一階擾動模型
            l1 = 1 + a1 - 3*lambda_e;
            l2 = 1 + lambda_e^3 / a2;
            l3 = -(1 - lambda_e)^3;

            params.l1 = l1;
            params.l2 = l2;
            params.l3 = l3;
            params.num_gains = 3;

            fprintf('  l1 = %.8f\n', l1);
            fprintf('  l2 = %.8f\n', l2);
            fprintf('  l3 = %.8f\n', l3);

        case 2
            % Type 2: 二階擾動模型（積分型）
            l1 = 2 + a1 - 4*lambda_e;
            l2 = 1 + lambda_e^4 / a2;
            l3 = -(1 - lambda_e)^3 * (3 + lambda_e);
            l4 = -(1 - lambda_e)^4;

            params.l1 = l1;
            params.l2 = l2;
            params.l3 = l3;
            params.l4 = l4;
            params.num_gains = 4;

            fprintf('  l1 = %.8f\n', l1);
            fprintf('  l2 = %.8f\n', l2);
            fprintf('  l3 = %.8f\n', l3);
            fprintf('  l4 = %.8f\n', l4);

        case 1
            % Type 1: 二階擾動模型（參數化）
            beta = system_params.beta;

            l1 = 1 + beta + a1 - 4*lambda_e;
            l2 = 1 + lambda_e^4 / (a2 * beta);
            l3 = -(-beta + (1+beta)^2 - 4*(1+beta)*lambda_e + 6*lambda_e^2 - lambda_e^4/beta);
            l4 = -((1+beta) - 4*lambda_e - (1+beta)*lambda_e^4/beta^2 + 4*lambda_e^3/beta);

            params.l1 = l1;
            params.l2 = l2;
            params.l3 = l3;
            params.l4 = l4;
            params.beta = beta;
            params.num_gains = 4;

            fprintf('  l1 = %.8f\n', l1);
            fprintf('  l2 = %.8f\n', l2);
            fprintf('  l3 = %.8f\n', l3);
            fprintf('  l4 = %.8f\n', l4);
    end

    fprintf('✓ 估測器增益計算完成\n\n');

    %% 準備其他控制器參數
    fprintf('▶ 準備控制器參數...\n');

    % 系統參數
    params.a1 = system_params.a1;
    params.a2 = system_params.a2;
    params.B = system_params.B;
    params.B_inv = inv(system_params.B);
    params.Ts = system_params.Ts;

    % 設計參數
    params.lambda_c = design_params.lambda_c;
    params.lambda_e = design_params.lambda_e;

    % 計算反饋項係數
    params.fb_coeff_1 = system_params.a1 - design_params.lambda_c;  % (a1 - λc)
    params.fb_coeff_2 = system_params.a2;                            % a2

    % 控制器類型
    params.controller_type = controller_type;

    fprintf('  a1 = %.6f\n', params.a1);
    fprintf('  a2 = %.6f\n', params.a2);
    fprintf('  λc = %.6f\n', params.lambda_c);
    fprintf('  反饋係數 (a1-λc) = %.6f\n', params.fb_coeff_1);
    fprintf('  反饋係數 a2 = %.6f\n', params.fb_coeff_2);
    fprintf('✓ 控制器參數準備完成\n\n');

    %% 寫入 workspace
    fprintf('▶ 寫入參數到 MATLAB workspace...\n');

    % 寫入所有參數到 base workspace
    param_names = fieldnames(params);
    for i = 1:length(param_names)
        param_name = param_names{i};
        param_value = params.(param_name);
        assignin('base', param_name, param_value);
    end

    fprintf('✓ 已寫入 %d 個參數\n', length(param_names));
    fprintf('\n');

    %% 摘要
    fprintf('╔════════════════════════════════════════════════════════════╗\n');
    fprintf('║                    計算完成！                              ║\n');
    fprintf('╚════════════════════════════════════════════════════════════╝\n');
    fprintf('\n');
    fprintf('參數已寫入 workspace，可以直接在 Simulink 中使用:\n');
    fprintf('  • 估測器增益: l1, l2, l3');
    if controller_type <= 2
        fprintf(', l4');
    end
    fprintf('\n');
    fprintf('  • 系統參數: a1, a2, B, B_inv, Ts\n');
    fprintf('  • 控制參數: lambda_c, fb_coeff_1, fb_coeff_2\n');
    fprintf('\n');
end
