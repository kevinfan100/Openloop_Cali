# Flux Controller Implementation Guide

## 📋 專案概述

本專案實現了三種基於差分方程式的磁通控制器設計，根據 `Flux_Control_B_merged.pdf` 文件。

### 控制器類型

| 類型 | 擾動模型 | 增益數量 | 複雜度 | 適用場景 |
|------|---------|---------|--------|---------|
| **Type 3** | 一階：`wT[k+1] = wT[k]` | 3 個 (l1, l2, l3) | 低 | 常數擾動 |
| **Type 2** | 二階（積分）：`wT[k+1] = wT[k] + δwT[k]` | 4 個 (l1, l2, l3, l4) | 中 | 斜坡擾動 |
| **Type 1** | 二階（參數化）：`w1[k+1] = (1+β)w1[k] - βw2[k]` | 4 個 + β | 高 | 可調擾動 |

---

## 🏗️ 檔案結構

```
Openloop_Cali/
│
├── controllers/                              # 控制器模型
│   ├── create_flux_controller_type3.m       ✅ 自動生成 Type 3 控制器
│   └── Flux_Controller_Type3.slx            （自動生成）
│
├── scripts/
│   ├── design/                              # 設計腳本
│   │   └── calculate_flux_controller_params.m  ✅ 計算所有參數
│   │
│   └── framework/                           # 框架腳本（現有）
│       ├── setup_controller.m
│       ├── run_simulation.m
│       └── analyze_results.m
│
├── examples/                                # 使用範例
│   └── example_flux_controller_type3.m      ✅ 完整測試範例
│
├── Mathematical_Derivation/                 # 數學推導
│   └── Flux_Control_B_merged.pdf
│
└── Control_System_Framework.slx             # 主控制框架（現有）
```

---

## 🔄 .m 和 .slx 的交互關係

### 工作流程圖

```
┌─────────────────────────────────────────────────────────────────┐
│                     Step 1: 建立模型                             │
│  create_flux_controller_type3.m                                 │
│         ↓                                                        │
│  Flux_Controller_Type3.slx                                      │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│                     Step 2: 計算參數                             │
│  calculate_flux_controller_params.m                             │
│         ↓                                                        │
│  MATLAB Workspace Variables:                                    │
│    • a1, a2, B, B_inv                                           │
│    • lambda_c, lambda_e                                         │
│    • l1, l2, l3 (estimator gains)                              │
│    • fb_coeff_1, fb_coeff_2                                     │
│    • Ts                                                          │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│                     Step 3: 執行模擬                             │
│  Simulink 讀取 workspace 變數                                   │
│         ↓                                                        │
│  sim('Flux_Controller_Type3')                                   │
│         ↓                                                        │
│  輸出: u[k], e[k]                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 關鍵概念

1. **.m 腳本**負責：
   - 數學計算（增益、參數）
   - 自動化建模
   - 數據分析

2. **.slx 模型**負責：
   - 差分方程式實現
   - 動態系統模擬
   - 視覺化信號流

3. **Workspace** 是橋樑：
   - `.m` 計算參數 → 寫入 workspace
   - `.slx` 讀取 workspace → 執行模擬

---

## 🚀 快速開始

### 方法 1: 使用完整範例（推薦）

```matlab
cd C:\Users\kevin\Desktop\code\Openloop_Cali
example_flux_controller_type3
```

這個腳本會自動：
1. 建立控制器模型
2. 計算參數
3. 執行測試
4. 顯示結果

### 方法 2: 手動步驟

```matlab
% 1. 建立控制器模型
addpath('controllers');
create_flux_controller_type3();

% 2. 設定系統參數
sys.a1 = 1.8;
sys.a2 = -0.85;
sys.B = eye(6);
sys.Ts = 1e-4;

% 3. 設定設計參數
design.lambda_c = 0.5;
design.lambda_e = 0.3;

% 4. 計算參數
addpath('scripts/design');
params = calculate_flux_controller_params(sys, design, 3);

% 5. 設定參考訊號
Vd_ref = ones(6,1);

% 6. 執行模擬
sim_time = 0.05;
sim('Flux_Controller_Type3');
```

---

## 📐 差分方程式在 Simulink 中的實現

### Unit Delay 的使用

```
差分方程式:  x[k+1] = f(x[k], ...)

Simulink 實現:
  [計算 x[k+1]] → [Unit Delay] → x[k]
                      ↑
                      └── 輸出到下一時間步
```

### Type 3 控制器結構

#### 1. 誤差計算
```
δv[k] = vd[k-1] - vm[k]

[Vd] → [Delay] → [Sum(+-)] → δv[k]
                     ↑
[Vm] ────────────────┘
```

#### 2. 前饋項
```
vff[k] = vd[k] - a1·vd[k-1] - a2·vd[k-2]

