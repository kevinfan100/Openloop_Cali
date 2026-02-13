# Openloop_cali 專案規範

> **語言偏好**: 中文為主，英文為輔（專有名詞可用英文）

六極電磁致動器 (hexapole electromagnetic actuator) 開迴路頻率響應校準。
Signal chain: DAC → Amplifier (k_A) → Coil → Magnetic Flux → Hall Sensor → Vm
Model: H(s) = A₂/(s²+A₁s+A₂) · B — 二階過阻尼，bandwidth ~200Hz

## 專案架構

```
run_analysis.m          ← 統一入口
configs/
  default_config.m      ← 所有共用參數 (~90 行)
  build_data_files.m    ← 自動從 prefix + frequencies 生成 .dat 檔名
  Hung_config.m         ← 只寫差異 (~15 行覆寫)
  Hung_no_washer_config.m
  Hung_spring_washer_config.m ← Hung spring washer (19 點, DA ch2 → Vm ch2)
  Hung_single_yoke_config.m  ← Hung single yoke (15 點, DA ch2 → Vm ch2)
  NTU_config.m
  NTU_t_config.m        ← NTU tip sensor (DA ch2 → Vm ch3)
  NTU_s_config.m        ← NTU surface sensor (DA ch2 → Vm ch2)
  Hung_pair_2_config.m  ← Hung pair 主通道 (DA ch2 → Vm ch2)
  Hung_pair_3_config.m  ← Hung pair 耦合通道 (DA ch2 → Vm ch3)
  NTU_pair_2_config.m   ← NTU pair 主通道 (DA ch2 → Vm ch2, 15 點)
  NTU_pair_3_config.m   ← NTU pair 耦合通道 (DA ch2 → Vm ch3, 15 點)
  Sweep_config.m        ← UI 自動掃頻 template (15 點頻率表)
  config_template.m     ← 新實驗 template (有註解說明)
pipeline/
  step_read.m           ← 讀取 .dat + DAC 轉換 + L1 sanity check
  step_steady_state.m   ← 穩態檢測 (conservative，低頻有 fallback)
  step_fft.m            ← FFT + THD + CSV 輸出 (super-period 精確截斷)
  step_fit.m            ← Phase offset removal + fitting (single-curve)
  step_plot.m           ← Bode 圖生成 (Model+Data / Residuals / Data Only 三 tab) + Dashboard
  step_compare.m        ← 多實驗比較: Bode / Spectrum / Lissajous / Ratio / CrossChannel / TS_Lissajous / TS_TimeDomain (Tag → subfolder output)
functions/              ← 核心演算法 (6 個 active)
  read_hsdata.m         ← binary reader (V1~V8 格式, vectorized fread)
  repair_bad_points.m   ← 壞點修復 (100kHz 數據)
  detect_steady_state_relative.m ← 穩態檢測 (relative threshold)
  compute_super_period.m ← Super-period 計算 (消除 FFT 頻譜洩漏)
  fit_single_tf.m       ← 3×3 加權最小平方
  get_experiment_colors.m ← 固定顏色方案
data/
  Hung/single_raw_data/       ← 19 個 .dat 檔
  Hung_no_washer/single_raw_data/
  Hung_spring_washer/single_raw_data/ ← 19 個 .dat 檔
  NTU/single_raw_data/
  NTU_ts/single_raw_data/     ← 19 個 .dat 檔 (tip+surface 雙通道)
  Hung_pair/pair_raw_data/   ← 19 個 .dat 檔 (V8, dual-channel excite+coupled)
  NTU_pair/pair_raw_data/    ← 15 個 .dat 檔 (V8, dual-channel excite+coupled)
  Hung_single_yoke/single_yoke_raw_data/ ← 15 個 .dat 檔 (V8, single yoke)
results/
  Hung/                       ← diagnostics/ + figures/ + fitting_results/
  Hung_no_washer/
  Hung_spring_washer/         ← spring washer 結果
  Hung_single_yoke/           ← single yoke 結果
  NTU/
  NTU_t/                      ← tip sensor 結果
  NTU_s/                      ← surface sensor 結果
  Hung_pair_2/                ← excite channel 結果 (Vm ch2)
  Hung_pair_3/                ← coupled channel 結果 (Vm ch3)
  NTU_pair_2/                 ← NTU excite channel 結果 (Vm ch2)
  NTU_pair_3/                 ← NTU coupled channel 結果 (Vm ch3)
  Comparison_*.png                     ← 無 Tag 時的比較圖 (預設位置)
  Hung_pair/Comparison_*.png           ← Hung pair 比較圖 (Tag='Hung_pair')
  NTU_pair/Comparison_*.png            ← NTU pair 比較圖 (Tag='NTU_pair')
  Hung_yoke/Comparison_*.png           ← Hung single_yoke vs pair 比較圖 (Tag='Hung_yoke')
  NTU_yoke/Comparison_*.png            ← NTU single vs pair 比較圖 (Tag='NTU_yoke')
legacy/                       ← 舊腳本
  Model_6_6_Continuous_Weighted.m ← MIMO 6×6 fitting (自包含)
  P1.m ~ P6.m                    ← 6×6 頻率響應數據 (Model_6_6 需要)
  openloop_bode.m, main_openloop_cali.m ← v2.0 入口
  plot_vm_spectrum.m, plot_vm_vs_current.m ← 已整合進 step_compare
  functions/                     ← 12 個未使用函數 (apply_plot_style, create_top_legend, ...)
```

