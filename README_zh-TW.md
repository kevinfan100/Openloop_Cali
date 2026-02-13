# 開迴路波德分析流程

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020a+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

> **六極電磁致動器開迴路頻率響應校準**

**繁體中文** | [English](README.md)

---

## 專案概述

本專案提供一套自動化的**純 MATLAB** 流程，用於六極電磁致動器的開迴路頻率響應分析。從二進位測量數據（`.dat`）處理到波德圖、轉移函數擬合與多實驗比較。

**信號鏈:** DAC &rarr; 放大器 (k_A) &rarr; 線圈 &rarr; 磁通量 &rarr; 霍爾感測器 &rarr; Vm

**模型:** H(s) = A&#8322;/(s&#178;+A&#8321;s+A&#8322;) &middot; B &mdash; 二階過阻尼，頻寬 ~200Hz

### 11 組實驗

| 類型 | 實驗名稱 | 說明 | 頻率點數 |
|------|---------|------|---------|
| 單通道 | `Hung` | Hung 致動器（含環）| 19 |
| 單通道 | `Hung_no_washer` | Hung 致動器（無墊片）| 19 |
| 單通道 | `Hung_spring_washer` | Hung 致動器（彈簧墊片）| 19 |
| 單通道 | `Hung_single_yoke` | Hung 單軛鐵 | 15 |
| 單通道 | `NTU` | NTU 致動器 | 19 |
| 雙通道 | `NTU_t` / `NTU_s` | NTU 尖端 / 表面感測器 | 19 |
| 配對 | `Hung_pair_2` / `Hung_pair_3` | Hung 激勵 / 耦合通道 | 19 |
| 配對 | `NTU_pair_2` / `NTU_pair_3` | NTU 激勵 / 耦合通道 | 15 |

---

## 專案結構

```
Openloop_cali/
├── run_analysis.m              # 統一入口
├── configs/                    # 實驗配置
│   ├── default_config.m        #   共用預設值 (~92 行)
│   ├── build_data_files.m      #   自動生成 .dat 檔名
│   ├── Hung_config.m           #   各實驗只覆寫差異 (~15 行)
│   ├── Hung_no_washer_config.m
│   ├── Hung_spring_washer_config.m
│   ├── Hung_single_yoke_config.m
│   ├── NTU_config.m
│   ├── NTU_t_config.m / NTU_s_config.m
│   ├── Hung_pair_2_config.m / Hung_pair_3_config.m
│   ├── NTU_pair_2_config.m / NTU_pair_3_config.m
│   ├── Sweep_config.m          #   UI 自動掃頻 template (15 點)
│   └── config_template.m       #   新實驗 template
├── pipeline/                   # 處理步驟
│   ├── step_read.m             #   讀取 .dat + DAC 轉換 + 驗證
│   ├── step_steady_state.m     #   穩態檢測
│   ├── step_fft.m              #   FFT + THD + CSV 輸出
│   ├── step_fit.m              #   相位校正 + 曲線擬合
│   ├── step_plot.m             #   波德圖 + Dashboard
│   └── step_compare.m          #   多實驗比較圖
├── functions/                  # 核心演算法 (6 個 active)
│   ├── read_hsdata.m           #   二進位讀取器 (V1-V8, 向量化 fread)
│   ├── repair_bad_points.m     #   壞點修復
│   ├── detect_steady_state_relative.m
│   ├── compute_super_period.m  #   Super-period 計算
│   ├── fit_single_tf.m         #   加權最小平方擬合
│   └── get_experiment_colors.m #   固定顏色方案
├── data/                       # 原始二進位數據 (.dat, gitignore)
├── results/                    # 輸出結果 (大部分 gitignore)
└── legacy/                     # 舊腳本 (v2.0 架構)
    ├── Model_6_6_Continuous_Weighted.m  # MIMO 6x6 擬合
    ├── P1.m ~ P6.m                      # 6x6 頻率響應數據
    └── functions/                       # 12 個未使用函數
```

---

## 環境需求

| 軟體 | 版本 | 必要 |
|------|------|------|
| **MATLAB** | R2020a+ | 是 |
| Control System Toolbox | - | 擬合功能需要 |

---

## 快速開始

```matlab
% 切換到專案目錄
cd 'path/to/Openloop_cali'

% 完整 pipeline: 讀取 → 穩態 → FFT → 擬合 → 繪圖 + Dashboard
run_analysis('Hung', 'all');

% 只做 FFT（產生 CSV，不擬合）
run_analysis('Hung', 'fft');

% 從 CSV 擬合（不需 .dat）
run_analysis('Hung', 'fit');

% 覆寫擬合參數
run_analysis('Hung', 'fit', 'wc_Hz', 1);

% 多實驗波德比較
run_analysis({'Hung', 'Hung_no_washer', 'NTU'}, 'compare');

% 正規化比較（各實驗以自己的 H(0.1Hz) 正規化）
run_analysis({'Hung', 'Hung_no_washer', 'NTU'}, 'compare', 'Normalize', true);
```

### Pipeline 步驟

