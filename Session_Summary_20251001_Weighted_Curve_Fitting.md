# Session Summary: Weighted Curve Fitting Implementation
**Date**: 2025-10-01
**File Modified**: `Model_6_6_Continuous_Weighted.m`
**Reference Document**: `Multiple_curve_fitting_weighted_MQ.pdf`

---

## 1. Primary Request and Intent

The user requested modifications to `Model_6_6_Continuous_Weighted.m` based on a mathematical derivation PDF:

1. **Add weighting to single curve fitting**: Implement weighted least squares with function w(ω) = 1/(1+(ω²/ωc²))^p
2. **Replace multiple curve algorithm**: Change from 38×38 matrix to 2×2 block matrix algorithm (PDF page 3)
3. **Parameter control**: All adjustable parameters (p, wc_Hz) at top of file in Hz units
4. **Parameter comparison feature**: Enable comparing multiple parameter sets on same Bode plot
5. **Plotting requirements**:
   - Use log scale for frequency axis
   - Match plotting style from `Model_6_6_Continuous.m`
   - Add -3 dB reference line
   - Add weighting info to plot titles
   - Use raw (non-normalized) data for parameter comparison
   - Use normalized data for single parameter mode

---

## 2. Key Technical Concepts

- **Weighted Least Squares**: Frequency-dependent weighting w(ω) = 1/(1+(ω²/ωc²))^p
- **Low-pass filter weighting**: Higher weights at low frequencies (< wc), lower at high frequencies
- **2×2 Block Matrix Algorithm**: More efficient than 38×38 matrix, better numerical stability
- **DC Gain Normalization**: H(s=0) = b/a2 for transfer function H(s) = b/(s²+a1·s+a2)
- **Transfer Function Matrix**: G(s) = (A2/(s²+A1·s+A2)) * B where B is 6×6 matrix
- **Vector definitions**: v₁, v₂, yb are 36×1 vectors corresponding to indices 3-38 in block matrix

---

## 3. Files and Code Sections

### `Model_6_6_Continuous_Weighted.m` (Main file modified)

#### **Lines 7-36: Parameter Control Section**
```matlab
%% ========== CURVE FITTING PARAMETERS ==========
% Single curve fitting - Parameter Comparison
ENABLE_PARAM_COMPARISON = false;  % true: compare multiple parameters, false: single parameter

% If ENABLE_PARAM_COMPARISON = false, use these parameters:
p_single = 1;                 % Weighting exponent (0.5 or 1)
wc_single_Hz = 5;             % Cutoff frequency (Hz) for low-pass weighting

% If ENABLE_PARAM_COMPARISON = true, define parameter sets to compare:
% Each row: [p, wc_Hz]
param_sets_single = [
    0.5, 1000;   % Almost no weighting (baseline)
    1.0, 10;     % Strong low-freq weighting, wc=10 Hz
    1.0, 5;      % Strong low-freq weighting, wc=5 Hz
    0.5, 5;      % Moderate weighting, wc=5 Hz
];

excited_channel = 5;
channel = 5;

% Multiple curve fitting weighting
p_multi = 1;
wc_multi_Hz = 5;

% Plot control switches
PLOT_ONE_CURVE = false;
PLOT_MULTI_CURVE = true;
```
**Importance**: Centralized parameter control, Hz units auto-converted to rad/s

---

#### **Lines 90-185: Single Curve Fitting Logic**
```matlab
if ENABLE_PARAM_COMPARISON
    % === Compare multiple parameter sets ===
    num_params = size(param_sets_single, 1);

    a1_all = zeros(num_params, 1);
    a2_all = zeros(num_params, 1);
    b_all = zeros(num_params, 1);
    H_fitted_all = cell(num_params, 1);

    for idx = 1:num_params
        p_test = param_sets_single(idx, 1);
        wc_test_Hz = param_sets_single(idx, 2);
        wc_test = wc_test_Hz * 2 * pi;

        weight_k = 1 ./ (1 + (w_k.^2 / wc_test^2)).^p_test;

        % Build weighted matrices and solve
        % ... [matrix building code]

        H_fitted_all{idx} = b_all(idx) ./ (s.^2 + a1_all(idx)*s + a2_all(idx));
    end
else
    % === Single parameter fitting ===
    wc_single = wc_single_Hz * 2 * pi;
    weight_k = 1 ./ (1 + (w_k.^2 / wc_single^2)).^p_single;
    % ... [standard fitting]
end
```
**Importance**: Supports both comparison mode and single parameter mode

---