## 使用方式

```matlab
run_analysis('Hung', 'all');                           % 完整 pipeline: read→steady→fft→fit→plot+dashboard
run_analysis('Hung', 'fft');                           % read→steady→fft (只產 CSV)
run_analysis('Hung', 'fit');                           % 從 CSV fitting (不需重新讀 .dat)
run_analysis('Hung', 'fit', 'wc_Hz', 1);               % 覆寫 fitting 參數
run_analysis('Hung', 'plot');                          % 從 fit_results.mat 或 CSV 畫圖
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare');                                       % Bode 比較 (預設)
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare', 'Type', 'spectrum', 'Frequencies', [1,10,100]);   % Vm 頻譜比較
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare', 'Type', 'lissajous', 'Frequencies', [1,10,100]); % Lissajous 比較
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare', 'Type', 'all', 'Frequencies', [1,10,100]);       % 全部比較圖

% Hung_spring_washer 分析
run_analysis('Hung_spring_washer', 'all');                                                                 % spring washer 完整 pipeline
run_analysis({'Hung','Hung_no_washer','Hung_spring_washer','NTU'}, 'compare');                             % 4 組比較

% NTU_ts 雙通道分析 (tip vs surface)
run_analysis('NTU_t', 'fft');                                                                         % tip sensor (Vm ch3)
run_analysis('NTU_s', 'fft');                                                                         % surface sensor (Vm ch2)
run_analysis({'NTU_t', 'NTU_s'}, 'compare', 'Normalize', false);                                     % Bode dB 疊圖
run_analysis({'NTU_t', 'NTU_s'}, 'compare', 'Normalize', false, 'Scale', 'linear');                   % Bode linear 疊圖
run_analysis({'NTU_t', 'NTU_s'}, 'compare', 'Type', 'ratio');                                        % 比值圖
run_analysis({'NTU_t', 'NTU_s'}, 'compare', 'Type', 'cross_channel', 'Frequencies', [500,1000,2000]); % 跨通道散射
run_analysis({'NTU_t', 'NTU_s'}, 'compare', 'Type', 'ts_lissajous', 'Frequencies', [10,100,1000]);   % TS Vm/I 疊圖
run_analysis({'NTU_t', 'NTU_s'}, 'compare', 'Type', 'ts_timedomain', 'Frequencies', [10,100,1000]);  % TS 時域疊圖
run_analysis({'NTU_t', 'NTU_s'}, 'compare', 'Normalize', true);                                      % TS 正規化 Bode → _TS.png

% Hung_pair 雙通道分析 (excite ch2 vs coupled ch3)
run_analysis('Hung_pair_2', 'fft');                                                                       % excite channel (Vm ch2)
run_analysis('Hung_pair_3', 'fft');                                                                       % coupled channel (Vm ch3)
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', false, 'Tag', 'Hung_pair');           % Bode dB 疊圖
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', false, 'Scale', 'linear', 'Tag', 'Hung_pair'); % Bode linear
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'Hung_pair');            % 正規化 Bode
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Type', 'ratio', 'Tag', 'Hung_pair');              % 比值圖

% NTU_pair 雙通道分析 (excite ch2 vs coupled ch3, 15 點頻率表)
run_analysis('NTU_pair_2', 'fft');                                                                           % excite channel (Vm ch2)
run_analysis('NTU_pair_3', 'fft');                                                                           % coupled channel (Vm ch3)
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', false, 'Tag', 'NTU_pair');                 % Bode dB → results/NTU_pair/
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'NTU_pair');                  % 正規化 Bode
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Type', 'ratio', 'Tag', 'NTU_pair');                    % 比值圖

% Hung single yoke vs pair 比較 (Tag → results/Hung_yoke/)
run_analysis({'Hung_single_yoke','Hung_pair_2','Hung_pair_3'}, 'compare', ...
    'Normalize', true, 'KeepOrder', true, 'Tag', 'Hung_yoke');                                               % 正規化 Bode

% NTU single vs pair 比較 (Tag → results/NTU_yoke/)
run_analysis({'NTU','NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'NTU_yoke');            % 正規化 Bode
```

