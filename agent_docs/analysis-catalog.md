# 分析清單

> 所有分析項目、觸發方式、狀態。

| ID | 分析 | 觸發 | 來源 | 狀態 |
|----|------|------|------|------|
| A1 | Raw Bode (DataOnly) | 固定 | CSV → `Bode_{name}_DataOnly.png` | ✅ step_plot |
| A2 | Model+Data Bode | 固定 | fit_results → `Bode_{name}_Fitted.png` | ✅ step_plot Tab 1 |
| A3 | Fitting Residuals | 固定 | fit_results → `Bode_{name}_Residuals.png` | ✅ step_plot Tab 3 |
| A4 | Dashboard | 固定 | CSV + fit_results → `Dashboard_{name}.png` | ✅ step_plot |
| A5 | Normalized Comparison | 按需 | 多實驗 CSV → `Comparison_Bode.png` | ✅ step_compare (bode) |
| B1 | Vm Spectrum | 可選 | .dat → `Comparison_Vm_Spectrum.png` | ✅ step_compare (spectrum) |
| B2 | Vm Time-Domain | 可選 | 診斷 | 未實作 |
| B3 | Vm P-P vs Freq | 建議固定 | SNR 判斷 | 未實作 |
| C1 | Lissajous | 可選 | .dat → `Comparison_Lissajous.png` | ✅ step_compare (lissajous) |
| C2 | Ratio (通道比值) | 可選 | CSV → `Comparison_Ratio.png` | ✅ step_compare (ratio) |
| C3 | Cross-Channel | 可選 | .dat → `Comparison_CrossChannel.png` | ✅ step_compare (cross_channel) |
| C4 | TS Lissajous (Vm/I) | 可選 | .dat → `Comparison_TS_Lissajous_{freqs}.png` + `_Normalized_{freqs}.png` | ✅ step_compare (ts_lissajous) |
| C5 | TS TimeDomain | 可選 | .dat → `Comparison_TS_TimeDomain_{freqs}.png` | ✅ step_compare (ts_timedomain) |
| D1/D2 | Cross-channel | 未來 | 多通道 | 未實作 |
| E1 | MIMO Per-Excitation Bode | 固定 | P*.m → `MIMO_Bode_P1~P6.png` | ✅ step_mimo_plot |
| E2 | MIMO B Matrix | 固定 | fit_results → `MIMO_B_Matrix.png` | ✅ step_mimo_plot |
| E3 | MIMO Shared Hypothesis | 固定 | batch single → `MIMO_Shared_Hypothesis.png` | ✅ step_mimo_plot |
| E4 | MIMO Phase Correction | 固定 | correction_map → `MIMO_Phase_Correction.png` | ✅ step_mimo_plot |

## 已整合進 Pipeline 的功能

1. Vm 頻譜比較 → `step_compare` `'Type','spectrum'`
2. Lissajous / Vm vs Current → `step_compare` `'Type','lissajous'`
3. Fitting Residuals → `step_plot` Tab 3
4. Dashboard 總覽 → `step_plot` `generate_dashboard()`
5. TS Lissajous (Vm/I) → `step_compare` `'Type','ts_lissajous'` (原始+正規化)
6. TS TimeDomain → `step_compare` `'Type','ts_timedomain'`
7. MIMO 6x6 fitting → `step_mimo_fft` + `step_mimo_fit` + `step_mimo_plot`
8. ZOH 離散化 → `step_mimo_fit`
9. 共享假設檢驗 (CV) → `step_mimo_fit` + `step_mimo_plot`

## 尚未整合

- Averaged FFT 模式 — 目前 full 模式結果良好
- MIMO .dat 數據來源 — `step_mimo_fft` 目前僅支援 `'legacy'` (P*.m)
