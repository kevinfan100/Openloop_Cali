# MIMO DAT Pipeline Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable the MIMO 6x6 pipeline to read raw .dat files (not just legacy P*.m), so new experiments like NTU_hx can go through `run_analysis('NTU_hx', 'mimo_all')`.

**Architecture:** Add `load_dat_pdata.m` function (parallel to `load_legacy_pdata.m`) that reads 6 folders of .dat files, runs read + steady-state + FFT on all 6 Vm channels per file, and assembles a 6x6xN frequency response tensor. Wire it into `step_mimo_fft.m`'s existing `case 'dat'` branch. Add `NTU_hx_config.m` with DAT-specific MIMO settings.

**Tech Stack:** MATLAB, existing pipeline functions (`read_hsdata`, `detect_steady_state_relative`, `compute_super_period`)

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `functions/load_dat_pdata.m` | **Create** | Read 6 folders of .dat files → 6x6xN tensor |
| `configs/NTU_hx_config.m` | **Create** | MIMO config for NTU_hx experiment |
| `pipeline/step_mimo_fft.m` | **Modify (line 38-40)** | Replace error with `load_dat_pdata` call |

**Not modified:** `step_mimo_fit.m`, `step_mimo_plot.m`, `run_analysis.m`, `fit_mimo_tf.m`, `auto_phase_correct_6x6.m` — all accept 6x6xN tensor regardless of source.

---

## Task 1: Create `NTU_hx_config.m`

**Files:**
- Create: `configs/NTU_hx_config.m`

- [ ] **Step 1: Create config file**

```matlab
function config = NTU_hx_config()
%NTU_HX_CONFIG NTU hexapole MIMO 6x6 實驗配置 (DAT 來源)
%
% 使用方式:
%   run_analysis('NTU_hx', 'mimo_all');
%   run_analysis('NTU_hx', 'mimo_fit');
%   run_analysis('NTU_hx', 'mimo_plot');

    config = default_config();
    config.experiment_name = 'NTU_hx';

    %% 15 點頻率表
    config.expected_frequencies = [
        0.1, 1, 10, 50, 100, 200, 500, 1000, ...
        1200, 1250, 1500, 1600, 2000, 2500, 3000
    ];

    %% MIMO 專用設定
    config.mimo = struct();
    config.mimo.num_channels = 6;
    config.mimo.data_source = 'dat';
    config.mimo.legacy_data_folder = '';  % 不使用 legacy
    config.mimo.pair_map = [2, 1, 4, 3, 6, 5];

    % DAT 來源設定
    config.mimo.dat_base_folder = fullfile(config.project_root, 'data', 'NTU_hx');
    config.mimo.dat_subfolder = {'hx_p1'; 'hx_p2'; 'hx_p3'; ...
                                  'hx_p4'; 'hx_p5'; 'hx_p6'};
    config.mimo.dat_prefix = {'NTU_hx_p1'; 'NTU_hx_p2'; 'NTU_hx_p3'; ...
                               'NTU_hx_p4'; 'NTU_hx_p5'; 'NTU_hx_p6'};

    % 各通道放大器增益 (同 MIMO_config)
    config.mimo.k_A_diag = [0.3618, 0.3614, 0.3536, 0.3532, 0.3573, 0.3610];

    % ZOH 取樣時間
    config.mimo.T_sample = 1e-5;  % 10 us (100 kHz)

    %% Fitting 參數
    config.fitting.p_weight = 0.5;
    config.fitting.wc_Hz = 0.1;

    %% 輸出路徑
    config.output_folder = fullfile(config.project_root, 'results', 'NTU_hx');
end
```

- [ ] **Step 2: Verify config loads without error**

Run in MATLAB:
```matlab
addpath('configs'); addpath('functions');
config = NTU_hx_config();
disp(config.mimo)
```

Expected: struct with `data_source='dat'`, `dat_subfolder` cell array of 6 entries.

- [ ] **Step 3: Commit**