[Vd] ─┬────────────────────────────→ [Sum] → vff[k]
      ├→ [Delay] → [Gain: -a1] ────→   ↑
      └→ [Delay]² → [Gain: -a2] ───→   ↑
```

#### 3. 估測器
```
innovation[k] = δv[k] - ŝ₁[k]
ŝ₁[k+1] = λc·ŝ₁[k] + l1·innovation[k]
ŝ₂[k+1] = ŝ₁[k] + l2·innovation[k]
ŵT[k+1] = ŵT[k] + l3·innovation[k]

[δv] ─┬─→ [Sum(+-)] ──→ innovation
      │       ↑
      │   [ŝ₁[k]]
      │       ↓
      │   [3 個並行的估測器分支]
```

#### 4. 反饋項
```
δvfb[k] = (a1-λc)·ŝ₁[k] + a2·ŝ₂[k]

[ŝ₁] → [Gain: a1-λc] ─┐
                       ├→ [Sum] → δvfb[k]
[ŝ₂] → [Gain: a2] ────┘
```

#### 5. 控制律
```
u[k] = B⁻¹{vff[k] + δvfb[k] - ŵT[k]}

[vff] ──┐
[δvfb] ─┤→ [Sum(++-)] → [Gain: B⁻¹] → u[k]
[ŵT] ───┘
```

---

## ⚙️ 參數調整指南

### 控制參數 λc

```
λc = 0.1 ~ 0.3   快速響應，可能震盪
λc = 0.3 ~ 0.5   平衡性能（推薦）
λc = 0.5 ~ 0.7   穩定但響應慢
λc = 0.7 ~ 0.9   非常保守
```

### 估測器參數 λe

```
λe = 0.1 ~ 0.3   快速估測（推薦）
λe = 0.3 ~ 0.5   中等速度
λe > 0.5         估測較慢
```

### 調參建議

1. **先調 λc**：
   - 從 0.5 開始
   - 觀察控制訊號和誤差
   - 太震盪 → 增大 λc
   - 太慢 → 減小 λc

2. **再調 λe**：
   - 從 0.3 開始
   - λe 應該 < λc
   - 估測器應該比控制更快收斂

3. **驗證穩定性**：
   - 所有特徵值必須 < 1
   - 觀察長時間運行是否發散

---

## 🔧 整合到主框架

如果你想將控制器整合到 `Control_System_Framework.slx`：

```matlab
% 確保參數已計算
params = calculate_flux_controller_params(sys, design, 3);

% 整合控制器
addpath('scripts/framework');
setup_controller('Flux_Controller_Type3', params);

% 執行框架模擬
sim_results = run_simulation('Control_System_Framework', sim_time);
```

---

## 📊 與現有 PI 控制器的對比

| 特性 | PI 控制器 | Flux 控制器 |
|------|-----------|------------|
| 結構 | 6 個獨立通道 | 6×6 耦合系統 |
| 參數 | Kp, Ki (對角矩陣) | a1, a2, B, λc, λe |
| 擾動補償 | 無 | 有（估測器） |
| 前饋 | 無 | 有 |
| 複雜度 | 低 | 中 |
| 性能 | 基礎 | 進階 |

---

## 🐛 常見問題

### 1. 模型無法開啟
```matlab
% 確保路徑正確
addpath('controllers');
addpath('scripts/design');
addpath('scripts/framework');
```

### 2. 變數未定義
```matlab
% 重新計算參數
params = calculate_flux_controller_params(sys, design, 3);
```

### 3. 模擬發散
```
檢查:
• λc, λe 是否 < 1
• a1, a2 是否正確
• B 矩陣是否可逆
```

### 4. 性能不佳
```
調整:
• 減小 λc 加快響應
• 減小 λe 改善估測
• 檢查系統參數是否準確
```

---

## 📝 下一步

### 短期目標
- [ ] 執行 `example_flux_controller_type3.m` 驗證功能
- [ ] 調整參數觀察性能變化
- [ ] 整合到主框架進行閉迴路測試

### 中期目標
- [ ] 實現 Type 2 控制器（積分型擾動）
- [ ] 實現 Type 1 控制器（參數化擾動）
- [ ] 對比三種控制器性能

### 長期目標
- [ ] 實時硬體測試
- [ ] 自動調參工具
- [ ] 性能優化

---

## 📚 參考資料

- **數學推導**: `Mathematical_Derivation/Flux_Control_B_merged.pdf`
- **控制器結構**: `controllers/create_flux_controller_type3.m`
- **使用範例**: `examples/example_flux_controller_type3.m`

---

## 👤 作者

Claude Code
Date: 2025-10-11

---

## 📄 License

根據專案整體 license