#### **Lines 187-300: Multiple Curve Fitting - 2×2 Block Matrix**
```matlab
% === Build 2x2 block matrix (PDF Page 3) ===
A_2x2 = [
    a11 - (1/n)*v1'*v1,     -(1/n)*v1'*v2;
    -(1/n)*v2'*v1,          a22 - (1/n)*v2'*v2
];

Y_2x2 = [
    y1 - (1/n)*v1'*yb;
    y2 - (1/n)*v2'*yb
];

% Check matrix condition (optional)
if cond(A_2x2) > 1e12
    warning('Matrix may be ill-conditioned (cond=%.2e)', cond(A_2x2));
end

% === Solve for a1, a2 ===
X_2x2 = A_2x2 \ Y_2x2;
A1 = X_2x2(1);
A2 = X_2x2(2);

% === Solve for b vector and B matrix ===
b_vec = (1/n) * (yb - A1*v1 - A2*v2);  % 36x1
```
**Importance**: Complete replacement of 38×38 algorithm with efficient 2×2 block matrix

---

#### **Lines 316-384: Parameter Comparison Plotting (No Normalization)**
```matlab
if ENABLE_PARAM_COMPARISON
    % Raw measured data (dB)
    h_db_raw = 20*log10(h_k);

    % Plot measured data
    semilogx(W, h_db_raw, 'ko', 'MarkerSize', 12, 'LineWidth', 2, ...
        'MarkerFaceColor', 'w', 'DisplayName', 'Measured');

    % Plot each parameter's model
    colors = {[1 0 0], [0 0.7 0], [0 0 1], [1 0 1]};
    line_styles = {'-', '--', '-.', ':'};

    for idx = 1:num_params
        H_model_smooth = b_all(idx) ./ (s_smooth.^2 + a1_all(idx)*s_smooth + a2_all(idx));
        H_model_db = 20*log10(abs(H_model_smooth));

        semilogx(freq_smooth, H_model_db, ...
            'Color', colors{idx}, 'LineStyle', line_styles{idx}, 'LineWidth', 2.5, ...
            'DisplayName', sprintf('p=%.1f,ωc=%g', param_sets_single(idx,:)));
    end
```
**Importance**: Overlays multiple parameter results using raw magnitude (no normalization)

---

#### **Lines 386-438: Single Parameter Plotting (Normalized)**
```matlab
else
    % Normalize by DC gain (H(s=0) = b/a2)
    dc_gain = b / a2;
    h_k_norm = h_k / dc_gain;
    h_db_norm = 20*log10(h_k_norm);

    H_model_smooth = b ./ (s_smooth.^2 + a1*s_smooth + a2);
    H_model_norm = H_model_smooth / dc_gain;
    semilogx(freq_smooth, 20*log10(abs(H_model_norm)), 'k-', 'LineWidth', 3, ...);
```
**Importance**: Uses DC gain normalization for single parameter visualization

---

### `Multiple_curve_fitting_weighted_MQ.pdf` (Reference document)
- Provided mathematical derivation for weighted least squares
- Showed 2×2 block matrix algorithm on page 3
- Had typo (second v₁ᵀ should be v₂ᵀ) that user corrected

---

## 4. Errors and Fixes

### Error 1: Weighting function formula error
- **Initial**: w(ω) = 1/(1+(ω²/ω₂)²)^p
- **User correction**: w(ω) = 1/(1+(ω²/ωc²))^p
- **Fix**: Updated all weighting function calculations

### Error 2: DC gain calculation error
- **Initial**: Used `b` directly for normalization
- **User correction**: DC gain = b/a2 (from H(s=0))
- **Fix**: Changed to `dc_gain = b / a2` (line 390)

### Error 3: Normalization strategy confusion
- **Initial plan**: Use unified or individual DC gains for comparison
- **User feedback**: "不對如果是這樣的情況就可以完全不用作正規劃了，直接不做正規畫"
- **Fix**: Comparison mode uses raw magnitude, single mode uses normalized

### Error 4: String replacement error in Edit tool
- **Error**: "String to replace not found in file"
- **Cause**: File content had been modified by user between reads
- **Fix**: Re-read file to get current content before editing

---

## 5. Problem Solving Summary

### ✅ Solved Problems
1. Implemented weighted least squares for single curve with correct formula
2. Replaced 38×38 matrix algorithm with 2×2 block matrix (more efficient)
3. Unified parameter control at top of file with Hz units
4. Added parameter comparison feature to overlay multiple parameter sets
5. Matched plotting style from Model_6_6_Continuous.m
6. Implemented appropriate normalization strategies for different modes
7. Added numerical stability check with simplified warning

### Design Decisions
- Parameter comparison uses 4 sets by default (limited by colors/line styles)
- Comparison mode: no normalization (raw data)
- Single mode: normalized by DC gain (b/a2)
- Y-axis: fixed max 5 dB, auto min (min-5 dB)
- Removed -3 dB line from comparison mode (only in single mode)
- Console outputs fitting parameters for each parameter set

---

## 6. Chronological User Messages

