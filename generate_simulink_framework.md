# 控制系統框架使用指南

## 📋 模型概述

**檔案名稱：** `Control_System_Framework.slx`
**生成腳本：** `generate_control_framework.m`

### **完整架構（已包含所有元件，除了控制器）**

```
Vd (6×1) ──→ [Sum] ──→ e_out ──→ [控制器接口] ──→ u_in ──→ [DAC] ──→ [Plant] ──→ [ADC] ──→ Vm (6×1)
 參考         誤差     輸出給控制器   從控制器來     數位轉類比   36個TF   類比轉數位    測量輸出
              ↑                                                                            │
              └────────────────────────────────────────────────────────────────────────────┘
                                            回授 (Vm → Sum)
```

---

## ✅ 已完成的部分

| 元件 | 說明 | 訊號名稱 |
|------|------|----------|
| ✅ 參考訊號 | Constant block，預設值 `[1;1;1;1;1;1]` | **Vd** (6×1) |
| ✅ 誤差計算 | Sum block，`e = Vd - Vm` | **e** (6×1) |
| ✅ 控制器輸出埠 | 誤差訊號輸出 | **e_out** (6×1) |
| ✅ 控制器輸入埠 | 控制訊號輸入 | **u_in** (6×1) |
| ✅ DAC | 6 個 ZOH，Ts=10μs | u_digital → u_analog |
| ✅ Plant | 36 個二階轉移函數 | u_analog → y_analog |
| ✅ ADC | 6 個 ZOH，Ts=10μs | y_analog → y_digital |
| ✅ 回授連線 | Vm 連回 Sum | Vm → Sum/2 |
| ✅ 監測訊號 | Scope + To Workspace | u, e, Vm, Vm_analog |

---

## ❌ 需要您手動加入的部分

### **唯一缺少：控制器**

```
e_out (6×1) ──→ [您的控制器] ──→ u_in (6×1)
```

---

## 🎯 如何加入控制器

### **方法 1：簡單比例控制器（手動加入）**

開啟模型後，拖拉一個 **Gain** block：

1. 打開模型：
   ```matlab
   open_system('Control_System_Framework')
   ```

2. 從 Simulink Library Browser：
   - `Math Operations` → `Gain`
   - 拖拉到模型中，放在 `e_out` 和 `u_in` 之間

3. 設定參數：
   - Gain value: `eye(6) * 0.5`（6×6 對角矩陣，增益 0.5）

4. 連線：
   - `e_out` → `Gain` 輸入
   - `Gain` 輸出 → `u_in`

---

### **方法 2：比例控制器（用腳本加入）**

```matlab
% 開啟模型
open_system('Control_System_Framework')

% 加入 Gain block
add_block('simulink/Math Operations/Gain', ...
    'Control_System_Framework/Controller');

% 設定增益（比例控制器，K = 0.5）
set_param('Control_System_Framework/Controller', ...
    'Gain', 'eye(6) * 0.5', ...
    'Position', [500, 180, 550, 220]);

% 連線：e_out → Controller
add_line('Control_System_Framework', ...
    'e_out/1', 'Controller/1', 'autorouting', 'on');

% 連線：Controller → u_in
add_line('Control_System_Framework', ...
    'Controller/1', 'u_in/1', 'autorouting', 'on');

% 儲存
save_system('Control_System_Framework')
```

---

### **方法 3：PID 控制器（6 個獨立）**

```matlab
% 開啟模型
open_system('Control_System_Framework')

% 建立 Demux（拆分誤差訊號）
add_block('simulink/Signal Routing/Demux', ...
    'Control_System_Framework/Demux_e');
set_param('Control_System_Framework/Demux_e', 'Outputs', '6');

% 建立 6 個 PID 控制器
for i = 1:6
    pid_name = sprintf('Control_System_Framework/PID_%d', i);
    add_block('simulink/Discrete/Discrete PID Controller', pid_name);

    % 設定 PID 參數（可自訂）
    set_param(pid_name, ...
        'P', '0.5', ...        % 比例增益
        'I', '0.1', ...        % 積分增益
        'D', '0.01', ...       % 微分增益
        'SampleTime', '1e-5'); % 採樣時間
end

% 建立 Mux（合併控制訊號）
add_block('simulink/Signal Routing/Mux', ...
    'Control_System_Framework/Mux_u');
set_param('Control_System_Framework/Mux_u', 'Inputs', '6');

% 連線：e_out → Demux_e
add_line('Control_System_Framework', 'e_out/1', 'Demux_e/1', 'autorouting', 'on');

% 連線：Demux_e → PID_i → Mux_u
for i = 1:6
    add_line('Control_System_Framework', ...
        sprintf('Demux_e/%d', i), sprintf('PID_%d/1', i), 'autorouting', 'on');
    add_line('Control_System_Framework', ...
        sprintf('PID_%d/1', i), sprintf('Mux_u/%d', i), 'autorouting', 'on');
end

% 連線：Mux_u → u_in
add_line('Control_System_Framework', 'Mux_u/1', 'u_in/1', 'autorouting', 'on');

save_system('Control_System_Framework')
```

