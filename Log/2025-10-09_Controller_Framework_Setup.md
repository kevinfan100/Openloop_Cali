# 控制器框架建立紀錄

**標題：** Controller Framework Setup - Modular PI Controller Implementation
**日期：** 2025-10-09
**分支：** `controller-framework-setup`
**作者：** Claude Code

---

## 📋 目錄

1. [專案概述](#專案概述)
2. [架構設計討論](#架構設計討論)
3. [實作內容](#實作內容)
4. [檔案結構](#檔案結構)
5. [工作流程說明](#工作流程說明)
6. [Git 提交記錄](#git-提交記錄)
7. [使用指南](#使用指南)
8. [未來擴展](#未來擴展)

---

## 專案概述

### 背景
專案中已建立 `Control_System_Framework.slx`，包含完整的 Plant 模型（DAC + 36個轉移函數 + ADC），但缺少控制器部分。

### 目標
建立**模組化的控制器框架**，支援多種控制器類型（PI、反饋線性化、滑模、自適應等），並實現：
1. 控制器模型獨立設計與測試
2. 統一的接口標準（輸入 Vd, Vm；輸出 u, e）
3. 自動化的整合、模擬、分析流程
4. 可重用的腳本與工具

### 核心理念
**控制器架構 = 回授控制 + 前饋控制 + 狀態估測器**

因此控制器需要接收：
- `Vd` (參考訊號) - 用於前饋控制
- `Vm` (測量輸出) - 用於回授和狀態估測

而非僅接收誤差 `e`。

---

## 架構設計討論

### 問題 1: 整體架構
**使用者需求：**
> 我想要一種控制器就獨立一個控制器的組，但是 Control_System_Framework.slx 是共用的，且最後的輸出與分析也是共用的。

**解決方案：**
```
專案結構/
├── Control_System_Framework.slx        # 共用系統框架
├── controllers/
│   ├── PI_controller.slx              # 獨立控制器模型 1
│   ├── Feedback_Lin_controller.slx    # 獨立控制器模型 2
│   └── Sliding_Mode_controller.slx    # 獨立控制器模型 3
├── scripts/
│   ├── setup_controller.m             # 共用整合腳本
│   ├── run_simulation.m               # 共用模擬腳本
│   └── analyze_results.m              # 共用分析腳本
└── results/
    └── (各控制器的模擬結果)
```

**優點：**
- ✅ 模組化：每個控制器獨立開發、測試、維護
- ✅ 可重用：共用 Plant 模型和分析工具
- ✅ 易比較：統一接口，方便性能比較
- ✅ 清晰：結構清楚，易於管理

### 問題 2: 控制器接口
**使用者澄清：**
> 控制器的組成應該是回授控制+前饋+估測器，給控制器的接口輸入應該為 Vm, Vd，輸出應該是 u。

**修改前：**
```
e_out (6×1) → [控制器] → u_in (6×1)
```

**修改後：**
```
Vd (6×1) ─┬→ [控制器] → u (6×1)
Vm (6×1) ─┘         └→ e (6×1, 監測用)
```

**實現方式：**
1. 刪除 `e_out` 輸出埠
2. 控制器直接接收 `Vd` 和 `Vm`
3. 控制器內部計算誤差 `e = Vd - Vm`
4. 控制器輸出 `u`（控制訊號）和 `e`（供監測）

---

## 實作內容

### Phase 1: 修改系統框架
**檔案：** `Control_System_Framework.slx`, `modify_framework_for_controller.m`

**修改內容：**
1. 移除 `e_out` 輸出埠及相關連線
2. 保留 `u_in` 輸入埠
3. 更新模型標註，說明新接口
4. 建立自動化修改腳本

**結果：**
- 控制器接口標準化：`Vd, Vm → Controller → u`
- 靈活支援複雜控制架構（回授+前饋+估測）

### Phase 2: 建立資料夾結構
**新增資料夾：**
```
controllers/   - 控制器模型 (.slx)
scripts/       - 自動化腳本 (.m)
results/       - 模擬結果 (.mat, .fig, .png)
Log/           - 文件與紀錄 (.md)
```

**更新 .gitignore：**
- 排除模擬結果檔案（`results/*.mat`, `*.fig`, `*.png`）
- 保留資料夾結構（`.gitkeep`）
- 忽略 Simulink 備份檔（`*.slx.r2024a`）

### Phase 3: 建立 PI 控制器
**檔案：** `controllers/PI_controller.slx`, `create_PI_controller.m`

**設計：**
- **輸入埠：** Vd (6×1), Vm (6×1)
- **輸出埠：** u (6×1), e (6×1)
- **架構：** 6 個獨立的離散 PI 控制器（解耦 MIMO）
- **控制律：**
  ```
  e[k] = Vd[k] - Vm[k]
  u[k] = Kp * e[k] + Ki * Ts * Σe[i]  (i=0 to k)
  ```
- **參數：**
  - `Kp`: 6×6 對角矩陣（比例增益）
  - `Ki`: 6×6 對角矩陣（積分增益）
  - `Ts_controller`: 採樣時間（預設 1e-5 秒）

**實現方式：**
- 使用 Simulink 內建的 `Discrete PID Controller` block
- 設定 D=0（僅 PI）
- 參數從 MATLAB workspace 讀取

### Phase 4: 建立自動化腳本
建立 4 個核心腳本，實現完整的自動化工作流程：

#### 1. `setup_controller.m`
**功能：** 將控制器模型整合到系統框架

**主要步驟：**
1. 載入框架模型
2. 刪除舊控制器（如果存在）
3. 添加 Model Reference block
4. 設定控制器模型名稱
5. 連接訊號線（Vd, Vm → Controller → u_in）
6. 設定參數到 workspace
7. 儲存框架

**使用範例：**
```matlab
params.Kp = diag([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]);
params.Ki = diag([10, 10, 10, 10, 10, 10]);
params.Ts_controller = 1e-5;
setup_controller('PI_controller', params);
```

#### 2. `run_simulation.m`
**功能：** 執行 Simulink 模擬並回傳結果

**主要步驟：**
1. 設定求解器參數（Solver, MaxStep, RelTol）
2. 執行 `sim()` 函數
3. 從 workspace 提取結果（u, e, Vm, Vm_analog）
4. 計算最終值
5. 顯示摘要

**回傳結構：**
```matlab
sim_results.t          % 時間向量 (N×1)
sim_results.u          % 控制訊號 (N×6)
sim_results.e          % 誤差 (N×6)
sim_results.Vm         % 測量輸出 (N×6)
sim_results.Vm_analog  % 類比輸出 (N×6)
sim_results.Vm_final   % 最終值 (6×1)
sim_results.e_final    % 最終誤差 (6×1)
```

**使用範例：**
```matlab
sim_results = run_simulation('Control_System_Framework', 0.01);
```

#### 3. `analyze_results.m`
**功能：** 計算性能指標並繪圖

**性能指標：**
- Settling Time（穩定時間，2% 誤差帶）
- Rise Time（上升時間，10% → 90%）
- Overshoot（超調量，%）
- Steady-State Error（穩態誤差）
- Peak Time & Value（峰值時間與值）

**繪圖：**
- 18 個子圖（6 通道 × 3 訊號）
  - Row 1: 輸出響應（Vm）
  - Row 2: 誤差（e）
  - Row 3: 控制訊號（u）
- 自動標註穩定時間、參考值
- 可儲存 .fig 和 .png

**使用範例：**
```matlab
plot_options.save_fig = true;
plot_options.fig_name = 'results/PI_performance.fig';
performance = analyze_results(sim_results, 1, plot_options);
```

#### 4. `example_run_PI.m`
**功能：** 完整的 PI 控制器測試範例

**工作流程：**
```
Step 1: 設定 PI 參數 (Kp, Ki, Ts)
   ↓
Step 2: 整合控制器到框架 (setup_controller)
   ↓
Step 3: 設定參考訊號 (Vd)
   ↓
Step 4: 執行模擬 (run_simulation)
   ↓
Step 5: 分析結果 (analyze_results)
   ↓
Step 6: 儲存結果 (.mat, .txt, .fig, .png)
```

**產生檔案：**
- `results/PI_controller_results.mat` - 完整數據
- `results/PI_controller_report.txt` - 性能報告
- `results/PI_controller_performance.fig` - 圖表（可編輯）
- `results/PI_controller_performance.png` - 圖表（靜態）

**使用方式：**
```matlab
% 直接執行
example_run_PI
```

---

## 檔案結構

### 完整目錄樹
```
Openloop_Cali/
│
├── Control_System_Framework.slx         # 共用系統框架（已修改）
├── modify_framework_for_controller.m    # 框架修改腳本
│
├── controllers/                         # 控制器模型
│   ├── PI_controller.slx               # PI 控制器模型
│   └── create_PI_controller.m          # PI 控制器生成腳本
│
├── scripts/                             # 自動化腳本
│   ├── setup_controller.m              # 整合腳本
│   ├── run_simulation.m                # 模擬腳本
│   ├── analyze_results.m               # 分析腳本
│   └── example_run_PI.m                # 完整範例
│
├── results/                             # 模擬結果（git 忽略）
│   ├── PI_controller_results.mat
│   ├── PI_controller_report.txt
│   ├── PI_controller_performance.fig
│   └── PI_controller_performance.png
│
├── Log/                                 # 文件與紀錄
│   └── 2025-10-09_Controller_Framework_Setup.md  (本文件)
│
└── .gitignore                          # 更新（排除結果檔案）
```

### 關鍵檔案說明

| 檔案 | 類型 | 說明 |
|------|------|------|
| `Control_System_Framework.slx` | Simulink | 共用系統框架（Plant + DAC/ADC） |
| `PI_controller.slx` | Simulink | PI 控制器模型（獨立） |
| `setup_controller.m` | MATLAB | 控制器整合腳本 |
| `run_simulation.m` | MATLAB | 模擬執行腳本 |
| `analyze_results.m` | MATLAB | 性能分析腳本 |
| `example_run_PI.m` | MATLAB | 完整測試範例 |

---

## 工作流程說明

### 流程圖
```
[使用者] → [example_run_PI.m] → [setup_controller.m] → [修改 Framework.slx]
                ↓
        [run_simulation.m] → [執行 Simulink 模擬]
                ↓
        [Simulink] → [儲存結果到 workspace: u, e, Vm, Vm_analog]
                ↓
        [run_simulation.m] → [提取結果到 sim_results 結構]
                ↓
        [analyze_results.m] → [計算性能指標 + 繪圖]
                ↓
        [儲存結果] → [.mat, .txt, .fig, .png]
```

### 詳細步驟

#### Step 1: 參數設定
```matlab
Kp = diag([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]);
Ki = diag([10, 10, 10, 10, 10, 10]);
Ts_controller = 1e-5;
```

#### Step 2: 整合控制器
```matlab
setup_controller('PI_controller', params);
```
**內部運作：**
1. 打開 `Control_System_Framework.slx`
2. 插入 Model Reference block → 指向 `PI_controller.slx`
3. 連接訊號：
   - `Vd/1` → `Controller/1`
   - `Mux_Vm/1` → `Controller/2`
   - `Controller/1` → `u_in/1`
   - `Controller/2` → `Scope_e/1`, `e_log/1`
4. 設定參數到 workspace：`Kp`, `Ki`, `Ts_controller`

#### Step 3: 執行模擬
```matlab
sim_results = run_simulation('Control_System_Framework', 0.01);
```
**內部運作：**
1. 設定求解器：`ode45`, MaxStep=1e-6
2. 執行 `sim()`
3. Simulink 運行：
   ```
   Vd → Controller → u → DAC → Plant → ADC → Vm
                      ↑                        ↓
                      └────────────────────────┘
   ```
4. `To Workspace` blocks 自動存 `u`, `e`, `Vm`, `Vm_analog`
5. 提取到 `sim_results` 結構

#### Step 4: 分析結果
```matlab
performance = analyze_results(sim_results);
```
**內部運作：**
1. 計算各通道的性能指標
2. 繪製 18 個子圖
3. 顯示性能報告表格
4. 儲存圖表（如果設定）

#### Step 5: 儲存結果
```matlab
save('results/PI_controller_results.mat', 'results_data');
```
**儲存內容：**
- 參數（Kp, Ki, Ts）
- 模擬結果（t, u, e, Vm）
- 性能指標（settling time, overshoot, etc.）
- 時間戳記

---

## Git 提交記錄

### Branch: `controller-framework-setup`

#### Commit 1: 修改控制器接口
```
commit 923b2f7
Modify controller interface: change from e_out to Vd,Vm inputs

- Remove e_out output port (error signal)
- Controller now receives Vd (reference) and Vm (measured output) as inputs
- Controller outputs u (control signal) directly to u_in
- Error calculation moved inside controller for flexible architecture
- Interface standardization for modular controller design
```

**修改檔案：**
- `Control_System_Framework.slx`
- `modify_framework_for_controller.m`

#### Commit 2: 建立資料夾結構
```
commit 409dd8a
Setup controller framework folder structure

- Create controllers/ for controller models (.slx files)
- Create scripts/ for automation scripts (.m files)
- Create results/ for simulation outputs (.mat, .fig files)
- Update .gitignore to exclude result files but keep folder structure
```

**新增檔案：**
- `controllers/.gitkeep`
- `scripts/.gitkeep`
- `results/.gitkeep`
- `.gitignore` (更新)

#### Commit 3: 建立 PI 控制器
```
commit e190485
Add PI controller model

- Discrete PI controller with 6 independent channels
- Inputs: Vd (reference, 6×1), Vm (measured output, 6×1)
- Outputs: u (control signal, 6×1), e (error, 6×1 for monitoring)
- Control law: e[k] = Vd[k] - Vm[k], u[k] = Kp*e[k] + Ki*Ts*Σe[i]
- Parameters: Kp, Ki (6×6 diagonal matrices), Ts_controller (sample time)
```

**新增檔案：**
- `controllers/PI_controller.slx`
- `controllers/create_PI_controller.m`

#### Commit 4: 建立自動化腳本
```
commit 3207a79
Add controller framework automation scripts

Core Scripts:
- setup_controller.m: Integrate controller model into framework
- run_simulation.m: Execute simulation and collect results
- analyze_results.m: Calculate performance metrics and plot
- example_run_PI.m: Complete PI controller test workflow

Features:
- Modular design for easy controller switching
- Standardized performance analysis
- Automated result visualization and export
```

**新增檔案：**
- `scripts/setup_controller.m`
- `scripts/run_simulation.m`
- `scripts/analyze_results.m`
- `scripts/example_run_PI.m`

---

## 使用指南

### 快速開始

#### 方法 1: 使用完整範例（推薦）
```matlab
% 在 MATLAB 中執行
cd 'c:\Users\kevin\Desktop\code\Openloop_Cali'
example_run_PI
```

**結果：**
- 自動執行完整流程
- 產生圖表視窗
- 儲存結果到 `results/` 資料夾
- 顯示性能報告

#### 方法 2: 手動步驟
```matlab
% Step 1: 設定參數
Kp = diag([0.5, 0.5, 0.5, 0.5, 0.5, 0.5]);
Ki = diag([10, 10, 10, 10, 10, 10]);
Ts_controller = 1e-5;

params.Kp = Kp;
params.Ki = Ki;
params.Ts_controller = Ts_controller;

% Step 2: 整合控制器
addpath('scripts');
setup_controller('PI_controller', params);

% Step 3: 執行模擬
sim_results = run_simulation('Control_System_Framework', 0.01);

% Step 4: 分析結果
performance = analyze_results(sim_results);

% Step 5: 儲存（可選）
save('results/my_results.mat', 'sim_results', 'performance');
```

### 參數調整

#### 調整 PI 增益
```matlab
% 增加比例增益（更快響應，但可能超調）
Kp = diag([0.8, 0.8, 0.8, 0.8, 0.8, 0.8]);

% 增加積分增益（減少穩態誤差，但可能震盪）
Ki = diag([20, 20, 20, 20, 20, 20]);

% 不同通道使用不同增益
Kp = diag([0.5, 0.6, 0.7, 0.8, 0.5, 0.6]);
Ki = diag([10, 12, 15, 18, 10, 12]);
```

#### 調整參考訊號
```matlab
% 方法 1: 在腳本中修改
Vd_ref = [1.5; 1.5; 1.5; 1.5; 1.5; 1.5];

% 方法 2: 不同通道不同參考值
Vd_ref = [1.0; 1.2; 1.4; 1.6; 1.8; 2.0];

% 方法 3: 直接在模型中修改
set_param('Control_System_Framework/Vd', 'Value', mat2str(Vd_ref));
```

#### 調整模擬時間
```matlab
% 短時間測試（快速檢查）
sim_time = 0.005;  % 5 ms

% 長時間觀察穩態（完整響應）
sim_time = 0.05;   % 50 ms
```

### 切換控制器

未來當你建立其他控制器（例如滑模控制）時：

```matlab
% Step 1: 建立新的控制器模型
% controllers/Sliding_Mode_controller.slx
% (確保接口一致：Vd, Vm → u, e)

% Step 2: 設定參數
params.lambda = 10;  % 滑模參數
params.eta = 0.1;

% Step 3: 整合（與 PI 相同）
setup_controller('Sliding_Mode_controller', params);

% Step 4: 執行（與 PI 相同）
sim_results = run_simulation('Control_System_Framework', 0.01);
performance = analyze_results(sim_results);
```

### 性能比較

比較多種控制器：

```matlab
% 測試 PI 控制器
setup_controller('PI_controller', params_PI);
sim_PI = run_simulation('Control_System_Framework', 0.01);
perf_PI = analyze_results(sim_PI);

% 測試滑模控制器
setup_controller('Sliding_Mode_controller', params_SM);
sim_SM = run_simulation('Control_System_Framework', 0.01);
perf_SM = analyze_results(sim_SM);

% 比較
fprintf('Settling Time: PI=%.4fs, SM=%.4fs\n', ...
    mean(perf_PI.settling_time), mean(perf_SM.settling_time));
fprintf('Overshoot: PI=%.2f%%, SM=%.2f%%\n', ...
    mean(perf_PI.overshoot), mean(perf_SM.overshoot));

% 繪製比較圖
figure;
subplot(2,1,1);
plot(sim_PI.t, sim_PI.Vm(:,1), 'b-', 'DisplayName', 'PI');
hold on;
plot(sim_SM.t, sim_SM.Vm(:,1), 'r-', 'DisplayName', 'Sliding Mode');
legend;
title('Channel 1 Comparison');
```

---

## 未來擴展

### 計畫中的控制器

根據 `Flux_Control_B_merged.pdf`，未來將實作：

#### 1. 反饋線性化控制器 (Feedback Linearization)
```
controllers/Feedback_Lin_controller.slx

架構：
  - 非線性補償模組（基於系統模型）
  - 線性控制器（極點配置）
  - 狀態估測器（觀測器）

參數：
  - 系統參數（a1, a2, b from transfer functions）
  - 期望極點位置
  - 觀測器增益
```

#### 2. 滑模控制器 (Sliding Mode Control)
```
controllers/Sliding_Mode_controller.slx

架構：
  - 滑模面設計（s = c*e + ė）
  - 趨近律（指數趨近律）
  - 切換函數（飽和函數減少顫振）

參數：
  - lambda（滑模面斜率）
  - eta（趨近律增益）
  - delta（邊界層厚度）
```

#### 3. 自適應控制器 (Adaptive Control)
```
controllers/Adaptive_controller.slx

架構：
  - 參數估測器（RLS, MIT rule）
  - 自適應律
  - 控制律（基於估測參數）

參數：
  - gamma（自適應增益）
  - 初始參數估測值
  - 遺忘因子（for RLS）
```

### 工具擴展

#### 自動調參工具
```matlab
% scripts/auto_tune_PI.m
% 使用遺傳演算法或粒子群演算法自動調整 Kp, Ki

function [Kp_opt, Ki_opt] = auto_tune_PI(cost_function)
    % GA or PSO optimization
    % cost_function: 例如最小化 settling time + overshoot
end
```

#### 批次比較工具
```matlab
% scripts/compare_controllers.m
% 批次測試多個控制器並產生比較報告

controllers = {'PI_controller', 'Sliding_Mode_controller', 'Adaptive_controller'};
compare_controllers(controllers);
```

#### 實時監控工具
```matlab
% scripts/realtime_monitor.m
% 模擬時顯示即時波形（使用 Simulink Dashboard）
```

### 文件擴展

#### 控制器設計指南
```
Log/Controller_Design_Guide.md

內容：
  - 如何設計新的控制器
  - 接口規範詳細說明
  - 參數調整建議
  - 常見問題 FAQ
```

#### 性能基準
```
Log/Performance_Benchmarks.md

內容：
  - 各控制器的性能基準
  - 不同參數下的表現
  - 適用場景建議
```

---

## 總結

### 已完成
✅ 修改 `Control_System_Framework.slx` 控制器接口
✅ 建立模組化資料夾結構
✅ 實作 PI 控制器模型
✅ 建立 4 個自動化腳本
✅ 完整的使用範例
✅ Git 版本控制與文件

### 核心成果
1. **標準化接口：** 所有控制器統一為 `Vd, Vm → u, e`
2. **模組化設計：** 控制器獨立，框架共用，腳本可重用
3. **自動化流程：** 一鍵執行整合、模擬、分析
4. **完整文件：** 從討論到實作的完整紀錄

### 下一步建議
1. **測試 PI 控制器：** 執行 `example_run_PI.m` 驗證功能
2. **調整參數：** 根據系統響應微調 Kp, Ki
3. **實作其他控制器：** 參考 PI 的架構，建立反饋線性化、滑模、自適應控制器
4. **性能比較：** 比較不同控制器的表現

---

**文件結束**
**最後更新：** 2025-10-09
**Git 分支：** controller-framework-setup
**Commits:** 4 個 (923b2f7, 409dd8a, e190485, 3207a79)
