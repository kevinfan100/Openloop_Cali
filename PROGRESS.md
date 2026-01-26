# Openloop_cali 進度追蹤

**更新日期:** 2026-01-26

---

## 已完成任務

### 1. 專案結構重構
- [x] 創建 `functions/` 目錄
- [x] 創建 `results/` 目錄結構 (`bode_data/`, `figures/`, `reports/`)
- [x] 清理 Python 相關檔案 (`hsdata_reader.py`, `requirements.txt`, `processed_csv/`)

### 2. 核心函數實作
- [x] `read_hsdata.m` - 二進制 HSData 讀取器 (V1-V8 支援)
- [x] `repair_bad_points.m` - 壞點插值修復
- [x] `detect_excitation.m` - 激勵通道/頻率檢測
- [x] `detect_steady_state.m` - 穩態檢測
- [x] `perform_fft.m` - FFT 頻率響應分析

### 3. 數據處理函數
- [x] `normalize_data.m` - 相位偏移移除、幅值正規化

### 4. 擬合函數
- [x] `fit_single_tf.m` - 單曲線二階轉移函數擬合
- [x] `fit_mimo_tf.m` - MIMO 多曲線擬合 (共享分母)
- [x] `zoh_discretize.m` - 零階保持離散化

### 5. 輸出函數
- [x] `save_bode_data.m` - 儲存 P*.m 格式
- [x] `export_latex.m` - LaTeX 輸出

### 6. 視覺化函數
- [x] `plot_bode.m` - 標準化波德圖公版
- [x] `plot_comparison.m` - 擬合對比圖

### 7. 主腳本
- [x] `main_openloop_cali.m` - 全自動流程腳本

### 8. 文檔更新
- [x] README.md - 更新為純 MATLAB 版本

---

## 待完成任務

### 等待用戶操作
- [ ] UI 更新完成後，export 新的 .dat 檔案
- [ ] 使用新數據執行完整流程測試

### 可選優化
- [ ] 更新 README_zh-TW.md (中文版)
- [ ] 添加單元測試
- [ ] 添加錯誤處理改進

---

## 檔案清單

### 新增檔案 (functions/)
```
functions/
├── read_hsdata.m          # 二進制讀取
├── repair_bad_points.m    # 壞點修復
├── detect_excitation.m    # 激勵檢測
├── detect_steady_state.m  # 穩態檢測
├── perform_fft.m          # FFT 分析
├── normalize_data.m       # 數據正規化
├── fit_single_tf.m        # 單曲線擬合
├── fit_mimo_tf.m          # MIMO 擬合
├── zoh_discretize.m       # ZOH 離散化
├── save_bode_data.m       # 儲存數據
├── export_latex.m         # LaTeX 輸出
├── plot_bode.m            # 波德圖
└── plot_comparison.m      # 對比圖
```

### 新增檔案 (根目錄)
```
main_openloop_cali.m       # 主腳本
PROGRESS.md                # 進度追蹤
```

### 刪除檔案
```
hsdata_reader.py           # Python 讀取器 (已整合到 MATLAB)
requirements.txt           # Python 依賴
processed_csv/             # CSV 中間檔案夾
```

### 保留檔案 (舊版參考)
```
openloop_bode.m                   # 舊版 Stage 2
Model_6_6_Continuous_Weighted.m   # 舊版 Stage 3
P1.m ~ P6.m                       # 現有測試數據
```

---

## 波德圖公版樣式

### 顏色配置
| 通道 | 顏色 | RGB |
|------|------|-----|
| P1 | 深藍色 | [0, 0, 0.5] |
| P2 | 藍色 | [0, 0, 1] |
| P3 | 綠色 | [0, 0.5, 0] |
| P4 | 紅色 | [1, 0, 0] |
| P5 | 粉紫色 | [0.8, 0, 0.8] |
| P6 | 青色 | [0, 0.75, 0.75] |

### 樣式參數
- 線寬: 3.5
- 標記大小: 9
- 字體大小: 18-22
- 座標軸線寬: 2.5
- X 軸: 對數刻度 (10^0, 10^1, ...)

---

## 測試計劃

### 階段一：函數單元測試 (可用現有數據)
- [x] `read_hsdata.m` - 需要 raw_data/ 中的 .dat 檔案
- [x] `plot_bode.m` - 可使用現有 P1.m 測試

### 階段二：整合測試 (等待新數據)
- [ ] 執行完整流程
- [ ] 驗證輸出格式

### 階段三：回歸測試
- [ ] 比較新舊系統輸出
- [ ] 確保 P1.m~P6.m 格式相容

---

## 已知問題

1. **raw_data 目錄為空**: 當前 raw_data/ 目錄可能沒有新的 .dat 檔案，Stage 1 會跳過
2. **中文 README 未更新**: README_zh-TW.md 仍為舊版內容

---

## 版本資訊

- **版本**: 2.0 (Pure MATLAB)
- **日期**: 2026-01-26
- **變更**: 移除 Python 依賴，整合為純 MATLAB 流程