---

## 🔌 訊號接口說明

### **輸入訊號**

| 埠名稱 | 類型 | 維度 | 說明 | 預設值 |
|--------|------|------|------|--------|
| `Vd` | 內建 | 6×1 | 參考電壓（目標值） | `[1;1;1;1;1;1]` |
| `u_in` | 輸入埠 | 6×1 | 控制訊號（從控制器） | **需外接** |

### **輸出訊號**

| 埠名稱 | 類型 | 維度 | 說明 |
|--------|------|------|------|
| `e_out` | 輸出埠 | 6×1 | 誤差訊號（給控制器） |
| `Vm` | 輸出埠 | 6×1 | 測量電壓（數位） |

### **監測訊號（To Workspace）**

| 變數名稱 | 維度 | 說明 |
|----------|------|------|
| `u` | N×6 | 控制訊號歷程 |
| `e` | N×6 | 誤差訊號歷程 |
| `Vm` | N×6 | 測量輸出（數位） |
| `Vm_analog` | N×6 | 測量輸出（類比） |

---

## 🎮 模擬設定

### **Solver 設定（建議）**

```matlab
% 開啟模型
open_system('Control_System_Framework')

% 設定求解器
set_param('Control_System_Framework', 'Solver', 'ode45');
set_param('Control_System_Framework', 'MaxStep', '1e-6');    % 採樣時間的 1/10
set_param('Control_System_Framework', 'StopTime', '0.1');    % 模擬 100 ms

% 儲存設定
save_system('Control_System_Framework')
```

### **執行模擬**

```matlab
% 方法 1：GUI 執行
open_system('Control_System_Framework')
% 點擊 Run 按鈕

% 方法 2：命令列執行
sim('Control_System_Framework', 0.1)  % 模擬 0.1 秒

% 方法 3：取得結果
sim_out = sim('Control_System_Framework', 'StopTime', '0.1');
```

---

## 📊 結果分析

### **讀取模擬結果**

```matlab
% 模擬後，數據自動存在 workspace

% 時間向量
t = u.time;  % 或 e.time, Vm.time (都相同)

% 訊號數據
u_data = u.Data;          % N×6 矩陣
e_data = e.Data;          % N×6 矩陣
Vm_data = Vm.Data;        % N×6 矩陣
Vm_analog_data = Vm_analog.Data;  % N×6 矩陣

% 繪製通道 1 的結果
figure;
subplot(3,1,1);
plot(t, Vm_data(:,1), 'b-', 'LineWidth', 1.5);
hold on;
yline(1, 'r--', 'Reference');
ylabel('Vm_1');
title('Channel 1 Response');
grid on;

subplot(3,1,2);
plot(t, e_data(:,1), 'r-', 'LineWidth', 1.5);
ylabel('e_1 (Error)');
grid on;

subplot(3,1,3);
plot(t, u_data(:,1), 'g-', 'LineWidth', 1.5);
ylabel('u_1 (Control)');
xlabel('Time (s)');
grid on;
```

---

## 🔧 修改參考訊號

### **修改 Vd 的值**

```matlab
% 方法 1：在模型中修改
open_system('Control_System_Framework')
set_param('Control_System_Framework/Vd', 'Value', '[2; 2; 2; 2; 2; 2]');

% 方法 2：不同通道不同參考值
set_param('Control_System_Framework/Vd', 'Value', '[1; 1.5; 2; 1.8; 1.2; 1.6]');

% 方法 3：從 workspace 變數
Vd_ref = [1.5; 1.5; 1.5; 1.5; 1.5; 1.5];
set_param('Control_System_Framework/Vd', 'Value', mat2str(Vd_ref));
```

### **改用階躍訊號（動態參考）**

```matlab
% 刪除 Constant，改用 Step
delete_block('Control_System_Framework/Vd');

add_block('simulink/Sources/Step', 'Control_System_Framework/Vd');
set_param('Control_System_Framework/Vd', ...
    'Time', '0.05', ...           % 在 t=0.05s 時階躍
    'Before', '[0;0;0;0;0;0]', ...
    'After', '[1;1;1;1;1;1]');
```

---

## 🚀 快速開始範例

### **完整流程：建立 → 加控制器 → 模擬 → 分析**

