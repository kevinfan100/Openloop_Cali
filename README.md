# Open-Loop Bode Analysis Pipeline

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020a+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

> **Open-loop frequency response calibration for hexapole electromagnetic actuators**

[繁體中文](README_zh-TW.md) | **English**

---

## Overview

This project provides an automated **pure MATLAB** pipeline for open-loop frequency response analysis of hexapole electromagnetic actuators. It processes raw binary measurement data (`.dat`) into Bode plots, transfer function fits, and multi-experiment comparisons.

**Signal chain:** DAC &rarr; Amplifier (k_A) &rarr; Coil &rarr; Magnetic Flux &rarr; Hall Sensor &rarr; Vm

**Model:** H(s) = A&#8322;/(s&#178;+A&#8321;s+A&#8322;) &middot; B &mdash; second-order overdamped, bandwidth ~200 Hz

### 11 Experiments

| Group | Experiment | Description | Freq Points |
|-------|-----------|-------------|-------------|
| Single | `Hung` | Hung actuator (with ring) | 19 |
| Single | `Hung_no_washer` | Hung actuator (no washer) | 19 |
| Single | `Hung_spring_washer` | Hung actuator (spring washer) | 19 |
| Single | `Hung_single_yoke` | Hung single yoke | 15 |
| Single | `NTU` | NTU actuator | 19 |
| Dual | `NTU_t` / `NTU_s` | NTU tip / surface sensor | 19 |
| Pair | `Hung_pair_2` / `Hung_pair_3` | Hung excite / coupled channel | 19 |
| Pair | `NTU_pair_2` / `NTU_pair_3` | NTU excite / coupled channel | 15 |

---

## Project Structure

```
Openloop_cali/
├── run_analysis.m              # Unified entry point
├── configs/                    # Experiment configurations
│   ├── default_config.m        #   Shared defaults (~92 lines)
│   ├── build_data_files.m      #   Auto-generate .dat filenames
│   ├── Hung_config.m           #   Per-experiment overrides (~15 lines each)
│   ├── Hung_no_washer_config.m
│   ├── Hung_spring_washer_config.m
│   ├── Hung_single_yoke_config.m
│   ├── NTU_config.m
│   ├── NTU_t_config.m / NTU_s_config.m
│   ├── Hung_pair_2_config.m / Hung_pair_3_config.m
│   ├── NTU_pair_2_config.m / NTU_pair_3_config.m
│   ├── Sweep_config.m          #   UI frequency sweep template (15 points)
│   └── config_template.m       #   Template for new experiments
├── pipeline/                   # Processing steps
│   ├── step_read.m             #   Read .dat + DAC conversion + sanity check
│   ├── step_steady_state.m     #   Steady-state detection
│   ├── step_fft.m              #   FFT + THD + CSV output
│   ├── step_fit.m              #   Phase offset removal + curve fitting
│   ├── step_plot.m             #   Bode plots + Dashboard
│   └── step_compare.m          #   Multi-experiment comparison plots
├── functions/                  # Core algorithms (6 active)
│   ├── read_hsdata.m           #   Binary reader (V1-V8, vectorized fread)
│   ├── repair_bad_points.m     #   Bad point interpolation
│   ├── detect_steady_state_relative.m
│   ├── compute_super_period.m  #   Super-period calculation
│   ├── fit_single_tf.m         #   Weighted least squares fitting
│   └── get_experiment_colors.m #   Fixed color scheme
├── data/                       # Raw binary data (.dat, gitignored)
│   ├── Hung/single_raw_data/
│   ├── Hung_no_washer/single_raw_data/
│   ├── Hung_spring_washer/single_raw_data/
│   ├── NTU/single_raw_data/
│   ├── NTU_ts/single_raw_data/
│   ├── Hung_pair/pair_raw_data/
│   ├── NTU_pair/pair_raw_data/
│   └── Hung_single_yoke/single_yoke_raw_data/
├── results/                    # Output (mostly gitignored)
│   ├── <experiment>/diagnostics/  # Raw_Bode_Data.csv, Dashboard
│   ├── <experiment>/figures/      # Bode plots (Fitted/Residuals/DataOnly)
│   ├── <experiment>/fitting_results/  # fit_results.mat
│   └── <Tag>/Comparison_*.png     # Comparison plots
└── legacy/                     # Old scripts (v2.0 architecture)
    ├── Model_6_6_Continuous_Weighted.m  # MIMO 6x6 fitting
    ├── P1.m ~ P6.m                      # 6x6 frequency response data
    └── functions/                       # 12 unused functions
```

---

## Prerequisites

| Software | Version | Required |
|----------|---------|----------|
| **MATLAB** | R2020a+ | Yes |
| Control System Toolbox | - | For `c2d`, `tf` functions (fitting only) |

---

## Quick Start

```matlab
% Navigate to project directory
cd 'path/to/Openloop_cali'

% Full pipeline: read → steady-state → FFT → fit → plot + dashboard
run_analysis('Hung', 'all');

% FFT only (produces CSV, no fitting)
run_analysis('Hung', 'fft');

% Fit from existing CSV (no .dat needed)
run_analysis('Hung', 'fit');

% Override fitting parameters
run_analysis('Hung', 'fit', 'wc_Hz', 1);

% Multi-experiment Bode comparison
run_analysis({'Hung', 'Hung_no_washer', 'NTU'}, 'compare');

% Normalized comparison (each experiment normalized by its own H(0.1Hz))
run_analysis({'Hung', 'Hung_no_washer', 'NTU'}, 'compare', 'Normalize', true);
```

### Pipeline Steps

