# TODO List for Model_6_6_Continuous_Weighted.m

**Generated:** 2025-10-07
**Project:** MIMO Transfer Function Fitting - Openloop Calibration

---

## Overview

This document contains implementation tasks for improving the `Model_6_6_Continuous_Weighted.m` script. Tasks include terminology updates, visualization enhancements, terminal output improvements, and a new comparison feature between single curve and multi-curve fitting results.

---

## Task List

### Group 1: Terminology Updates

#### [ ] Task 1: Replace 'DISCRETIZATION' terminology in main code
**File:** `Model_6_6_Continuous_Weighted.m`
**Location:** Line 407 (Section 6 header)

**Action:**
- Change `DISCRETIZATION` to `CONTINUOUS-TO-DISCRETE CONVERSION`
- This reflects that ZOH method provides exact transformation, not approximation

**Reason:**
- Professor's feedback: "DISCRETIZATION" implies approximation
- ZOH provides mathematically exact conversion at sampling instants

---

#### [ ] Task 2: Update all related comments and documentation
**File:** `Model_6_6_Continuous_Weighted.m`

**Action:**
- Search for all occurrences of "discretization", "discrete", "discretize" in comments
- Update to use "continuous-to-discrete conversion" or "discrete-time equivalent" terminology
- Key locations:
  - Line 1: File header comment
  - Line 5: Purpose description
  - Line 17: Output description
  - Line 56: Parameter section comment
  - Line 419: Section 6 description

**Examples:**
- "perform Zero-Order Hold (ZOH) discretization" → "perform ZOH continuous-to-discrete conversion"
- "Discrete transfer function" → "Discrete-time equivalent transfer function"

---

#### [ ] Task 3: Update Chinese and English README files
**Files:** All README files in the project

**Action:**
- Update terminology to match the code changes
- Ensure consistency between Chinese and English versions
- Key terms to update:
  - 離散化 → 連續時間轉離散時間
  - Discretization → Continuous-to-discrete conversion

---

### Group 2: Visualization Improvements

#### [ ] Task 4: Optimize Single Parameter Mode legend
**Location:** Lines 699-750 (Single Curve Bode Plot - Single Parameter Mode)

**Requirements:**
1. **Legend position:** 'southwest' for both magnitude and phase plots
2. **Legend order:** 'Model' on top, then channel curves
3. **Channel naming:** Change from `'Ch%d'` to `'P%d (H(0)=%.4f)'`
   - Format: `P4 (H(0)=0.2322)` where H(0) is the DC gain (b/a2)
4. **Font size:** Adjust to maximum size without overlapping data curves

**Implementation notes:**
- DC gain = `b / a2`
- Use `'southwest'` for legend location
- Legend should show: `['Model', 'P4 (H(0)=0.2322)']`

---

#### [ ] Task 5: Optimize Multiple Curve legend
**Location:** Lines 754-841 (Multiple Curve Bode Plot)

**Requirements:**
1. **Legend position:** 'southwest' for both magnitude and phase plots
2. **Legend order:** 'Model' on top, then channel curves
3. **Channel naming:** Change from `'Channel %d'` to `'P%d (B%d%d=%.4f)'`
   - Format: `P1 (B41=0.3618)` where B41 is the B matrix element
   - Subscripts: first digit = output channel, second digit = excitation channel
4. **Font size:** Adjust to maximum size without overlapping data curves

**Implementation notes:**
- For excitation channel `j`, output channel `i`: use `B(i,j)` value
- Example: If excited_ch=1, ch=4, display `'P4 (B41=0.3618)'`
- Use `'southwest'` for legend location

---

### Group 3: Terminal Output Enhancements

#### [ ] Task 6: Enhance Single Curve Fitting terminal output
**Location:** Lines 230-234 (SECTION 4 output)

**Current output:**
```
=== Single Curve Fitting ===
w(ω)=1/(1+(ω²/ωc²))^p, ωc=62.83 rad/s (10.00 Hz), p=0.5
a1=13386.515057, a2=26781953.243187, b=6218661.612646
```

**New output format:**
```
=== Single Curve Fitting ===
w(ω)=1/(1+(ω²/ωc²))^p, ωc=62.83 rad/s (10.00 Hz), p=0.5
H(s) = [2.6782e+07/(s² + 1.3387e+04·s + 2.6782e+07)]
b/a2 = 0.2322 (DC gain)
a1=13386.515057, a2=26781953.243187, b=6218661.612646
```

**Requirements:**
1. Add normalized transfer function display using scientific notation (similar to Multi Curve format)
2. Display DC gain: `b/a2 = [value] (DC gain)`
3. Keep original full-precision a1, a2, b values

---

#### [ ] Task 7: Enhance Multiple Curve Fitting terminal output
**Location:** Line 405 (SECTION 5 output)

**Current output:**
```
H(s) = [2.6782e+07/(s² + 1.3387e+04·s + 2.6782e+07)] · B
```

**New output format:**
```
H(s) = [2.6782e+07/(s² + 1.3387e+04·s + 2.6782e+07)] · B
A1=13386.515057, A2=26781953.243187
```

**Requirements:**
1. Add full-precision A1, A2 values after the normalized transfer function
2. Keep the existing scientific notation format

---

### Group 4: New Comparison Feature (SECTION 9)

#### [ ] Task 8: Add control switch in SECTION 1
**Location:** SECTION 1 (Configuration, after line 72)

**Action:**
Add the following configuration parameter:
```matlab
% --- One Curve vs Multi Curve Comparison Control ---
ENABLE_ONE_MULTI_COMPARISON = true;   % Enable comparison between one curve and multi curve fitting
ONE_MULTI_COMPARISON_CHANNELS = [1];  % Excitation channels to plot individually (for grouped Bode plots)
```