### Pipeline 各步驟 (step) 說明
| Step | 輸入 | 輸出 | 說明 |
|------|------|------|------|
| `'all'` | .dat files | CSV + .mat + PNG + Dashboard | 完整流程 |
| `'read'` | .dat files | struct array | 只讀取驗證 |
| `'fft'` | .dat files | Raw_Bode_Data.csv | 讀取→穩態→FFT |
| `'fit'` | CSV | fit_results.mat + Fitted/Residuals/DataOnly PNG + Dashboard | 從 CSV fitting + 畫圖 |
| `'plot'` | .mat 或 CSV | Fitted/Residuals/DataOnly PNG + Dashboard | 只畫圖 |
| `'compare'` | CSV 或 .dat | Comparison_*.png | 多實驗比較 (Type: bode/spectrum/lissajous/ratio/cross_channel/ts_lissajous/ts_timedomain/all) |

---

## 階段一：數據處理 → 頻域轉換

### 1.1 read_hsdata()
- Input: `.dat` binary (V1~V8 格式)
- DAC→Voltage: `(da - 32768) * (20/65536)` [V] — 固定公式
- Sanity checks: freq, channel, fs, loop_mode 與 config 比對
- 壞點修復: 只有 100kHz 數據需要 (`config.enable_bad_point_repair`)

### 1.2 穩態檢測
- 方法: relative threshold (預設 0.2%)
- 策略: conservative — 所有分析通道都檢測，取最晚穩定
- `check_points`: `min(25, period_samples)` — 防高頻重複
- 低頻 fallback: 數據不足時用最後幾個週期

### 1.3 FFT (Super-Period 精確截斷)
- `H(jω) = Vm_fft(f_bin) / DA_fft(f_bin)` — DA 用激勵通道，Vm 用分析通道
- **Super-period 截斷**: 使用 `compute_super_period(freq, fs)` 計算包含整數週期的最小整數 samples
  - 公式: `min_periods = freq / gcd(fs, freq)`, `super_period = min_periods × fs / freq`
  - 例: 1200 Hz → super_period=50 samples (3 週期)，消除 `round(fs/freq)=17` 的 2% 誤差
  - **Fallback**: 若穩態段不夠長放不下 1 個 super-period (如 700/900/1400/1800 Hz in Hung)，退回 `round(fs/freq)` 近似截斷
- 不加窗
- THD: 2~10次諧波，上限 `0.8 × Nyquist`
- `full` 模式 (預設) / `averaged` 模式 (可選)

### 1.4 180° 相位修正
- 實驗觀測確定，硬體相關
- `self_correct_channels = [1,3,6]` — 修正 H_{excite,excite}
- `other_correct_channels = [2,4,5]` — 修正 H_{i,excite}, i≠excite
- Single ch2→ch2: 不需修正
- 修正後所有 H_ij 低頻相位趨近 0°

### 1.5 bode_table 輸出 (CSV)
欄位（目前 single-channel 模式）:
```
Frequency_Hz | Magnitude_Linear | Magnitude_dB | Phase_deg | THD_percent
```
- 保留原始 Phase_deg（未正規化）
- Phase 正規化在 fitting/plotting 階段才計算（減去 Phase(ω_min)）
- CSV 保留所有 19 個頻率，fitting 時才根據 `exclude_frequencies` 排除

