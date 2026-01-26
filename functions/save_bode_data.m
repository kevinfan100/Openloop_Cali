function save_bode_data(output_path, frequencies, magnitudes_linear, phases_processed, excite_ch, varargin)
%SAVE_BODE_DATA 儲存波德圖數據為 .m 檔案
%
% 產生與現有 P1.m ~ P6.m 格式相容的輸出檔案
%
% 使用方式:
%   save_bode_data(output_path, frequencies, magnitudes_linear, phases_processed, excite_ch)
%   save_bode_data(..., 'Name', 'Value', ...)
%
% 輸入:
%   output_path       - 輸出檔案路徑 (如 'results/bode_data/P1.m')
%   frequencies       - 頻率向量 [Hz] (1 x N)
%   magnitudes_linear - 線性幅值 (6 x N)
%   phases_processed  - 處理後的相位 [deg] (6 x N)
%   excite_ch         - 激勵通道 (1-6)
%
% 選項 (Name-Value pairs):
%   'Magnitudes_dB' - dB 幅值 (6 x N) (default: 自動計算)
%   'Description'   - 檔案描述 (default: '')
%   'Verbose'       - 顯示處理信息 (default: true)
%
% 輸出檔案格式:
%   % P{n} Frequency Response Data
%   % Generated: YYYY-MM-DD HH:MM:SS
%   frequencies = [...];
%   magnitudes_linear = [...];
%   phases_processed = [...];

    %% 解析輸入參數
    p = inputParser;
    addRequired(p, 'output_path', @ischar);
    addRequired(p, 'frequencies', @isnumeric);
    addRequired(p, 'magnitudes_linear', @isnumeric);
    addRequired(p, 'phases_processed', @isnumeric);
    addRequired(p, 'excite_ch', @isnumeric);
    addParameter(p, 'Magnitudes_dB', [], @isnumeric);
    addParameter(p, 'Description', '', @ischar);
    addParameter(p, 'Verbose', true, @islogical);

    parse(p, output_path, frequencies, magnitudes_linear, phases_processed, excite_ch, varargin{:});
    opts = p.Results;

    %% 確保輸出目錄存在
    [output_dir, ~, ~] = fileparts(output_path);
    if ~isempty(output_dir) && ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    %% 計算 dB 幅值 (如果未提供)
    if isempty(opts.Magnitudes_dB)
        magnitudes_dB = 20 * log10(magnitudes_linear);
    else
        magnitudes_dB = opts.Magnitudes_dB;
    end

    %% 確保正確維度
    frequencies = frequencies(:)';  % 1 x N
    [num_ch, num_freq] = size(magnitudes_linear);

    %% 寫入檔案
    fid = fopen(output_path, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', output_path);
    end

    try
        % 檔頭註釋
        fprintf(fid, '%% P%d Frequency Response Data\n', excite_ch);
        fprintf(fid, '%% Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        if ~isempty(opts.Description)
            fprintf(fid, '%% %s\n', opts.Description);
        end
        fprintf(fid, '%% Excitation Channel: P%d\n', excite_ch);
        fprintf(fid, '%% Number of frequencies: %d\n', num_freq);
        fprintf(fid, '%% Frequency range: %.2f - %.2f Hz\n', min(frequencies), max(frequencies));
        fprintf(fid, '\n');

        % 頻率向量
        fprintf(fid, 'frequencies = [');
        fprintf(fid, '%.6f', frequencies(1));
        for k = 2:num_freq
            fprintf(fid, ', %.6f', frequencies(k));
        end
        fprintf(fid, '];\n\n');

        % 線性幅值矩陣
        fprintf(fid, 'magnitudes_linear = [\n');
        for ch = 1:num_ch
            fprintf(fid, '    ');
            fprintf(fid, '%.8e', magnitudes_linear(ch, 1));
            for k = 2:num_freq
                fprintf(fid, ', %.8e', magnitudes_linear(ch, k));
            end
            if ch < num_ch
                fprintf(fid, ';  %% P%d output\n', ch);
            else
                fprintf(fid, '   %% P%d output\n', ch);
            end
        end
        fprintf(fid, '];\n\n');

        % 處理後的相位矩陣
        fprintf(fid, 'phases_processed = [\n');
        for ch = 1:num_ch
            fprintf(fid, '    ');
            fprintf(fid, '%.6f', phases_processed(ch, 1));
            for k = 2:num_freq
                fprintf(fid, ', %.6f', phases_processed(ch, k));
            end
            if ch < num_ch
                fprintf(fid, ';  %% P%d output\n', ch);
            else
                fprintf(fid, '   %% P%d output\n', ch);
            end
        end
        fprintf(fid, '];\n');

        fclose(fid);

        if opts.Verbose
            fprintf('  Bode data saved: %s\n', output_path);
        end

    catch ME
        fclose(fid);
        rethrow(ME);
    end
end
