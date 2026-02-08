function data_files = build_data_files(prefix, frequencies)
%BUILD_DATA_FILES 自動從 prefix + frequencies 生成檔名清單
%
% 格式: <prefix>_<freq>hz.dat
% 例: Hung_single_0.1hz.dat, Hung_single_100hz.dat
%
% Input:
%   prefix      - 檔名前綴 (e.g. 'Hung_single')
%   frequencies - 頻率向量 (e.g. [0.1, 1, 10, ...])
%
% Output:
%   data_files  - cell array of filenames

    n = length(frequencies);
    data_files = cell(1, n);
    for i = 1:n
        f = frequencies(i);
        if f == floor(f)
            freq_str = sprintf('%d', f);
        else
            freq_str = sprintf('%g', f);
        end
        data_files{i} = sprintf('%s_%shz.dat', prefix, freq_str);
    end
end