```bash
git add configs/NTU_hx_config.m
git commit -m "feat(configs): add NTU_hx MIMO config for DAT data source"
```

---

## Task 2: Create `load_dat_pdata.m`

**Files:**
- Create: `functions/load_dat_pdata.m`

**References:**
- `functions/load_legacy_pdata.m` — output format (6x6xN tensor, same signature)
- `pipeline/step_read.m` — `read_hsdata` usage, DAC conversion
- `pipeline/step_steady_state.m` — `detect_steady_state_relative` usage
- `pipeline/step_fft.m:69-79` — FFT computation (fundamental bin extraction)
- `functions/compute_super_period.m` — super-period calculation

- [ ] **Step 1: Create `load_dat_pdata.m`**

Function signature matches `load_legacy_pdata`:
```
[H_mag, H_phase_raw, freq_out] = load_dat_pdata(config, varargin)
```

Input: full config struct (needs `mimo.dat_base_folder`, `mimo.dat_subfolder`, `mimo.dat_prefix`, `expected_frequencies`, `dac.*`, `steady_state.*`).

Output: identical to `load_legacy_pdata` — `H_mag` (6x6xN), `H_phase_raw` (6x6xN deg), `freq_out` (1xN Hz).

```matlab
function [H_mag, H_phase_raw, freq_out] = load_dat_pdata(config, varargin)
%LOAD_DAT_PDATA 從 .dat 檔案載入 6x6 頻率響應數據
%
% 從 6 個激勵通道資料夾讀取 .dat 檔案，對所有 6 個 Vm 通道做 FFT，
% 組裝為 6x6xN tensor。等效於 load_legacy_pdata 但直接處理原始數據。
%
% 使用方式:
%   [H_mag, H_phase_raw, frequencies] = load_dat_pdata(config)
%
% 輸入:
%   config - MIMO config struct (需有 config.mimo.dat_* 欄位)
%
% 選項:
%   'Verbose' - 顯示處理資訊 (default: true)
%
% 輸出:
%   H_mag         - 6 x 6 x N magnitude (linear)
%   H_phase_raw   - 6 x 6 x N phase (deg, 原始未修正)
%   freq_out      - 1 x N Hz

    %% 解析參數
    pr = inputParser;
    pr.KeepUnmatched = true;
    addRequired(pr, 'config', @isstruct);
    addParameter(pr, 'Verbose', true, @islogical);
    parse(pr, config, varargin{:});
    opts = pr.Results;

    %% 設定
    num_ch = config.mimo.num_channels;   % 6
    base_folder = config.mimo.dat_base_folder;
    subfolders = config.mimo.dat_subfolder;    % 6x1 cell
    prefixes = config.mimo.dat_prefix;         % 6x1 cell
    freq_out = config.expected_frequencies;
    num_freq = length(freq_out);

    H_mag = zeros(num_ch, num_ch, num_freq);
    H_phase_raw = zeros(num_ch, num_ch, num_freq);

    %% 逐激勵通道處理
    for p_idx = 1:num_ch
        excite_ch = p_idx;
        data_folder = fullfile(base_folder, subfolders{p_idx});
        data_files = build_data_files(prefixes{p_idx}, freq_out);

        if opts.Verbose
            fprintf('\n--- P%d: excite ch%d (%s) ---\n', p_idx, excite_ch, subfolders{p_idx});
        end

        for k = 1:num_freq
            freq = freq_out(k);
            filepath = fullfile(data_folder, data_files{k});

            if opts.Verbose
                fprintf('  [%d/%d] %.1f Hz ... ', k, num_freq, freq);
            end

            try
                %% 1. Read binary
                data = read_hsdata(filepath);
                fs = data.sampling_rate;

                %% 2. DAC -> Voltage (激勵通道)
                da_volt = (double(data.da) - config.dac.zero_offset) * ...
                          (config.dac.voltage_range / config.dac.resolution);

                %% 3. Steady-state detection (用對角通道 Vm)
                Vm_diag = data.Vm(:, excite_ch);
                period_samples = round(fs / freq);
                actual_check_pts = min(config.steady_state.check_points, period_samples);

                steady_info = detect_steady_state_relative(Vm_diag, freq, fs, ...
                    'RelativeThreshold', config.steady_state.relative_threshold, ...
                    'ConsecutivePeriods', config.steady_state.consecutive_periods, ...
                    'CheckPoints', actual_check_pts, ...
                    'Verbose', false);

                if steady_info.index > 0
                    steady_start = steady_info.index;
                else
                    % Low-frequency fallback: use last periods
                    min_periods = config.steady_state.min_periods_for_fft;
                    total_samples = size(data.Vm, 1);
                    steady_start = max(1, total_samples - min_periods * period_samples + 1);
                    if opts.Verbose, fprintf('(fallback) '); end
                end

                %% 4. Super-period & FFT length
                [sp_samples, ~] = compute_super_period(freq, fs);
                available_samples = size(data.Vm, 1) - steady_start + 1;
                available_super = floor(available_samples / sp_samples);

                if available_super > 0
                    fft_length = available_super * sp_samples;
                else
                    available_periods = floor(available_samples / period_samples);
                    fft_length = available_periods * period_samples;
                end

                %% 5. FFT on all 6 Vm channels + DA excitation channel
                da_steady = da_volt(steady_start : steady_start + fft_length - 1, excite_ch);
                DA_fft = fft(da_steady);
                N = fft_length;
                freq_axis = (0:N-1) * fs / N;
                [~, fundamental_bin] = min(abs(freq_axis - freq));

                for out_ch = 1:num_ch
                    Vm_steady = data.Vm(steady_start : steady_start + fft_length - 1, out_ch);
                    Vm_fft = fft(Vm_steady);

                    H_complex = Vm_fft(fundamental_bin) / DA_fft(fundamental_bin);
                    H_mag(out_ch, p_idx, k) = abs(H_complex);
                    H_phase_raw(out_ch, p_idx, k) = angle(H_complex) * 180 / pi;
                end

                if opts.Verbose, fprintf('OK\n'); end

            catch ME
                if opts.Verbose, fprintf('ERROR: %s\n', ME.message); end
                % Leave zeros for this (p_idx, k) entry
            end
        end
    end

    %% Summary
    if opts.Verbose
        n_nonzero = nnz(H_mag);
        n_total = numel(H_mag);
        fprintf('\nDAT P-data loaded:\n');
        fprintf('  Source: %s\n', base_folder);
        fprintf('  Excitation channels: %d folders x %d frequencies\n', num_ch, num_freq);
        fprintf('  Tensor: %d x %d x %d\n', num_ch, num_ch, num_freq);
        fprintf('  Non-zero entries: %d/%d (%.1f%%)\n', ...
            n_nonzero, n_total, n_nonzero/n_total*100);
    end
end
```

