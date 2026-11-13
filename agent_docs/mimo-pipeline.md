# MIMO 6x6 Pipeline

> MIMO 專用參考文檔。

## 架構

- `step_mimo_fft.m` — Stage 1: 數據→頻域 CSV (6x6xN tensor)
- `step_mimo_fit.m` — Stage 2: 自動相位修正→batch single→MIMO fitting→ZOH
- `step_mimo_plot.m` — 繪圖: Per-excitation Bode / B Matrix / CV / Phase Diagnostic

## Model

```
H(s) = [A2/(s^2+A1*s+A2)] * B
```
- 共享 (A1,A2)，獨立 b_l (36 個 DC gain)
- `fit_mimo_tf.m`: block matrix reduction → 2x2 系統
- `B_modified`: off-diagonal 取負 (物理符號慣例)
- 記錄 B_raw 和 B_modified

## 自動 180 deg 相位修正

- `auto_phase_correct_6x6` 投票法
- 使用低頻 3 點投票 (0.1, 1, 10 Hz)
- |phase| > 90 deg 門檻
- 修正後再 offset removal
- 18/36 通道需修正，完全匹配 legacy 硬編碼
- `self_correct_channels = [1,3,6]`
- `other_correct_channels = [2,4,5]`

## 兩階段設計

- Stage 1 (`mimo_fft`): 原始 CSV — 不做相位修正
- Stage 2 (`mimo_fit`): 修正→擬合
- 三種精度輸出: .mat (double), CSV (10位有效), LaTeX (4位有效)

## 共享假設檢驗

- 36-channel batch single fitting → a1_matrix, a2_matrix
- CV (coefficient of variation): CV < 10% → 假設合理
- 實測 CV: a1=59%, a2=72% — 偏高但 MIMO fitting 仍穩定 (cond=1.48e7)

## ZOH 離散化

- `c2d(H_continuous, T_sample, 'zoh')`, `T_sample = 1e-5s` (100kHz)
- k_A 不參與 identification

## 關鍵參數

```matlab
k_A_diag = [0.3618, 0.3614, 0.3536, 0.3532, 0.3573, 0.3610];
T_sample = 1e-5;              % ZOH (100 kHz)
pair_map = [2,1,4,3,6,5];    % 配對通道 (繪圖跳過 paired)

% Fitting 結果 (wc_Hz=0.1, p=0.5)
A1 = 6617.2;                 % s^-1
A2 = 1.159e7;                % s^-2
B_diag = [0.237, 0.282, 0.211, 0.236, 0.257, 0.185];
```

## 注意事項

- **MIMO wc_Hz 預設 0.1** — MIMO_config 覆寫 default_config 的 wc_Hz=100
- **P*.m 頻率不完全一致** — P1 用 0.1 Hz，P2 用 0.102605 Hz 等；統一使用第一個檔案的頻率向量
- **B_modified 繪圖用 abs(dc_gain)** — off-diagonal dc_gain 為負，magnitude 正規化需用 abs()
- **A1/A2 預期值** — wc_Hz=0.1 時 A1~6617, A2~1.16e7
- **資料來源**: `step_mimo_fft` 目前僅支援 `'legacy'` (P*.m)，未來可擴充 .dat

## Band fit 與 PT3D 2026 數據 (2026-11-13, branch feature/v8-data-band-fit)

- `functions/fit_mimo_band.m`：同樣的共用二階結構 H = G·B，G(s) = A2/(s²+A1 s+A2)，但
  - B = |H(f_min)|（0.1 Hz 實測，同 legacy B_raw 意義；B_modified 非對角取負）
  - A1/A2：固定 G(0)=1，只在頻帶（預設 200–1500 Hz）最小化 6 條對角曲線的複數相對誤差 Σ|G/Hn − 1|²
  - legacy `fit_mimo_tf`（wc 0.1 Hz，權重 ≈ 0.1/f）照舊執行；band 結果放在 `fit_results.band`（含 ZOH 離散 k_o/b/a1/a2）
- 開關：`config.fitting.band.enable / range / curves`（default 關閉，舊實驗結果不變）
- `config.output.save_processed_mat = true`：另存 `results/<exp>/processed/MIMO_Raw_Bode_Data.mat`、`mimo_fit_results.mat`（fitting_results/*.mat 被 git ignore，processed/ 會進版控）
- `configs/PT3D_OL_2V_20261113_config.m`：PT3D_SW FreqSweep 開迴路（三個控制開關全關，alpha = 激發軸，beta = 2 V），HSData V8，100 kHz，15 點；`.dat` 在實驗機 `PT3D_SW\Export`，不在 repo
- `compare_fit_methods.m`：2025 (legacy P*.m) vs 2026 × legacy vs band，輸出 `results/compare_fit_20261113/README.md`
- `read_hsdata.m`：V6 header 實為 120 bytes（116 欄位 + 4 對齊），原本寫 116