### 1.6 數據可靠性驗證 (4 Levels)
- **L1**: Header 自動檢查 (每檔都跑)
- **L2**: 時域波形診斷 (可選)
- **L3**: FFT 品質指標 (THD + SNR)
- **L4**: Dashboard 總覽 + Console 文字摘要

---

## 階段二：頻域分析 / Fitting

### 2.1 兩條路徑
- **路徑 A**: 純頻域分析 (不 fitting) — 正規化比較、THD 趨勢、通道間比較
- **路徑 B**: Transfer Function Fitting

### 2.2 正規化 (多實驗比較)
- Magnitude: 各自除以自己的 `H(ω_ref)`，`ω_ref` = 最低頻
- Phase: 各自減去自己在 `ω_ref` 的相位
- **不使用任何跨實驗 scaling factor** (no 7/5)

### 2.3 Phase offset removal (fitting 前處理)
- 每條曲線減去 `Phase(ω_min)` — 消除 sensor DC 偏移
- 永遠做 (single 和 MIMO)

### 2.4 加權函數
```
w(ω) = 1 / (1 + (ω²/ωc²))^p
預設: p=0.5, wc=100Hz — config 中統一定義
```

**注意：wc_Hz 對 fitting 品質影響極大。** 各實驗歷史最佳值：
| 實驗 | wc_Hz | R² | 備註 |
|------|-------|-----|------|
| Hung | 1 | ~0.99 | 舊腳本預設 |
| Hung_no_washer | 1 | ~0.99 | 同 Hung |
| NTU | 10 | ~0.99 | 需要較高 wc |

default_config 統一用 `wc_Hz=100`（保守值），使用者可透過覆寫取得更佳 fitting：
```matlab
run_analysis('Hung', 'fit', 'wc_Hz', 1);
run_analysis('NTU', 'fit', 'wc_Hz', 10);
```

### 2.5 Single-curve fitting
- Model: `G(s) = b / (s² + a₁s + a₂)`
- `fit_single_tf.m`: 3×3 加權最小平方
- 品質: R² ≥ 0.85, DC gain 正號, ζ > 0
- step_fit 支援 `FromCSV` 模式 — 直接從 CSV 載入，不需重新讀 .dat

### 2.6 MIMO fitting (6×6)
- `H(s) = [A₂/(s²+A₁s+A₂)] · B`
- 共享 (A₁,A₂)，獨立 b_ℓ
- `fit_mimo_tf.m`: block matrix reduction → 2×2 系統
- `B_modified`: off-diagonal 取負 (物理符號慣例)
- 記錄 B_raw 和 B_modified

### 2.7 共享假設檢驗
- 36-channel batch single fitting → `a₁_matrix`, `a₂_matrix`
- 計算 CV (coefficient of variation): CV < 10% → 假設合理

### 2.8 ZOH 離散化
- `c2d(H_continuous, T_sample, 'zoh')`, `T_sample = 1e-5s` (100kHz)
- `k_A` 不參與 identification，只在控制器設計時使用

### 2.9 Exclude frequencies
- CSV 保留所有頻率
- Fitting 時根據 `config.fitting.exclude_frequencies` 排除
- 各實驗預設排除：Hung=[0.1, 900]、NTU=[0.1]、NoWasher=[0.1, 900]

---

## 開發注意事項（Pitfalls & Lessons）

### Pipeline 設計規則
1. **所有 pipeline step functions 必須設定 `p.KeepUnmatched = true`**
   - `run_analysis` 會將完整的 `varargin`（如 `'wc_Hz', 1`）轉發給所有 steps
   - 若某 step 的 `inputParser` 不認識某參數且沒設 `KeepUnmatched`，會報錯
   - 目前所有 6 個 step 都已正確設定

2. **新增 pipeline step 的 checklist：**
   - [ ] `p.KeepUnmatched = true` — 必須
   - [ ] 接受 `'Verbose'` 參數 — 一致性
   - [ ] 第一個參數是 `config` — pipeline 慣例
   - [ ] 函數名稱以 `step_` 開頭

3. **cell array 語法（checkcode 相容）：**
   - 多行 cell array 用分號 + ellipsis（`; ...`），不要用逗號換行
   - 逗號+換行會被 MATLAB 解讀為 row separator → checkcode 警告

