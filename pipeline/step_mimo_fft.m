function [H_mag, H_phase_raw, frequencies] = step_mimo_fft(config, varargin)
%STEP_MIMO_FFT Stage 1: 數據 → 頻域 CSV (6x6 MIMO)
%
% 根據 data_source 載入數據，組裝 6x6xN tensor，輸出原始 CSV
% 不做相位修正 — 輸出原始頻域數據
%
% 使用方式:
%   [H_mag, H_phase, freqs] = step_mimo_fft(config)
%
% 輸入:
%   config - MIMO_config() 回傳的設定
%
% 輸出:
%   H_mag         - 6 x 6 x N magnitude (linear)
%   H_phase_raw   - 6 x 6 x N phase (deg, 原始未修正)
%   frequencies   - 1 x N Hz
%
% CSV 輸出:
%   MIMO_Raw_Bode_Data.csv (wide format)
%   欄位: Frequency_Hz, H_11_Mag, H_11_Phase_deg, H_12_Mag, ...

    %% 解析參數
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'config', @isstruct);
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, config, varargin{:});
    opts = p.Results;

    fprintf('\n=== Step MIMO FFT: Stage 1 (Data -> Frequency Domain) ===\n');

    %% 根據 data_source 載入
    switch config.mimo.data_source
        case 'legacy'
            [H_mag, H_phase_raw, frequencies] = load_legacy_pdata( ...
                config.mimo.legacy_data_folder, 'Verbose', opts.Verbose);

        case 'dat'
            error('step_mimo_fft:dat_not_implemented', ...
                'DAT data source not yet implemented. Use ''legacy'' for now.');

        otherwise
            error('step_mimo_fft:unknown_source', ...
                'Unknown data_source: %s', config.mimo.data_source);
    end

    %% 輸出 CSV
    if config.output.save_csv
        csv_path = fullfile(config.output_folder, 'fitting_results', ...
            'MIMO_Raw_Bode_Data.csv');

        write_mimo_csv(csv_path, H_mag, H_phase_raw, frequencies);

        if opts.Verbose
            fprintf('CSV saved: %s\n', csv_path);
        end
    end

    fprintf('Stage 1 complete: %d x %d x %d tensor\n', ...
        size(H_mag, 1), size(H_mag, 2), size(H_mag, 3));
end

%% === Local function: write CSV ===
function write_mimo_csv(csv_path, H_mag, H_phase, frequencies)
    num_freq = length(frequencies);

    % 建構表頭
    header = {'Frequency_Hz'};
    for i = 1:6
        for j = 1:6
            header{end+1} = sprintf('H_%d%d_Mag', i, j); %#ok<AGROW>
            header{end+1} = sprintf('H_%d%d_Phase_deg', i, j); %#ok<AGROW>
        end
    end

    % 開檔寫入
    fid = fopen(csv_path, 'w');
    fprintf(fid, '%s', header{1});
    for c = 2:length(header)
        fprintf(fid, ',%s', header{c});
    end
    fprintf(fid, '\n');

    % 逐頻率寫入
    for k = 1:num_freq
        fprintf(fid, '%.6f', frequencies(k));
        for i = 1:6
            for j = 1:6
                fprintf(fid, ',%.10e,%.6f', H_mag(i, j, k), H_phase(i, j, k));
            end
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end