| 步驟 | 輸入 | 輸出 | 說明 |
|------|------|------|------|
| `'all'` | .dat 檔案 | CSV + .mat + PNG + Dashboard | 完整流程 |
| `'read'` | .dat 檔案 | struct array | 只讀取驗證 |
| `'fft'` | .dat 檔案 | Raw_Bode_Data.csv | 讀取 &rarr; 穩態 &rarr; FFT |
| `'fit'` | CSV | fit_results.mat + 波德圖 + Dashboard | 擬合 + 繪圖 |
| `'plot'` | .mat 或 CSV | 波德圖 + Dashboard | 只繪圖 |
| `'compare'` | CSV 或 .dat | Comparison_*.png | 多實驗比較 |

### 比較類型

```matlab
% 波德幅頻 + 相頻（預設）
run_analysis({'Hung','NTU'}, 'compare');

% Vm 頻譜
run_analysis({'Hung','NTU'}, 'compare', 'Type', 'spectrum', 'Frequencies', [1,10,100]);

% Lissajous (Vm vs 電流)
run_analysis({'Hung','NTU'}, 'compare', 'Type', 'lissajous', 'Frequencies', [1,10,100]);

% 通道比值
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ratio');

% 全部比較類型
run_analysis({'Hung','NTU'}, 'compare', 'Type', 'all', 'Frequencies', [1,10,100]);
```

---

## 數據設置

### 方式一：下載預錄數據

<!-- TODO: 雲端連結準備好後補上 -->
下載數據壓縮檔，解壓到 `data/` 目錄。

### 方式二：自行量測

使用實驗 UI 在各頻率點錄製 `.dat` 檔案，放到對應資料夾：

```
data/<實驗名稱>/single_raw_data/<前綴>_<頻率>hz.dat
```

**命名規則:** `<前綴>_0.1hz.dat`, `<前綴>_1hz.dat`, ..., `<前綴>_2000hz.dat`

前綴在各實驗的 config 檔案中定義（例如 Hung 的前綴是 `Hung_single`）。

### 數據格式

- 二進位 HSData 格式 (V1-V8)，由 `read_hsdata.m` 讀取
- 取樣率: 20,000 Hz
- DAC: 16-bit (0-65535)，零點 = 32768，範圍 = 20V

---

## 配置指南

### 預設配置 (`configs/default_config.m`)

包含所有共用參數（~92 行）：DAC 轉換、穩態檢測、FFT 設定、擬合參數、繪圖樣式等。

### 實驗覆寫

每個實驗 config 繼承 `default_config` 後只覆寫差異：

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

### 新增實驗步驟

1. 複製 `configs/config_template.m` &rarr; `configs/<名稱>_config.m`
2. 設定 `experiment_name`, `data_prefix`, `data_folder`, `output_folder`
3. 呼叫 `build_data_files()` 自動生成檔名
4. 設定 `exclude_frequencies`（如需要）
5. 將 `.dat` 檔案放入 `data/<名稱>/single_raw_data/`
6. 在 `functions/get_experiment_colors.m` 加入顏色定義
7. 執行 `run_analysis('<名稱>', 'all')` 驗證

---

## 函數參考

### 使用中的函數 (`functions/`)

| 函數 | 用途 |
|------|------|
| `read_hsdata(filepath)` | 讀取二進位 .dat 檔案 (V1-V8, 向量化 fread) |
| `repair_bad_points(Vm, da, ...)` | 修復壞數據點（僅 100kHz 數據）|
| `detect_steady_state_relative(vm, freq, fs, ...)` | 穩態區域檢測 |
| `compute_super_period(freq, fs)` | 計算 FFT 截斷用 super-period |
| `fit_single_tf(h, phi, w, ...)` | 單曲線加權最小平方擬合 |
| `get_experiment_colors()` | 所有實驗的固定顏色方案 |

### 舊函數 (`legacy/functions/`)

12 個 v2.0 架構的函數，pipeline 不再呼叫。

---

## 輸出檔案

### 各實驗結果 (`results/<名稱>/`)

```
results/<名稱>/
├── diagnostics/
│   ├── Raw_Bode_Data.csv          # FFT 結果（納入版本控制）
│   └── Dashboard_<名稱>.png       # 總覽 Dashboard
├── figures/
│   ├── Bode_<名稱>_Fitted.png     # 模型 + 數據波德圖
│   ├── Bode_<名稱>_Residuals.png  # 擬合殘差
│   └── Bode_<名稱>_DataOnly.png   # 純數據波德圖
└── fitting_results/
    └── fit_results.mat            # 擬合參數
```

### 比較結果 (`results/` 或 `results/<Tag>/`)

```
results/Comparison_Bode.png                    # 預設（無 Tag）
results/Hung_pair/Comparison_Bode.png          # Tag='Hung_pair'
results/NTU_yoke/Comparison_Bode.png           # Tag='NTU_yoke'
```

---

## 舊腳本

`legacy/` 目錄包含 v2.0 架構的舊腳本：

- `Model_6_6_Continuous_Weighted.m` &mdash; MIMO 6&times;6 轉移函數擬合（自包含，透過 `eval` 載入 `P1.m`~`P6.m`）
- `P1.m` ~ `P6.m` &mdash; 6 通道頻率響應數據
- `legacy/functions/` &mdash; 12 個被 pipeline 取代的函數

執行舊版 MIMO 擬合：
```matlab
cd legacy
Model_6_6_Continuous_Weighted
```

---

**最後更新:** 2026-02-13
**版本:** 3.0