```matlab
%% Step 1: 生成控制框架
clear; clc; close all;
generate_control_framework

%% Step 2: 加入簡單比例控制器
open_system('Control_System_Framework')

add_block('simulink/Math Operations/Gain', ...
    'Control_System_Framework/Controller');
set_param('Control_System_Framework/Controller', ...
    'Gain', 'eye(6) * 0.8', ...
    'Position', [500, 180, 550, 220]);

add_line('Control_System_Framework', 'e_out/1', 'Controller/1', 'autorouting', 'on');
add_line('Control_System_Framework', 'Controller/1', 'u_in/1', 'autorouting', 'on');

save_system('Control_System_Framework')

%% Step 3: 設定求解器並模擬
set_param('Control_System_Framework', 'Solver', 'ode45');
set_param('Control_System_Framework', 'MaxStep', '1e-6');
set_param('Control_System_Framework', 'StopTime', '0.1');

sim_out = sim('Control_System_Framework');

%% Step 4: 分析結果
t = Vm.time;

figure('Position', [100, 100, 1200, 800]);
for ch = 1:6
    subplot(3, 2, ch);
    plot(t, Vm.Data(:,ch), 'b-', 'LineWidth', 1.5);
    hold on;
    yline(1, 'r--', 'Reference');
    xlabel('Time (s)');
    ylabel(sprintf('Vm_%d', ch));
    title(sprintf('Channel %d Response', ch));
    grid on;
end

sgtitle('MIMO Control System Response', 'FontSize', 16, 'FontWeight', 'bold');

%% Step 5: 計算性能指標
for ch = 1:6
    y = Vm.Data(:,ch);

    % 穩定時間 (2% 誤差帶)
    final_val = y(end);
    settling_idx = find(abs(y - final_val) > 0.02*final_val, 1, 'last');
    if isempty(settling_idx)
        ts(ch) = 0;
    else
        ts(ch) = t(settling_idx);
    end

    % 超調量
    overshoot(ch) = (max(y) - final_val) / final_val * 100;

    fprintf('Channel %d: Ts = %.4f s, Overshoot = %.2f%%\n', ...
        ch, ts(ch), overshoot(ch));
end
```

---

## 🔄 與後續腳本的互動

### **預留的接口設計**

此框架已預留標準接口，後續可用以下方式與控制器互動：

#### **接口 1：直接連接方塊**
```matlab
% 控制器設計腳本 (design_controller.m)
function design_controller(K_gain)
    % 加入控制器到現有框架
    open_system('Control_System_Framework')

    add_block('simulink/Math Operations/Gain', ...
        'Control_System_Framework/Controller');
    set_param('Control_System_Framework/Controller', 'Gain', mat2str(K_gain));

    add_line('Control_System_Framework', 'e_out/1', 'Controller/1', 'autorouting', 'on');
    add_line('Control_System_Framework', 'Controller/1', 'u_in/1', 'autorouting', 'on');

    save_system('Control_System_Framework')
end

% 使用範例
K = eye(6) * 0.5;
design_controller(K)
```

#### **接口 2：Model Reference**
```matlab
% 將控制器設計成獨立模型，用 Model Reference 引用
add_block('simulink/Ports & Subsystems/Model', ...
    'Control_System_Framework/Controller');
set_param('Control_System_Framework/Controller', ...
    'ModelName', 'My_Controller_Model');
```

#### **接口 3：參數化控制器**
```matlab
% 使用 MATLAB Function 或 S-Function
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    'Control_System_Framework/Controller');

% 在 MATLAB Function 中實作控制邏輯
% function u = controller(e)
%     K = evalin('base', 'K_matrix');
%     u = K * e;
% end
```

---

## 📚 訊號命名規範總結

| 訊號 | 完整名稱 | 說明 |
|------|----------|------|
| **Vd** | Desired Voltage | 參考電壓（目標值） |
| **Vm** | Measured Voltage | 測量電壓（實際輸出） |
| **e** | Error | 誤差 (Vd - Vm) |
| **u** | Control Signal | 控制訊號 |
| **Vm_analog** | Measured Voltage (Analog) | 類比輸出（連續） |

---

## ⚠️ 注意事項

1. **控制器增益調整：**
   - 初始建議：K = eye(6) * 0.5（對角矩陣，增益 0.5）
   - 過大可能導致不穩定
   - 過小響應會很慢

2. **採樣時間一致性：**
   - DAC/ADC: Ts = 10 μs
   - 控制器也應使用 Ts = 10 μs
   - 求解器 MaxStep ≤ Ts/10

3. **監測訊號：**
   - 模擬前確保 `To Workspace` 的變數名稱唯一
   - 模擬後數據會覆蓋 workspace 中的同名變數

---

## ✅ 檢查清單

執行前確認：
- [ ] 已執行 `Model_6_6_Continuous_Weighted.m` 生成參數
- [ ] 已執行 `generate_control_framework` 建立模型
- [ ] 已加入控制器（連接 e_out → Controller → u_in）
- [ ] 已設定求解器參數
- [ ] 已設定模擬時間

執行後檢查：
- [ ] Scope 訊號正常
- [ ] Workspace 有 u, e, Vm, Vm_analog 變數
- [ ] 系統穩定（輸出收斂）

---

**Author:** Claude Code
**Date:** 2025-10-07
**Version:** 1.0
