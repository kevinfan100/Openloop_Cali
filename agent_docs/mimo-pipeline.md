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
