# MATLAB (.m) 與 Simulink (.slx) 互動基礎教學

## 📚 目錄
1. [核心概念](#核心概念)
2. [基礎互動函數](#基礎互動函數)
3. [實戰範例](#實戰範例)
4. [常見問題](#常見問題)
5. [學習資源](#學習資源)

---

## 🎯 核心概念

### 什麼是 .m 和 .slx？

| 檔案類型 | 用途 | 特性 |
|---------|------|------|
| **.m (MATLAB Script)** | 程式腳本、數值計算、數據分析 | 文字檔、易於版本控制、適合自動化 |
| **.slx (Simulink Model)** | 圖形化模擬、系統動態模擬 | 二進位檔、視覺化清晰、適合系統建模 |

### 互動的三種模式

```
模式 1: .m 控制 .slx          模式 2: .slx 呼叫 .m          模式 3: 雙向互動
┌─────────┐                  ┌─────────┐                  ┌─────────┐
│  .m     │ ───參數───→      │  .slx   │                  │  .m     │
│  腳本   │                  │  模型   │                  │  腳本   │
│         │ ←──結果───       │    ↓    │                  │    ↕    │
└─────────┘                  │ MATLAB  │                  │  .slx   │
                             │ Function│                  │  模型   │
                             └─────────┘                  └─────────┘
```

---

## 🔧 基礎互動函數

### 1️⃣ 模型管理函數

#### **建立與開啟模型**

```matlab
% 建立新模型
new_system('my_model')              % 建立（不開啟）
new_system('my_model', 'Model')     % 明確指定為 Model 類型
open_system('my_model')             % 開啟模型視窗

% 關閉模型
close_system('my_model')            % 關閉（不儲存）
close_system('my_model', 1)         % 關閉並儲存
close_system('my_model', 0)         % 關閉不儲存

% 儲存模型
save_system('my_model')                           % 儲存
save_system('my_model', 'new_name')              % 另存新檔
save_system('my_model', 'my_model', 'OverwriteIfChangedOnDisk', true)

% 檢查模型狀態
bdIsLoaded('my_model')              % 模型是否已載入（回傳 1 或 0）
```

**實用範例：安全地開啟模型**
```matlab
function safe_open_model(model_name)
    % 如果已開啟，先關閉再重新開啟
    if bdIsLoaded(model_name)
        close_system(model_name, 0);  % 0 = 不儲存
    end
    open_system(model_name);
end
```

---

#### **添加方塊（Block）**

```matlab
% 基本語法
add_block('來源路徑', '目標路徑')

% 範例：添加 Gain 方塊
add_block('simulink/Math Operations/Gain', 'my_model/Gain1')

% 範例：添加輸入端口
add_block('simulink/Sources/In1', 'my_model/Input1')

% 範例：添加轉移函數
add_block('simulink/Continuous/Transfer Fcn', 'my_model/TF1')
```

**常用方塊路徑速查表**

| 方塊類型 | Simulink 路徑 |
|---------|--------------|
| 輸入端口 | `simulink/Sources/In1` |
| 輸出端口 | `simulink/Sinks/Out1` |
| Gain | `simulink/Math Operations/Gain` |
| Sum | `simulink/Math Operations/Sum` |
| Transfer Fcn | `simulink/Continuous/Transfer Fcn` |
| PID Controller | `simulink/Continuous/PID Controller` |
| Discrete PID | `simulink/Discrete/Discrete PID Controller` |
| Scope | `simulink/Sinks/Scope` |
| Step | `simulink/Sources/Step` |
| Zero-Order Hold | `simulink/Discrete/Zero-Order Hold` |

---

#### **設定方塊參數**

```matlab
% 基本語法
set_param('方塊路徑', '參數名稱', '參數值')

% 範例：設定 Gain 值
set_param('my_model/Gain1', 'Gain', '2.5')

% 範例：設定轉移函數係數
set_param('my_model/TF1', 'Numerator', '[1]')
set_param('my_model/TF1', 'Denominator', '[1, 2, 1]')

% 範例：設定方塊位置 [left, top, right, bottom]
set_param('my_model/Gain1', 'Position', '[100, 100, 130, 130]')

% 範例：設定 PID 參數
set_param('my_model/PID1', 'P', '0.5')
set_param('my_model/PID1', 'I', '0.1')
set_param('my_model/PID1', 'D', '0.05')

% 範例：設定採樣時間（離散方塊）
set_param('my_model/Discrete_PID', 'SampleTime', '0.001')
```

**使用變數設定參數**
```matlab
% 方法 1：直接使用變數名（推薦）
Kp = 0.5;
set_param('my_model/PID1', 'P', 'Kp')  % 注意：傳入字串 'Kp'

% 方法 2：使用數值轉字串
Kp = 0.5;
set_param('my_model/PID1', 'P', num2str(Kp))

% 方法 3：使用 sprintf 格式化
b_value = 1.234e-5;
set_param('my_model/TF1', 'Numerator', sprintf('[%.12e]', b_value))
```

---

#### **連接方塊**

```matlab
% 基本語法
add_line('模型名稱', '來源方塊/端口號', '目標方塊/端口號')

% 範例：連接 Input1 的輸出端口 1 到 Gain1 的輸入端口 1
add_line('my_model', 'Input1/1', 'Gain1/1')

% 範例：使用自動路由
add_line('my_model', 'Gain1/1', 'Output1/1', 'autorouting', 'on')

% 範例：連接到 Sum 方塊的特定輸入
add_line('my_model', 'Gain1/1', 'Sum1/1')  % Sum 的第 1 個輸入
add_line('my_model', 'Gain2/1', 'Sum1/2')  % Sum 的第 2 個輸入
```

**Sum 方塊的特殊設定**
```matlab
% 設定 Sum 方塊的輸入數量和符號
set_param('my_model/Sum1', 'Inputs', '++')    % 2 個正輸入
set_param('my_model/Sum1', 'Inputs', '+-')    % 1 正 1 負
set_param('my_model/Sum1', 'Inputs', '+++')   % 3 個正輸入
```

---

### 2️⃣ 執行模擬函數

#### **基本模擬**

```matlab
% 方法 1：最簡單的執行
sim('my_model')

% 方法 2：設定模擬時間
sim('my_model', 'StopTime', '10')  % 模擬 10 秒

% 方法 3：接收輸出結果
out = sim('my_model', 'StopTime', '5');

% 方法 4：完整參數設定
simOut = sim('my_model', ...
             'StopTime', '10', ...
             'SolverType', 'Fixed-step', ...
             'FixedStep', '1e-4');
```

---

#### **模擬前設定參數**

```matlab
% 設定模擬參數
set_param('my_model', 'StopTime', '10')           % 終止時間
set_param('my_model', 'SolverType', 'Fixed-step') % 固定步長
set_param('my_model', 'FixedStep', '1e-4')        % 步長大小
set_param('my_model', 'Solver', 'ode4')           % Solver 類型

% 完整範例
function setup_simulation(model_name, stop_time, step_size)
    set_param(model_name, 'StopTime', num2str(stop_time));
    set_param(model_name, 'SolverType', 'Fixed-step');
    set_param(model_name, 'FixedStep', num2str(step_size));
    set_param(model_name, 'Solver', 'ode4');
end
```

---

#### **參數傳遞到 Simulink**

```matlab
% 方法 1：直接在 base workspace 設定變數（最常用）
Kp = 0.5;
Ki = 0.1;
Ts = 1e-4;
sim('my_model')  % Simulink 會自動讀取 workspace 的變數

% 方法 2：使用 assignin（明確指定）
assignin('base', 'Kp', 0.5);
assignin('base', 'Ki', 0.1);

% 方法 3：載入 .mat 檔案
load('parameters.mat')  % 載入所有變數到 workspace
sim('my_model')

% 方法 4：使用 Simulink.SimulationInput（進階）
in = Simulink.SimulationInput('my_model');
in = in.setVariable('Kp', 0.5);
in = in.setVariable('Ki', 0.1);
out = sim(in);
```

---

#### **從 Simulink 取得結果**

```matlab
% 在 Simulink 中設定「To Workspace」方塊
% - Variable name: output_data
% - Save format: Array

% 執行模擬
sim('my_model', 'StopTime', '10');

% 在 MATLAB 中取得結果
plot(output_data)

% 或使用 simOut 物件
out = sim('my_model');
time = out.tout;           % 時間向量
output = out.yout;         % 輸出數據（需在模型中配置）
```

**配置輸出紀錄**
```matlab
% 設定模型儲存輸出
set_param('my_model', 'SaveOutput', 'on');
set_param('my_model', 'OutputSaveName', 'yout');

% 執行並取得結果
out = sim('my_model');
plot(out.yout)
```

---

### 3️⃣ 查詢與除錯函數

```matlab
% 查詢方塊參數
get_param('my_model/Gain1', 'Gain')

% 查詢模型所有方塊
find_system('my_model', 'Type', 'Block')

% 查詢特定類型的方塊
find_system('my_model', 'BlockType', 'Gain')

% 查詢模型狀態
get_param('my_model', 'SimulationStatus')  % 'stopped', 'running', etc.

% 刪除方塊
delete_block('my_model/Gain1')

% 刪除連線
delete_line('my_model', 'Gain1/1', 'Output1/1')
```

---

## 🚀 實戰範例

### 範例 1：純 .m 腳本建立簡單模型

**目標**：建立一個「輸入 → Gain → 輸出」的模型

```matlab
% create_simple_model.m
function create_simple_model()
    % 1. 建立模型
    model_name = 'Simple_Gain_Model';

    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end

    new_system(model_name);
    open_system(model_name);

    % 2. 添加方塊
    add_block('simulink/Sources/In1', [model_name '/Input']);
    add_block('simulink/Math Operations/Gain', [model_name '/Gain']);
    add_block('simulink/Sinks/Out1', [model_name '/Output']);

    % 3. 設定位置
    set_param([model_name '/Input'], 'Position', [100, 100, 130, 120]);
    set_param([model_name '/Gain'], 'Position', [200, 100, 230, 120]);
    set_param([model_name '/Output'], 'Position', [300, 100, 330, 120]);

    % 4. 設定 Gain 值
    set_param([model_name '/Gain'], 'Gain', '2.5');

    % 5. 連接方塊
    add_line(model_name, 'Input/1', 'Gain/1', 'autorouting', 'on');
    add_line(model_name, 'Gain/1', 'Output/1', 'autorouting', 'on');

    % 6. 儲存
    save_system(model_name);

    fprintf('✓ 模型建立完成: %s.slx\n', model_name);
end
```

**執行方式**：
```matlab
>> create_simple_model
>> open_system('Simple_Gain_Model')
```

---

### 範例 2：.m 控制 .slx 執行模擬

**步驟 1：建立 Simulink 模型（手動或用上面的腳本）**

**步驟 2：撰寫控制腳本**

```matlab
% run_simulation_sweep.m
% 功能：掃描不同 Gain 值，觀察輸出

clear; clc;

%% 設定
model_name = 'Simple_Gain_Model';
gain_values = 0.5:0.5:3.0;  % Gain 從 0.5 到 3.0
results = zeros(length(gain_values), 1);

%% 批量模擬
fprintf('開始批量模擬...\n');

for i = 1:length(gain_values)
    % 設定 Gain 參數
    set_param([model_name '/Gain'], 'Gain', num2str(gain_values(i)));

    % 執行模擬
    sim_out = sim(model_name, 'StopTime', '1');

    % 儲存結果（假設最後的輸出值）
    results(i) = sim_out.yout(end);

    fprintf('  Gain = %.1f → 輸出 = %.2f\n', gain_values(i), results(i));
end

%% 畫圖
figure;
plot(gain_values, results, 'o-', 'LineWidth', 2);
xlabel('Gain 值');
ylabel('輸出');
title('Gain 掃描結果');
grid on;

fprintf('✓ 模擬完成\n');
```

---

### 範例 3：使用變數參數化（推薦方法）

**在 .slx 中**：
- Gain 方塊參數設為 `K_gain`（變數名，不是數值）

**在 .m 中**：
```matlab
% run_with_variables.m
clear; clc;

%% 設定參數（在 workspace）
K_gain = 2.5;
T_simulation = 5;

%% 執行模擬
assignin('base', 'K_gain', K_gain);
sim('Simple_Gain_Model', 'StopTime', num2str(T_simulation));

%% 也可以批量測試
K_values = [0.5, 1.0, 2.0, 5.0];

for K_gain = K_values
    assignin('base', 'K_gain', K_gain);
    sim('Simple_Gain_Model', 'StopTime', '5');
    % 分析結果...
end
```

---

### 範例 4：建立數位控制系統

```matlab
% create_digital_control.m
function create_digital_control()
    model_name = 'Digital_Control_System';

    % 建立模型
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end
    new_system(model_name);
    open_system(model_name);

    % 添加方塊
    add_block('simulink/Sources/Step', [model_name '/Reference']);
    add_block('simulink/Discrete/Discrete PID Controller', [model_name '/Controller']);
    add_block('simulink/Discrete/Zero-Order Hold', [model_name '/ZOH']);
    add_block('simulink/Continuous/Transfer Fcn', [model_name '/Plant']);
    add_block('simulink/Sinks/Scope', [model_name '/Scope']);

    % 設定位置
    set_param([model_name '/Reference'], 'Position', [50, 100, 80, 120]);
    set_param([model_name '/Controller'], 'Position', [150, 90, 200, 130]);
    set_param([model_name '/ZOH'], 'Position', [250, 95, 280, 125]);
    set_param([model_name '/Plant'], 'Position', [330, 95, 380, 125]);
    set_param([model_name '/Scope'], 'Position', [450, 95, 480, 125]);

    % 設定參數（使用變數）
    set_param([model_name '/Controller'], 'P', 'Kp');
    set_param([model_name '/Controller'], 'I', 'Ki');
    set_param([model_name '/Controller'], 'D', 'Kd');
    set_param([model_name '/Controller'], 'SampleTime', 'Ts');

    set_param([model_name '/ZOH'], 'SampleTime', 'Ts');

    set_param([model_name '/Plant'], 'Numerator', '[1]');
    set_param([model_name '/Plant'], 'Denominator', '[1 2 1]');

    % 連接方塊
    add_line(model_name, 'Reference/1', 'Controller/1', 'autorouting', 'on');
    add_line(model_name, 'Controller/1', 'ZOH/1', 'autorouting', 'on');
    add_line(model_name, 'ZOH/1', 'Plant/1', 'autorouting', 'on');
    add_line(model_name, 'Plant/1', 'Scope/1', 'autorouting', 'on');

    % 儲存
    save_system(model_name);
    fprintf('✓ 數位控制系統建立完成\n');
end
```

**執行模擬**：
```matlab
% 1. 建立模型
create_digital_control

% 2. 設定參數
Kp = 0.8;
Ki = 0.2;
Kd = 0.1;
Ts = 0.01;  % 採樣時間 10 ms

% 3. 執行模擬
sim('Digital_Control_System', 'StopTime', '10')
```

---

## ❓ 常見問題

### Q1: 為什麼我的變數在 Simulink 中讀不到？

**原因**：變數不在 base workspace 中。

**解決方法**：
```matlab
% 方法 1：確保變數在 base workspace
Kp = 0.5;  % 直接在 Command Window 或腳本中設定

% 方法 2：使用 assignin
assignin('base', 'Kp', 0.5);

% 方法 3：檢查變數是否存在
if ~exist('Kp', 'var')
    error('變數 Kp 不存在！');
end
```

---

### Q2: 如何知道方塊的參數名稱？

**方法 1**：查看方塊對話框（雙擊方塊，參數名稱通常在描述中）

**方法 2**：使用 `get_param`
```matlab
% 查看所有參數
get_param('my_model/Gain1', 'ObjectParameters')

% 查看特定參數
get_param('my_model/Gain1', 'Gain')
```

---

### Q3: 模擬時出現「Algebraic loop」錯誤？

**原因**：訊號形成閉迴路且沒有延遲。

**解決方法**：
```matlab
% 在回授路徑中加入 Memory 或 Unit Delay
add_block('simulink/Discrete/Unit Delay', [model_name '/Delay']);
```

---

### Q4: 如何自動擷取 Simulink 的輸出數據？

**方法 1**：使用 To Workspace 方塊
```matlab
% 在 Simulink 中：添加 To Workspace，變數名設為 output_data
sim('my_model');
plot(output_data);  % 在 MATLAB 中直接使用
```

**方法 2**：配置模型輸出
```matlab
set_param('my_model', 'SaveOutput', 'on');
set_param('my_model', 'OutputSaveName', 'yout');
out = sim('my_model');
plot(out.yout);
```

---

### Q5: .slx 檔案太大，如何優化？

**方法**：
```matlab
% 使用程式自動生成模型，不手動編輯
% 好處：
% 1. .slx 變成「產出物」，不需版本控制
% 2. 用 .m 腳本管理，容易追蹤變更
% 3. 可隨時重新生成

% 參考你專案中的 generate_simulink_model.m
```

---

## 📖 學習資源

### 官方文件

#### MATLAB 基礎
- [MATLAB 快速入門](https://www.mathworks.com/help/matlab/getting-started-with-matlab.html)
- [MATLAB 函數參考](https://www.mathworks.com/help/matlab/referencelist.html)

#### Simulink 基礎
- [Simulink 快速入門](https://www.mathworks.com/help/simulink/getting-started-with-simulink.html)
- [Simulink 方塊庫](https://www.mathworks.com/help/simulink/block-libraries.html)

#### 程式化建模
- [Programmatic Modeling Basics](https://www.mathworks.com/help/simulink/programmatic-modeling-basics.html)
- [add_block 函數文件](https://www.mathworks.com/help/simulink/slref/add_block.html)
- [set_param 函數文件](https://www.mathworks.com/help/simulink/slref/set_param.html)
- [sim 函數文件](https://www.mathworks.com/help/simulink/slref/sim.html)

#### 數位控制
- [Discrete PID Controller](https://www.mathworks.com/help/simulink/slref/discretepidcontroller.html)
- [Zero-Order Hold](https://www.mathworks.com/help/simulink/slref/zeroorderhold.html)

---

### 影片教學

#### MathWorks 官方頻道
- [Simulink Onramp（互動式課程）](https://www.mathworks.com/learn/tutorials/simulink-onramp.html)
  - 免費、約 3-5 小時、有證書

- [MATLAB & Simulink YouTube 官方頻道](https://www.youtube.com/user/MATLAB)
  - 搜尋關鍵字：「Programmatic Simulink」

#### 推薦影片（YouTube）

1. **Getting Started with Simulink**
   - [Simulink Tutorial for Beginners](https://www.youtube.com/watch?v=iOmqgewj5XI)
   - 時長：~30 分鐘，涵蓋基本操作

2. **程式化建模**
   - [Programmatically Create Simulink Models](https://www.youtube.com/results?search_query=matlab+programmatically+create+simulink)
   - 搜尋關鍵字：programmatically create simulink model

3. **數位控制系統**
   - [Digital Control Systems with MATLAB and Simulink](https://www.youtube.com/results?search_query=digital+control+matlab+simulink)
   - 搜尋：discrete PID simulink

4. **MIMO 系統**
   - [MIMO System Identification](https://www.youtube.com/results?search_query=MIMO+system+simulink)

---

### 實用部落格與教學網站

1. **MATLAB Central（論壇）**
   - https://www.mathworks.com/matlabcentral/
   - 可搜尋程式碼範例和問題解答

2. **File Exchange（程式碼分享）**
   - https://www.mathworks.com/matlabcentral/fileexchange/
   - 下載別人寫好的工具

3. **Control Tutorials for MATLAB and Simulink**
   - http://ctms.engin.umich.edu/CTMS/
   - 密西根大學製作，涵蓋 PID、State-space、Digital Control

4. **MATLAB 技術部落格**
   - https://blogs.mathworks.com/
   - 官方技術文章

---

### 書籍推薦

1. **《Digital Control System Analysis and Design》**
   - 作者：Charles L. Phillips
   - 涵蓋數位控制理論 + MATLAB 實作

2. **《MATLAB and Simulink for Engineers》**
   - 作者：Agam Kumar Tyagi
   - 適合初學者

3. **《Simulink: A Very Brief Introduction》**
   - 線上免費資源：https://www.mathworks.com/academia/books.html

---

### 中文資源

1. **MATLAB 台灣官方頻道**
   - https://www.youtube.com/@MATLABTW
   - 有繁體中文教學影片

2. **MATLAB 線上研討會（中文）**
   - https://www.mathworks.com/company/events/webinars.html
   - 選擇「Taiwan」地區

3. **台灣 MATLAB 使用者社群**
   - Facebook 搜尋：MATLAB Taiwan

---

## 🎓 學習路徑建議

### 第 1 週：基礎操作
- [ ] 完成 Simulink Onramp（3 小時）
- [ ] 手動建立一個簡單模型（Step → Gain → Scope）
- [ ] 執行範例 1：用 .m 建立模型

### 第 2 週：參數傳遞
- [ ] 學習 `set_param` 和 `get_param`
- [ ] 執行範例 2：批量掃描參數
- [ ] 執行範例 3：使用變數參數化

### 第 3 週：數位控制
- [ ] 了解採樣時間、ZOH 概念
- [ ] 執行範例 4：數位控制系統
- [ ] 調整 PID 參數，觀察效果

### 第 4 週：整合應用
- [ ] 將你的 MIMO 系統整合到 Simulink
- [ ] 設計簡單控制器
- [ ] 批量測試不同控制參數

---

## 📝 快速指令速查表

```matlab
% === 模型管理 ===
new_system('model')               % 建立模型
open_system('model')              % 開啟模型
close_system('model', 0)          % 關閉不儲存
save_system('model')              % 儲存模型
bdIsLoaded('model')               % 檢查是否載入

% === 方塊操作 ===
add_block('source', 'dest')       % 添加方塊
set_param('block', 'Param', 'Val') % 設定參數
get_param('block', 'Param')       % 查詢參數
delete_block('block')             % 刪除方塊

% === 連線操作 ===
add_line('model', 'src/1', 'dst/1')  % 連接方塊
delete_line('model', 'src/1', 'dst/1') % 刪除連線

% === 執行模擬 ===
sim('model')                      % 執行模擬
sim('model', 'StopTime', '10')    % 設定時間
out = sim('model')                % 取得輸出

% === 參數傳遞 ===
assignin('base', 'var', value)    % 傳遞變數
evalin('base', 'var')             % 讀取變數
```

---

## 🔗 本專案相關檔案

在本專案中，你可以參考：

1. **系統鑑別範例**
   - `Model_6_6_Continuous_Weighted.m` - 完整的數據處理流程

2. **自動建模範例**
   - `generate_simulink_model.m` - 自動生成 36 個轉移函數的 Simulink 模型

3. **使用說明**
   - `simulink_usage_guide.txt` - Simulink 使用步驟

---

## 💡 下一步

建議你：

1. **執行本文的範例 1-4**，熟悉基本操作
2. **閱讀你專案中的 `generate_simulink_model.m`**，理解如何批量建立方塊
3. **開始設計你的第一個控制器**，可從單一通道 SISO 控制開始

**有任何問題，隨時提問！**

---

**文件版本**：1.0
**建立日期**：2025-10-07
**適用對象**：MATLAB/Simulink 初學者、控制系統工程師