### 數據處理注意
3b. **`read_hsdata` 使用 vectorized fread-with-skip** — 每個欄位只需 1 次 fseek + fread（共 3~5 次），取代舊版 per-record for loop（N×3~5 次 fread）。1.5M records: ~1.7s (原本需數十秒)
3c. **V8 格式為目前預設** — `data.Vm` (N×6 single), `data.da` (N×6 uint16), 無 `.channels` 欄位；`data.sampling_rate`, `data.frequency`, `data.channel` 來自 header
3d. **`detect_steady_state_relative` API** — `ss_info = detect_steady_state_relative(vm, freq, fs, 'Name', Value)` 回傳 struct with `.index`（穩態起始 sample index）
4. **THD 值會因穩態窗口選擇而略有不同** — 這是預期行為，不影響 fitting
5. **Super-period FFT 後，整除頻率維持 zero diff，非整除頻率有 0.3%~2% 改善** — 700/900/1400/1800 Hz 因穩態段太短會 fallback 到 round() 截斷，結果與舊版一致
6. **Fitting 品質 (R²) 高度依賴 `wc_Hz`** — 使用錯誤的 wc 會導致 R² < 0 或不穩定極點
6b. **Bode 比較圖 XLim/freq_max 自動從 CSV 取 max(freq)** — 不再寫死 2000，支援新 15 點頻率表 (max=3000)

### 繪圖注意
7. **`exportgraphics` 可能顯示 "axes toolbar" 警告** — 純外觀問題，不是錯誤
8. **`pbaspect([1 1 1])` 會壓縮 subplot 面積** — 標題可能被截斷
9. **不要在每個 subplot 各放 legend** — 會擋住標題；改用共用水平 legend 放圖頂
10. **`subplot()` 呼叫會重建 axes** — 手動調整 Position 後再呼叫 `subplot(1,n,k)` 會銷毀已繪製內容；改用 `ax_handles = gobjects(1,n)` 存 handle，之後用 handle 操作
11. **Legend 手動定位流程** — 必須先 `drawnow`，再讀取 `lgd.Position` 取得實際寬高，再計算置中位置 `[0.5-w/2, y, w, h]`
12. **正規化 Bode 的 DisplayName 格式** — `sprintf('%s (H(0.1)=%.4f)', display_name, H_ref)`，legend 放 southwest
12b. **TS Lissajous 正規化必須先去 DC** — Vm 和 Current 都有 DC offset，直接除以 `max(abs)` 會被 DC 壓縮；正確做法: 先 `x - mean(x)` 再 `/ max(abs(...))`
12c. **Tag → subfolder** — `step_compare` 的 `Tag` 參數控制輸出子資料夾：`Tag='Hung_pair'` → `results/Hung_pair/Comparison_*.png`；無 Tag → `results/Comparison_*.png`。檔名不再附加 tag 後綴
12d. **pair display_name** — `excite` / `coupled`（無 `V_` 前綴），在 `get_experiment_colors.m` 和各 `*_config.m` 中定義
12e. **NTU_pair 雙通道** — NTU_pair_2 (excite, Vm ch2) + NTU_pair_3 (coupled, Vm ch3)，共用 `data/NTU_pair/pair_raw_data/`，15 點頻率表
12f. **NTU_pair 相位特徵** — excite Phase(0.1Hz)=-4.5° (無 180° 偏移)；coupled 有 200Hz 反共振 (notch + 500Hz phase jump +22°)；與 Hung_pair 不同 (excite 有 180° 偏移)
12g. **角色統一配色** — pair/yoke 比較圖中 single=red 's', excite=blue 'o', coupled=green 'd'，Hung 和 NTU 系列一致。此配色與三組實驗比較 (Hung=blue, NoWasher=green, NTU=red) 無衝突

### Git / 工作流程規則
13. **Commit 前必須清理臨時檔案** — 若在討論過程中產生了臨時腳本（如 `test_*.m`、`temp_*.m`）或臨時輸出圖片（如根目錄的 `.png`），commit 前務必刪除。Claude 應主動判斷並提醒清除這些臨時產物。
14. **每輪討論或更動後必須更新 CLAUDE.md** — 對專案架構、規則、參數、注意事項的任何新理解或變更，都要反映到 CLAUDE.md 中。CLAUDE.md 是專案的 single source of truth，必須始終保持最新。