**Dependencies:**
- Requires `SAVE_ONE_CURVE_RESULTS = true`
- Will load data from `ONE_CURVE_OUTPUT_FILE`

---

#### [ ] Task 9: Implement static gain heatmap comparison
**Location:** New SECTION 9 (after SECTION 8)

**Purpose:** Compare DC gains between One Curve and Multi Curve fitting methods

**Implementation:**
1. **Load One Curve results:**
   ```matlab
   load(ONE_CURVE_OUTPUT_FILE, 'one_curve_results');
   DC_gain_one = one_curve_results.b_matrix ./ one_curve_results.a2_matrix;  % 6×6
   ```

2. **Multi Curve DC gain:**
   ```matlab
   DC_gain_multi = B;  % 6×6 (already in b/a2 form)
   ```

3. **Create 3 heatmaps side by side:**
   - Left: One Curve DC gains
   - Middle: Multi Curve DC gains
   - Right: Absolute difference or percentage error

4. **Heatmap specifications:**
   - Use `imagesc` or `heatmap`
   - Add colorbar
   - Annotate each cell with numerical values
   - Label axes: "Output Channel" (y), "Input Channel" (x)
   - Titles: "One Curve (b/a2)", "Multi Curve (B)", "Difference"

---

#### [ ] Task 10: Implement grouped Bode plot comparison (by excitation channel)
**Location:** SECTION 9

**Purpose:** Compare normalized transfer functions for each excitation channel

**Implementation:**
1. **Generate 6 figures** (one per excitation channel P1~P6)

2. **For each excitation channel j:**
   - Loop through 6 output channels (i = 1:6)
   - Extract One Curve TF: `H_one(i,j) = b(i,j) / (s² + a1(i,j)·s + a2(i,j))`
   - Normalize One Curve by DC gain: `H_one_norm = H_one / (b/a2)`
   - Extract Multi Curve TF: `H_multi = A2 / (s² + A1·s + A2)` (same for all channels)
   - Normalize Multi Curve by B matrix: `H_multi_norm = H_multi / B(i,j)`

3. **Plotting style:**
   - **6 gray lines** (One Curve, one per output channel):
     - Color: `[0.7, 0.7, 0.7]`
     - LineWidth: 1.5
     - No markers
   - **1 black line** (Multi Curve, shared for all channels):
     - Color: `'k'`
     - LineWidth: 3
   - **NO LEGEND**

4. **Plot layout:**
   - Subplot(2,1,1): Magnitude (dB)
   - Subplot(2,1,2): Phase (deg)
   - Title: `'P%d Excitation: One Curve (gray) vs Multi Curve (black)'`
   - Use same axis properties as existing Bode plots (log scale, etc.)

---

#### [ ] Task 11: Implement full 36-curve Bode plot comparison
**Location:** SECTION 9

**Purpose:** Show all 36 transfer functions on a single plot

**Implementation:**
1. **Single figure with all 36 curves**

2. **For all channel pairs (i,j):**
   - Extract and normalize One Curve TFs (same as Task 10)
   - 36 gray lines total

3. **Multi Curve:**
   - Single black line (normalized, represents the common dynamics)

4. **Plotting style:**
   - **36 gray lines:**
     - Color: `[0.7, 0.7, 0.7]`
     - LineWidth: 1.0 (thinner to avoid clutter)
   - **1 black line:**
     - Color: `'k'`
     - LineWidth: 3
   - **NO LEGEND**

5. **Plot layout:**
   - Subplot(2,1,1): Magnitude (dB)
   - Subplot(2,1,2): Phase (deg)
   - Title: `'All 36 Channels: One Curve (gray) vs Multi Curve (black)'`

---

## Implementation Priority

**Suggested order:**
1. Group 3 (Terminal outputs) - Quick wins, improve user experience
2. Group 2 (Visualization) - Enhance existing plots
3. Group 1 (Terminology) - Documentation updates
4. Group 4 (New feature) - Major addition, implement last

---

## Notes for Implementation

### General Guidelines:
- Test each change incrementally
- Verify plots are not cluttered after legend changes
- Ensure backward compatibility with existing configuration options
- Add appropriate comments for new code sections

### Data Dependencies:
- SECTION 9 requires `one_curve_36_results.mat` to exist
- Check file existence before loading:
  ```matlab
  if ~exist(ONE_CURVE_OUTPUT_FILE, 'file')
      warning('One curve results not found. Run with SAVE_ONE_CURVE_RESULTS=true first.');
      return;
  end
  ```

### Frequency Response Calculation:
- Use consistent frequency vector: `freq_smooth = logspace(log10(min(W)), log10(max(W)), 200)`
- Convert to rad/s: `s_smooth = 1j * 2 * pi * freq_smooth`

### Normalization:
- **One Curve:** Normalize each TF by its own DC gain `b(i,j)/a2(i,j)`
- **Multi Curve:** Normalize by corresponding B matrix element `B(i,j)`
- After normalization, all curves should start at 0 dB at low frequencies

---

## Testing Checklist

After implementation, verify:
- [ ] All plots render without errors
- [ ] Legends are positioned correctly and don't overlap data
- [ ] Terminal output shows all required information
- [ ] SECTION 9 handles missing data gracefully
- [ ] All terminology is updated consistently
- [ ] README files match code documentation

---

## Contact & References

**Related Files:**
- Main script: `Model_6_6_Continuous_Weighted.m`
- Data files: `P1.m` ~ `P6.m`
- Output: `one_curve_36_results.mat`, `transfer_function_latex.txt`

**Key Concepts:**
- ZOH (Zero-Order Hold): Exact continuous-to-discrete conversion method
- DC gain: H(s=0) = b/a2 for second-order system
- Normalization: Remove DC gain to compare dynamic response only

---

**End of TODO List**