- [ ] **Step 2: Run `checkcode` to verify zero warnings**

Run in MATLAB:
```matlab
checkcode('functions/load_dat_pdata.m')
```

Expected: no warnings.

- [ ] **Step 3: Commit**

```bash
git add functions/load_dat_pdata.m
git commit -m "feat(functions): add load_dat_pdata for MIMO DAT data loading"
```

---

## Task 3: Wire `step_mimo_fft.m` to use `load_dat_pdata`

**Files:**
- Modify: `pipeline/step_mimo_fft.m:38-40`

- [ ] **Step 1: Replace the error stub with actual call**

Change lines 38-40 in `step_mimo_fft.m` from:

```matlab
        case 'dat'
            error('step_mimo_fft:dat_not_implemented', ...
                'DAT data source not yet implemented. Use ''legacy'' for now.');
```

To:

```matlab
        case 'dat'
            [H_mag, H_phase_raw, frequencies] = load_dat_pdata( ...
                config, 'Verbose', opts.Verbose);
```

- [ ] **Step 2: Run `checkcode` on modified file**

Run in MATLAB:
```matlab
checkcode('pipeline/step_mimo_fft.m')
```

Expected: no warnings.

- [ ] **Step 3: Commit**

```bash
git add pipeline/step_mimo_fft.m
git commit -m "feat(pipeline): enable DAT data source in step_mimo_fft"
```

