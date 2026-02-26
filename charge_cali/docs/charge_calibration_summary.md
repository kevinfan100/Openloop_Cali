# 磁荷校準 (Charge Calibration) — 技術摘要

> NTU 無 yoke 六極致動器，單極磁荷校準實驗結果

---

## 1. 模型

**倒平方律** — 單極 (monopole) 磁荷模型：

```
H(x) = a² / (x + b)²
```

- `x`: 磁極尖端到感測器距離 [μm]
- `b`: 等效磁荷點偏移 (offset behind tip surface) [μm]
- `a`: 振幅常數 (含 Hall sensitivity、線圈參數)

**線性化**: `1/√H = (1/a)·x + b/a` → 線性回歸求 a, b

---

## 2. 實驗

| 項目 | 規格 |
|------|------|
| 距離 | 22 點: 10, 30, 50, 100 ~ 2000 μm |
| 頻率 | 15 點: 0.1 ~ 3000 Hz |
| 有效數據 | 330 / 330 (100%) |
| 擬合模型 | H(x) = a² / (x+b)² |

### 硬體參數

| 參數 | 值 | 來源 |
|------|-----|------|
| N_c | 50 turns | 硬體設計 |
| k_A | 0.3614 A/V | 放大器 |
| S_H | 130 V/T | EQ-730L datasheet |
| r_tip | 5 μm | 磁極尖端曲率半徑 |

---

## 3. 擬合結果

### 全範圍 (10 ~ 2000 μm)

| 頻率 | a | b [μm] | R² |
|------|--------|---------|--------|
| 0.1 Hz | 765.57 | 1979.3 | 0.9921 |
| 1 Hz | 764.84 | 1977.6 | 0.9921 |
| 10 Hz | 765.63 | 1979.9 | 0.9919 |
| **Mean ± Std** | **765.35 ± 0.43** | **1978.9 ± 1.2** | |

### 短範圍 (10 ~ 500 μm)

| 頻率 | a | b [μm] | R² |
|------|--------|---------|--------|
| 0.1 Hz | 604.84 | 1504 | 0.999 |

> **b 隨距離範圍改變**: 10~500 μm → b = 1504 μm; 10~2000 μm → b = 1979 μm。
> 純倒平方律在寬距離範圍 fit 較差，暗示多極貢獻 (multipole contributions)。

**關鍵結論**: b 跨頻率高度一致 (CV = 0.06%)，驗證 b 為頻率無關的幾何參數。

---

## 4. 信號鏈與參數反推

```
V_DA  →[k_A]→  I  →[N_c / R_a]→  Φ  →[q = Φ/μ₀]→  B(x) = N_c·I / (4π·R_a·(x+b)²)  →[S_H]→  V_m
```

> μ₀ 在磁荷定義和 Coulomb's law 中互消，B(x) 不含 μ₀。

**從擬合 a 反推 R_a**:

```
a² = S_H · N_c · k_A × 10¹² / (4π · R_a)

→ R_a = S_H · N_c · k_A × 10¹² / (4π · a²)
```

| 擬合範圍 | a | R_a [A/Wb] | k_pole [Wb/A] |
|----------|------|------------|---------------|
| 10~2000 μm | 765.35 | 3.19 × 10⁸ | 1.57 × 10⁻⁷ |
| 10~500 μm | 604.84 | 5.11 × 10⁸ | 9.78 × 10⁻⁸ |

---

## 5. 力量模型

### 推導流程

