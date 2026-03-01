# 驗證方法

> Pipeline 驗證紀錄與完整驗證指令。

## 驗證通過項目

1. 三組實驗各 19/19 檔案成功讀取
2. CSV Magnitude/Phase 與舊 pipeline 完全一致 (diff=0)
3. THD 略有不同（穩態窗口不同，無害）
4. compare 模式: Bode/Spectrum/Lissajous 三種比較圖正確
5. 參數覆寫: `run_analysis('Hung','fit','wc_Hz',1)` 正確
6. 所有新檔案通過 `checkcode` 零警告
7. step_plot: Fitting Residuals (Tab 3) + Dashboard 正確
8. step_compare: spectrum + lissajous 正確讀 .dat
9. NTU_ts 雙通道: NTU_t (tip, Vm ch3) + NTU_s (surface, Vm ch2) FFT 正確
10. 正規化 Bode TS: `Comparison_Bode_TS.png` 含 H(0.1) 值
11. TS Lissajous + TS TimeDomain: 原始+正規化版本正確
12. Super-period FFT: 23 頻率精確整數，整除 zero diff，非整除 0.3%~2% 改善
13. Bode freq_max 自動: 從 CSV max(freq) 推算
14. Vectorized read_hsdata: fread-with-skip bit-identical (Hung + Hung_pair)
15. Hung_pair 雙通道: excite + coupled FFT + 比較圖正確
16. NTU_pair 雙通道: 15 點頻率表正確
17. Hung_single_yoke: single yoke + pair 比較圖正確
18. Tag subfolder: `results/<Tag>/` 正確
19. Display names: `excite` / `coupled` (無 V_ 前綴)
20. 角色統一配色: single=red, excite=blue, coupled=green
21. Hung_spring_washer: H(0.1Hz)=0.0438, Phase(0.1Hz)=177.3 deg
22. Charge calibration (Hung): 合成數據回收精度 0% / <1.5%, R^2=1.0/0.9999
23. Charge calibration (NTU): 22 距離, 330/330 有效, b=1978.9+-1.2 um, R^2>0.992
24. Charge physics (NTU): k_pole=1.57e-7 Wb/A, crossover ~609 um
25. MIMO 6x6: correction_map 匹配 legacy (18/36), A1=6617.2 差異 <0.01%

## 完整驗證指令

```matlab
% 單實驗 pipeline
run_analysis('Hung', 'all');
run_analysis('Hung_no_washer', 'all');
run_analysis('Hung_spring_washer', 'all');
run_analysis('NTU', 'all');

% 多實驗比較
run_analysis({'Hung','Hung_no_washer','Hung_spring_washer','NTU'}, 'compare');
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare', 'Type', 'spectrum', 'Frequencies', [1,10,100]);
run_analysis({'Hung','Hung_no_washer','NTU'}, 'compare', 'Type', 'lissajous', 'Frequencies', [1,10,100]);

% NTU_ts 雙通道
run_analysis('NTU_t', 'fft');
run_analysis('NTU_s', 'fft');
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Normalize', false);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Normalize', false, 'Scale', 'linear');
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ratio');
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'cross_channel', 'Frequencies', [500,1000,2000]);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ts_lissajous', 'Frequencies', [10,100,1000]);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Type', 'ts_timedomain', 'Frequencies', [10,100,1000]);
run_analysis({'NTU_t','NTU_s'}, 'compare', 'Normalize', true);

% Hung_pair 雙通道
run_analysis('Hung_pair_2', 'fft');
run_analysis('Hung_pair_3', 'fft');
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', false, 'Tag', 'Hung_pair');
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'Hung_pair');
run_analysis({'Hung_pair_2','Hung_pair_3'}, 'compare', 'Type', 'ratio', 'Tag', 'Hung_pair');

% NTU_pair 雙通道
run_analysis('NTU_pair_2', 'fft');
run_analysis('NTU_pair_3', 'fft');
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', false, 'Tag', 'NTU_pair');
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'NTU_pair');
run_analysis({'NTU_pair_2','NTU_pair_3'}, 'compare', 'Type', 'ratio', 'Tag', 'NTU_pair');

% Yoke 比較
run_analysis({'Hung_single_yoke','Hung_pair_2','Hung_pair_3'}, 'compare', ...
    'Normalize', true, 'KeepOrder', true, 'Tag', 'Hung_yoke');
run_analysis({'NTU','NTU_pair_2','NTU_pair_3'}, 'compare', 'Normalize', true, 'Tag', 'NTU_yoke');

% Charge calibration (獨立入口)
run_charge_cali('Charge_Hung', 'full');
run_charge_cali('Charge_NTU', 'full');
run_charge_cali('Charge_NTU', 'fit');
run_charge_cali('Charge_NTU', 'plot');
analyze_charge_physics('Charge_NTU');

% MIMO 6x6 fitting
run_analysis('MIMO', 'mimo_all');
run_analysis('MIMO', 'mimo_fit');
run_analysis('MIMO', 'mimo_plot');
```
