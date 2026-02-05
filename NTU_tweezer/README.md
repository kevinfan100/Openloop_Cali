# NTU_tweezer One-Curve Fitting Analysis

## Overview

This directory implements **one-curve fitting** (二階系統鑑別) for the NTU_tweezer dataset, performing open-loop system identification of the transfer function **H(jω) = VM2(jω) / DA2(jω)** using channel 2 excitation data.

## Implementation Status

✅ **COMPLETED** - Full pipeline implemented and tested successfully.

## System Identification

**Transfer Function Model:**
```
H(s) = b / (s² + a1·s + a2)
```

**Fitted Results:**
- Results will be generated after running the analysis pipeline
- Transfer function parameters: a1, a2, b
- DC gain, natural frequency, damping ratio
- Pole locations and stability analysis
- R² fitting quality metric

## Files Structure

```
NTU_tweezer/
├── NTU_config.m                 ✅ Configuration file
├── diagnose_NTU_data_summary.m  ✅ Data quality diagnostic script
├── fit_NTU_bode.m               ✅ Transfer function fitting script
├── README.md                    ✅ This file
│
├── single_raw_data/             ✅ 19 frequency point data files
│   ├── NTU_single_0.1hz.dat
│   ├── NTU_single_1hz.dat
│   └── ... (17 more files)
│
└── results/                     ⚙️ Auto-generated outputs
    ├── diagnostics/
    │   ├── Dashboard_Summary.png  - Quality overview
    │   └── Bode_Summary.csv       - Frequency response data
    └── figures/
        ├── Bode_NTU_Model66_style.png - Bode diagram (model + measured)
        └── Bode_NTU_DataOnly.png      - Bode diagram (measured only)
```

## Quick Start

### Stage 1: Data Quality Diagnostic

```matlab
% Navigate to NTU_tweezer directory
cd C:\Users\PME406_01\Desktop\Openloop_cali\Openloop_cali\NTU_tweezer

% Run diagnostic to validate data quality
diagnose_NTU_data_summary
```

**Expected Output:**
- `results/diagnostics/Dashboard_Summary.png` - THD distribution and quality metrics
- `results/diagnostics/Bode_Summary.csv` - Frequency response data for 17-19 points

### Stage 2: Transfer Function Fitting

```matlab
% Run transfer function fitting with Bode plots
fit_NTU_bode
```

**Expected Output:**
- Console: Fitted transfer function parameters, poles, R² quality metric
- Interactive Figure: Two-tab Bode plot (Model+Measured, Data-only)
- Auto-saved: `results/figures/Bode_NTU_DataOnly.png`

## Key Features

### Tab-Based Bode Visualization
- **Tab 1: Model + Measured** - Black model curve + blue measured data points
- **Tab 2: Measured Data Only** - Pure experimental data (auto-saved as PNG)
- Phase range: [-180, 0] deg
- X-axis: Logarithmic from 0.1 Hz to 2000 Hz

### DAC to Voltage Conversion
Critical formula (ref: `openloop_bode.m` Line 118-119):
```matlab
da_volt = (da - 32768) * (20.0 / 65536)
```
- Ensures correct transfer function units: **[V/V]** (not [V/counts])
- Zero offset: 32768 (0V)
- Voltage range: ±10V (20V peak-to-peak)

### Integer Period Handling
- Sampling rate: **20 kHz** (not 100kHz, no bad point issues)
- Period samples: `round(fs / freq)` to minimize spectral leakage
- FFT uses integer multiples of periods

### Phase Normalization
- Removes phase offset at lowest frequency (0.1 Hz)
- Ensures consistent phase reference across all frequencies

## Data Specifications

| Parameter | Value |
|-----------|-------|
| **Frequency Points** | 19 (0.1, 1, 10, 50, 100, ..., 2000 Hz) |
| **Sampling Rate** | 20 kHz |
| **Excitation Channel** | Channel 2 |
| **Excitation Amplitude** | 2.0 V |
| **Loop Mode** | Open-loop (loop_mode=1) |
| **Data Format** | V8 HSData (168-byte header, 124 bytes/record) |

## Configuration

Edit `NTU_config.m` to customize:

```matlab
% Steady-state detection
config.steady_state.threshold = 2e-3;        % V
config.steady_state.consecutive_periods = 3;
config.steady_state.min_periods_for_fft = 2;

% Fitting parameters
config.fitting.p_weight = 0.5;               % Weighting exponent
config.fitting.wc_Hz = 100;                  % Cutoff frequency [Hz]

% Output options
config.output.save_bode_data = true;
config.output.save_fitting_results = true;
config.output.save_figures = true;
config.output.figure_format = 'png';
config.output.figure_dpi = 300;
```