| Step | Input | Output | Description |
|------|-------|--------|-------------|
| `'all'` | .dat files | CSV + .mat + PNG + Dashboard | Full pipeline |
| `'read'` | .dat files | struct array | Read & validate only |
| `'fft'` | .dat files | Raw_Bode_Data.csv | Read &rarr; steady-state &rarr; FFT |
| `'fit'` | CSV | fit_results.mat + Bode PNGs + Dashboard | Fitting + plots |
| `'plot'` | .mat or CSV | Bode PNGs + Dashboard | Plot only |
| `'compare'` | CSV or .dat | Comparison_*.png | Multi-experiment comparison |

### Comparison Types

```matlab
% Bode magnitude + phase (default)
run_analysis({'Hung','NTU'}, 'compare');

% Vm frequency spectrum
run_analysis({'Hung','NTU'}, 'compare', 'Type', 'spectrum', 'Frequencies', [1,10,100]);

% Lissajous (Vm vs Current)
run_analysis({'Hung','NTU'}, 'compare', 'Type', 'lissajous', 'Frequencies', [1,10,100]);

% Channel ratio
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ratio');

% All comparison types at once
run_analysis({'Hung','NTU'}, 'compare', 'Type', 'all', 'Frequencies', [1,10,100]);
```

---

## Data Setup

### Option 1: Download Pre-recorded Data

<!-- TODO: Add cloud storage link when available -->
Download the data archive and extract it into the `data/` directory.

### Option 2: Record Your Own Data

Use the experiment UI to record `.dat` files at each frequency point. Place them in the appropriate folder:

```
data/<experiment_name>/single_raw_data/<prefix>_<freq>hz.dat
```

**Naming convention:** `<prefix>_0.1hz.dat`, `<prefix>_1hz.dat`, ..., `<prefix>_2000hz.dat`

The prefix is defined in each experiment's config file (e.g., `Hung_single` for Hung).

### Data Format

- Binary HSData format (V1-V8), read by `read_hsdata.m`
- Sampling rate: 20,000 Hz
- DAC: 16-bit (0-65535), zero = 32768, range = 20V

---

## Configuration Guide

### Default Configuration (`configs/default_config.m`)

Contains all shared parameters (~92 lines): DAC conversion, steady-state detection, FFT settings, fitting parameters, plot style, etc.

### Per-Experiment Override

Each experiment config inherits from `default_config` and overrides only the differences:

```matlab
function config = Hung_config()
    config = default_config();
    config.experiment_name = 'Hung';
    config.data_prefix = 'Hung_single';
    config.data_folder = fullfile(config.project_root, 'data', 'Hung', 'single_raw_data');
    config.output_folder = fullfile(config.project_root, 'results', 'Hung');
    config.data_files = build_data_files(config.data_prefix, config.expected_frequencies);
    config.fitting.exclude_frequencies = [0.1, 900];
end
```

### Adding a New Experiment

1. Copy `configs/config_template.m` &rarr; `configs/<name>_config.m`
2. Set `experiment_name`, `data_prefix`, `data_folder`, `output_folder`
3. Call `build_data_files()` to auto-generate filenames
4. Set `exclude_frequencies` if needed
5. Place `.dat` files in `data/<name>/single_raw_data/`
6. Add color entry to `functions/get_experiment_colors.m`
7. Run `run_analysis('<name>', 'all')` to verify

---

## Function Reference

### Active Functions (`functions/`)

| Function | Purpose |
|----------|---------|
| `read_hsdata(filepath)` | Read binary .dat file (V1-V8, vectorized fread) |
| `repair_bad_points(Vm, da, ...)` | Fix bad data points (100kHz data only) |
| `detect_steady_state_relative(vm, freq, fs, ...)` | Locate steady-state region |
| `compute_super_period(freq, fs)` | Compute super-period for FFT truncation |
| `fit_single_tf(h, phi, w, ...)` | Single-curve weighted least squares fitting |
| `get_experiment_colors()` | Fixed color scheme for all experiments |

### Legacy Functions (`legacy/functions/`)

12 functions from v2.0 architecture, no longer called by the pipeline.

---

## Output Files

### Per-Experiment Results (`results/<name>/`)

```
results/<name>/
├── diagnostics/
│   ├── Raw_Bode_Data.csv          # FFT results (version-controlled)
│   └── Dashboard_<name>.png       # Overview dashboard
├── figures/
│   ├── Bode_<name>_Fitted.png     # Model + Data Bode plot
│   ├── Bode_<name>_Residuals.png  # Fitting residuals
│   └── Bode_<name>_DataOnly.png   # Data-only Bode plot
└── fitting_results/
    └── fit_results.mat            # Fitting parameters
```

### Comparison Results (`results/` or `results/<Tag>/`)

```
results/Comparison_Bode.png                    # Default (no Tag)
results/Hung_pair/Comparison_Bode.png          # Tag='Hung_pair'
results/NTU_yoke/Comparison_Bode.png           # Tag='NTU_yoke'
```

### CSV Format (`Raw_Bode_Data.csv`)

```
Frequency_Hz | Magnitude_Linear | Magnitude_dB | Phase_deg | THD_percent
```

---

## Legacy Scripts

The `legacy/` directory contains the old v2.0 architecture:

- `Model_6_6_Continuous_Weighted.m` &mdash; MIMO 6&times;6 transfer function fitting (self-contained, uses `P1.m`~`P6.m` via `eval`)
- `P1.m` ~ `P6.m` &mdash; 6-channel frequency response data
- `legacy/functions/` &mdash; 12 functions superseded by the pipeline

To run the legacy MIMO fitting:
```matlab
cd legacy
Model_6_6_Continuous_Weighted
```

---

**Last Updated:** 2026-02-13
**Version:** 3.0