### 已整合進 Pipeline 的功能
15. **Vm 頻譜比較** — 已整合為 `step_compare` 的 `'Type','spectrum'` 模式（原 `legacy/plot_Vm_spectrum.m`）
16. **Lissajous / Vm vs Current** — 已整合為 `step_compare` 的 `'Type','lissajous'` 模式（原 `legacy/plot_Vm_vs_current.m`）
17. **Fitting Residuals** — 已整合為 `step_plot` Tab 3
18. **Dashboard 總覽** — 已整合為 `step_plot` 的 `generate_dashboard()` local function
19. **TS Lissajous (Vm/I)** — 已整合為 `step_compare` 的 `'Type','ts_lissajous'` 模式（同時產生原始 + 正規化兩張圖；正規化先去 DC 再除以 max(abs)）
20. **TS TimeDomain** — 已整合為 `step_compare` 的 `'Type','ts_timedomain'` 模式（tip+surface 時域疊圖）

### 尚未整合進 Pipeline 的功能
21. **MIMO 6×6 fitting**（原 `Model_6_6_Continuous_Weighted.m` + `P1~P6.m`）— 已搬到 `legacy/`，未來可整合為 `step_fit` 的 MIMO 模式
22. **Averaged FFT 模式** — 目前 full 模式結果良好，需要時再實作
23. **ZOH 離散化 Pipeline 整合** — 等 MIMO 完成後一起做
24. **共享假設檢驗 (CV)** — 等 MIMO 完成後一起做

---

## 階段三：繪圖呈現

### 3.1 全域 Style
```matlab
% Font
FontSize:   tick=24, label=40, legend=22, title=24
FontWeight: bold (all)

% Axis
XAxis.LineWidth = 3;
YAxis.LineWidth = 3;
box on;

% Plot
LineWidth = 3.5;
MarkerSize = 12;
MarkerFaceColor = 'none';
```

### 3.2 Legend 規則
- 預設: 頂端水平有框 (`Box='on'`, `Orientation='horizontal'`)
- 正規化 Bode: `Location='southwest'`，只在 Magnitude subplot，DisplayName 含 `H(0.1)=value`
- 非正規化 Bode: `Location='northoutside'`，水平排列
- TS Lissajous / TS TimeDomain: 手動定位 `[0.5-w/2, 0.92, w, h]`，放在圖頂中央

### 3.3 固定顏色方案
```matlab
% 角色統一配色 (pair/yoke 比較圖)
single           = [1,0,0]     red    's'   % NTU='single', Hung_single_yoke='single yoke'
excite           = [0,0,1]     blue   'o'   % Hung_pair_2, NTU_pair_2
coupled          = [0,0.6,0]   green  'd'   % Hung_pair_3, NTU_pair_3

% 多組實驗比較 (Hung/NoWasher/SpringWasher/NTU)
Hung             = [0,0,1]     blue   'o'
NoWasher         = [0,0.6,0]   green  'd'
SpringWasher     = [0.6,0,0.8] purple '^'   % display_name='Hung (SpringWasher)'
NTU              = [1,0,0]     red    's'   % display_name='single'

% TS 雙通道
NTU_t            = [0,0,1]     blue   'o'   % V_{tip}
NTU_s            = [1,0,0]     red    's'   % V_{surface}

% 6×6 通道
P1=k, P2=b, P3=g, P4=r, P5=m, P6=c

% 多頻率: lines(N) MATLAB 預設色板
```

### 3.4 圖表規格 (8 種)

| 圖表 | Size | Layout | X scale | Grid | Legend |
|------|------|--------|---------|------|--------|
| Bode Data Only | [900,720] | 2×1 | log | off | sw, mag only |
| Bode Model+Data | [900,720] | 2×1 | log | off | sw, mag only |
| Bode Comparison | [1050,820] | 2×1 | log | off | sw, mag only |
| Vm Spectrum | [1200,1200] | 3×1 | loglog | on | top horizontal |
| Lissajous | [1800,600] | 1×3 | linear | on | top horizontal |
| Dashboard | [1600,900] | 2×2 | mixed | on | per-subplot |
| Fitting Residuals | [900,720] | 2×1 | semilogx | on | best, RMSE in legend |
| Ratio | [900,720] | 2×1 | semilogx | on | best |
| Cross-Channel | [1800,600] | 1×N | linear | on | per-subplot axis labels |
| TS Lissajous | [1800,650] | 1×N | linear | on | top center manual, LineWidth=2 |
| TS Lissajous Norm | [1800,650] | 1×N | linear | on | top center manual, LineWidth=2, 去DC+normalize |
| TS TimeDomain | [1800,700] | 1×N | linear | on | top center manual, LineWidth=2 |
| 6×6 Bode | [900,720] | 2×1 | log | off | channel colors |