1. "你針對這個數學推倒 跟我說你預計要怎麼改Model_6_6_Continuous_Weighted.m..." - Initial request to modify file based on PDF
2. "我有發現最後一頁中定義的V1'重複定義了..." - Corrected PDF typo and weighting formula
3. "Q1 這個方案可以，Q2方案B..." - Confirmed Hz units and numerical check strategy
4. "可以開始實做了，記得註解等等都先用淺顯簡單的英文標示" - Started implementation
5. "多條curve 的頻率軸要用指數類型的" - Requested log scale for frequency axis
6. "你針對這個數學推倒 跟我說你預計要怎麼改Model_6_6_Continuous_Weighted.m" (repeated)
7. Multiple curve plotting style request: "@Openloop_Cali/Model_6_6_Continuous.m 多條curve的對比這個檔案中的繪圖風格照搬過來用"
8. "沒錯!就是這個意思" - Confirmed normalization by DC gain for single curve
9. "幫我刪除USE_WEIGHTED_SINGLE的功能..." - Requested parameter comparison feature
10. "方法一 感覺比較好，你會怎麼建構這部分的程式碼..." - Chose overlay comparison approach
11. "沒錯!就是這個意思" - Confirmed understanding of normalization
12. "不對如果是這樣的情況就可以完全不用作正規劃了..." - Decided no normalization for comparison
13. "可以開始操作了" (multiple times) - Confirmed to proceed with implementation
14. "我最多可以放幾組參數?" - Asked about parameter limit

---

## 7. Current Status and Pending Tasks

### Current Parameter Limit
**Line 331-332**:
```matlab
colors = {[1 0 0], [0 0.7 0], [0 0 1], [1 0 1]};  % 4 colors
line_styles = {'-', '--', '-.', ':'};              % 4 line styles
```

**Current limit**: 4 parameter sets
**Reason**: Color and line style array definitions

### Recommendations for Extension
- **Optimal**: 2-4 parameter sets (best visual clarity)
- **Acceptable**: 5-6 parameter sets
- **Not recommended**: >8 parameter sets (plot becomes cluttered)

### Options to Extend Support
1. **Add more colors to the array** (recommend 6-8)
2. **Use auto-cycling with modulo operations**
3. **Use MATLAB colormap for unlimited sets**

### Pending Decision
- User needs to confirm:
  1. How many parameter sets they typically need to compare
  2. Whether they want the color/line style arrays extended (and to what limit)

---

## 8. Key Mathematical Formulas

### Weighting Function
```
w(ω) = 1 / (1 + (ω²/ωc²))^p
```
- **p**: Weighting exponent (typical: 0.5 or 1)
- **ωc**: Cutoff frequency (rad/s)
- **Effect**: Low-pass filter characteristic (emphasizes low frequencies)

### Transfer Function (Single Curve)
```
H(s) = b / (s² + a1·s + a2)
```
- **DC Gain**: H(s=0) = b/a2

### Transfer Function Matrix (Multiple Curves)
```
G(s) = (A2 / (s² + A1·s + A2)) * B
```
- **A1, A2**: Common denominator coefficients (scalars)
- **B**: 6×6 numerator coefficient matrix

### 2×2 Block Matrix System
```
[a11 - (1/n)v₁ᵀv₁    -(1/n)v₁ᵀv₂  ] [A1]   [y1 - (1/n)v₁ᵀyb]
[-(1/n)v₂ᵀv₁         a22 - (1/n)v₂ᵀv₂] [A2] = [y2 - (1/n)v₂ᵀyb]
```
- **v₁, v₂, yb**: 36×1 vectors (indices 3-38 in original formulation)
- **n**: Number of frequency points (36)

---

## 9. File Structure Reference

```
Openloop_Cali/
├── Model_6_6_Continuous_Weighted.m  (Modified file)
├── Model_6_6_Continuous.m           (Reference for plotting style)
├── Multiple_curve_fitting_weighted_MQ.pdf  (Math derivation reference)
└── Session_Summary_20251001_Weighted_Curve_Fitting.md  (This file)
```

---

## 10. Usage Instructions

### Single Parameter Mode
1. Set `ENABLE_PARAM_COMPARISON = false`
2. Adjust `p_single` and `wc_single_Hz` at top of file
3. Run script
4. Result: Normalized Bode plot with DC gain = 0 dB

### Parameter Comparison Mode
1. Set `ENABLE_PARAM_COMPARISON = true`
2. Edit `param_sets_single` matrix (max 4 rows currently)
3. Each row format: `[p, wc_Hz]`
4. Run script
5. Result: Raw Bode plot overlaying all parameter sets

### Multiple Curve Fitting
1. Adjust `p_multi` and `wc_multi_Hz` at top of file
2. Set `PLOT_MULTI_CURVE = true`
3. Run script
4. Result: 6×6 transfer function matrix fitted using 2×2 block algorithm

---

## End of Session Summary
