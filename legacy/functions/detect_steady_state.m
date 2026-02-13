function steady_info = detect_steady_state(Vm_signal, target_freq, sampling_rate, varargin)
%DETECT_STEADY_STATE 檢測穩態區域
%
% 比較相鄰週期的波形差異，找出穩態起始點
%
% 使用方式:
%   steady_info = detect_steady_state(Vm_signal, target_freq, sampling_rate)
%   steady_info = detect_steady_state(..., 'Name', 'Value', ...)
%
% 輸入:
%   Vm_signal     - Vm 電壓數據 (6 x N) 或 (1 x N)
%   target_freq   - 目標頻率 [Hz]
%   sampling_rate - 取樣頻率 [Hz]
%
% 選項 (Name-Value pairs):
%   'StabilityThreshold'   - 穩態判決閾值 [V] (default: 2e-3)
%   'ConsecutivePeriods'   - 需要連續穩定的週期數 (default: 3)
%   'CheckPoints'          - 每週期檢查點數 (default: 25)
%   'StartPeriod'          - 開始檢測的週期 (default: 1)
%   'Verbose'              - 顯示處理信息 (default: true)
%
% 輸出:
%   steady_info - 結構體，包含:
%     .period        - 穩態起始週期索引
%     .index         - 穩態起始樣本索引
%     .max_periods   - 最大可用週期數
%     .period_samples - 每週期樣本數

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'Vm_signal', @isnumeric);
    addRequired(p, 'target_freq', @isnumeric);
    addRequired(p, 'sampling_rate', @isnumeric);
    addParameter(p, 'StabilityThreshold', 2e-3, @isnumeric);
    addParameter(p, 'ConsecutivePeriods', 3, @isnumeric);
    addParameter(p, 'CheckPoints', 25, @isnumeric);
    addParameter(p, 'StartPeriod', 1, @isnumeric);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, Vm_signal, target_freq, sampling_rate, varargin{:});
    opts = p.Results;

    %% 轉換為 6 通道矩陣（如果是單通道輸入）
    if isvector(Vm_signal)
        Vm_clean = Vm_signal(:)';
        Vm_clean = repmat(Vm_clean, 6, 1);
    else
        Vm_clean = Vm_signal;
    end

    clean_length = size(Vm_clean, 2);

    %% 計算週期參數
    period_samples = round(sampling_rate / target_freq);
    max_periods = floor(clean_length / period_samples);
    check_positions = round(linspace(1, period_samples, opts.CheckPoints));

    if opts.Verbose
        fprintf('  Steady-state detection:\n');
        fprintf('    Period samples: %d\n', period_samples);
        fprintf('    Max periods: %d\n', max_periods);
        fprintf('    Threshold: %.4f V\n', opts.StabilityThreshold);
    end

    %% 處理數據不足的情況
    if max_periods < 5
        if opts.Verbose
            fprintf('    Warning: Insufficient periods (%d), using last period as steady-state\n', max_periods);
        end

        steady_period = max(1, max_periods - 1);
        steady_info = struct('period', steady_period, ...
                            'index', steady_period * period_samples + 1, ...
                            'max_periods', max_periods, ...
                            'period_samples', period_samples);
        return;
    end

    %% 對每個 Vm 通道檢測穩態
    steady_periods = [];

    for Vm_ch = 1:6
        signal = Vm_clean(Vm_ch, :);

        % 從 start_period 開始測試每個週期
        for test_period = opts.StartPeriod:(max_periods - opts.ConsecutivePeriods)
            all_stable = true;

            % 檢查連續週期的穩定性
            for i = 1:opts.ConsecutivePeriods
                current_period = test_period + i - 1;
                next_period = current_period + 1;

                current_start = current_period * period_samples + 1;
                next_start = next_period * period_samples + 1;

                max_diff = 0;

                % 在檢查點比較相鄰週期
                for pos_idx = 1:length(check_positions)
                    pos = check_positions(pos_idx);
                    current_idx = current_start + pos - 1;
                    next_idx = next_start + pos - 1;

                    if current_idx <= length(signal) && next_idx <= length(signal)
                        current_val = signal(current_idx);
                        next_val = signal(next_idx);
                        diff = abs(current_val - next_val);
                        max_diff = max(max_diff, diff);
                    end
                end

                % 如果差異超過閾值，標記為不穩定
                if max_diff >= opts.StabilityThreshold
                    all_stable = false;
                    break;
                end
            end

            % 如果找到穩定週期，記錄並停止
            if all_stable
                steady_periods(end+1) = test_period;
                break;
            end
        end
    end

    %% 選擇最保守的穩態點（最大值）
    if ~isempty(steady_periods)
        recommended_period = max(steady_periods);
        clean_index = recommended_period * period_samples + 1;

        steady_info = struct(...
            'period', recommended_period, ...
            'index', clean_index, ...
            'max_periods', max_periods, ...
            'period_samples', period_samples);

        if opts.Verbose
            fprintf('    Steady-state detected: Period %d, Index %d\n', recommended_period, clean_index);
        end
    else
        % 如果沒有找到穩定週期，使用最後幾個週期
        if opts.Verbose
            fprintf('    Warning: No stable period found (threshold %.4fV)\n', opts.StabilityThreshold);
            fprintf('    Using last %d periods as steady-state\n', opts.ConsecutivePeriods);
        end

        steady_period = max(1, max_periods - opts.ConsecutivePeriods);
        steady_info = struct('period', steady_period, ...
                            'index', steady_period * period_samples + 1, ...
                            'max_periods', max_periods, ...
                            'period_samples', period_samples);
    end
end
