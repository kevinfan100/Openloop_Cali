# Openloop_cali 專案規範

六極電磁致動器 (hexapole electromagnetic actuator) 開迴路頻率響應校準。
Signal chain: DAC → Amplifier (k_A) → Coil → Magnetic Flux → Hall Sensor → VM
Model: H(s) = A₂/(s²+A₁s+A₂) · B — 二階過阻尼，bandwidth ~200Hz

## 專案架構

```
run_analysis.m          ← 統一入口
configs/
  default_config.m      ← 所有共用參數 (~90 行)
  build_data_files.m    ← 自動從 prefix + frequencies 生成 .dat 檔名
  Hung_config.m         ← 只寫差異 (~15 行覆寫)
  Hung_noring_config.m
  NTU_config.m
  config_template.m     ← 新實驗 template (有註解說明)
pipeline/
  step_read.m           ← 讀取 .dat + DAC 轉換 + L1 sanity check
  step_steady_state.m   ← 穩態檢測 (conservative，低頻有 fallback)
  step_fft.m            ← FFT + THD + CSV 輸出
  step_fit.m            ← Phase offset removal + fitting (single-curve)
  step_plot.m           ← Bode 圖生成 (Model+Data / Data Only 雙 tab)
  step_compare.m        ← 多實驗比較 (固定順序 Hung→NoRing→NTU)
functions/              ← 核心演算法 (保留不動)
  read_hsdata.m         ← binary reader (V1~V8 格式)
  detect_steady_state.m, detect_steady_state_relative.m
  fit_single_tf.m       ← 3×3 加權最小平方
  apply_plot_style.m    ← 統一 style 工具
  create_top_legend.m   ← 頂端水平 legend 工具
  get_experiment_colors.m ← 固定顏色方案
data/
  Hung/single_raw_data/       ← 19 個 .dat 檔
  Hung_noring/single_raw_data/
  NTU/single_raw_data/
results/
  Hung/                       ← diagnostics/ + figures/ + fitting_results/
  Hung_noring/
  NTU/
  Comparison_Bode.png         ← 三實驗比較圖
legacy/                       ← 舊腳本 (diagnose_*.m, fit_*.m 等)
```

## 使用方式

```matlab
run_analysis('Hung', 'all');                           % 完整 pipeline: read→steady→fft→fit→plot
run_analysis('Hung', 'fft');                           % read→steady→fft (只產 CSV)
run_analysis('Hung', 'fit');                           % 從 CSV fitting (不需重新讀 .dat)
run_analysis('Hung', 'fit', 'wc_Hz', 1);               % 覆寫 fitting 參數
run_analysis('Hung', 'plot');                          % 從 fit_results.mat 或 CSV 畫圖
run_analysis({'Hung','Hung_noring','NTU'}, 'compare');  % 三實驗比較圖
```

### Pipeline 各步驟 (step) 說明
| Step | 輸入 | 輸出 | 說明 |
|------|------|------|------|
| `'all'` | .dat files | CSV + .mat + PNG | 完整流程 |
| `'read'` | .dat files | struct array | 只讀取驗證 |
| `'fft'` | .dat files | Raw_Bode_Data.csv | 讀取→穩態→FFT |
| `'fit'` | CSV | fit_results.mat + PNG | 從 CSV fitting + 畫圖 |
| `'plot'` | .mat 或 CSV | PNG | 只畫圖 |
| `'compare'` | 多個 CSV | Comparison_Bode.png | 多實驗比較 |

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

### 1.3 FFT
- `H(jω) = VM_fft(f_bin) / DA_fft(f_bin)` — DA 用激勵通道，VM 用分析通道
- 整數週期截斷，不加窗
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
| Hung_noring | 1 | ~0.99 | 同 Hung |
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
- 各實驗預設排除：Hung=[0.1, 900]、NTU=[0.1]、NoRing=[0.1, 900]

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
4. **THD 值會因穩態窗口選擇而略有不同** — 這是預期行為，不影響 fitting
5. **Magnitude 和 Phase 應與舊 CSV 完全一致（zero diff）** — 驗證基準
6. **Fitting 品質 (R²) 高度依賴 `wc_Hz`** — 使用錯誤的 wc 會導致 R² < 0 或不穩定極點

### 繪圖注意
7. **`exportgraphics` 可能顯示 "axes toolbar" 警告** — 純外觀問題，不是錯誤
8. **`pbaspect([1 1 1])` 會壓縮 subplot 面積** — 標題可能被截斷
9. **不要在每個 subplot 各放 legend** — 會擋住標題；改用共用水平 legend 放圖頂