## Results Interpretation

### Data Quality Grades
- **Grade A**: Average THD < 1%, Max THD < 2% (Excellent)
- **Grade B**: Average THD < 3%, Max THD < 5% (Good)
- **Grade C**: Average THD < 5%, Max THD < 10% (Fair)
- **Grade D**: Average THD ≥ 5% or Max THD ≥ 10% (Poor)

### Fitting Quality
- **R² > 0.85**: Excellent fit (second-order model is appropriate)
- **R² = 0.20-0.85**: Moderate fit (higher-order dynamics may exist)
- **R² < 0.20**: Poor fit (check data quality or model assumptions)

### System Characteristics
- **Stable System**: All poles must have negative real parts (left half-plane)
- **Underdamped**: ζ < 1 (complex poles, oscillatory response)
- **Overdamped**: ζ > 1 (real poles, no oscillation)
- **Critically Damped**: ζ = 1 (repeated real poles)

## Validation Checklist

After running the analysis, verify:
- [ ] Dashboard_Summary.png generated
- [ ] Bode_Summary.csv has 17-19 rows, 5 columns
- [ ] Average THD < 10%
- [ ] Console shows "Poles in LHP: PASS"
- [ ] R² > 0.20
- [ ] Interactive figure has two tabs
- [ ] Tab 2 auto-saved as Bode_NTU_DataOnly.png
- [ ] X-axis shows 10^(-1) tick for 0.1 Hz
- [ ] Phase axis range is [-180, 0] deg
- [ ] Title shows ω_c=100.0 Hz (not 0 Hz)

## Dependencies

### Functions from `../functions/`
- `read_hsdata.m` - Read V8 HSData files
- `detect_steady_state_relative.m` - Relative steady-state detection
- `fit_single_tf.m` - Second-order transfer function fitting

### MATLAB Requirements
- MATLAB R2014b+ (for uitabgroup, uitab)
- MATLAB R2020a+ (for exportgraphics)
- Signal Processing Toolbox (FFT, filtering)
- Optimization Toolbox (curve fitting)

## Troubleshooting

### Common Issues

1. **"Steady state not detected"**
   - Increase `RELATIVE_THRESHOLD_PERCENT` from 0.2 to 0.5
   - Reduce `config.steady_state.consecutive_periods`
   - Check if data file is corrupted

2. **Poor R² value (< 0.20)**
   - Check Dashboard_Summary.png for THD distribution
   - Verify phase normalization removed offset correctly
   - Consider excluding high-frequency points with poor THD

3. **Tab 2 not saved automatically**
   - Check MATLAB version (needs R2020a+)
   - Ensure `results/figures/` directory exists
   - Try manually saving: `exportgraphics(tab2, 'output.png')`

4. **0.1 Hz tick not showing on x-axis**
   - Verify `log_ticks = 10.^((-1:ceil(log10(freq_max))))`
   - Check if 0.1 Hz data point was excluded

## Comparison with Hung_tweezer

| Item | Hung_tweezer | NTU_tweezer |
|------|--------------|-------------|
| **Data Source** | Hung_single_*.dat | NTU_single_*.dat |
| **Pipeline** | Identical | Identical |
| **Configuration** | Hung_config.m | NTU_config.m |
| **Scripts** | diagnose_Hung_data_summary.m, fit_Hung_bode.m | diagnose_NTU_data_summary.m, fit_NTU_bode.m |
| **Results Location** | Hung_tweezer/results/ | NTU_tweezer/results/ |

## Future Extensions

- [ ] Multi-curve (MIMO) fitting comparison
- [ ] ZOH discretization to H(z)
- [ ] Additional channel analysis (ch 1, 3-6)
- [ ] SNR/data quality metrics
- [ ] LaTeX report generation
- [ ] Higher-order model fitting

## Data Provenance

**Source:** PT3D UI Project
**Commit:** f3c81cfc877eb419f8e8f849bf30f44f7ebec359
**Date:** 2026-02-05
**Experimenter:** NTU Lab

## References

- Implementation Plan: NTU_tweezer Analysis Pipeline Implementation Plan
- Hung_tweezer: Reference implementation for pipeline structure
- Main Pipeline: `../main_analysis.m` for multi-curve MIMO approach
- DAC Conversion: `../scripts/openloop_bode.m` Line 118-119

---

**Last Updated:** 2026-02-05
**Status:** Production Ready ✅
