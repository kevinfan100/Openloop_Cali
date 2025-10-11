# Development Rules & Guidelines
# Openloop_Cali 專案開發規範

**Last Updated**: 2025-10-09
**Project**: Control System Framework Development

---

## 📋 Table of Contents

1. [File Management Rules](#file-management-rules)
2. [Naming Conventions](#naming-conventions)
3. [Git Workflow](#git-workflow)
4. [Code Organization](#code-organization)
5. [Documentation Standards](#documentation-standards)
6. [Testing & Validation](#testing--validation)

---

## 🗂️ File Management Rules

### ❌ **PROHIBITED: Temporary & Iteration Files**

**嚴格禁止**提交以下類型的檔案到 Git：

#### 1. **版本迭代檔案** (Version Iterations)
```
❌ modify_framework_v2.m
❌ design_PI_old.m
❌ controller_new.m
❌ setup_v3.m
❌ test_copy.m
```

**原因**: 使用 Git 版本控制，不需要手動建立版本檔案

**正確做法**:
- 直接修改原檔案
- 使用 `git commit` 記錄變更
- 需要時使用 `git log` 或 `git diff` 查看歷史

#### 2. **臨時測試檔案** (Temporary Test Files)
```
❌ check_vd_sample_time.m
❌ inspect_model_structure.m
❌ debug_controller.m
❌ test_something.m
❌ tmp_analysis.m
```

**原因**: 這些是一次性調試工具，完成後應立即刪除

**正確做法**:
- 完成調試後，刪除檔案
- 如果功能有用，整合到現有函數中
- 不要累積調試檔案

#### 3. **修改腳本** (Modification Scripts)
```
❌ modify_framework_for_controller.m
❌ update_model_parameters.m
❌ fix_connections.m
```

**原因**: 一次性腳本執行完即無用

**正確做法**:
- 執行完成後刪除
- 或整合到 `generate_simulink_framework.m`

---

### ✅ **ALLOWED: When Temporary Files Are Acceptable**

臨時檔案可以在**本地開發**時建立，但：

1. **必須在任務完成後刪除**
2. **絕不提交到 Git**
3. **檔名必須清楚標示為臨時** (例如 `_temp`, `_test`)

**範例**:
```matlab
% 本地調試時可以建立
debug_frequency_response_temp.m  % ✓ 清楚標示 _temp

% 但完成後必須：
% 1. 刪除檔案
% 2. 或整合到 analyze_plant_frequency.m
```

---

## 📝 Naming Conventions

### 檔案命名規範

#### 1. **函數檔案** (Reusable Functions)
```
格式: verb_noun.m
```

**範例**:
- `design_PI_frequency.m` ✅
- `analyze_plant_frequency.m` ✅
- `setup_controller.m` ✅
- `run_simulation.m` ✅

#### 2. **範例腳本** (Example Scripts)
```
格式: example_description.m
```

**範例**:
- `example_frequency_design.m` ✅
- `example_run_PI.m` ✅

#### 3. **Simulink 模型** (Simulink Models)
```
格式: ModelName.slx (PascalCase)
```

**範例**:
- `Control_System_Framework.slx` ✅
- `PI_controller.slx` ✅

#### 4. **資料檔案** (Data Files)
```
格式: descriptive_name.mat
```

**範例**:
- `one_curve_36_results.mat` ✅
- `plant_parameters.mat` ✅

---

## 🔄 Git Workflow

### Branching Strategy

```
main (master)           ← 穩定版本，可運行的程式碼
  │
  ├─ feature/xxx        ← 新功能開發
  ├─ bugfix/xxx         ← Bug 修復
  └─ experiment/xxx     ← 實驗性功能（可選）
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body (optional)>
```

**Types**:
- `feat`: 新功能
- `fix`: Bug 修復
- `refactor`: 重構（不改變功能）
- `docs`: 文檔更新
- `test`: 測試相關
- `chore`: 雜項（工具、配置等）

**範例**:
```bash
feat(framework): change controller interface to (Vd, Vm) → u

- Remove error calculation from framework
- Use Goto/From blocks for signal routing
- Simplify visual annotations

fix(design): correct PI parameter calculation in design_PI_frequency.m

docs(readme): update project structure documentation

refactor(scripts): reorganize controller design functions
```

### Commit Checklist

在提交前檢查：

- [ ] **沒有臨時檔案** (`*_temp.m`, `*_v2.m`, `check_*.m`)
- [ ] **程式碼可執行** (沒有語法錯誤)
- [ ] **沒有個人路徑** (使用相對路徑)
- [ ] **文件已更新** (如果修改了接口)
- [ ] **Commit message 清楚** (說明改了什麼和為什麼)

---

## 📂 Code Organization

### 專案結構

```
Openloop_Cali/
│
├── Control_System_Framework.slx    # 主要 Simulink 框架
├── generate_simulink_framework.m   # 框架生成器
│
├── Model_6_6_Continuous_Weighted.m # Plant 模型定義
├── P1.m ~ P6.m                     # 各通道 Plant 參數
├── one_curve_36_results.mat        # Plant 數據（重要！）
│
├── controllers/                    # 控制器模型
│   ├── PI_controller.slx
│   └── PID_controller.slx
│
├── scripts/                        # 核心腳本
│   ├── framework/                  # Simulink 框架交互
│   │   ├── setup_controller.m
│   │   ├── run_simulation.m
│   │   └── analyze_results.m
│   │
│   ├── design/                     # 控制器設計
│   │   ├── design_PI_frequency.m
│   │   ├── analyze_plant_frequency.m
│   │   └── example_frequency_design.m
│   │
│   └── results/                    # 模擬結果
│       └── (plots and data)
│
├── docs/                           # 文檔
│   ├── 控制器開發與Git管理策略.md
│   ├── generate_simulink_framework.md
│   └── MATLAB_Simulink_互動基礎教學.md
│
├── Mathematical_Derivation/        # 數學推導
│
├── .gitignore                      # Git 忽略規則
├── DEVELOPMENT_RULES.md            # 本文件
└── PROJECT_STRUCTURE.md            # 專案結構說明
```

### 分類原則

1. **Framework Interaction** (`scripts/framework/`)
   - 與 Simulink 模型交互
   - 執行模擬
   - 分析結果

2. **Controller Design** (`scripts/design/`)
   - 控制器參數設計
   - 頻域/時域分析
   - Plant 分析

3. **Documentation** (`docs/`)
   - 使用說明
   - 理論推導
   - 開發紀錄

---

## 📚 Documentation Standards

### 檔案註釋格式

每個 `.m` 檔案必須包含：

```matlab
% function_name.m
% Short description (one line)
%
% Purpose:
%   Detailed description of what this function does
%
% Usage:
%   [output1, output2] = function_name(input1, input2, options)
%
% Inputs:
%   input1    - Description of input1
%   input2    - Description of input2
%   options   - (Optional) Structure with fields...
%
% Outputs:
%   output1   - Description of output1
%   output2   - Description of output2
%
% Example:
%   result = function_name(data, 'option1', value1);
%
% Author: Your Name
% Date: YYYY-MM-DD
% Modified: YYYY-MM-DD - Description of changes

function [output1, output2] = function_name(input1, input2, options)
    % Function body
end
```

### 重要變更記錄

當修改現有檔案時，添加 `Modified` 行：

```matlab
% Modified: 2025-10-09 - Changed controller interface to (Vd, Vm) → u
```

---

## 🧪 Testing & Validation

### 修改框架後的檢查清單

當修改 Simulink 框架或核心腳本後：

- [ ] **重新生成框架** (執行 `generate_simulink_framework.m`)
- [ ] **開啟模型檢查** (確認接口位置正確)
- [ ] **執行範例** (運行 `example_frequency_design.m` 或類似)
- [ ] **檢查結果** (確認模擬可運行)
- [ ] **更新文檔** (如果有介面變更)

### 提交前測試

```matlab
% 1. 測試框架生成
generate_simulink_framework();

% 2. 測試控制器設計
example_frequency_design;

% 3. 檢查沒有錯誤
```

---

## 🚫 Common Mistakes to Avoid

### 1. **不要建立重複功能**

❌ **錯誤**:
```
design_PI_frequency.m
design_PI_from_normalized_plant.m    % 功能重複
design_PI_alternative.m              % 功能重複
```

✅ **正確**:
- 保留一個通用版本
- 使用 `options` 參數區分不同方法
- 或在函數內部提供多種 method

### 2. **不要累積測試檔案**

❌ **錯誤**:
```
test1.m
test2.m
test_new.m
test_final.m
check_something.m
debug_issue.m
```

✅ **正確**:
- 測試完立即刪除
- 或整合到單元測試

### 3. **不要使用絕對路徑**

❌ **錯誤**:
```matlab
load('C:\Users\PME406_01\Desktop\code\Openloop_Cali\data.mat');
```

✅ **正確**:
```matlab
load('data.mat');  % 使用相對路徑
```

---

## 📞 Contact & Questions

如果對規範有疑問：

1. 查看 [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
2. 檢查現有程式碼的風格
3. 提出 issue 討論

---

## 📅 Version History

| Date       | Version | Changes                                      |
|------------|---------|----------------------------------------------|
| 2025-10-09 | 1.0     | Initial development rules document           |
| 2025-10-09 | 1.1     | Added Git workflow and file organization     |

---

**Remember**: 程式碼的可維護性比快速開發更重要！
