# Open-Loop Bode Analysis Pipeline

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020a+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

> **Automated frequency response analysis and MIMO transfer function identification for multi-channel control systems**

[繁體中文](README_zh-TW.md) | **English**

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Workflow](#workflow)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Guide](#configuration-guide)
- [Output Files](#output-files)
- [Function Reference](#function-reference)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project provides an end-to-end **pure MATLAB** pipeline for **open-loop frequency response analysis** and **MIMO (Multiple-Input Multiple-Output) transfer function fitting** from binary measurement data.

### Key Capabilities:
- **Binary Data Reading**: Native MATLAB HSData `.dat` file parser (V1-V8 support)
- **Automated Bode Analysis**: FFT-based transfer function extraction with steady-state detection
- **MIMO Model Fitting**: 6×6 transfer function matrix identification with weighted least squares
- **ZOH Discretization**: Sampled-data system conversion for digital controller implementation
- **Standardized Visualization**: Consistent Bode plot styling for publication-ready figures

### Version 2.0 Changes:
- **Pure MATLAB**: Removed Python dependency (hsdata_reader.py)
- **Modular Design**: All functions in `functions/` folder
- **One-Click Execution**: Single `main_openloop_cali.m` script for full pipeline
- **Standardized Plots**: Unified Bode plot styling

---

## Project Structure

```
Openloop_cali/
├── main_openloop_cali.m          # Main script - one-click execution
│
├── functions/                     # Function modules
│   ├── read_hsdata.m             # Binary file reader (V1-V8)
│   ├── repair_bad_points.m       # Bad point interpolation
│   ├── detect_excitation.m       # Excitation channel/frequency detection
│   ├── detect_steady_state.m     # Steady-state detection
│   ├── perform_fft.m             # FFT frequency response analysis
│   ├── normalize_data.m          # Data normalization (phase offset removal)
│   ├── fit_single_tf.m           # Single curve fitting
│   ├── fit_mimo_tf.m             # MIMO multi-curve fitting
│   ├── zoh_discretize.m          # ZOH discretization
│   ├── save_bode_data.m          # Save Bode data to .m files
│   ├── export_latex.m            # LaTeX output generation
│   ├── plot_bode.m               # Standardized Bode plot
│   └── plot_comparison.m         # Fitting comparison plots
│
├── raw_data/                      # Input: Binary .dat files
│   ├── P1/
│   │   ├── 0.1Hz.dat
│   │   ├── 1Hz.dat
│   │   └── ... (19 frequencies)
│   ├── P2/
│   └── ... (P3~P6)
│
├── results/                       # Output directory
│   ├── bode_data/                 # P1.m ~ P6.m
│   ├── figures/                   # PNG images
│   └── reports/                   # LaTeX, MAT files
│
├── P1.m ~ P6.m                    # Legacy frequency response data
├── openloop_bode.m                # Legacy Stage 2 script
├── Model_6_6_Continuous_Weighted.m # Legacy Stage 3 script
└── README.md                      # This file
```

---

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                     STAGE 1: DATA PROCESSING                    │
│                                                                 │
│  Raw Binary Data (.dat)                                         │
│         │                                                       │
│         ├─ read_hsdata.m → Parse binary format (V1-V8)         │
│         ├─ repair_bad_points.m → Fix bad samples               │
│         ├─ detect_excitation.m → Find excitation channel/freq  │
│         ├─ detect_steady_state.m → Locate steady-state region  │
│         └─ perform_fft.m → H(jω) = Vm(jω) / DA(jω)             │
│         ↓                                                       │
│  Frequency Response Data (P1.m ~ P6.m)                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    STAGE 2: MODEL FITTING                       │
│                                                                 │
│  P1.m ~ P6.m                                                    │
│         │                                                       │
│         ├─ fit_single_tf.m → 36 individual transfer functions  │
│         └─ fit_mimo_tf.m → Unified MIMO model                  │
│              H(s) = [A₂/(s² + A₁s + A₂)] · B                   │
│         ↓                                                       │
│  [ zoh_discretize.m ]                                          │
│         ↓                                                       │
│  Discrete Transfer Function H(z⁻¹)                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                     STAGE 3: OUTPUT                             │
│                                                                 │
│  ├─ save_bode_data.m → P1.m ~ P6.m                             │
│  ├─ export_latex.m → transfer_function_latex.txt               │
│  ├─ plot_bode.m → Bode_P1.png ~ Bode_P6.png                    │
│  └─ plot_comparison.m → Comparison plots                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| **MATLAB** | R2020a+ | All processing |

### MATLAB Toolboxes
- Control System Toolbox (for c2d, tf functions)
- Signal Processing Toolbox (optional, for advanced filtering)

---

## Quick Start

### One-Click Execution

```matlab
% Navigate to project directory
cd 'path/to/Openloop_cali'

% Run the complete pipeline
run('main_openloop_cali.m')
```

This will:
1. Process all `.dat` files in `raw_data/P1~P6/`
2. Generate frequency response data `P1.m ~ P6.m`
3. Fit MIMO transfer function model
4. Perform ZOH discretization
5. Generate Bode plots and comparison figures
6. Export LaTeX and MAT files

### Process Existing P*.m Files Only

If you already have P1.m ~ P6.m files:

```matlab
% Edit main_openloop_cali.m
ENABLE_STAGE1 = false;  % Skip raw data processing
ENABLE_STAGE2 = true;   % Run fitting
ENABLE_STAGE3 = true;   % Generate outputs

% Run
run('main_openloop_cali.m')
```

---

## Configuration Guide

### Main Configuration (`main_openloop_cali.m`)

All parameters are in **SECTION 1: Configuration**.

#### Sampling and Data Repair
```matlab
SAMPLING_RATE = 100000;              % Default sampling rate [Hz]
AUTO_DETECT_SAMPLING_RATE = true;    % Read from V6+ header

BAD_POINT_INTERVAL = 10000;          % Bad point every N samples
INTERPOLATION_METHOD = 'spline';     % 'linear'|'spline'|'pchip'|'makima'
ENABLE_BAD_POINT_REPAIR = true;      % Enable repair (100kHz only)
```

#### Steady-State Detection
```matlab
STABILITY_THRESHOLD = 2e-3;          % Max voltage diff between periods [V]
CONSECUTIVE_PERIODS = 3;             % Required stable periods
```

#### Fitting Parameters
```matlab
P_WEIGHT = 0.5;                      % Weighting exponent
WC_HZ = 0.1;                         % Cutoff frequency [Hz]
T_SAMPLE = 1e-5;                     % Discretization sample time [s]
```

#### Output Control
```matlab
ENABLE_STAGE1 = true;                % Process raw data
ENABLE_STAGE2 = true;                % Fit transfer functions
ENABLE_STAGE3 = true;                % Generate outputs

PLOT_BODE = true;                    % Generate Bode plots
PLOT_COMPARISON = true;              % Generate comparison plots
SAVE_FIGURES = true;                 % Save PNG files
EXPORT_LATEX = true;                 % Generate LaTeX output
EXPORT_MAT = true;                   % Save MAT file
```

---

## Output Files

### Frequency Response Data (`results/bode_data/P*.m`)

```matlab
% P1.m example
frequencies = [0.1, 1.0, 10.0, ...];           % Hz (1 x N)
magnitudes_linear = [0.237, 0.233, ...];       % V/V (6 x N)
phases_processed = [-10.25, -10.35, ...];      % deg (6 x N)
```

### Transfer Function (`results/reports/`)

- `fitting_results.mat` - MATLAB structure with all parameters
- `transfer_function_latex.txt` - LaTeX formatted output

### Figures (`results/figures/`)

- `Bode_P1.png` ~ `Bode_P6.png` - Individual Bode plots
- `Comparison_P1.png` ~ `Comparison_P6.png` - Fitting comparison
- `Comparison_dc_gain.png` - DC gain matrix comparison
- `Comparison_grid.png` - 36-channel overview

---

## Function Reference

### Core Functions

| Function | Purpose |
|----------|---------|
| `read_hsdata(file_path)` | Read binary .dat file |
| `repair_bad_points(Vm, da)` | Fix bad data points |
| `detect_excitation(da, fs)` | Find excitation channel/frequency |
| `detect_steady_state(Vm, fs, freq)` | Locate steady-state |
| `perform_fft(Vm, da, info, ch, freq, fs)` | Compute H(jω) |

### Fitting Functions

| Function | Purpose |
|----------|---------|
| `fit_single_tf(h, phi, w)` | Single curve fitting |
| `fit_mimo_tf(H_mag, H_phase, freq)` | MIMO fitting |
| `zoh_discretize(A1, A2, T)` | ZOH discretization |

### Visualization Functions

| Function | Purpose |
|----------|---------|
| `plot_bode(freq, mag, phase)` | Standardized Bode plot |
| `plot_comparison(freq, H_mag, H_phase, A1, A2, B)` | Comparison plots |

### Output Functions

| Function | Purpose |
|----------|---------|
| `save_bode_data(path, freq, mag, phase, ch)` | Save P*.m file |
| `export_latex(path, A1, A2, B, num_z, den_z)` | Export LaTeX |
| `normalize_data(H_mag, H_phase, freq)` | Phase offset removal |

---

## Troubleshooting

### "No .dat files found"
- Check `raw_data/P1/` folder contains `.dat` files
- Verify folder naming (P1, P2, ... P6)

### "No stable period found"
```matlab
% Relax threshold
STABILITY_THRESHOLD = 5e-3;
CONSECUTIVE_PERIODS = 2;
```

### "Matrix ill-conditioned"
- Check frequency response data quality
- Verify all P*.m files have consistent frequency points

### "Cannot find P*.m"
- Run Stage 1 first, or
- Place existing P1.m~P6.m in project root or `results/bode_data/`

---

## Bode Plot Style Reference

The standardized Bode plot follows these conventions:

```matlab
% Colors (P1-P6)
channel_colors = [
    0.0000, 0.0000, 0.5000;  % P1: Dark blue
    0.0000, 0.0000, 1.0000;  % P2: Blue
    0.0000, 0.5000, 0.0000;  % P3: Green
    1.0000, 0.0000, 0.0000;  % P4: Red
    0.8000, 0.0000, 0.8000;  % P5: Magenta
    0.0000, 0.7500, 0.7500;  % P6: Cyan
];

% Markers
markers = {'o', 's', '^', 'd', 'v', 'p'};  % Circle, Square, Triangle, Diamond, etc.

% Style
unified_linewidth = 3.5;
unified_markersize = 9;
ax.FontSize = 18;
ax.FontWeight = 'bold';
ax.LineWidth = 2.5;
```

---

**Last Updated:** 2026-01-26
**Version:** 2.0 (Pure MATLAB)