---

## Task 4: End-to-end validation

**Prerequisite:** User must place .dat files in `data/NTU_hx/hx_p1/` through `data/NTU_hx/hx_p6/`.

- [ ] **Step 1: Verify data files exist**

Run in MATLAB:
```matlab
config = NTU_hx_config();
for p = 1:6
    folder = fullfile(config.mimo.dat_base_folder, config.mimo.dat_subfolder{p});
    files = dir(fullfile(folder, '*.dat'));
    fprintf('P%d: %d files in %s\n', p, length(files), folder);
end
```

Expected: each P folder has 15 .dat files.

- [ ] **Step 2: Run `mimo_fft` only — verify tensor and CSV**

```matlab
run_analysis('NTU_hx', 'mimo_fft');
```

Expected output:
- Console: `Stage 1 complete: 6 x 6 x 15 tensor`
- File: `results/NTU_hx/fitting_results/MIMO_Raw_Bode_Data.csv` (16 lines: header + 15 freq)

Quick sanity check:
```matlab
T = readtable(fullfile('results','NTU_hx','fitting_results','MIMO_Raw_Bode_Data.csv'));
disp(T.Frequency_Hz')       % Should match frequencies_15
disp(T.H_11_Mag')           % Diagonal: should be largest values
disp(T.H_12_Mag')           % Off-diagonal: should be smaller
```

- [ ] **Step 3: Run full `mimo_all` pipeline**

```matlab
run_analysis('NTU_hx', 'mimo_all');
```

Expected outputs in `results/NTU_hx/`:
- `fitting_results/MIMO_Raw_Bode_Data.csv`
- `fitting_results/MIMO_Corrected_Bode_Data.csv`
- `fitting_results/MIMO_Fit_Results.csv`
- `fitting_results/mimo_fit_results.mat`
- `fitting_results/transfer_function_latex.txt`
- `figures/MIMO_Bode_P1.png` ~ `MIMO_Bode_P6.png`
- `figures/MIMO_B_Matrix.png`
- `figures/MIMO_Shared_Hypothesis.png`
- `figures/MIMO_Phase_Correction.png`

- [ ] **Step 4: Verify B_modified diagonal is reasonable**

```matlab
loaded = load(fullfile('results','NTU_hx','fitting_results','mimo_fit_results.mat'));
fr = loaded.fit_results;
fprintf('A1 = %.6e\n', fr.A1);
fprintf('A2 = %.6e\n', fr.A2);
fprintf('B_diag = '); disp(diag(fr.B_modified)');
fprintf('CV_a1 = %.2f%%\n', fr.batch_single.cv_a1);
fprintf('CV_a2 = %.2f%%\n', fr.batch_single.cv_a2);
```

- [ ] **Step 5: Commit all results and validation**

```bash
git add configs/NTU_hx_config.m functions/load_dat_pdata.m pipeline/step_mimo_fft.m
git commit -m "feat(mimo): enable DAT data source pipeline for NTU_hx 6x6 experiment"
```

---

## Summary of changes

| File | Lines changed | What |
|------|--------------|------|
| `configs/NTU_hx_config.m` | +40 (new) | MIMO config with DAT source |
| `functions/load_dat_pdata.m` | +120 (new) | .dat → 6x6xN tensor loader |
| `pipeline/step_mimo_fft.m` | 3 lines replaced | Wire `case 'dat'` to `load_dat_pdata` |

Total: ~160 lines new code, 3 lines modified. Zero changes to fitting/plotting pipeline.