1. **磁路 (Hopkinson's law)**: `Φ = N_c · I / R_a`, 定義 `k_pole = N_c / R_a`
2. **磁荷**: `q = Φ / μ₀`
3. **磁場 (Coulomb's law)**: `B(x) = k_pole · I / (4π · (x+b)²)` — μ₀ 互消
4. **磁場梯度**: `|dB/dx| = 2 · k_pole · I / (4π · (x+b)³)`
5. **順磁球能量**: `U = -(χ_eff · V_bead / 2μ₀) · B²`
6. **力量**: `F = -dU/dx = (χ_eff · V_bead / μ₀) · B · |dB/dx|`

### 最終公式

```
F(x) = 2 · χ_eff · V_bead · N_c² · I² / (μ₀ · (4π)² · R_a² · (x+b)⁵)
```

**雙線性形式**: `F = ψ(x) · I²`

### 磁珠參數 (Dynabeads M-450)

| 參數 | 值 | 來源 |
|------|-----|------|
| χ (volume susceptibility) | 0.4 | Datasheet |
| d (直徑) | 4.5 μm | Datasheet |
| χ_eff = 3χ/(3+χ) | 0.353 | 退磁修正 (球) |
| V_bead = (4/3)π·r³ | 4.77 × 10⁻¹⁷ m³ | 計算 |

### 力量估算 (10~500 μm 擬合, I = 0.723 A)

| 距離 | F |
|------|-----|
| 100 μm | ~0.15 pN |
| 200 μm | ~0.03 pN |
| 500 μm | ~0.001 pN |

> Sub-piconewton 等級，遠低於有 yoke 設計。

---

## 6. 與 Menq 文獻比較

### b — 有意義的比較指標

| 設計 | b / l [μm] | 特徵 |
|------|-----------|------|
| **NTU (本實驗, 無 yoke)** | **b = 1979** | 磁荷點在極尖 ~2 mm 後方 |
| Menq 2010 (quadrupole, 有 yoke) | l = 405 | 磁荷集中在尖端附近 |

> b >> r_tip = 5 μm → **無 yoke 時磁通不集中**，等效磁荷點遠離極尖。
> b 是磁場集中程度的 figure of merit；yoke 對力量是必要的。

### R_a — 不可直接比較

| 設計 | R_a [A/Wb] | 磁路 |
|------|-----------|------|
| NTU (無 yoke) | 3.19 × 10⁸ | R_total = R_pole + R_gap + R_return_air |
| Menq Quad (有 yoke) | 1.8 × 10⁹ | R_airgap only (yoke 提供低 R 回路) |
| Menq Hex (有 yoke) | 2.8 × 10⁹ | R_airgap only |

> NTU R_a 看起來較小，但定義不同 (R_total vs R_airgap)，**不可直接比較**。

### 力量壓制

```
F_real / F_ideal = [r_tip / (r_tip + b)]⁵ ≈ 10⁻¹⁴
```

> 無 yoke → b 極大 → 1/(x+b)⁵ 衰減劇烈 → 力量被壓制約 14 個數量級。

---

## 7. 圖表索引

### Pipeline 自動生成 (results/Charge_NTU/figures/)

| 圖檔 | 說明 |
|------|------|
| `Charge_Fit_Overlay.png` | 三頻率 (0.1/1/10 Hz) 擬合曲線疊圖 |
| `Charge_Fit_Summary.png` | b 跨頻率一致性 + R² |
| `Charge_Fit_Single_0p1Hz.png` | 0.1 Hz 單頻擬合 (全範圍) |
| `Charge_Fit_Single_0p1Hz_10to500um.png` | 0.1 Hz 單頻擬合 (10~500 μm) |
| `Charge_Lissajous_0p1Hz.png` | Lissajous (資料品質確認) |
| `Charge_Lissajous_0p1Hz_Normalized.png` | 正規化 Lissajous |
| `Charge_Physics_Analysis.png` | B / dB/dx / F / SNR 2×2 物理分析 |

### 報告/PPT 用 (docs/figures/)

| 圖檔 | 說明 |
|------|------|
| `linearized_fit.png` | 1/√H vs x 線性化 + 殘差 (NEW-5) |
| `yoke_comparison.png` | 有/無 yoke H(x) 衰減對比 (NEW-7) |
| `force_vs_distance.png` | F(x), 10~500 μm, 線性 y 軸 |

---

## 8. 文獻

1. Zhang & Menq, "Modeling of a 3-D Magnetic Actuator for Magnetic Microbead Manipulation," *IEEE/ASME Trans. Mechatronics*, 2010 — quadrupole, l = 405 μm
2. Menq et al., "Design and Modeling of a 3-D Magnetic Actuator," *IEEE/ASME Trans. Mechatronics*, 2011 — hexapole, R_a = 2.8 × 10⁹
3. EQ-730L Hall Sensor datasheet — S_H = 130 V/T
4. Griffiths, *Introduction to Electrodynamics*, 4th ed. — χ_eff 退磁修正