### Git / 工作流程規則
10. **Commit 前必須清理臨時檔案** — 若在討論過程中產生了臨時腳本（如 `test_*.m`、`temp_*.m`）或臨時輸出圖片（如根目錄的 `.png`），commit 前務必刪除。Claude 應主動判斷並提醒清除這些臨時產物。
11. **每輪討論或更動後必須更新 CLAUDE.md** — 對專案架構、規則、參數、注意事項的任何新理解或變更，都要反映到 CLAUDE.md 中。CLAUDE.md 是專案的 single source of truth，必須始終保持最新。

### 尚未整合進 Pipeline 的功能
12. **VM 頻譜比較**（原 `plot_vm_spectrum.m`）— 目前在 `legacy/`，未來可整合為 `step_compare` 的子功能
13. **Lissajous / VM vs Current**（原 `plot_vm_vs_current.m`）— 同上
14. **MIMO 6×6 fitting**（原 `Model_6_6_Continuous_Weighted.m` + `P1~P6.m`）— 保留在根目錄，未來可整合為 `step_fit` 的 MIMO 模式

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
- 例外: Bode 圖用 `Location='southwest'`，只在 Magnitude subplot

### 3.3 固定顏色方案
```matlab
% 三組實驗
Hung    = [0,0,1]   blue  'o'
NoRing  = [0,0.6,0] green 'd'
NTU     = [1,0,0]   red   's'

% 6×6 通道
P1=k, P2=b, P3=g, P4=r, P5=m, P6=c

% 多頻率: lines(N) MATLAB 預設色板
```

### 3.4 圖表規格 (8 種)

| 圖表 | Size | Layout | X scale | Grid | Legend |
|------|------|--------|---------|------|--------|
| Bode Data Only | [900,720] | 2×1 | log | off | sw, mag only |
| Bode Model+Data | [900,720] | 2×1 | log | off | sw, mag only |
| Bode Comparison | [900,720] | 2×1 | log | off | sw, mag only |
| VM Spectrum | [1200,1200] | 3×1 | loglog | on | top horizontal |
| Lissajous | [1800,600] | 1×3 | linear | on | top horizontal |
| Dashboard | [1600,900] | 2×2 | mixed | on | per-subplot |
| Fitting Residuals | [900,720] | 2×1 | semilogx | on | - |
| 6×6 Bode | [900,720] | 2×1 | log | off | channel colors |

### 3.5 子圖規則
- **Subplot 順序 ALWAYS: Hung → Hung(NoRing) → NTU** (Hung 系列相鄰)
- **Legend 順序必須 match subplot 順序**
- 多子圖: 共用水平 legend 放在圖頂
- **xlabel 只放最底圖** — 上面的子圖不要重複

---

## 分析清單

| ID | 分析 | 觸發 | 來源 |
|----|------|------|------|
| A1 | Raw Bode | 固定 | CSV |
| A2 | Normalized Comparison | 按需 | 多實驗 |
| A3 | THD vs Freq | 固定 | Dashboard |
| A4 | DC Gain 比較 | Console | - |
| B1 | VM Spectrum | 可選 | 指定頻率 |
| B2 | VM Time-Domain | 可選 | 診斷 |
| B3 | VM P-P vs Freq | 建議固定 | SNR 判斷 |
| C1 | Lissajous | 可選 | 指定頻率 |
| D1/D2 | Cross-channel | 未來 | 多通道 |

---

## Config 規範

### default_config.m — 所有共用參數 (~90 行)
```matlab
config = default_config();
% 回傳完整的 config struct，包含所有預設值
% 涵蓋: DAC、穩態、FFT、Fitting、Phase、Validation、Output、Plot style
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
H_ref.Hung_noring  = 0.0733;

% Frequencies (19 points, 所有實驗共用)
frequencies = [0.1, 1, 10, 50, 100, 200, 300, 400, 500, 600, ...
               700, 800, 900, 1000, 1200, 1400, 1600, 1800, 2000];
```

## 驗證方法

重構後的 pipeline 已通過以下驗證：
1. **三組實驗各 19/19 檔案成功讀取**
2. **CSV Magnitude/Phase 與舊 pipeline 完全一致**（diff = 0）
3. **THD 略有不同**（因穩態窗口選擇不同，無害）
4. **compare 模式正常運作** — Comparison_Bode.png 正確生成
5. **參數覆寫正常** — `run_analysis('Hung', 'fit', 'wc_Hz', 1)` 正確執行
6. **所有新檔案通過 `checkcode`** — 零警告
