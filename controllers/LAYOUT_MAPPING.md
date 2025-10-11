# Layout Template 座標對應表

這個文件記錄了 `create_flux_controller_type3.m` 中舊座標與 `layout_template.m` 新座標的對應關係。

---

## ✅ 已完成的座標替換

### **Section 1: 輸入端口**

| Block | 舊座標 | 新座標 (layout_template) |
|-------|--------|-------------------------|
| **Vd** |  |  |
| X | `input_x = 100` | `layout.x.input = 105` |
| Y | `vd_y-10 = 90` | `layout.y.input_vd-10 = 90` |
| **Vm** |  |  |
| X | `input_x = 100` | `layout.x.input = 105` |
| Y | `vm_y-10 = 190` | `layout.y.input_vm-10 = 150` |

**改變**: X 座標從 100 → 105，Vm 的 Y 從 200 → 160

---

### **Section 2: 誤差計算**

| Block | 舊座標 | 新座標 (layout_template) |
|-------|--------|-------------------------|
| **Vd_Delay** |  |  |
| X | `delay_x-50 = 450` | `layout.x.delays = 450` |
| Y | `vd_y-15 = 85` | `layout.y.ff_vd_delay-15 = 85` |
| **Error_Calc** |  |  |
| X | `error_x = 300` | `layout.x.error_calc = 290` |
| Y | `error_y-15 = 135` | `layout.y.error-15 = 137` |

**改變**: Error_Calc 的 X 從 300 → 290

---

### **Section 3: 前饋項**

| Block | 舊座標 | 新座標 (layout_template) |
|-------|--------|-------------------------|
| **Vd_Delay2** |  |  |
| X | `delay_x+50 = 550` | `layout.x.delays_2nd = 550` |
| Y | `vd_y-15 = 85` | `layout.y.ff_vd_delay-15 = 85` |
| **Gain_a1** |  |  |
| X | `ff_x-50 = 650` | `layout.x.ff_gain_a1 = 820` |
| Y | `ff_y-15 = 285` | `layout.y.ff_gain_a1-15 = 195` |
| **Gain_a2** |  |  |
| X | `ff_x-50 = 650` | `layout.x.ff_gain_a2 = 765` |
| Y | `ff_y+30-15 = 315` | `layout.y.ff_gain_a2-15 = 265` |
| **FF_Sum** |  |  |
| X | `ff_x+50 = 750` | `layout.x.ff_fb_sum = 915` |
| Y | `ff_y-15 = 285` | `layout.y.ff_sum-15 = 195` |

**改變**: 前饋模組的 X 座標大幅調整，從 650-750 → 765-915

---

### **Section 4: 估測器**

#### **Innovation**
| 舊座標 | 新座標 |
|--------|--------|
| X: `est_x-100 = 600` | `layout.x.innovation = 470` |
| Y: `est_y-15 = 485` | `layout.y.innovation-15 = 322` |

**改變**: 位置大幅調整

#### **估測器增益**
| Block | 舊 X | 新 X | 舊 Y | 新 Y |
|-------|------|------|------|------|
| Gain_l1 | `est_x-50 = 650` | `layout.x.est_gains = 565` | `est_y-15 = 485` | `layout.y.est_l1-15 = 325` |
| Gain_lambda_c | `est_x-50 = 650` | `layout.x.est_gains = 565` | `est_y+40-15 = 525` | `layout.y.est_lambda_c-15 = 375` |
| Gain_l2 | `est_x-50 = 650` | `layout.x.est_gains = 565` | `est_y+100-15 = 585` | `layout.y.est_l2-15 = 440` |
| Gain_l3 | `est_x-50 = 650` | `layout.x.est_gains = 565` | `est_y+160-15 = 645` | `layout.y.est_l3-15 = 525` |

**改變**: X 從 650 → 565，Y 座標全部向上移動

#### **估測器狀態（Sum + Delay）**
| Block | 舊 X (Sum) | 新 X (Sum) | 舊 X (Delay) | 新 X (Delay) | 舊 Y | 新 Y |
|-------|-----------|-----------|--------------|--------------|------|------|
| S1 | `est_x+20 = 720` | `layout.x.est_sum = 720` | `est_x+80 = 780` | `layout.x.est_delay = 780` | `est_y+20 = 520` | `layout.y.s1_center = 350` |
| S2 | `est_x+20 = 720` | `layout.x.est_sum = 720` | `est_x+80 = 780` | `layout.x.est_delay = 780` | `est_y+100 = 600` | `layout.y.s2_center = 450` |
| WT | `est_x+20 = 720` | `layout.x.est_sum = 720` | `est_x+80 = 780` | `layout.x.est_delay = 780` | `est_y+160 = 660` | `layout.y.wt_center = 535` |