### 3.5 子圖規則
- **Subplot 順序 ALWAYS: Hung → Hung(NoWasher) → Hung(SpringWasher) → Hung(SingleYoke) → NTU → NTU_t → NTU_s → Hung_pair_2 → Hung_pair_3 → NTU_pair_2 → NTU_pair_3**
- **Legend 順序必須 match subplot 順序**
- 多子圖: 共用水平 legend 放在圖頂
- **xlabel 只放最底圖** — 上面的子圖不要重複

---

## 分析清單

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

---

## Config 規範

### default_config.m — 所有共用參數 (~92 行)
```matlab
config = default_config();
% 回傳完整的 config struct，包含所有預設值
% 涵蓋: DAC、穩態、FFT、Fitting、Phase、Validation、Output、Plot style
% config.analysis_channel = config.excitation_channel (預設向後相容)
% 跨通道分析時覆寫 analysis_channel (如 NTU_t: ch3, NTU_s: ch2)
```

### <experiment>_config.m — 只寫差異 (~15 行)
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

### 新增實驗 Checklist
1. 複製 `config_template.m` → `<name>_config.m`
2. 修改 `experiment_name`, `data_prefix`, `data_folder`, `output_folder`
3. 呼叫 `build_data_files()` 自動生成檔名
4. 設定 `exclude_frequencies`（如需要）
5. 將 .dat 檔案放入 `data/<name>/single_raw_data/`
6. 執行 `run_analysis('<name>', 'all')` 驗證

---

## 關鍵常數

```matlab
% Hardware
fs = 20000;                  % Hz (NOT 100kHz)
dac.zero_offset = 32768;
dac.voltage_range = 20.0;   % ±10V
dac.resolution = 65536;     % 16-bit
k_A = 0.3614;               % A/V (channel 2 amplifier gain)

% Reference values (measured at 0.1 Hz)
H_ref.Hung         = 0.0591;   % H(0.1Hz) [V/V]
H_ref.NTU          = 0.0914;
H_ref.Hung_no_washer  = 0.0733;
H_ref.Hung_spring_washer = 0.0438; % spring washer (Vm ch2)
H_ref.NTU_t        = 0.2419;   % tip sensor (Vm ch3)
H_ref.NTU_s        = 0.0972;   % surface sensor (Vm ch2)
H_ref.Hung_pair_2  = 0.0295;   % excite channel (Vm ch2)
H_ref.Hung_pair_3  = 0.0014;   % coupled channel (Vm ch3)
H_ref.NTU_pair_2   = 0.1009;   % NTU excite channel (Vm ch2)
H_ref.NTU_pair_3   = 0.0015;   % NTU coupled channel (Vm ch3)
H_ref.Hung_single_yoke = 0.0313; % Hung single yoke (Vm ch2)

% Frequencies — 舊 19 點 (Hung/Hung_no_washer/NTU/NTU_ts)
frequencies_19 = [0.1, 1, 10, 50, 100, 200, 300, 400, 500, 600, ...
                  700, 800, 900, 1000, 1200, 1400, 1600, 1800, 2000];

% Frequencies — 新 15 點 (UI Freq Sweep, Sweep_config.m)
frequencies_15 = [0.1, 1, 10, 50, 100, 200, 500, 1000, ...
                  1200, 1250, 1500, 1600, 2000, 2500, 3000];
```

## 驗證方法

