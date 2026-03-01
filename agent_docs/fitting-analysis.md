# 階段二：頻域分析 / Fitting

> 詳細參考文檔。核心規則見 CLAUDE.md。

## 2.1 兩條路徑

- **路徑 A**: 純頻域分析 (不 fitting) — 正規化比較、THD 趨勢、通道間比較
- **路徑 B**: Transfer Function Fitting

## 2.2 正規化 (多實驗比較)

- Magnitude: 各自除以自己的 `H(w_ref)`，`w_ref` = 最低頻
- Phase: 各自減去自己在 `w_ref` 的相位
- **不使用任何跨實驗 scaling factor** (no 7/5)

## 2.3 Phase offset removal (fitting 前處理)

- 每條曲線減去 `Phase(w_min)` — 消除 sensor DC 偏移
- 永遠做 (single 和 MIMO)

## 2.4 加權函數

```
w(w) = 1 / (1 + (w^2/wc^2))^p
預設: p=0.5, wc=100Hz — config 中統一定義
```

### wc_Hz 對 fitting 品質影響極大

| 實驗 | wc_Hz | R^2 | 備註 |
|------|-------|-----|------|
| Hung | 1 | ~0.99 | 舊腳本預設 |
| Hung_no_washer | 1 | ~0.99 | 同 Hung |
| NTU | 10 | ~0.99 | 需要較高 wc |
| MIMO | 0.1 | stable | MIMO_config 覆寫 |

default_config 統一用 `wc_Hz=100`（保守值），使用者可透過覆寫取得更佳 fitting：
```matlab
run_analysis('Hung', 'fit', 'wc_Hz', 1);
run_analysis('NTU', 'fit', 'wc_Hz', 10);
```

## 2.5 Single-curve fitting

- Model: `G(s) = b / (s^2 + a1*s + a2)`
- `fit_single_tf.m`: 3x3 加權最小平方
- 品質: R^2 >= 0.85, DC gain 正號, zeta > 0
- step_fit 支援 `FromCSV` 模式 — 直接從 CSV 載入

## 2.6 MIMO fitting (6x6)

詳見 `agent_docs/mimo-pipeline.md`。

## 2.7 共享假設檢驗

- 36-channel batch single fitting → `a1_matrix`, `a2_matrix`
- 計算 CV (coefficient of variation): CV < 10% → 假設合理
- 實測 CV: a1=59%, a2=72% (偏高，但 MIMO fitting 仍穩定)

## 2.8 ZOH 離散化

- `c2d(H_continuous, T_sample, 'zoh')`, `T_sample = 1e-5s` (100kHz)
- `k_A` 不參與 identification，只在控制器設計時使用

## 2.9 Exclude frequencies

- CSV 保留所有頻率
- Fitting 時根據 `config.fitting.exclude_frequencies` 排除
- 各實驗預設排除：Hung=[0.1, 900]、NTU=[0.1]、NoWasher=[0.1, 900]