**改變**: X 保持不變，Y 座標全部向上移動並標準化間隔為 100

---

### **Section 5: 反饋項**

| Block | 舊座標 | 新座標 |
|-------|--------|--------|
| **FB_Gain1** |  |  |
| X | `fb_x = 700` | `layout.x.fb_gain_1 = 685` |
| Y | `fb_y-15 = 685` | `layout.y.fb_gain_1-15 = 570` |
| **FB_Gain2** |  |  |
| X | `fb_x = 700` | `layout.x.fb_gain_2 = 855` |
| Y | `fb_y+40-15 = 725` | `layout.y.fb_gain_2-15 = 610` |
| **FB_Sum** |  |  |
| X | `fb_x+70 = 770` | `layout.x.ff_fb_sum = 915` |
| Y | `fb_y+20-15 = 705` | `layout.y.fb_sum-15 = 577` |

**改變**: FB_Gain2 X 從 700 → 855，FB_Sum X 從 770 → 915

---

### **Section 6: 控制律**

| Block | 舊座標 | 新座標 |
|-------|--------|--------|
| **Control_Sum** |  |  |
| X | `control_x-100 = 1000` | `layout.x.control_sum = 1000` |
| Y | `control_y-15 = 485` | `layout.y.control-15 = 405` |
| **B_inv_Gain** |  |  |
| X | `control_x-30 = 1070` | `layout.x.b_inv = 1090` |
| Y | `control_y-15 = 485` | `layout.y.control-15 = 405` |

**改變**: X 微調，Y 從 500 → 420

---

### **Section 7: 輸出端口**

| Block | 舊座標 | 新座標 |
|-------|--------|--------|
| **u (control output)** |  |  |
| X | `output_x = 1300` | `layout.x.output = 1185` |
| Y | `control_y-10 = 490` | `layout.y.output_u-10 = 410` |
| **e (error output)** |  |  |
| X | `output_x = 1300` | `layout.x.output = 1185` |
| Y | `error_y-10 = 140` | `layout.y.output_e-10 = 145` |

**改變**: X 從 1300 → 1185，整體向左移

---

## 📊 主要改變總結

### **X 座標（水平）**
```
舊座標:  100  300  450  500  650-770  1000-1070  1300
新座標:  105  290  450  565  685-915  1000-1090  1185
變化:    +5   -10   0   +65  +35-+145    -20      -115
```

**主要調整**：
- 輸入層：微調 +5
- 誤差計算：向左 -10
- 估測器增益：向右 +65
- 前饋/反饋：大幅向右 +35~+145
- 控制律：微調 -20
- 輸出：向左 -115

### **Y 座標（垂直）**
```
區域          舊 Y 範圍        新 Y 範圍       變化
輸入層       90-210          90-170         Vm 向上
誤差         135-150         137-168        微調
前饋         285-315         195-295        向上 ~90
估測器       485-660         322-555        大幅向上 ~160
反饋         685-725         570-640        向上 ~115
控制律       485-500         405-435        向上 ~80
```

**主要調整**：整體佈局更緊湊，垂直間距更合理

---

## ✅ 使用新佈局的優點

1. **實際對應**: 新座標基於你手動調整的實際模型
2. **一致性**: 未來 Type 1, 2 控制器可以使用相同佈局
3. **易維護**: 修改 `layout_template.m` 即可調整所有控制器
4. **標準化**: 估測器狀態間隔統一為 100 像素

---

## 🔧 如何使用

```matlab
% 建立新模型時會自動載入模板
create_flux_controller_type3()

% 輸出顯示:
% ✓ 建立新模型
% ✓ 載入佈局模板
% ▶ 建立輸入端口...
% ...
```

所有座標都會自動從 `layout_template()` 讀取，確保與實際模型一致。

---

**記錄日期**: 2025-10-11
**對應模型**: Flux_Controller_Type3.slx (手動調整版)
