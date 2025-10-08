# 控制器開發與 Git 管理策略

**日期：** 2025-10-08
**專案：** Openloop_Cali
**階段：** 系統鑑別完成 → 控制器設計與模擬

---

## 📋 目錄

1. [專案現況](#專案現況)
2. [控制器開發策略](#控制器開發策略)
3. [結果儲存策略](#結果儲存策略)
4. [Git/GitHub 分支策略](#gitgithub-分支策略)
5. [響應圖與數據管理](#響應圖與數據管理)
6. [Claude 的建議總結](#claude-的建議總結)

---

## 專案現況

### 已完成部分
- ✅ 系統鑑別（6×6 MIMO 轉移函數）
- ✅ Simulink 控制框架 (`Control_System_Framework.slx`)
- ✅ 框架已包含：參考訊號、誤差計算、DAC/ADC、Plant (36 個 TF)、回授

### 待開發部分
- ⏳ 多種控制器實現（P, PI, PID, LQR, MPC...）
- ⏳ 控制器參數調整與比較
- ⏳ 模擬結果分析與視覺化

### 核心問題
1. 如何管理不同類型的控制器？
2. 如何處理大量的調參實驗結果？
3. 如何有效使用 Git 分支管理開發流程？
4. 響應圖、數據檔案該不該 commit？

---

## 控制器開發策略

### 1. 腳本化管理控制器

**建議資料夾結構：**
```
controllers/
├── P_controller.m              % 比例控制器
├── PI_controller.m             % PI 控制器
├── PID_controller.m            % PID 控制器
├── LQR_controller.m            % LQR 控制器
├── MPC_controller.m            % 模型預測控制
└── adaptive_controller.m       % 自適應控制
```

**每個控制器腳本的標準格式：**
```matlab
% P_controller.m
function P_controller(framework_model, K_gain)
    % 1. 清除舊控制器（如果存在）
    try
        delete_block([framework_model '/Controller']);
    catch
    end

    % 2. 加入新控制器
    add_block('simulink/Math Operations/Gain', ...
        [framework_model '/Controller']);
    set_param([framework_model '/Controller'], 'Gain', mat2str(K_gain));

    % 3. 連線：e_out → Controller → u_in
    add_line(framework_model, 'e_out/1', 'Controller/1', 'autorouting', 'on');
    add_line(framework_model, 'Controller/1', 'u_in/1', 'autorouting', 'on');

    % 4. 儲存
    save_system(framework_model);
end
```

### 2. 批次測試腳本

**主測試腳本範例：**
```matlab
% test_controllers.m
clear; clc; close all;

% 定義要測試的控制器與參數
test_cases = {
    'P',   eye(6)*0.5;
    'P',   eye(6)*0.8;
    'P',   eye(6)*1.2;
    'PI',  [0.5, 0.1];              % [Kp, Ki]
    'PID', [0.5, 0.1, 0.01];        % [Kp, Ki, Kd]
};

% 逐一測試
for i = 1:size(test_cases, 1)
    controller_type = test_cases{i, 1};
    params = test_cases{i, 2};

    % 應用控制器
    eval([controller_type '_controller(''Control_System_Framework'', params)']);

    % 執行模擬
    sim_out = sim('Control_System_Framework');

    % 儲存結果
    save_simulation_results(controller_type, params, Vm, u, e);
end
```

### 3. 優點
- ✅ 控制器可重複使用
- ✅ 易於版本控制（每個控制器是獨立檔案）
- ✅ 方便批次測試與比較
- ✅ 參數調整不影響框架本身

---

## 結果儲存策略

### 資料夾結構設計

```
results/
├── P_controller/
│   ├── K_0.5/
│   │   ├── response.png           # 響應圖
│   │   ├── data.mat              # 模擬數據 (Vm, u, e)
│   │   ├── metrics.json          # 性能指標 (Ts, overshoot, etc.)
│   │   └── README.md             # 實驗記錄
│   ├── K_0.8/
│   └── K_1.2/
│
├── PI_controller/
│   ├── Kp_0.5_Ki_0.1/
│   ├── Kp_0.8_Ki_0.2/
│   └── ...
│
├── PID_controller/
│   └── ...
│
└── comparison/                    # 控制器比較
    ├── all_controllers_ch1.png   # 通道 1 所有控制器比較圖
    ├── all_controllers_ch2.png
    ├── performance_table.csv     # 性能指標表格
    └── README.md                 # 比較分析報告
```

### 自動化儲存工具

**核心函數：`save_simulation_results.m`**
```matlab
function save_simulation_results(controller_type, params, Vm, u, e)
    % 1. 生成資料夾名稱
    param_str = generate_param_string(params);
    result_dir = fullfile('results', controller_type, param_str);

    % 2. 建立資料夾
    if ~exist(result_dir, 'dir')
        mkdir(result_dir);
    end

    % 3. 儲存數據
    save(fullfile(result_dir, 'data.mat'), 'Vm', 'u', 'e');

    % 4. 繪製並儲存圖表
    fig = plot_response(Vm, u, e);
    saveas(fig, fullfile(result_dir, 'response.png'));
    close(fig);

    % 5. 計算並儲存性能指標
    metrics = calculate_metrics(Vm, u, e);
    save_json(fullfile(result_dir, 'metrics.json'), metrics);

    % 6. 生成實驗記錄
    generate_result_readme(result_dir, controller_type, params, metrics);
end
```

**輔助函數：`generate_param_string.m`**
```matlab
function str = generate_param_string(params)
    % 範例：eye(6)*0.5 → "K_0.5"
    % 範例：[0.5, 0.1] → "Kp_0.5_Ki_0.1"
    if isscalar(params) || all(diag(params) == params(1,1))
        str = sprintf('K_%.2f', params(1,1));
    elseif length(params) == 2
        str = sprintf('Kp_%.2f_Ki_%.2f', params(1), params(2));
    elseif length(params) == 3
        str = sprintf('Kp_%.2f_Ki_%.2f_Kd_%.3f', params(1), params(2), params(3));
    else
        str = 'custom';
    end
end
```

### README.md 自動生成範例

**每個實驗資料夾內的 README.md：**
```markdown
# P Controller - K=0.5

## 實驗設定
- **控制器類型：** P (比例控制)
- **參數：** K = 0.5 * I(6×6)
- **模擬時間：** 0.1 秒
- **採樣時間：** 10 μs

## 性能指標
| 通道 | Settling Time (s) | Overshoot (%) | Steady-State Error |
|------|-------------------|---------------|--------------------|
| 1    | 0.0521           | 12.3          | 0.002             |
| 2    | 0.0498           | 11.8          | 0.001             |
| 3    | 0.0534           | 13.1          | 0.003             |
| 4    | 0.0512           | 12.5          | 0.002             |
| 5    | 0.0489           | 11.2          | 0.001             |
| 6    | 0.0545           | 13.8          | 0.004             |

## 結論
- 系統穩定
- 超調量偏高，可考慮降低增益
- 穩態誤差可接受

## 檔案
- `response.png` - 響應曲線圖
- `data.mat` - 完整模擬數據
- `metrics.json` - 性能指標 (JSON 格式)
```

---

## Git/GitHub 分支策略

### 分支命名規範

```
main (穩定版本)
│
├── feature/控制器名稱        # 開發新控制器功能
│   ├── feature/P-controller
│   ├── feature/PI-controller
│   ├── feature/PID-controller
│   └── feature/LQR-controller
│
├── experiment/實驗描述       # 調參實驗（不一定合併）
│   ├── experiment/tune-P-gain
│   ├── experiment/compare-PI-PID
│   └── experiment/robustness-test
│
├── fix/問題描述             # 修復 bug
│   └── fix/simulation-timeout
│
└── docs/文檔主題            # 文檔更新
    └── docs/controller-analysis
```

### 工作流程範例

#### 場景 1：開發新控制器

```bash
# 1. 從 main 創建分支
git checkout main
git pull
git checkout -b feature/PI-controller

# 2. 開發控制器
# (編輯 controllers/PI_controller.m)

# 3. 測試控制器
# (跑 test_controllers.m，確認可用)

# 4. 提交
git add controllers/PI_controller.m
git commit -m "feat: Add PI controller implementation"

# 5. 推送到遠端
git push -u origin feature/PI-controller

# 6. 創建 Pull Request（GitHub 上）
# 7. Code review 後合併到 main
git checkout main
git merge feature/PI-controller
git push
```

#### 場景 2：調參實驗（不合併到 main）

```bash
# 1. 創建實驗分支
git checkout -b experiment/tune-PI-params

# 2. 執行大量實驗
# (測試 50+ 組參數組合)

# 3. 提交實驗結果
git add results/PI_controller/
git commit -m "exp: PI parameter tuning (Kp=0.3-1.5, Ki=0.05-0.3, 50 combinations)"

# 4. 推送（保留實驗記錄）
git push -u origin experiment/tune-PI-params

# 5. 只把最佳參數更新到 main
git checkout main
git checkout experiment/tune-PI-params -- controllers/PI_controller.m
git commit -m "chore: Update PI controller with optimal params (Kp=0.8, Ki=0.15)"
git push
```

#### 場景 3：比較多個控制器

```bash
# 1. 創建實驗分支
git checkout -b experiment/P-vs-PI-vs-PID

# 2. 跑比較實驗
# (生成 results/comparison/)

# 3. 提交比較結果
git add results/comparison/
git commit -m "exp: Compare P, PI, PID controllers on step response"

# 4. 推送
git push -u origin experiment/P-vs-PI-vs-PID

# 5. 撰寫分析報告後合併文檔
git checkout main
git checkout experiment/P-vs-PI-vs-PID -- results/comparison/README.md
git commit -m "docs: Add controller comparison analysis"
git push
```

### Commit 訊息規範

```
feat:   新功能（例：feat: Add LQR controller）
exp:    實驗記錄（例：exp: Tune PID parameters, 100 tests）
fix:    修復 bug（例：fix: Correct gain matrix dimension）
docs:   文檔更新（例：docs: Add tuning guidelines）
chore:  維護性工作（例：chore: Update .gitignore）
refactor: 重構代碼（例：refactor: Simplify controller loading）
```

---

## 響應圖與數據管理

### 三種策略比較

| 策略 | 優點 | 缺點 | 適用情境 |
|------|------|------|----------|
| **策略 1：不 commit 大檔案** | • Repo 輕量<br>• 避免 merge conflict<br>• 可從數據重新生成 | • 需重跑模擬<br>• 協作時無法直接看圖 | **小團隊、個人專案**<br>（推薦） |
| **策略 2：Git LFS** | • 可 commit 圖片和數據<br>• Repo 不會變大<br>• 歷史可追溯 | • 需設定 LFS<br>• 某些平台有容量限制 | 需長期保存結果的專案 |
| **策略 3：雲端連結** | • Repo 完全不存大檔案<br>• 適合超大數據集 | • 需維護雲端空間<br>• 連結可能失效 | 數據量極大的專案 |

### 策略 1：不 commit 大檔案（推薦）

**.gitignore 設定：**
```gitignore
# CSV data files
*.csv

# Simulation results - Large files (regenerable)
results/**/*.png
results/**/*.fig
results/**/*.mat
results/**/*.slx.autosave

# Keep small & important files
!results/**/metrics.json
!results/**/README.md

# MATLAB/Simulink generated files
*.slx.autosave
*.slxc
slprj/
*.asv

# Generated plots
Pic_all_result/

# Backup files
*.zip
*.rar
*.7z
```

**Git 追蹤內容：**
- ✅ 控制器腳本（`.m` 檔案）
- ✅ 性能指標（`metrics.json`）
- ✅ 實驗記錄（`README.md`）
- ✅ Simulink 框架（`Control_System_Framework.slx`）
- ❌ 響應圖（`.png`）
- ❌ 模擬數據（`.mat`）

**重新生成結果的方法：**
```matlab
% regenerate_results.m
% 從 git commit 記錄重新跑實驗

% 1. 讀取實驗設定（從 README.md 或 commit message）
% 2. 應用對應的控制器
% 3. 執行模擬
% 4. 重新生成圖表

% 範例：
P_controller('Control_System_Framework', eye(6)*0.5);
sim_out = sim('Control_System_Framework');
save_simulation_results('P', eye(6)*0.5, Vm, u, e);
```

### 策略 2：Git LFS（選用）

**設定步驟：**
```bash
# 1. 安裝 Git LFS
# Windows: 下載安裝 https://git-lfs.github.com/
# Mac: brew install git-lfs

# 2. 初始化
git lfs install

# 3. 追蹤大檔案
git lfs track "*.png"
git lfs track "*.mat"
git lfs track "*.fig"

# 4. 提交設定
git add .gitattributes
git commit -m "chore: Setup Git LFS for simulation results"
```

**注意事項：**
- GitHub 免費帳號：1 GB storage + 1 GB/month bandwidth
- 超過需付費或改用其他方案

### 策略 3：雲端連結（選用）

**README.md 範例：**
```markdown
# PID Controller - Kp=0.5, Ki=0.1, Kd=0.01

## 性能指標
- Settling time: 0.042s
- Overshoot: 8.3%

## 完整結果（雲端連結）
- [響應圖 (Google Drive)](https://drive.google.com/file/d/xxx)
- [模擬數據 (OneDrive)](https://1drv.ms/u/s!xxx)
```

---

## Claude 的建議總結

### 🎯 核心建議

#### 1. 檔案組織
```
Openloop_Cali/
├── controllers/                    # 控制器腳本（版本控制）
│   ├── P_controller.m
│   ├── PI_controller.m
│   └── PID_controller.m
│
├── results/                        # 實驗結果
│   ├── P_controller/
│   ├── PI_controller/
│   └── comparison/
│
├── utils/                          # 工具函數
│   ├── save_simulation_results.m
│   ├── plot_response.m
│   └── calculate_metrics.m
│
├── Control_System_Framework.slx    # Simulink 框架
├── generate_simulink_framework.m
└── test_controllers.m              # 主測試腳本
```

#### 2. Git 工作流程
- **main 分支**：只放穩定、可用的程式碼
- **feature/xxx**：開發新控制器，開發完成後合併到 main
- **experiment/xxx**：調參實驗，保留記錄但不一定合併
- **分支隨時可刪**：實驗完成後，可刪除分支（歷史仍保留）

#### 3. 結果管理
**最推薦做法：**
- **不 commit**：`*.png`, `*.mat`（可重新生成）
- **commit**：`metrics.json`, `README.md`（體積小且重要）
- **好處**：Repo 輕量、避免衝突、容易維護

**替代方案：**
- 如果需要保存所有結果 → 用 Git LFS
- 如果數據超大（> 1GB）→ 用雲端連結

#### 4. 開發節奏建議

**第一階段：建立基礎**
```bash
# 1. 創建 controllers/ 資料夾和工具函數
git checkout -b feature/controller-framework
# (建立檔案結構)
git add controllers/ utils/
git commit -m "feat: Setup controller framework and utilities"
git push -u origin feature/controller-framework
# (合併到 main)
```

**第二階段：實現第一個控制器**
```bash
# 2. 開發 P 控制器
git checkout -b feature/P-controller
# (寫 P_controller.m，測試可用)
git add controllers/P_controller.m
git commit -m "feat: Implement P controller"
git push -u origin feature/P-controller
# (合併到 main)
```

**第三階段：調參實驗**
```bash
# 3. 調整 P 控制器參數
git checkout -b experiment/tune-P-gain
# (測試多組增益，儲存結果到 results/)
git add results/P_controller/
git commit -m "exp: Test P controller with K=0.3~1.5 (20 values)"
git push -u origin experiment/tune-P-gain
# (選擇性合併：只把最佳參數更新到 main)
```

**第四階段：重複第二、三階段**
- 開發 PI 控制器
- 開發 PID 控制器
- 比較所有控制器

#### 5. 建議的優先順序

**立即可做：**
1. ✅ 更新 `.gitignore`（排除 `*.png`, `*.mat`）
2. ✅ 創建 `controllers/` 資料夾
3. ✅ 寫第一個控制器（P controller）
4. ✅ 測試可用後 commit

**之後再做：**
- 📅 開發更多控制器（PI, PID, LQR...）
- 📅 完善自動化工具（`save_simulation_results.m`）
- 📅 撰寫比較分析報告

**不急著做：**
- 🔜 檔案重組（等檔案變多再說）
- 🔜 Git LFS（先用簡單方案）
- 🔜 CI/CD 自動化測試（專案成熟後）

---

## ✅ 行動檢查清單

閱讀完後，可以思考以下問題：

### 控制器開發
- [ ] 我想開發哪些控制器？（P, PI, PID, LQR, MPC...）
- [ ] 我需要調整哪些參數？（增益、採樣時間...）
- [ ] 我需要比較哪些指標？（穩定時間、超調量、穩態誤差...）

### Git 策略
- [ ] 我習慣用分支嗎？還是都在 main 上開發？
- [ ] 實驗分支要不要定期刪除？（保持 repo 整潔）
- [ ] Commit 訊息要不要統一格式？（feat, exp, fix...）

### 結果管理
- [ ] 圖片要不要 commit？（建議：不要）
- [ ] 數據要不要 commit？（建議：不要）
- [ ] 需不需要 Git LFS？（建議：先不用）
- [ ] 實驗記錄（README.md）要詳細到什麼程度？

### 工具開發
- [ ] 需不需要自動化工具？（save_simulation_results.m）
- [ ] 需不需要批次測試腳本？（test_controllers.m）
- [ ] 需不需要比較工具？（compare_controllers.m）

---

## 📝 我的筆記與想法

_(留給你自己寫下思考後的想法)_

### 哪些建議我想採納？


### 哪些建議我想調整？


### 還有什麼問題想問 Claude？


---

## 📚 相關文件
- [generate_simulink_framework.md](generate_simulink_framework.md) - Simulink 框架使用指南
- [MATLAB_Simulink_互動基礎教學.md](MATLAB_Simulink_互動基礎教學.md)

---

**撰寫者：** Claude (Anthropic)
**日期：** 2025-10-08
**版本：** 1.0