重構後的 pipeline 已通過以下驗證：
1. **三組實驗各 19/19 檔案成功讀取**
2. **CSV Magnitude/Phase 與舊 pipeline 完全一致**（diff = 0）
3. **THD 略有不同**（因穩態窗口選擇不同，無害）
4. **compare 模式正常運作** — Bode / Spectrum / Lissajous 三種比較圖皆正確生成
5. **參數覆寫正常** — `run_analysis('Hung', 'fit', 'wc_Hz', 1)` 正確執行
6. **所有新檔案通過 `checkcode`** — 零警告
7. **step_plot 新功能** — Fitting Residuals (Tab 3) + Dashboard 正確生成
8. **step_compare 新模式** — `'Type','spectrum'` 和 `'Type','lissajous'` 正確讀取 .dat 並生成圖表
9. **NTU_ts 雙通道** — NTU_t (tip, Vm ch3) 和 NTU_s (surface, Vm ch2) FFT + 比較圖皆正確生成
10. **正規化 Bode TS** — NTU_t/NTU_s pair 自動存為 `Comparison_Bode_TS.png`，legend 含 H(0.1) 值
11. **TS Lissajous + TS TimeDomain** — 新 compare type 正確生成 Vm/I 疊圖和時域疊圖（ts_lissajous 同時產生原始+正規化版本）
12. **Super-period FFT** — `compute_super_period` 正確性已驗證 (23 頻率皆為精確整數)，整除頻率 zero diff，非整除頻率 0.3%~2% 改善，fallback 正常運作
13. **Bode freq_max 自動** — 比較圖 XLim 從 CSV max(freq) 自動推算，不再寫死 2000
14. **Vectorized read_hsdata** — fread-with-skip 產出與 per-record loop bit-identical（Hung + Hung_pair 皆 zero diff verified）
15. **Hung_pair 雙通道** — Hung_pair_2 (excite, Vm ch2) 和 Hung_pair_3 (coupled, Vm ch3) FFT + 比較圖正確生成
16. **NTU_pair 雙通道** — NTU_pair_2 (excite, Vm ch2) 和 NTU_pair_3 (coupled, Vm ch3) FFT + 比較圖正確生成 (15 點頻率表)
17. **Hung_single_yoke** — single yoke FFT + 與 pair 比較圖正確生成 (15 點頻率表)
18. **Tag subfolder output** — `step_compare` 的 `Tag` 參數改為存到 `results/<Tag>/` 子資料夾，不再加後綴到檔名
19. **Display names** — pair 實驗圖例改為 `excite` / `coupled`（移除 `V_` 前綴）
20. **角色統一配色** — single=red 's', excite=blue 'o', coupled=green 'd'，Hung/NTU 系列完全一致；NTU_yoke 3-way 比較正確生成
21. **Hung_spring_washer** — config + data + pipeline 完整運作，H(0.1Hz)=0.0438，Phase(0.1Hz)=177.3°（有 180° 偏移，同 Hung）

### 完整驗證指令
```matlab
run_analysis('Hung', 'all');
run_analysis('Hung_no_washer', 'all');
run_analysis('Hung_spring_washer', 'all');
run_analysis('NTU', 'all');
run_analysis({'Hung','Hung_no_washer','Hung_spring_washer','NTU'}, 'compare');
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare', 'Type', 'spectrum', 'Frequencies', [1,10,100]);
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare', 'Type', 'lissajous', 'Frequencies', [1,10,100]);

% NTU_ts 雙通道
run_analysis('NTU_t', 'fft');
run_analysis('NTU_s', 'fft');
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Normalize', false);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Normalize', false, 'Scale', 'linear');
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ratio');
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'cross_channel', 'Frequencies', [500,1000,2000]);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ts_lissajous', 'Frequencies', [10,100,1000]);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ts_timedomain', 'Frequencies', [10,100,1000]);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Normalize', true);  % → Comparison_Bode_TS.png

% Hung_pair 雙通道
run_analysis('Hung_pair_2', 'fft');
run_analysis('Hung_pair_3', 'fft');
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', false, 'Tag', 'Hung_pair');
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'Hung_pair');
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Type', 'ratio', 'Tag', 'Hung_pair');

% NTU_pair 雙通道
run_analysis('NTU_pair_2', 'fft');
run_analysis('NTU_pair_3', 'fft');
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', false, 'Tag', 'NTU_pair');
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'NTU_pair');
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Type', 'ratio', 'Tag', 'NTU_pair');

% Hung single yoke vs pair
run_analysis({'Hung_single_yoke','Hung_pair_2','Hung_pair_3'}, 'compare', ...
    'Normalize', true, 'KeepOrder', true, 'Tag', 'Hung_yoke');

% NTU single vs pair
run_analysis({'NTU','NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'NTU_yoke');
```
