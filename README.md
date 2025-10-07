# Open-Loop Bode Analysis Pipeline

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020a+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Python](https://img.shields.io/badge/Python-3.7+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

> **Automated frequency response analysis and MIMO transfer function identification for multi-channel control systems**

[繁體中文](README_zh-TW.md) | **English**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Workflow](#workflow)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Detailed Usage](#detailed-usage)
- [Configuration Guide](#configuration-guide)
- [Output Files](#output-files)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This project provides an end-to-end pipeline for **open-loop frequency response analysis** and **MIMO (Multiple-Input Multiple-Output) transfer function fitting** from binary measurement data.

### Key Capabilities:
- ✅ **Binary-to-CSV Conversion**: Convert HSData `.dat` files to CSV format
- ✅ **Automated Bode Analysis**: FFT-based transfer function extraction with steady-state detection
- ✅ **MIMO Model Fitting**: 6×6 transfer function matrix identification
- ✅ **Robust Signal Processing**: Advanced interpolation, noise handling, and validation



---

## 📁 Project Structure

```
Openloop_cali/
│
├── README.md                          # This file (English)
├── README_zh-TW.md                    # Traditional Chinese version
├── requirements.txt                   # Python dependencies
│
├── hsdata_reader.py                   # Stage 1: Binary-to-CSV converter
├── openloop_bode.m                    # Stage 2: Bode analysis
├── Model_6_6_Continuous_Weighted.m    # Stage 3: MIMO model fitting
│
├── raw_data/                          # Input: Binary data files
│   ├── P1/
│   │   ├── 0.1Hz.dat
│   │   ├── 1Hz.dat
│   │   ├── 10Hz.dat
│   │   ├── 50Hz.dat
│   │   ├── 100Hz.dat
│   │   ├── ... (19 frequencies total)
│   │   └── 2000Hz.dat
│   ├── P2/
│   │   └── ... (same structure)
│   ├── P3/
│   ├── P4/
│   ├── P5/
│   └── P6/
│
├── processed_csv/                     # Stage 1 Output: CSV files
│   ├── P1/
│   │   ├── 0.1Hz.csv
│   │   ├── 1Hz.csv
│   │   └── ... (19 files)
│   ├── P2/
│   └── ... (P3~P6)
│
├── P1.m                               # Stage 2 Output: Frequency response
├── P2.m
├── P3.m
├── P4.m
├── P5.m
├── P6.m
│
├── transfer_function_latex.txt        # Stage 3 Output: Unified MIMO model
└── one_curve_36_results.mat           # Stage 3 Output: 36 individual transfer functions
```

---

## 🔄 Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                     STAGE 1: DATA CONVERSION                    │
│                                                                 │
│  Raw Binary Data (.dat)                                        │
│         │                                                       │
│         ├─ P1/0.1Hz.dat, 1Hz.dat, 10Hz.dat, ...               │
│         ├─ P2/0.1Hz.dat, 1Hz.dat, 10Hz.dat, ...               │
│         └─ ... (P3 ~ P6)                                       │
│         ↓                                                       │
│  [ hsdata_reader.py ]                                          │
│         ↓                                                       │
│  CSV Files (vm_0~5, vd_0~5, da_0~5)                           │
│         │                                                       │
│         └─ processed_csv/P1/*.csv                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STAGE 2: BODE ANALYSIS                        │
│                                                                 │
│  CSV Files                                                      │
│         ↓                                                       │
│  [ openloop_bode.m ]                                           │
│         │                                                       │
│         ├─ Data repair (interpolation)                         │
│         ├─ Excitation detection                                │
│         ├─ Steady-state detection                              │
│         ├─ FFT analysis (H = VM/DA)                            │
│         └─ Phase processing                                    │
│         ↓                                                       │
│  Frequency Response Data (P1.m ~ P6.m)                         │
│         │                                                       │
│         └─ Variables: frequencies, magnitudes_linear,          │
│            phases, phases_processed                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STAGE 3: MODEL FITTING                        │
│                                                                 │
│  P1.m ~ P6.m                                                    │
│         ↓                                                       │
│  [ Model_6_6_Continuous_Weighted.m ]                           │
│         │                                                       │
│         ├─ Load 6×6 frequency response matrix                  │
│         ├─ Weighted curve fitting (H(s) = ωn²/(s²+2ζωn·s+ωn²))│
│         ├─ Sampled-data system conversion (ZOH)               │
│         └─ LaTeX output generation                             │
│         ↓                                                       │
│  MIMO Transfer Function Model                                  │
│         │                                                       │
│         ├─ Continuous: H(s)                                    │
│         ├─ Discrete: H(z⁻¹)                                    │
│         └─ LaTeX: transfer_function_latex.txt                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| **Python** | 3.7+ | Data conversion (Stage 1) |
| **MATLAB** | R2020a+ | Analysis & modeling (Stage 2 & 3) |

### MATLAB Toolboxes
- Control System Toolbox
- Signal Processing Toolbox

### Python Dependencies
```bash
pip install -r requirements.txt
```

**Required packages:**
- `numpy >= 1.20.0`
- `pandas >= 1.3.0`
- `tqdm >= 4.60.0`

---

## 🚀 Installation

### 1. Clone or Download Project
```bash
cd /path/to/your/workspace
# Download or clone the Openloop_cali folder
```

### 2. Install Python Dependencies
```bash
cd Openloop_cali
pip install -r requirements.txt
```

### 3. Verify MATLAB Installation
```matlab
% In MATLAB command window
ver  % Check installed toolboxes
```

### 4. Prepare Data Folders
```bash
Openloop_cali/
├── raw_data/          # Place your .dat files here
│   ├── P1/
│   │   ├── 0.1Hz.dat
│   │   ├── 1Hz.dat
│   │   └── ...
│   ├── P2/
│   └── ... (P3~P6)
└── processed_csv/     # Auto-created by hsdata_reader.py
```

---

## ⚡ Quick Start

### Complete Pipeline (3 Steps)

```bash
# Navigate to project directory
cd /path/to/Openloop_cali

# Step 1: Convert all binary data to CSV (P1~P6)
python hsdata_reader.py all

# Step 2: Analyze frequency response for each channel (in MATLAB)
# Open MATLAB in project directory, then run:
```

```matlab
% Process all channels P1~P6
for i = 1:6
    folder = fullfile(pwd, 'processed_csv', sprintf('P%d', i));
    openloop_bode(folder);
end
```

```bash
# Step 3: Fit MIMO transfer function model (in MATLAB)
```

```matlab
% Run model fitting script
run('Model_6_6_Continuous_Weighted.m')
```

### Process Single Channel (Example: P1 only)

```bash
# Step 1: Convert P1 data only
python hsdata_reader.py P1

# Step 2: Analyze P1 (in MATLAB)
```

```matlab
openloop_bode(fullfile(pwd, 'processed_csv', 'P1'))
```

---

## 📖 Detailed Usage

### Stage 1: Data Conversion

**Command:**
```bash
python hsdata_reader.py <folder_name>
```

**Options:**
- `P1`, `P2`, ..., `P6` - Process single folder
- `all` - Process all P1~P6 folders
- (no arguments) - Show help message

**Example:**
```bash
# Process all folders
python hsdata_reader.py all

# Process P1 only
python hsdata_reader.py P1
```

**Output:**
- Creates `processed_csv/P1/*.csv` with columns:
  - `index`, `vm_0~5`, `vd_0~5`, `da_0~5`

**Progress Display:**
```
==========================================================
Processing folder: P1
Input:  /path/to/raw_data/P1
Output: /path/to/processed_csv/P1
Files:  19 .dat files found
==========================================================
Converting P1: 100%|████████████| 19/19 [00:05<00:00, 3.2file/s]

✓ Folder 'P1' completed:
  - Successfully processed: 19 files
```

---

### Stage 2: Bode Analysis

**Command (MATLAB):**
```matlab
% Use default path (processed_csv/P1)
openloop_bode()

% Or specify custom path
openloop_bode('path/to/processed_csv/P2')
```

**Processing Steps:**
1. Load CSV data
2. Repair bad data points (every 10000th sample)
3. Detect excitation channel and frequency
4. Detect steady-state region
5. Perform FFT analysis (H = VM/DA)
6. Process phase data (180° correction)
7. Generate Bode plots
8. Save results to `P1.m` (or P2.m, etc.)

**Output Example:**
```
=== OPENLOOP BODE ANALYSIS ===
Data folder: C:\...\processed_csv\P1
Found 19 CSV files

[1/19] Processing: 0.1Hz.csv (5.2 MB)
  Step 1: Loading CSV data...
  Step 2: Repairing bad data points...
    Using interpolation method: spline
    VM repair RMS error: 0.000012 V (average)
    DA repair RMS error: 0.000008 V (average)
    Total data points: 100000, Repaired points: 10
  Step 3: Detecting excitation channel and frequency...
    Excitation: DA1, Frequency: 0.1 Hz
  Step 4: Steady-state detection...
    Period samples: 1000000, Max periods: 10
    Steady-state detected: Period 5, Index 5000001
  Step 5: FFT analysis (mode: full)...
    Using full FFT: 5 periods
  ✓ Successfully processed frequency 0.1 Hz

[2/19] Processing: 1Hz.csv (5.2 MB)
...

=== ANALYSIS COMPLETE ===
Successfully processed: 19 frequency points
Frequency range: 0.1 - 2000.0 Hz

Saving Bode data to: C:\...\P1.m...
✓ Bode data saved successfully

=== ALL OPERATIONS COMPLETE ===
```

**Generated Files:**
- `P1.m` (or P2.m, etc.) - MATLAB data file with variables:
  - `frequencies` - Frequency points (Hz)
  - `magnitudes_linear` - Linear magnitude (6 × N)
  - `phases` - Original phase (degrees)
  - `phases_processed` - Processed phase with 180° correction

**Bode Plot Visualization:**
- Two-panel plot (magnitude & phase)
- All 6 channels plotted
- Theoretical model overlay
- Auto-saved as MATLAB figure

---

### Stage 3: MIMO Model Fitting

**Command (MATLAB):**
```matlab
run('Model_6_6_Continuous_Weighted.m')
```

**Requirements:**
- All `P1.m ~ P6.m` files must exist in project directory

**Processing:**
1. Load 6×6 frequency response matrix from P1~P6.m
2. Fit second-order transfer function for each element
3. Apply weighted least-squares optimization
4. Perform sampled-data system conversion via ZOH (T = 10 μs)
5. Generate LaTeX output
6. (Optional) SECTION 9: One-Curve vs Multi-Curve comparison

**Output Files:**
- `transfer_function_latex.txt` - LaTeX formatted transfer function
- `one_curve_36_results.mat` - Individual transfer functions (36 elements)

**SECTION 9: Model Comparison (Optional)**

Enable comparison between one-curve and multi-curve fitting methods:

```matlab
% In Model_6_6_Continuous_Weighted.m, SECTION 1
ENABLE_ONE_MULTI_COMPARISON = true;
ONE_MULTI_COMPARISON_CHANNELS = [1, 2, 3, 4, 5, 6];  % Select channels
```

**Generated Plots:**
1. **Steady-State Gain Matrix** - 2-panel comparison showing H(s=0) values
   - Panel 1: One-Curve method (individual fitting)
   - Panel 2: Multi-Curve method (unified model)

2. **Grouped Bode Plots** - Frequency response comparison by excitation channel
   - Gray lines: One-Curve individual fits (paired channel highlighted in darker gray)
   - Black line: Multi-Curve unified model
   - Legend shows only the paired channel (e.g., P1↔P2, P3↔P4, P5↔P6)

**Output Format Example:**
```latex
% Continuous Transfer Function H(s)
H_{11}(s) = \frac{1.4848 \times 10^7}{s^2 + 8187.7 s + 1.4848 \times 10^7}

% Discrete Transfer Function H(z^{-1})
H_{11}(z^{-1}) = \frac{0.3618 (3.6963 \times 10^{-6} z^{-1} + ...}{1 - 1.9181 z^{-1} + 0.9182 z^{-2}}
```

---

## ⚙️ Configuration Guide

### `openloop_bode.m` - Section 1 Parameters

All adjustable parameters are centralized at the top of the file (lines 28-56).

#### File I/O Configuration
```matlab
% Auto-detected (no manual editing needed)
SCRIPT_DIR = fileparts(mfilename('fullpath'));
DEFAULT_DATA_FOLDER = fullfile(SCRIPT_DIR, 'processed_csv', 'P1');
OUTPUT_BASE_FOLDER = SCRIPT_DIR;
```

#### Signal Processing Parameters
| Parameter | Default | Description | Recommended Values |
|-----------|---------|-------------|-------------------|
| `SAMPLING_RATE` | 100000 | Sampling rate (Hz) | 100000 (fixed) |
| `MIN_DA_THRESHOLD` | 1e-10 | Minimum DA signal for valid FFT | 1e-10 ~ 1e-8 |
| `INTERPOLATION_METHOD` | `'spline'` | Bad point repair method | `'spline'`, `'pchip'`, `'makima'`, `'linear'` |

#### Steady-State Detection Parameters
| Parameter | Default | Description | Tuning Tips |
|-----------|---------|-------------|------------|
| `STABILITY_THRESHOLD` | 2e-3 | Max voltage difference between periods (V) | Increase if false positives, decrease for stricter detection |
| `CONSECUTIVE_PERIODS` | 3 | Required consecutive stable periods | 3-5 for good SNR, 1-2 for noisy data |
| `CHECK_POINTS` | 25 | Sample points per period for comparison | 20-30 typical |
| `START_PERIOD` | 1 | Starting period index for detection | 1 (skip transient if > 1) |

#### FFT Analysis Configuration
| Parameter | Default | Description | Use Case |
|-----------|---------|-------------|----------|
| `FFT_MODE` | `'full'` | FFT calculation mode | `'full'` (default), `'averaged'` (lower noise) |
| `COMPARE_FFT_METHODS` | `false` | Enable FFT method comparison | `true` for debugging |

#### Visualization Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `CHANNEL_COLORS` | `['k','b','g','r','m','c']` | Plot colors for 6 channels |
| `DISPLAY_CHANNELS` | `[1,2,3,4,5,6]` | Channels to show in Bode plot |
| `PLOT_STEADY_STATE` | `true` | Enable steady-state overlay plot |
| `PLOT_CHANNEL` | `[1]` | Channels for overlay (0=all, 1-6=specific) |
| `PLOT_FREQUENCY_LIST` | `[0.1]` | Frequencies to plot (empty=all) |

#### Model Parameters (Theoretical Curve)
```matlab
MODEL_WN_SQUARED = 1.4848e7;      % Natural frequency squared (rad²/s²)
MODEL_TWO_ZETA_WN = 8.1877e3;     % 2ζωn (rad/s)
```

### Common Configuration Scenarios

**Scenario 1: Noisy Data**
```matlab
STABILITY_THRESHOLD = 5e-3;       % Relax threshold
CONSECUTIVE_PERIODS = 5;          % Require more stable periods
FFT_MODE = 'averaged';            % Use period averaging
```

**Scenario 2: Quick Processing (Skip Visualization)**
```matlab
PLOT_STEADY_STATE = false;        % Disable overlay plots
PLOT_FREQUENCY_LIST = [];         % Don't plot any frequencies
```

**Scenario 3: Debug Mode**
```matlab
COMPARE_FFT_METHODS = true;       % Compare FFT methods
PLOT_STEADY_STATE = true;
PLOT_CHANNEL = 0;                 % Plot all channels
PLOT_FREQUENCY_LIST = [];         % Plot all frequencies
```

---

## 📂 Output Files

### Stage 1: CSV Files

**Location:** `processed_csv/P1/*.csv`

**Format:**
```csv
index,vm_0,vm_1,vm_2,vm_3,vm_4,vm_5,vd_0,...,da_5
0,0.0012,0.0034,...,32768
1,0.0013,0.0035,...,32769
...
```

**Columns (19 total):**
- `index` - Sample index
- `vm_0 ~ vm_5` - VM voltage measurements (6 channels)
- `vd_0 ~ vd_5` - VD voltage measurements (6 channels)
- `da_0 ~ da_5` - DA digital values (6 channels, 0-65535)

---

### Stage 2: Frequency Response Data Files

**Location:** `P1.m`, `P2.m`, ..., `P6.m`

**Variables:**

| Variable | Dimension | Description | Example |
|----------|-----------|-------------|---------|
| `frequencies` | 1 × N | Frequency points (Hz) | `[0.1, 1.0, 10.0, ...]` |
| `magnitudes_linear` | 6 × N | Linear magnitude (V/V) | `[0.237, 0.233, ...]` |
| `phases` | 6 × N | Original phase (degrees) | `[169.75, 169.65, ...]` |
| `phases_processed` | 6 × N | Processed phase (degrees) | `[-10.25, -10.35, ...]` |

**Usage Example:**
```matlab
% Load P1 data
run('P1.m')

% Plot magnitude for channel 1
figure;
semilogx(frequencies, 20*log10(magnitudes_linear(1,:)));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('P1 Channel 1 Frequency Response');

% Plot processed phase for all channels
figure;
semilogx(frequencies, phases_processed');
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');
legend('P1','P2','P3','P4','P5','P6');
```

---

### Stage 3: Transfer Function Model

**Location:** `transfer_function_latex.txt`

**Content:**
- Continuous transfer function H(s) - 6×6 matrix
- Discrete transfer function H(z⁻¹) - 6×6 matrix
- LaTeX formatted for direct inclusion in documents

---

## 🔧 Troubleshooting

### Common Issues

#### ❌ **Error: "No CSV files found in folder"**

**Cause:** Stage 1 not completed or wrong folder path

**Solution:**
```bash
# Check if CSV files exist
ls processed_csv/P1/

# If empty, run Stage 1 first
python hsdata_reader.py P1
```

---

#### ⚠️ **Warning: "Frequency mismatch - target X Hz, actual Y Hz"**

**Cause:** FFT bin does not exactly match excitation frequency

**Impact:** Depends on relative error magnitude

| Excitation Frequency | Acceptable Error | Example |
|---------------------|------------------|---------|
| 0.1 ~ 1 Hz | < 0.01 Hz | 0.1 Hz with 0.05 Hz error → 50% error, ❌ needs attention |
| 1 ~ 10 Hz | < 0.05 Hz | 5 Hz with 0.05 Hz error → 1% error, ✅ acceptable |
| 10 ~ 100 Hz | < 0.1 Hz | 50 Hz with 0.1 Hz error → 0.2% error, ✅ acceptable |
| 100 ~ 1000 Hz | < 0.5 Hz | 500 Hz with 0.5 Hz error → 0.1% error, ✅ acceptable |
| 1000 ~ 2000 Hz | < 1 Hz | 1500 Hz with 1 Hz error → 0.07% error, ✅ acceptable |

**General Rule:** Relative error < 1% is usually negligible

**Solution (if needed):**
- Check if raw data file name matches actual frequency
- Verify sampling rate is correctly set (100 kHz)
- Ensure data length is sufficient (at least 5 complete periods)

---

#### ⚠️ **Warning: "No stable period found (threshold 0.0020V)"**

**Cause:** Signal has not reached steady-state or threshold too strict

**Solutions:**

**Option 1: Relax threshold**
```matlab
STABILITY_THRESHOLD = 5e-3;  % Increase from 2e-3
```

**Option 2: Reduce required consecutive periods**
```matlab
CONSECUTIVE_PERIODS = 2;     % Reduce from 3
```

**Option 3: Skip initial transient**
```matlab
START_PERIOD = 3;            % Start from period 3
```

---

#### ⚠️ **Warning: "Insufficient periods (only X), using last period as steady-state"**

**Cause:** Data file too short (< 5 complete periods)

**Impact:** Results may include transient response, less reliable

**Solutions:**
- Use longer data acquisition time
- Verify data file is complete (not truncated)
- Accept lower reliability (program will still run)

---

#### ⚠️ **Warning: "Requested end_index exceeds data length"**

**Cause:** Program's calculated data range exceeds actual data length

**Common Reasons:**
1. Steady-state detected near end of data, insufficient remaining data
2. Data file truncated (not completely saved)
3. Available period count overestimated

**Automatic Handling:**
- ✅ Display warning message
- ✅ Automatically trim to data end
- ✅ Attempt to continue FFT analysis

**How to Determine if Action is Needed:**

**Case 1: Subsequent Processing Succeeds**
```
Warning CH1: Requested end_index (100999) exceeds data length (100000)
...
✓ Successfully processed frequency 100.0 Hz
```
→ **No action needed**, program auto-recovered, results are reliable

**Case 2: Subsequent Processing Fails**
```
Warning CH1: Requested end_index (100999) exceeds data length (100000)
Warning CH1: Insufficient data (999 samples) for one period (2000 samples)
✗ Processing failed: ...
```
→ **Action needed**:
- Check if original .dat file is complete
- Verify CSV conversion process
- Consider using longer data acquisition time

---

#### ❌ **Stage 3 Error: "Undefined function or variable 'P1'"**

**Cause:** P1.m ~ P6.m files not generated

**Solution:**
```matlab
% Verify all files exist
dir('P*.m')

% If missing, re-run Stage 2 for missing channels
openloop_bode(fullfile(pwd, 'processed_csv', 'P1'))
```

---

### Debug Mode

Enable detailed diagnostics:

```matlab
% In openloop_bode.m, Section 1
FFT_MODE = 'averaged';
COMPARE_FFT_METHODS = true;      % Compare FFT methods
PLOT_STEADY_STATE = true;        % Show waveform overlays
PLOT_CHANNEL = 0;                % Plot all channels
PLOT_FREQUENCY_LIST = [];        % Plot all frequencies
```

This will generate:
- FFT method comparison statistics
- Steady-state waveform plots for all frequencies
- Detailed console output

---

**Last Updated:** 2025-10-05
**Version:** 2.0
