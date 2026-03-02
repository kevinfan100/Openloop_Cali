# Openloop_cali 專案規範

> **語言偏好**: 中文為主，英文為輔（專有名詞可用英文）

六極電磁致動器 (hexapole electromagnetic actuator) 開迴路頻率響應校準。
Signal chain: DAC → Amplifier (k_A) → Coil → Magnetic Flux → Hall Sensor → Vm
Model: H(s) = A2/(s^2+A1*s+A2) * B — 二階過阻尼，bandwidth ~200Hz

## 專案架構

```
run_analysis.m              ← 統一入口
configs/                    ← default_config + 各實驗 config (~15 行覆寫)
pipeline/                   ← 6 single steps + 3 MIMO steps
  step_read / step_steady_state / step_fft / step_fit / step_plot / step_compare
  step_mimo_fft / step_mimo_fit / step_mimo_plot
functions/                  ← 10 個核心演算法 (read_hsdata, fit_single_tf, etc.)
data/                       ← Hung/ Hung_no_washer/ Hung_spring_washer/ NTU/ NTU_ts/ Hung_pair/ NTU_pair/ Hung_single_yoke/ Hung_test1/ Hung_single_yoke_test1/ Hung_pair_test1/
results/                    ← 各實驗結果 + Tag 子資料夾比較圖
charge_cali/                ← 獨立磁荷校準模組 (入口: run_charge_cali.m)
legacy/                     ← P1~P6.m (MIMO data) + 舊腳本 (保留供參考)
agent_docs/                 ← 詳細參考文檔 (不自動載入，需要時讀取)
```

**詳細參考文檔** (需要時用 Read 工具查閱):
- `agent_docs/data-processing.md` — 階段一: read → 穩態 → FFT → CSV
- `agent_docs/fitting-analysis.md` — 階段二: 正規化 → fitting → ZOH
- `agent_docs/plotting-guide.md` — 階段三: style / legend / 顏色 / 圖表規格
- `agent_docs/analysis-catalog.md` — 分析清單 A1~E4 + 整合狀態
- `agent_docs/verification.md` — 完整驗證指令 + 預期結果
- `agent_docs/mimo-pipeline.md` — MIMO 6x6 pipeline 詳細說明

## 使用方式

```matlab
% Single-channel pipeline
run_analysis('Hung', 'all');                     % 完整: read→steady→fft→fit→plot
run_analysis('Hung', 'fft');                     % 只產 CSV
run_analysis('Hung', 'fit', 'wc_Hz', 1);         % 覆寫 fitting 參數
run_analysis('Hung', 'plot');                    % 從 .mat 畫圖

% 多實驗比較 (Type: bode/spectrum/lissajous/ratio/cross_channel/ts_lissajous/ts_timedomain/all)
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare');
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', false, 'Tag', 'Hung_pair');

% MIMO 6x6
run_analysis('MIMO', 'mimo_all');                % 完整: 載入→CSV→修正→擬合→圖
run_analysis('MIMO', 'mimo_fit');                % 從 CSV 擬合

% Charge Calibration (獨立入口)
run_charge_cali('Charge_NTU', 'full');           % read→CSV→fit→plot
analyze_charge_physics('Charge_NTU');            % 物理分析
```

### Pipeline Steps

| Step | 輸入 | 輸出 |
|------|------|------|
| `'all'` | .dat | CSV + .mat + PNG + Dashboard |
| `'fft'` | .dat | Raw_Bode_Data.csv |
| `'fit'` | CSV | fit_results.mat + PNG |
| `'plot'` | .mat/CSV | PNG |
| `'compare'` | CSV/.dat | Comparison_*.png |
| `'mimo_all'` | P*.m | CSV + .mat + PNG + LaTeX |
| `'mimo_fit'` | CSV | mimo_fit_results.mat + PNG |
| `'mimo_plot'` | .mat | MIMO_*.png |

## Config 規範

- `default_config.m` — 所有共用參數 (~92 行)
- `<experiment>_config.m` — 繼承 default_config，只寫差異 (~15 行)
- 新增實驗: 複製 `config_template.m` → 改 name/prefix/folder → `build_data_files()` → 跑 `'all'` 驗證

## 全域 Plot Style

```matlab
FontSize:   tick=24, label=40, legend=22, title=24;  FontWeight: bold
XAxis.LineWidth=3; YAxis.LineWidth=3; box on
LineWidth=3.5; MarkerSize=12; MarkerFaceColor='none'
```

**顏色**: Hung=blue 'o', NoWasher=green 'd', SpringWasher=purple '^', NTU=red 's'
**Pair/Yoke 統一**: single=red 's', excite=blue 'o', coupled=green 'd'
**Subplot 順序**: Hung → NoWasher → SpringWasher → SingleYoke → NTU → NTU_t → NTU_s → pairs
**Legend**: 共用水平放圖頂; 正規化 Bode 放 southwest 含 H(0.1) 值; xlabel 只放最底圖

## 關鍵常數

```matlab
fs = 20000;                  % Hz (NOT 100kHz)
dac.zero_offset = 32768;  dac.voltage_range = 20.0;  dac.resolution = 65536;
k_A = 0.3614;               % A/V (channel 2)
N_c = 50;  r_tip = 5e-6;    % coil turns, pole tip radius [m]

% 頻率表
frequencies_19 = [0.1,1,10,50,100,200,300,400,500,600,700,800,900,1000,1200,1400,1600,1800,2000];
frequencies_15 = [0.1,1,10,50,100,200,500,1000,1200,1250,1500,1600,2000,2500,3000];
```

## 開發規則

1. **Pipeline steps 必須設 `p.KeepUnmatched = true`** — varargin 會轉發給所有 steps
2. **cell array 換行用 `; ...`** — 逗號+換行觸發 checkcode 警告
3. **Commit 前清理臨時檔案** — `test_*.m`, `temp_*.m`, 根目錄 `.png`
4. **每輪更動後更新 CLAUDE.md** — 或對應的 agent_docs 檔案
5. **Fitting R^2 高度依賴 `wc_Hz`** — Hung 最佳 1, NTU 最佳 10, MIMO 用 0.1
6. **正規化**: 各實驗除以自己的 H(0.1Hz)，不使用跨實驗 scaling
7. **Tag → subfolder**: `Tag='Hung_pair'` → `results/Hung_pair/Comparison_*.png`
8. **Pair display_name**: `excite` / `coupled` (無 `V_` 前綴)

### Charge Calibration 說明

- Model: `H(x) = a^2 / (x + b)^2` (倒平方律)
- 數據格式: `charge_cali_<distance>um_<freq>hz.dat` (V8, 20kHz)
- NTU 結果: 22 距離 (10~2000 um), b=1978.9+-1.2 um, R^2>0.992
- Physics: k_pole=1.57e-7 Wb/A, crossover ~609 um
- R_a 比較無效: NTU R_a=3.19e8 是 R_total (single pole 無 yoke), 不可與 Menq air-gap R_a 比較
