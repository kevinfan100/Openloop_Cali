function data = read_hsdata(filename)
%READ_HSDATA Read HSData file (supports V1/V2/V3/V4/V5/V6/V7/V8 format with header)
%
% Usage:
%   data = read_hsdata('HSData.dat')
%
% Input:
%   filename - Path to HSData file
%
% Output:
%   data.Vm           [N x 6] Measured voltage (float32)
%   data.vd           [N x 6] Desired voltage (float32)
%   data.da           [N x 6] DAC output (uint16)
%   data.debug        [N x 16] DebugRecord (V2-V4, float32)
%                     [N x 10] DebugRecord (V5/V6/V7/V8, float32)
%   data.adc_raw      [N x 12] Raw ADC data (V4+, uint16)
%   data.version      File version (1, 2, 3, 4, 5, 6, 7, or 8)
%   data.record_count Number of records
%   --- V3+ test parameters ---
%   data.frequency    Excitation frequency [Hz] (UI: Beta_m)
%   data.amplitude    Excitation amplitude [V] (UI: beta_tune)
%   data.channel      Excitation channel 1-6 (UI: alpha_tune)
%   data.fB_f         Feedforward bandwidth [Hz]
%   data.fB_c         Controller bandwidth [Hz]
%   data.fB_e         Estimator bandwidth [Hz]
%   --- V6+ extended parameters ---
%   data.sampling_rate  Data sampling frequency [Hz]
%   data.Kp           [1 x 6] Hall Sensor PID P gains
%   data.Ki           [1 x 6] Hall Sensor PID I gains
%   data.control_mode   0 = PID, 1 = R Controller
%   data.debug_signal_type  0 = PID outputs, 1 = R Controller w1_hat
%   data.loop_mode      0 = Closed-loop (HS Relax), 1 = Open-loop (非 Relax)
%   --- V7 InvModel_Test parameters ---
%   data.test_mode      0 = Normal, 1 = InvModel_Test
%   data.position_m   [1 x 3] Test position (Measurement coordinate) [um]
%   data.fd_direction [1 x 3] Force direction unit vector (Measurement coordinate)
%   data.R_norm       Normalization radius [um]
%   data.FGain        Force gain (g_H) [pN/V²]
%   --- V8 Extended InvModel_Test parameters ---
%   data.frame_rate     Camera frame rate [fps] (for timing verification)
%   data.fd_mode        0 = sine wave, 1 = constant
%   data.fd_const_value Constant mode fd value [V] (from beta_tune)
%   --- V7/V8 InvModel_Test output fields (auto-parsed from debug[1:10]) ---
%   Hall_Para_record layout (100kHz Sync Verification, 2026-01-14):
%   [0] = HsVd_VECT6[0]   - Vd output (raw from InvModel)
%   [1] = Vm[0]           - Measured voltage (for Vd-Vm sync check)
%   [2] = state_flags     - {fd_calc, AddrCalc, CtrlCalc, busy} (4-bit)
%   [3] = ADC_Data_cnt    - ADC counter (LSB=0 → 100kHz edge)
%   [4] = Vd_muxed[0]     - Vd sent to controller
%   [5] = intThe_INT      - LUT θ index
%   [6] = intPhi_INT      - LUT φ index
%   [7] = Fd_m[0]         - Input force X
%   [8] = Fxyz_norm       - ||fd|| norm
%   [9] = AddrCalc_cnt    - Address calc counter (0-164)
%   ---
%   data.invtest.Vd_raw        [N x 1] float32 - Vd output from InvModel_Test
%   data.invtest.Vm            [N x 1] float32 - Measured voltage (for sync check)
%   data.invtest.state_flags   [N x 1] uint32  - State machine flags
%   data.invtest.ADC_cnt       [N x 1] uint32  - ADC counter
%   data.invtest.Vd_muxed      [N x 1] float32 - Vd sent to controller
%   data.invtest.intThe_INT    [N x 1] uint32  - θ LUT address index ∈ [0, 60]
%   data.invtest.intPhi_INT    [N x 1] uint32  - φ LUT address index ∈ [0, 30]
%   data.invtest.Fd_m_x        [N x 1] float32 - Input force X
%   data.invtest.Fxyz_norm     [N x 1] float32 - ||fd|| norm
%   data.invtest.AddrCalc_cnt  [N x 1] uint32  - Address calc counter (0-164)
%
% File Format:
%   Header V1/V2: 24 bytes (magic[6] + padding[2] + version[4] + record_count[4] + timestamp[8])
%   Header V3-V5: 48 bytes (V1/V2 header + frequency[4] + amplitude[4] + channel[4] + fB_f[4] + fB_c[4] + fB_e[4])
%   Header V6:   116 bytes (V3 header + sampling_rate[4] + Kp[24] + Ki[24] + control_mode[4] + debug_signal_type[4] + loop_mode[4] + reserved[4])
%   Header V7:   152 bytes (V6 header + test_mode[4] + position_m[12] + fd_direction[12] + R_norm[4] + FGain[4])
%   Header V8:   168 bytes (V7 header + frame_rate[4] + fd_mode[4] + fd_const_value[4] + padding[4])
%   V1: 60 bytes/record (Vm[6] + vd[6] + da[6])
%   V2/V3: 124 bytes/record (Vm[6] + vd[6] + da[6] + DebugRecord[16])
%   V4: 148 bytes/record (V3 + adc_raw[12])
%   V5/V6: 124 bytes/record (Vm[6] + vd[6] + da[6] + DebugRecord[10] + adc_raw[12])
%       128-byte aligned USB packet, no sync marker drift
%
% DebugRecord index mapping (MATLAB 1-based index):
% ============================================================
% V2-V4 (16 floats):
%   [1:6]   = w1_hat[0:5] - Disturbance estimate (6 channels)
%   [7:12]  = u[0:5]      - Final control output (6 channels)
%   [13:16] = 0           - Unused
% V5 (10 floats):
%   [1:6]   = w1_hat[0:5] - Disturbance estimate (6 channels)
%   [7:10]  = u[0:3]      - Control output (4 channels)
% V6 (10 floats):
%   [1:6]   = mR_w1_hat_VECT6[0:5] - R Controller disturbance estimate (6 channels)
%   [7:10]  = 0           - Unused
% ============================================================
%
% adc_raw index mapping (MATLAB 1-based index):
% ============================================================
% High/Low Sensitivity pairs for AuxRatio calibration:
%   [1,2]   = X axis  (High, Low)
%   [3,4]   = Y axis  (High, Low)
%   [5,6]   = Z axis  (High, Low)
%   [7,8]   = Rx axis (High, Low)
%   [9,10]  = Ry axis (High, Low)
%   [11,12] = Rz axis (High, Low)
% ============================================================

    % Check if file exists
    if ~exist(filename, 'file')
        error('File not found: %s', filename);
    end

    % Open file
    fid = fopen(filename, 'rb');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    % Get file size
    fseek(fid, 0, 'eof');
    file_size = ftell(fid);
    fseek(fid, 0, 'bof');

    % Check for file header (starts with "HSDATA")
    magic = fread(fid, 6, 'char=>char')';
    has_header = strcmp(magic, 'HSDATA');

    if has_header
        % Read header (24 bytes base, 48 bytes for V3)
        % magic[6] + padding[2] + version[4] + record_count[4] + timestamp[8]
        fread(fid, 2, 'uint8');  % Skip padding
        version = fread(fid, 1, 'uint32');
        header_record_count = fread(fid, 1, 'uint32');
        timestamp = fread(fid, 1, 'uint64');

        % V3+: Read test parameters
        if version >= 3
            data.frequency = fread(fid, 1, 'float32');  % Excitation frequency [Hz]
            data.amplitude = fread(fid, 1, 'float32');  % Excitation amplitude [V]
            data.channel = fread(fid, 1, 'uint32');     % Excitation channel 1-6
            data.fB_f = fread(fid, 1, 'float32');       % Feedforward bandwidth [Hz]
            data.fB_c = fread(fid, 1, 'float32');       % Controller bandwidth [Hz]
            data.fB_e = fread(fid, 1, 'float32');       % Estimator bandwidth [Hz]

            % V6+: Read extended parameters
            if version >= 6
                data.sampling_rate = fread(fid, 1, 'float32');  % Data sampling rate [Hz]
                data.Kp = fread(fid, 6, 'float32')';            % PID P gains [1x6]
                data.Ki = fread(fid, 6, 'float32')';            % PID I gains [1x6]
                data.control_mode = fread(fid, 1, 'uint32');    % 0=PID, 1=R Controller
                data.debug_signal_type = fread(fid, 1, 'uint32'); % 0=PID, 1=w1_hat
                data.loop_mode = fread(fid, 1, 'uint32');       % 0=Closed(Relax), 1=Open(非Relax)
                fread(fid, 1, 'uint32');  % Skip reserved_v6

                % V7+: Read InvModel_Test parameters
                if version >= 7
                    data.test_mode = fread(fid, 1, 'uint32');       % 0=Normal, 1=InvModel_Test
                    data.position_m = fread(fid, 3, 'float32')';    % Test position [1x3] [um]
                    data.fd_direction = fread(fid, 3, 'float32')';  % Force direction [1x3] unit vector
                    data.R_norm = fread(fid, 1, 'float32');         % Normalization radius [um]
                    data.FGain = fread(fid, 1, 'float32');          % Force gain (g_H) [pN/V²]

                    % V8: Extended InvModel_Test parameters
                    if version >= 8
                        data.frame_rate = fread(fid, 1, 'float32');     % Camera frame rate [fps]
                        data.fd_mode = fread(fid, 1, 'uint32');         % 0=sine wave, 1=constant
                        data.fd_const_value = fread(fid, 1, 'float32'); % Constant mode fd value [V]
                        fread(fid, 4, 'uint8');  % Skip 4 bytes padding (C++ struct alignment to 8 bytes)
                        header_size = 168;  % V8: 168 bytes (164 + 4 padding)
                        fprintf('Header detected: version=%d, record_count=%d\n', version, header_record_count);
                        fprintf('  Test params: freq=%.1f Hz, amp=%.3f V, ch=%d, fB_f=%.1f, fB_c=%.1f, fB_e=%.1f\n', ...
                                data.frequency, data.amplitude, data.channel, data.fB_f, data.fB_c, data.fB_e);
                        fprintf('  V6 params: fs=%.0f Hz, ctrl_mode=%d, debug_type=%d, loop_mode=%d\n', ...
                                data.sampling_rate, data.control_mode, data.debug_signal_type, data.loop_mode);
                        fprintf('  V7 params: test_mode=%d, pos=[%.1f, %.1f, %.1f] um, dir=[%.3f, %.3f, %.3f], R_norm=%.1f um, FGain=%.4f\n', ...
                                data.test_mode, data.position_m(1), data.position_m(2), data.position_m(3), ...
                                data.fd_direction(1), data.fd_direction(2), data.fd_direction(3), ...
                                data.R_norm, data.FGain);
                        if data.fd_mode == 0
                            fd_mode_str = 'sine';
                        else
                            fd_mode_str = 'const';
                        end
                        fprintf('  V8 params: frame_rate=%.1f fps, fd_mode=%d (%s), fd_const_value=%.4f V\n', ...
                                data.frame_rate, data.fd_mode, fd_mode_str, data.fd_const_value);
                    else
                        header_size = 152;  % V7: 152 bytes (116 + 36)
                        fprintf('Header detected: version=%d, record_count=%d\n', version, header_record_count);
                        fprintf('  Test params: freq=%.1f Hz, amp=%.3f V, ch=%d, fB_f=%.1f, fB_c=%.1f, fB_e=%.1f\n', ...
                                data.frequency, data.amplitude, data.channel, data.fB_f, data.fB_c, data.fB_e);
                        fprintf('  V6 params: fs=%.0f Hz, ctrl_mode=%d, debug_type=%d, loop_mode=%d\n', ...
                                data.sampling_rate, data.control_mode, data.debug_signal_type, data.loop_mode);
                        fprintf('  V7 params: test_mode=%d, pos=[%.1f, %.1f, %.1f] um, dir=[%.3f, %.3f, %.3f], R_norm=%.1f um, FGain=%.4f\n', ...
                                data.test_mode, data.position_m(1), data.position_m(2), data.position_m(3), ...
                                data.fd_direction(1), data.fd_direction(2), data.fd_direction(3), ...
                                data.R_norm, data.FGain);
                    end
                else
                    header_size = 116;  % V6: 116 bytes (48 + 68)
                    fprintf('Header detected: version=%d, record_count=%d\n', version, header_record_count);
                    fprintf('  Test params: freq=%.1f Hz, amp=%.3f V, ch=%d, fB_f=%.1f, fB_c=%.1f, fB_e=%.1f\n', ...
                            data.frequency, data.amplitude, data.channel, data.fB_f, data.fB_c, data.fB_e);
                    fprintf('  V6 params: fs=%.0f Hz, ctrl_mode=%d, debug_type=%d, loop_mode=%d\n', ...
                            data.sampling_rate, data.control_mode, data.debug_signal_type, data.loop_mode);
                end
            else
                header_size = 48;
                fprintf('Header detected: version=%d, record_count=%d\n', version, header_record_count);
                fprintf('  Test params: freq=%.1f Hz, amp=%.3f V, ch=%d, fB_f=%.1f, fB_c=%.1f, fB_e=%.1f\n', ...
                        data.frequency, data.amplitude, data.channel, data.fB_f, data.fB_c, data.fB_e);
            end
        else
            header_size = 24;
            fprintf('Header detected: version=%d, record_count=%d\n', version, header_record_count);
        end
        data_size = file_size - header_size;
    else
        % No header - legacy format, detect by file size
        fseek(fid, 0, 'bof');
        header_size = 0;
        data_size = file_size;

        if mod(file_size, 124) == 0
            version = 2;
        elseif mod(file_size, 60) == 0
            version = 1;
        else
            if mod(file_size, 124) < mod(file_size, 60)
                version = 2;
            else
                version = 1;
            end
            warning('File size is not exact multiple of record size. Detected version: %d', version);
        end
    end

    % Set record size based on version
    if version >= 5
        record_size = 124;  % V5/V6: 124 bytes/record (DebugRecord[10] + adc_raw[12])
    elseif version >= 4
        record_size = 148;  % V4: 148 bytes/record (DebugRecord[16] + adc_raw[12])
    elseif version >= 2
        record_size = 124;  % V2/V3: 124 bytes/record (DebugRecord[16])
    else
        record_size = 60;   % V1: 60 bytes/record
    end

    % Calculate record count
    record_count = floor(data_size / record_size);

    % Pre-allocate arrays
    data.Vm = zeros(record_count, 6, 'single');
    data.vd = zeros(record_count, 6, 'single');
    data.da = zeros(record_count, 6, 'uint16');
    if version >= 5
        data.debug = zeros(record_count, 10, 'single');  % V5/V6: 10 floats
        data.adc_raw = zeros(record_count, 12, 'uint16');
    elseif version >= 4
        data.debug = zeros(record_count, 16, 'single');  % V4: 16 floats
        data.adc_raw = zeros(record_count, 12, 'uint16');
    elseif version >= 2
        data.debug = zeros(record_count, 16, 'single');  % V2/V3: 16 floats
    end

    % Read data (file pointer is already at correct position after header)
    % If has_header, we're at byte 24 (V1/V2) or 48 (V3); if not, we're at byte 0
    if ~has_header
        fseek(fid, 0, 'bof');
    end
    % else: file pointer is already positioned after header

    for i = 1:record_count
        % Vm[6] - 24 bytes (6 x float32)
        data.Vm(i,:) = fread(fid, 6, 'float32')';

        % vd[6] - 24 bytes (6 x float32)
        data.vd(i,:) = fread(fid, 6, 'float32')';

        % da[6] - 12 bytes (6 x uint16)
        data.da(i,:) = fread(fid, 6, 'uint16')';

        if version >= 5
            % V5: DebugRecord[10] - 40 bytes (10 x float32)
            data.debug(i,:) = fread(fid, 10, 'float32')';
            % V5: adc_raw[12] - 24 bytes (12 x uint16)
            data.adc_raw(i,:) = fread(fid, 12, 'uint16')';
        elseif version >= 4
            % V4: DebugRecord[16] - 64 bytes (16 x float32)
            data.debug(i,:) = fread(fid, 16, 'float32')';
            % V4: adc_raw[12] - 24 bytes (12 x uint16)
            data.adc_raw(i,:) = fread(fid, 12, 'uint16')';
        elseif version >= 2
            % V2/V3: DebugRecord[16] - 64 bytes (16 x float32)
            data.debug(i,:) = fread(fid, 16, 'float32')';
        end
    end

    % Store metadata
    data.version = version;
    data.record_count = record_count;
    data.file_size = file_size;

    % Close file
    fclose(fid);

    % Print summary
    fprintf('Read %d records from %s (Version %d, %d bytes/record)\n', ...
            record_count, filename, version, record_size);

    % V7 InvModel_Test: Parse debug fields into named struct
    % Hall_Para_record mapping (2026-01-14 100kHz Sync Verification):
    %   [0] = HsVd_VECT6[0]   - Vd output (raw from InvModel)
    %   [1] = Vm[0]           - Measured voltage (for Vd-Vm sync check)
    %   [2] = state_flags     - {fd_calc, AddrCalc, CtrlCalc, busy} (4-bit)
    %   [3] = ADC_Data_cnt    - ADC counter (LSB=0 → 100kHz edge)
    %   [4] = Vd_muxed[0]     - Vd sent to controller
    %   [5] = intThe_INT      - LUT θ index
    %   [6] = intPhi_INT      - LUT φ index
    %   [7] = Fd_m[0]         - Input force X
    %   [8] = Fxyz_norm       - ||fd|| norm
    %   [9] = AddrCalc_cnt    - Address calc counter (0-164)
    if version >= 7 && isfield(data, 'test_mode') && data.test_mode == 1
        % Auto-detect DebugRecord format by checking debug(:, 10)
        % - New format (100kHz Sync): AddrCalc_cnt as uint32, should be ~165
        % - Old format (SDRAM verify): fd_magnitude as float, should be ~[-5, 5]
        test_val = double(typecast(single(data.debug(1:min(100, end), 10)), 'uint32'));
        is_new_format = all(test_val >= 0 & test_val <= 200);

        if is_new_format
            % ============================================================
            % NEW FORMAT: 100kHz Sync Verification (0115 files)
            % ============================================================
            fprintf('Parsing InvModel_Test debug output fields (100kHz Sync mode)...\n');
            data.invtest.debug_format = '100kHz_sync';

            % 100kHz Sync Verification signals
            data.invtest.Vd_raw = data.debug(:, 1);          % [N x 1] Vd from InvModel_Test
            data.invtest.Vm = data.debug(:, 2);              % [N x 1] Measured voltage
            data.invtest.state_flags = double(typecast(single(data.debug(:, 3)), 'uint32'));  % [N x 1] State flags
            data.invtest.ADC_cnt = double(typecast(single(data.debug(:, 4)), 'uint32'));      % [N x 1] ADC counter
            data.invtest.Vd_muxed = data.debug(:, 5);        % [N x 1] Vd sent to controller

            % LUT address verification (stored as uint32, need typecast)
            data.invtest.intThe_INT = double(typecast(single(data.debug(:, 6)), 'uint32'));
            data.invtest.intPhi_INT = double(typecast(single(data.debug(:, 7)), 'uint32'));

            % Input validation
            data.invtest.Fd_m_x = data.debug(:, 8);          % [N x 1] Input force X
            data.invtest.Fxyz_norm = data.debug(:, 9);       % [N x 1] ||fd|| norm
            data.invtest.AddrCalc_cnt = double(typecast(single(data.debug(:, 10)), 'uint32')); % [N x 1] AddrCalc counter

            % Print diagnostic summary
            fprintf('  === 100kHz Sync Verification ===\n');
            fprintf('  Vd_raw:          min=%12.6f, max=%12.6f (InvModel output)\n', ...
                    min(data.invtest.Vd_raw), max(data.invtest.Vd_raw));
            fprintf('  Vm:              min=%12.6f, max=%12.6f (Measured voltage)\n', ...
                    min(data.invtest.Vm), max(data.invtest.Vm));
            fprintf('  Vd_muxed:        min=%12.6f, max=%12.6f (Vd to controller)\n', ...
                    min(data.invtest.Vd_muxed), max(data.invtest.Vd_muxed));
            fprintf('  state_flags:     unique values: %s\n', mat2str(unique(data.invtest.state_flags)'));
            fprintf('  ADC_cnt:         min=%6.0f, max=%6.0f\n', ...
                    min(data.invtest.ADC_cnt), max(data.invtest.ADC_cnt));
            fprintf('  === LUT Address Verification ===\n');
            fprintf('  intThe_INT:      min=%3.0f, max=%3.0f (expected [0, 60])\n', ...
                    min(data.invtest.intThe_INT), max(data.invtest.intThe_INT));
            fprintf('  intPhi_INT:      min=%3.0f, max=%3.0f (expected [0, 30])\n', ...
                    min(data.invtest.intPhi_INT), max(data.invtest.intPhi_INT));
            fprintf('  === Calculation State ===\n');
            fprintf('  Fd_m_x:          min=%12.6f, max=%12.6f (Input force X)\n', ...
                    min(data.invtest.Fd_m_x), max(data.invtest.Fd_m_x));
            fprintf('  Fxyz_norm:       min=%12.6f, max=%12.6f (||fd|| norm)\n', ...
                    min(data.invtest.Fxyz_norm), max(data.invtest.Fxyz_norm));
            fprintf('  AddrCalc_cnt:    min=%3.0f, max=%3.0f (expected [0, 164])\n', ...
                    min(data.invtest.AddrCalc_cnt), max(data.invtest.AddrCalc_cnt));
        else
            % ============================================================
            % OLD FORMAT: SDRAM Verification (0114 files)
            % ============================================================
            fprintf('Parsing InvModel_Test debug output fields (SDRAM verification mode)...\n');
            data.invtest.debug_format = 'sdram_verify';

            % LUT address verification (stored as uint32, need typecast)
            data.invtest.intThe_INT_raw = data.debug(:, 1);  % [N x 1] raw float32 bits
            data.invtest.intPhi_INT_raw = data.debug(:, 2);  % [N x 1] raw float32 bits
            data.invtest.intThe_INT = double(typecast(single(data.debug(:, 1)), 'uint32'));
            data.invtest.intPhi_INT = double(typecast(single(data.debug(:, 2)), 'uint32'));

            % SDRAM data verification
            data.invtest.SDRAM_coeff0 = data.debug(:, 3);    % [N x 1] First SDRAM coefficient

            % Calculation pipeline
            data.invtest.I1_interp = data.debug(:, 4);       % [N x 1] I1 interpolated (scaled)
            data.invtest.HsVd_ch0 = data.debug(:, 5);        % [N x 1] HsVd output ch0
            data.invtest.Sqrt_Fxyz_norm = data.debug(:, 6);  % [N x 1] Scale factor

            % Input validation
            data.invtest.Fd_m = data.debug(:, 7:9);          % [N x 3] Measurement coord force
            data.invtest.fd_magnitude = data.debug(:, 10);   % [N x 1] Input signal (fd magnitude after MUX)
            data.invtest.sine_wave = data.invtest.fd_magnitude;  % Alias

            % Print diagnostic summary
            fprintf('  === LUT Address Verification ===\n');
            fprintf('  intThe_INT:      min=%3.0f, max=%3.0f (expected [0, 60])\n', ...
                    min(data.invtest.intThe_INT), max(data.invtest.intThe_INT));
            fprintf('  intPhi_INT:      min=%3.0f, max=%3.0f (expected [0, 30])\n', ...
                    min(data.invtest.intPhi_INT), max(data.invtest.intPhi_INT));
            fprintf('  === SDRAM Data ===\n');
            fprintf('  SDRAM_coeff0:    min=%12.6f, max=%12.6f\n', ...
                    min(data.invtest.SDRAM_coeff0), max(data.invtest.SDRAM_coeff0));
            fprintf('  === Calculation Pipeline ===\n');
            fprintf('  Sqrt_Fxyz_norm:  min=%12.6f, max=%12.6f\n', ...
                    min(data.invtest.Sqrt_Fxyz_norm), max(data.invtest.Sqrt_Fxyz_norm));
            fprintf('  I1_interp:       min=%12.6f, max=%12.6f\n', ...
                    min(data.invtest.I1_interp), max(data.invtest.I1_interp));
            fprintf('  HsVd_ch0:        min=%12.6f, max=%12.6f (expected <10V)\n', ...
                    min(data.invtest.HsVd_ch0), max(data.invtest.HsVd_ch0));
            fprintf('  === Input Values ===\n');
            fprintf('  Fd_m range:\n');
            for i = 1:3
                fprintf('    [%d]: min=%12.6f, max=%12.6f\n', i-1, ...
                        min(data.invtest.Fd_m(:,i)), max(data.invtest.Fd_m(:,i)));
            end
            fprintf('  fd_magnitude:    min=%12.6f, max=%12.6f\n', ...
                    min(data.invtest.fd_magnitude), max(data.invtest.fd_magnitude));
        end
    end
end
