# 開迴路波德分析流程

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020a+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Python](https://img.shields.io/badge/Python-3.7+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

> **多通道控制系統的自動化頻率響應分析與 MIMO 轉移函數識別**

**繁體中文** | [English](README.md)

---

## 📋 目錄

- [專案概述](#專案概述)
- [專案結構](#專案結構)
- [工作流程](#工作流程)
- [環境需求](#環境需求)
- [安裝步驟](#安裝步驟)
- [快速開始](#快速開始)
- [詳細使用說明](#詳細使用說明)
- [配置指南](#配置指南)
- [輸出檔案說明](#輸出檔案說明)
- [常見問題](#常見問題)

---

## 🎯 專案概述

本專案提供一套完整的流程，用於從二進位測量數據進行**開迴路頻率響應分析**與 **MIMO（多輸入多輸出）轉移函數擬合**。

### 核心功能：
- ✅ **二進位轉 CSV**：將 HSData `.dat` 檔案轉換為 CSV 格式
- ✅ **自動化波德分析**：基於 FFT 的轉移函數提取與穩態檢測
- ✅ **MIMO 模型擬合**：6×6 轉移函數矩陣識別
- ✅ **穩健的信號處理**：先進的插值、雜訊處理與驗證



---

## 📁 專案結構

```
Openloop_cali/
│
├── README.md                          # 英文說明文件
├── README_zh-TW.md                    # 本檔案（繁體中文）
├── requirements.txt                   # Python 套件需求
│
├── hsdata_reader.py                   # 階段 1：二進位轉 CSV
├── openloop_bode.m                    # 階段 2：波德分析
├── Model_6_6_Continuous_Weighted.m    # 階段 3：MIMO 模型擬合
│
├── raw_data/                          # 輸入：二進位數據檔案
│   ├── P1/
│   │   ├── 0.1Hz.dat
│   │   ├── 1Hz.dat
│   │   ├── 10Hz.dat
│   │   ├── 50Hz.dat
│   │   ├── 100Hz.dat
│   │   ├── ... (共 19 個頻率)
│   │   └── 2000Hz.dat
│   ├── P2/
│   │   └── ... (相同結構)
│   ├── P3/
│   ├── P4/
│   ├── P5/
│   └── P6/
│
├── processed_csv/                     # 階段 1 輸出：CSV 檔案
│   ├── P1/
│   │   ├── 0.1Hz.csv
│   │   ├── 1Hz.csv
│   │   └── ... (19 個檔案)
│   ├── P2/
│   └── ... (P3~P6)
│
├── P1.m                               # 階段 2 輸出：頻率響應
├── P2.m
├── P3.m
├── P4.m
├── P5.m
├── P6.m
│
├── transfer_function_latex.txt        # 階段 3 輸出：統一 MIMO 模型
└── one_curve_36_results.mat           # 階段 3 輸出：36 組獨立轉移函數 (新增)
```

---

## 🔄 工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      階段 1：資料轉換                           │
│                                                                 │
│  原始二進位數據 (.dat)                                         │
│         │                                                       │
│         ├─ P1/0.1Hz.dat, 1Hz.dat, 10Hz.dat, ...               │
│         ├─ P2/0.1Hz.dat, 1Hz.dat, 10Hz.dat, ...               │
│         └─ ... (P3 ~ P6)                                       │
│         ↓                                                       │
│  [ hsdata_reader.py ]                                          │
│         ↓                                                       │
│  CSV 檔案 (vm_0~5, vd_0~5, da_0~5)                            │
│         │                                                       │
│         └─ processed_csv/P1/*.csv                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                      階段 2：波德分析                           │
│                                                                 │
│  CSV 檔案                                                       │
│         ↓                                                       │
│  [ openloop_bode.m ]                                           │
│         │                                                       │
│         ├─ 數據修復（插值）                                   │
│         ├─ 激勵檢測                                           │
│         ├─ 穩態檢測                                           │
│         ├─ FFT 分析 (H = VM/DA)                               │
│         └─ 相位處理                                           │
│         ↓                                                       │
│  頻率響應數據 (P1.m ~ P6.m)                                    │
│         │                                                       │
│         └─ 變數：frequencies, magnitudes_linear,              │
│            phases, phases_processed                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                      階段 3：模型擬合                           │
│                                                                 │
│  P1.m ~ P6.m                                                    │
│         ↓                                                       │
│  [ Model_6_6_Continuous_Weighted.m ]                           │
│         │                                                       │
│         ├─ 載入 6×6 頻率響應矩陣                               │
│         ├─ 加權曲線擬合 (H(s) = ωn²/(s²+2ζωn·s+ωn²))         │
│         ├─ ZOH 連續時間至離散時間轉換                          │
│         └─ 產生 LaTeX 輸出                                     │
│         ↓                                                       │
│  MIMO 轉移函數模型                                             │
│         │                                                       │
│         ├─ 連續時間：H(s)                                      │
│         ├─ 離散時間：H(z⁻¹)                                    │
│         └─ LaTeX：transfer_function_latex.txt                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 環境需求

### 軟體需求

| 軟體 | 版本 | 用途 |
|------|------|------|
| **Python** | 3.7+ | 資料轉換（階段 1） |
| **MATLAB** | R2020a+ | 分析與建模（階段 2 & 3） |

### MATLAB 工具箱
- Control System Toolbox（控制系統工具箱）
- Signal Processing Toolbox（信號處理工具箱）

### Python 套件
```bash
pip install -r requirements.txt
```

**必要套件：**
- `numpy >= 1.20.0`
- `pandas >= 1.3.0`
- `tqdm >= 4.60.0`

---

## 🚀 安裝步驟

### 1. 複製或下載專案
```bash
cd /path/to/your/workspace
# 下載或複製 Openloop_cali 資料夾
```

### 2. 安裝 Python 套件
```bash
cd Openloop_cali
pip install -r requirements.txt
```

### 3. 驗證 MATLAB 安裝
```matlab
% 在 MATLAB 命令視窗中
ver  % 檢查已安裝的工具箱
```

### 4. 準備資料資料夾
```bash
Openloop_cali/
├── raw_data/          # 將 .dat 檔案放在這裡
│   ├── P1/
│   │   ├── 0.1Hz.dat
│   │   ├── 1Hz.dat
│   │   └── ...
│   ├── P2/
│   └── ... (P3~P6)
└── processed_csv/     # 由 hsdata_reader.py 自動建立
```

---

## ⚡ 快速開始

### 完整流程（3 步驟）

```bash
# 進入專案目錄
cd /path/to/Openloop_cali

# 步驟 1：轉換所有二進位數據為 CSV (P1~P6)
python hsdata_reader.py all

# 步驟 2：分析每個通道的頻率響應（在 MATLAB 中）
# 在專案目錄中開啟 MATLAB，然後執行：
```

```matlab
% 處理所有通道 P1~P6
for i = 1:6
    folder = fullfile(pwd, 'processed_csv', sprintf('P%d', i));
    openloop_bode(folder);
end
```

```bash
# 步驟 3：擬合 MIMO 轉移函數模型（在 MATLAB 中）
```

```matlab
% 執行模型擬合腳本
run('Model_6_6_Continuous_Weighted.m')
```

### 處理單一通道（範例：僅 P1）

```bash
# 步驟 1：僅轉換 P1 數據
python hsdata_reader.py P1

# 步驟 2：分析 P1（在 MATLAB 中）
```

```matlab
openloop_bode(fullfile(pwd, 'processed_csv', 'P1'))
```

---

## 📖 詳細使用說明

### 階段 1：資料轉換

**指令：**
```bash
python hsdata_reader.py <資料夾名稱>
```

**選項：**
- `P1`, `P2`, ..., `P6` - 處理單一資料夾
- `all` - 處理所有 P1~P6 資料夾
- （無參數） - 顯示說明訊息

**範例：**
```bash
# 處理所有資料夾
python hsdata_reader.py all

# 僅處理 P1
python hsdata_reader.py P1
```

**輸出：**
- 建立 `processed_csv/P1/*.csv`，包含欄位：
  - `index`, `vm_0~5`, `vd_0~5`, `da_0~5`

**進度顯示：**
```
==========================================================
Processing folder: P1
Input:  /path/to/raw_data/P1
Output: /path/to/processed_csv/P1
Files:  19 .dat files found
==========================================================
Converting P1: 100%|████████████| 19/19 [00:05<00:00, 3.2file/s]

✓ Folder 'P1' completed:
  - Successfully processed: 19 files
```

---

### 階段 2：波德分析

**指令（MATLAB）：**
```matlab
% 使用預設路徑 (processed_csv/P1)
openloop_bode()

% 或指定自訂路徑
openloop_bode('path/to/processed_csv/P2')
```

**處理步驟：**
1. 載入 CSV 數據
2. 修復壞點（每 10000 個樣本）
3. 檢測激勵通道與頻率
4. 檢測穩態區域
5. 執行 FFT 分析 (H = VM/DA)
6. 處理相位數據（180° 校正）
7. 產生波德圖
8. 儲存結果至 `P1.m`（或 P2.m 等）

**輸出範例：**
```
=== OPENLOOP BODE ANALYSIS ===
Data folder: C:\...\processed_csv\P1
Found 19 CSV files

[1/19] Processing: 0.1Hz.csv (5.2 MB)
  Step 1: Loading CSV data...
  Step 2: Repairing bad data points...
    Using interpolation method: spline
    VM repair RMS error: 0.000012 V (average)
    DA repair RMS error: 0.000008 V (average)
    Total data points: 100000, Repaired points: 10
  Step 3: Detecting excitation channel and frequency...
    Excitation: DA1, Frequency: 0.1 Hz
  Step 4: Steady-state detection...
    Period samples: 1000000, Max periods: 10
    Steady-state detected: Period 5, Index 5000001
  Step 5: FFT analysis (mode: full)...
    Using full FFT: 5 periods
  ✓ Successfully processed frequency 0.1 Hz

[2/19] Processing: 1Hz.csv (5.2 MB)
...

=== ANALYSIS COMPLETE ===
Successfully processed: 19 frequency points
Frequency range: 0.1 - 2000.0 Hz

Saving Bode data to: C:\...\P1.m...
✓ Bode data saved successfully

=== ALL OPERATIONS COMPLETE ===
```

**產生的檔案：**
- `P1.m`（或 P2.m 等）- MATLAB 資料檔案，包含變數：
  - `frequencies` - 頻率點 (Hz)
  - `magnitudes_linear` - 線性幅度 (6 × N)
  - `phases` - 原始相位（度）
  - `phases_processed` - 處理後相位（含 180° 校正）

**波德圖視覺化：**
- 雙面板圖（幅度與相位）
- 繪製所有 6 個通道
- 理論模型疊加
- 自動儲存為 MATLAB 圖形

---

### 階段 3：MIMO 模型擬合

**指令（MATLAB）：**
```matlab
run('Model_6_6_Continuous_Weighted.m')
```

**需求：**
- 所有 `P1.m ~ P6.m` 檔案必須存在於專案目錄中

**處理流程：**
1. 從 P1~P6.m 載入 6×6 頻率響應矩陣
2. **（可選）批次單曲線擬合** - 產生 36 組獨立轉移函數
3. 對所有 36 個元素執行統一的多曲線擬合
4. 應用加權最小平方最佳化
5. 執行 ZOH 連續時間至離散時間轉換（T = 10 μs）
6. 產生 LaTeX 輸出

**輸出檔案：**
- `transfer_function_latex.txt` - LaTeX 格式統一 MIMO 模型
- `one_curve_36_results.mat` - **（新增）** 36 組獨立轉移函數參數

**輸出格式範例：**
```latex
% Continuous Transfer Function H(s)
H_{11}(s) = \frac{1.4848 \times 10^7}{s^2 + 8187.7 s + 1.4848 \times 10^7}

% Discrete Transfer Function H(z^{-1})
H_{11}(z^{-1}) = \frac{0.3618 (3.6963 \times 10^{-6} z^{-1} + ...}{1 - 1.9181 z^{-1} + 0.9182 z^{-2}}
```

---

## ⚙️ 配置指南

### `openloop_bode.m` - Section 1 參數

所有可調整參數集中於檔案頂部（第 28-56 行）。

#### 檔案 I/O 配置
```matlab
% 自動偵測（無需手動編輯）
SCRIPT_DIR = fileparts(mfilename('fullpath'));
DEFAULT_DATA_FOLDER = fullfile(SCRIPT_DIR, 'processed_csv', 'P1');
OUTPUT_BASE_FOLDER = SCRIPT_DIR;
```

#### 信號處理參數
| 參數 | 預設值 | 說明 | 建議值 |
|------|--------|------|--------|
| `SAMPLING_RATE` | 100000 | 採樣率 (Hz) | 100000（固定） |
| `MIN_DA_THRESHOLD` | 1e-10 | FFT 有效的最小 DA 信號 | 1e-10 ~ 1e-8 |
| `INTERPOLATION_METHOD` | `'spline'` | 壞點修復方法 | `'spline'`, `'pchip'`, `'makima'`, `'linear'` |

#### 穩態檢測參數
| 參數 | 預設值 | 說明 | 調整建議 |
|------|--------|------|----------|
| `STABILITY_THRESHOLD` | 2e-3 | 週期間最大電壓差 (V) | 有誤判時增加，需嚴格檢測時減少 |
| `CONSECUTIVE_PERIODS` | 3 | 需連續穩定的週期數 | SNR 好時 3-5，雜訊大時 1-2 |
| `CHECK_POINTS` | 25 | 每週期比較的取樣點數 | 一般 20-30 |
| `START_PERIOD` | 1 | 檢測起始週期索引 | 1（跳過暫態時 > 1） |

#### FFT 分析配置
| 參數 | 預設值 | 說明 | 使用情境 |
|------|--------|------|----------|
| `FFT_MODE` | `'full'` | FFT 計算模式 | `'full'`（預設）、`'averaged'`（降低雜訊） |
| `COMPARE_FFT_METHODS` | `false` | 啟用 FFT 方法比較 | `true` 用於除錯 |

#### 視覺化設定
| 參數 | 預設值 | 說明 |
|------|--------|------|
| `CHANNEL_COLORS` | `['k','b','g','r','m','c']` | 6 個通道的繪圖顏色 |
| `DISPLAY_CHANNELS` | `[1,2,3,4,5,6]` | 波德圖顯示的通道 |
| `PLOT_STEADY_STATE` | `true` | 啟用穩態疊圖 |
| `PLOT_CHANNEL` | `[1]` | 疊圖通道（0=全部，1-6=特定） |
| `PLOT_FREQUENCY_LIST` | `[0.1]` | 繪製的頻率（空=全部） |

#### 模型參數（理論曲線）
```matlab
MODEL_WN_SQUARED = 1.4848e7;      % 自然頻率平方 (rad²/s²)
MODEL_TWO_ZETA_WN = 8.1877e3;     % 2ζωn (rad/s)
```

---

### `Model_6_6_Continuous_Weighted.m` - Section 1 參數

所有可調整參數集中於檔案頂部（第 23-72 行）。

#### 36 通道獨立擬合控制 **(新增)**
| 參數 | 預設值 | 說明 |
|------|--------|------|
| `SAVE_ONE_CURVE_RESULTS` | `true` | 啟用 36 組獨立轉移函數擬合與儲存 |
| `ONE_CURVE_OUTPUT_FILE` | `'one_curve_36_results.mat'` | 輸出檔案名稱 |

**使用場景：**
```matlab
% 啟用：產生 36 組獨立模型供 Simulink 使用
SAVE_ONE_CURVE_RESULTS = true;

% 停用：僅產生統一 MIMO 模型，節省計算時間
SAVE_ONE_CURVE_RESULTS = false;
```

#### 單曲線擬合參數
| 參數 | 預設值 | 說明 |
|------|--------|------|
| `p_single` | 0.5 | 加權指數 |
| `wc_single_Hz` | 50 | 截止頻率 (Hz) |

**註：**這些參數同時用於 SECTION 4（單一驗證）和 SECTION 4.5（36 通道批次擬合）

#### 多曲線擬合參數
| 參數 | 預設值 | 說明 |
|------|--------|------|
| `p_multi` | 0.5 | 加權指數 |
| `wc_multi_Hz` | 0.1 | 截止頻率 (Hz) |

#### 視覺化控制
| 參數 | 預設值 | 說明 |
|------|--------|------|
| `PLOT_ONE_CURVE` | `false` | 繪製單曲線 Bode 圖 |
| `PLOT_MULTI_CURVE` | `false` | 繪製多曲線 Bode 圖 |
| `OUTPUT_LATEX` | `true` | 產生 LaTeX 輸出檔案 |

---

### 常見配置場景

**場景 1：雜訊數據**
```matlab
STABILITY_THRESHOLD = 5e-3;       % 放寬閾值
CONSECUTIVE_PERIODS = 5;          % 需要更多穩定週期
FFT_MODE = 'averaged';            % 使用週期平均
```

**場景 2：快速處理（跳過視覺化）**
```matlab
PLOT_STEADY_STATE = false;        % 停用疊圖
PLOT_FREQUENCY_LIST = [];         % 不繪製任何頻率
```

**場景 3：除錯模式**
```matlab
COMPARE_FFT_METHODS = true;       % 比較 FFT 方法
PLOT_STEADY_STATE = true;
PLOT_CHANNEL = 0;                 % 繪製所有通道
PLOT_FREQUENCY_LIST = [];         % 繪製所有頻率
```

---

## 📂 輸出檔案說明

### 階段 1：CSV 檔案

**位置：** `processed_csv/P1/*.csv`

**格式：**
```csv
index,vm_0,vm_1,vm_2,vm_3,vm_4,vm_5,vd_0,...,da_5
0,0.0012,0.0034,...,32768
1,0.0013,0.0035,...,32769
...
```

**欄位（共 19 欄）：**
- `index` - 樣本索引
- `vm_0 ~ vm_5` - VM 電壓測量值（6 通道）
- `vd_0 ~ vd_5` - VD 電壓測量值（6 通道）
- `da_0 ~ da_5` - DA 數位值（6 通道，0-65535）

---

### 階段 2：頻率響應數據檔案

**位置：** `P1.m`, `P2.m`, ..., `P6.m`

**變數：**

| 變數 | 維度 | 說明 | 範例 |
|------|------|------|------|
| `frequencies` | 1 × N | 頻率點 (Hz) | `[0.1, 1.0, 10.0, ...]` |
| `magnitudes_linear` | 6 × N | 線性幅度 (V/V) | `[0.237, 0.233, ...]` |
| `phases` | 6 × N | 原始相位（度） | `[169.75, 169.65, ...]` |
| `phases_processed` | 6 × N | 處理後相位（度） | `[-10.25, -10.35, ...]` |

**使用範例：**
```matlab
% 載入 P1 數據
run('P1.m')

% 繪製通道 1 的幅度
figure;
semilogx(frequencies, 20*log10(magnitudes_linear(1,:)));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('P1 Channel 1 Frequency Response');

% 繪製所有通道的處理後相位
figure;
semilogx(frequencies, phases_processed');
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');
legend('P1','P2','P3','P4','P5','P6');
```

---

### 階段 3：轉移函數模型

#### 3.1 統一 MIMO 模型

**位置：** `transfer_function_latex.txt`

**內容：**
- 連續時間轉移函數 H(s) - 統一的二階系統 + 增益矩陣 B
- 離散時間轉移函數 H(z⁻¹) - ZOH 連續至離散轉換版本
- LaTeX 格式，可直接插入文件

**模型形式：**
```
H(s) = [ωn² / (s² + 2ζωn·s + ωn²)] · B
```
其中所有 36 個輸入-輸出路徑共用相同的分母，僅增益矩陣 B 不同。

---

#### 3.2 獨立轉移函數參數 **(新增)**

**位置：** `one_curve_36_results.mat`

**控制開關（在 `Model_6_6_Continuous_Weighted.m` line 71）：**
```matlab
SAVE_ONE_CURVE_RESULTS = true;   % 啟用（預設）
SAVE_ONE_CURVE_RESULTS = false;  % 停用
```

**用途：**
- 為每個輸入-輸出路徑產生**獨立的**二階轉移函數參數
- 用於 Simulink 中建立更精確的 MIMO 模型
- 適合測試針對統一模型設計的控制器在「真實」非統一系統上的表現

**資料結構：**
```matlab
load('one_curve_36_results.mat');

% 檢視結構
one_curve_results
  ├── a1_matrix (6×6 double)  % 一階係數矩陣
  ├── a2_matrix (6×6 double)  % 二階係數矩陣
  ├── b_matrix  (6×6 double)  % 分子增益矩陣
  └── meta      (struct)      % 元數據
      ├── date: '2025-10-06 15:30:00'
      ├── p: 0.5              % 加權指數
      ├── wc_Hz: 50           % 截止頻率
      ├── frequencies: [19×1] % 頻率向量
      ├── num_channels: 6
      └── description: '36-channel individual transfer functions (continuous)'
```

**轉移函數定義：**
```
從輸入通道 j 到輸出通道 i 的轉移函數：

           b_matrix(i,j)
H_ij(s) = ──────────────────────────────────
          s² + a1_matrix(i,j)·s + a2_matrix(i,j)
```

**使用範例：**
```matlab
% 載入獨立轉移函數參數
load('one_curve_36_results.mat');

% 建立從輸入通道 3 到輸出通道 2 的轉移函數
i = 2;  % 輸出通道
j = 3;  % 輸入通道

a1_val = one_curve_results.a1_matrix(i, j);
a2_val = one_curve_results.a2_matrix(i, j);
b_val  = one_curve_results.b_matrix(i, j);

% 建立轉移函數物件
H_23 = tf(b_val, [1, a1_val, a2_val]);

% 分析
bode(H_23);
step(H_23);

% 查看所有 36 組參數
disp('一階係數 (a1):');
disp(one_curve_results.a1_matrix);

disp('二階係數 (a2):');
disp(one_curve_results.a2_matrix);

disp('分子增益 (b):');
disp(one_curve_results.b_matrix);
```

**與統一模型的差異：**

| 項目 | 統一 MIMO 模型 | 36 組獨立模型 |
|------|---------------|--------------|
| **分母** | 所有路徑共用 | 每個路徑獨立 |
| **自由度** | 低（2 參數 + 36 增益） | 高（108 參數） |
| **控制設計** | 簡單、統一 | 複雜、個別調整 |
| **真實度** | 近似 | 更接近實際系統 |
| **用途** | 控制器設計 | 模擬驗證、測試 |
| **檔案** | `transfer_function_latex.txt` | `one_curve_36_results.mat` |

**典型應用流程：**
1. 使用**統一模型**設計控制器（簡化、易分析）
2. 使用 **36 組獨立模型**在 Simulink 中測試控制器
3. 驗證控制器在非理想系統上的穩健性

---

## 🔧 常見問題

### 常見錯誤

#### ❌ **錯誤：「No CSV files found in folder」**

**原因：**階段 1 未完成或資料夾路徑錯誤

**解決方法：**
```bash
# 檢查 CSV 檔案是否存在
ls processed_csv/P1/

# 如果是空的，先執行階段 1
python hsdata_reader.py P1
```

---

#### ⚠️ **警告：「Frequency mismatch - target X Hz, actual Y Hz」**

**原因：** FFT bin 未精確匹配激勵頻率

**影響：** 取決於相對誤差大小

| 激勵頻率 | 可接受誤差 | 範例 |
|---------|-----------|------|
| 0.1 ~ 1 Hz | < 0.01 Hz | 0.1 Hz 誤差 0.05 Hz → 50% 誤差，❌ 需處理 |
| 1 ~ 10 Hz | < 0.05 Hz | 5 Hz 誤差 0.05 Hz → 1% 誤差，✅ 可接受 |
| 10 ~ 100 Hz | < 0.1 Hz | 50 Hz 誤差 0.1 Hz → 0.2% 誤差，✅ 可接受 |
| 100 ~ 1000 Hz | < 0.5 Hz | 500 Hz 誤差 0.5 Hz → 0.1% 誤差，✅ 可接受 |
| 1000 ~ 2000 Hz | < 1 Hz | 1500 Hz 誤差 1 Hz → 0.07% 誤差，✅ 可接受 |

**判斷原則：** 相對誤差 < 1% 時通常可忽略

**解決方法（如需要）：**
- 檢查原始數據檔名是否符合實際頻率
- 驗證採樣率設定正確（100 kHz）
- 確認數據長度足夠（至少 5 個完整週期）

---

#### ⚠️ **警告：「No stable period found (threshold 0.0020V)」**

**原因：**信號未達穩態或閾值過於嚴格

**解決方法：**

**選項 1：放寬閾值**
```matlab
STABILITY_THRESHOLD = 5e-3;  % 從 2e-3 增加
```

**選項 2：減少需連續的週期數**
```matlab
CONSECUTIVE_PERIODS = 2;     % 從 3 減少
```

**選項 3：跳過初始暫態**
```matlab
START_PERIOD = 3;            % 從週期 3 開始
```

---

#### ⚠️ **警告：「Insufficient periods (only X), using last period as steady-state」**

**原因：**數據檔案太短（< 5 個完整週期）

**影響：**結果可能包含暫態響應，可靠性較低

**解決方法：**
- 使用較長的數據擷取時間
- 驗證數據檔案完整（未截斷）
- 接受較低可靠性（程式仍會執行）

---

#### ⚠️ **警告：「Requested end_index exceeds data length」**

**原因：** 程式計算的數據範圍超出實際數據長度

**常見原因：**
1. 穩態檢測在數據尾端，剩餘數據不足
2. 數據檔案被截斷（未完整保存）
3. 可用週期數計算過於樂觀

**程式自動處理：**
- ✅ 顯示警告訊息
- ✅ 自動裁剪到數據末端
- ✅ 嘗試繼續執行 FFT 分析

**如何判斷是否需要處理：**

**情況 1：後續處理成功**
```
Warning CH1: Requested end_index (100999) exceeds data length (100000)
...
✓ Successfully processed frequency 100.0 Hz
```
→ **無需處理**，程式已自動恢復，結果可信

**情況 2：後續處理失敗**
```
Warning CH1: Requested end_index (100999) exceeds data length (100000)
Warning CH1: Insufficient data (999 samples) for one period (2000 samples)
✗ Processing failed: ...
```
→ **需要處理**：
- 檢查原始 .dat 檔案是否完整
- 驗證 CSV 轉換過程
- 考慮使用更長的數據擷取時間

---

#### ❌ **階段 3 錯誤：「Undefined function or variable 'P1'」**

**原因：**P1.m ~ P6.m 檔案未產生

**解決方法：**
```matlab
% 驗證所有檔案存在
dir('P*.m')

% 如果缺失，重新執行階段 2
openloop_bode(fullfile(pwd, 'processed_csv', 'P1'))
```

---

### 除錯模式

啟用詳細診斷：

```matlab
% 在 openloop_bode.m 的 Section 1
FFT_MODE = 'averaged';
COMPARE_FFT_METHODS = true;      % 比較 FFT 方法
PLOT_STEADY_STATE = true;        % 顯示波形疊圖
PLOT_CHANNEL = 0;                % 繪製所有通道
PLOT_FREQUENCY_LIST = [];        % 繪製所有頻率
```

這將產生：
- FFT 方法比較統計
- 所有頻率的穩態波形圖
- 詳細的主控台輸出

---

**最後更新：** 2025-10-05
**版本：** 2.0
