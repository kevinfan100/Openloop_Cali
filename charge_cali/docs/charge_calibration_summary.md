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
| χ (volume susceptibility) | ~0.4 | 文獻常用近似值 (見 §8 說明) |
| d (直徑) | 4.5 μm | Invitrogen 產品規格 |
| χ_eff = 3χ/(3+χ) | ~0.35 | 退磁修正 (球) |
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

## 8. 推導知識來源

整個力量推導串了 3 個領域的知識：

```
推導步驟                   所屬領域                 來源
──────────────────────────────────────────────────────────────
Φ = N_c·I / R_a           磁路學                   電機學教科書 / Griffiths Ch.7
q = Φ/μ₀, B = ...         磁荷模型 (monopole)      Menq 論文 (非教科書標準內容)
M = χ·H                   磁化 (magnetization)     Griffiths Ch.6.1
χ_eff = 3χ/(3+χ)          退磁 (demagnetization)   Griffiths Ch.6.2, Example 6.1
U = -χ_eff·V·B²/(2μ₀)    順磁體能量               Griffiths Ch.6.4.3
F = -dU/dx                力 = 能量梯度             基礎力學
```

### 各概念白話說明

| 概念 | 說明 | Griffiths 位置 |
|------|------|----------------|
| 磁化 M | 材料放入磁場，內部微小磁矩被排列，產生淨磁矩密度 | Ch.6.1 |
| 順磁 (paramagnetic) | M 和外場同方向但很弱 (χ ~ 0.001~1)，磁珠就是順磁體 | Ch.6.1.3 |
| 磁化率 χ | M = χ·H，衡量材料被磁化的容易程度 | Ch.6.4.1 |
| 退磁因子 | 有限大小物體被磁化後，內部產生反向場削弱外場效果。球的退磁因子 = 1/3 → χ_eff = 3χ/(3+χ) | Ch.6.2 (Ex.6.1) |
| 能量 U | 順磁球在外場中的能量。1/2 因子是因為 m 由 B 感應產生 (非永久磁鐵) | Ch.6.4.3 |
| 力 F | F = -dU/dx，能量對位置的梯度 | 基礎力學 |

### 磁荷模型 (monopole) 的來源

磁荷模型**不是**教科書的標準內容。這是 Menq 論文為了簡化多極致動器分析而採用的工程近似——把磁極尖端等效為一個「點磁荷」，用 Coulomb's law 計算 B field。來源是論文本身 (Zhang & Menq 2010, Section II)。

### χ ≈ 0.4 的來源 — 從 Fonnum 2005 數據推算

χ_vol ≈ 0.4 在磁珠操控文獻中被廣泛使用，但沒有論文直接報告此值。以下從已確認的參數推算：

**已知參數 (有確認來源)：**

| 參數 | 值 | 來源 |
|------|-----|------|
| 磁珠密度 ρ_bead | 1600 kg/m³ | Thermo Fisher |
| 含鐵量 | 20 wt% Fe | Thermo Fisher |
| 磁性成分 | maghemite (γ-Fe₂O₃) | Fonnum 2005 |
| 奈米粒子尺寸 d_core | ~8 nm | Fonnum 2005 |
| 飽和磁化強度 M_s | ~340 kA/m | Fonnum 2005 |
| 超順磁行為 | 確認 | Fonnum 2005 + Thermo Fisher |

**推算流程：**

```
Step 1: 體積分率
  Fe₂O₃ 中 Fe 的質量比 = 2×55.85 / 159.69 = 69.9%
  Fe₂O₃ 質量分率 = 20% / 69.9% = 28.6 wt%
  體積分率 f_vol = (28.6% × 1600) / 4860 = 9.4%

Step 2: 奈米粒子磁化率 (Langevin 模型，超順磁低場線性區)
  χ_nanoparticle = μ₀ · Ms² · V_core / (3 · kB · T)
                 = 4π×10⁻⁷ × (340000)² × 2.68×10⁻²⁵ / (3 × 1.38×10⁻²³ × 300)
                 = 3.13

Step 3: 磁珠整體磁化率
  χ_bead = f_vol × χ_nanoparticle = 0.094 × 3.13 = 0.29
```

**敏感度分析** — χ 正比於 d_core³，對粒子尺寸非常敏感：

| d_core | χ_bead | 備註 |
|--------|--------|------|
| 7 nm | 0.20 | |
| **8 nm** | **0.29** | Fonnum 報告 "~8 nm" |
| 9 nm | 0.42 | 接近文獻常用 0.4 |
| 10 nm | 0.58 | |

**結論**：
- Fonnum 報告 d ≈ 8 nm → χ ≈ 0.29；若實際為 ~9 nm → χ ≈ 0.42
- 文獻常用的 **χ ≈ 0.4 對應 d_core ≈ 9 nm**，在 Fonnum 量測誤差範圍內
- 合理範圍：**χ = 0.2 ~ 0.5**（粒子尺寸分佈 7~10 nm）
- 即使 χ 差 2 倍，力量仍在 sub-pN，「無 yoke → 力量極弱」的結論不變
- 如需精確力量值，應以 Stokes drag 實驗校準，不依賴 χ 計算

### 建議閱讀 (最少量，~20 頁)

教科書：**Griffiths, *Introduction to Electrodynamics*, 4th ed., Cambridge University Press, 2017**
(ISBN: 978-1108420419)

台灣各大學圖書館通常有館藏，也可在以下平台取得：
- 學校圖書館 (搜尋 "Griffiths electrodynamics")
- Amazon / 博客來 (英文原文)
- 簡體中文譯本：《电动力学导论》(機械工業出版社)

只需讀以下章節即可理解本推導的全部物理基礎：

1. **Ch.6.1** (~10 頁) — 磁化、順磁、χ 的定義
2. **Ch.6.2, Example 6.1** (~5 頁) — 球的退磁，推導 χ_eff = 3χ/(3+χ)
3. **Ch.6.4.3** (~3 頁) — 磁體在非均勻場中的能量和力

---

## 9. 文獻

1. Zhang & Menq, "Modeling of a 3-D Magnetic Actuator for Magnetic Microbead Manipulation," *IEEE/ASME Trans. Mechatronics*, 2010 — quadrupole, l = 405 μm
2. Menq et al., "Design and Modeling of a 3-D Magnetic Actuator," *IEEE/ASME Trans. Mechatronics*, 2011 — hexapole, R_a = 2.8 × 10⁹
3. EQ-730L Hall Sensor datasheet — S_H = 130 V/T
4. Griffiths, *Introduction to Electrodynamics*, 4th ed., Cambridge University Press, 2017 — Ch.6: 磁化、退磁、順磁體力量
5. Fonnum et al., "Characterisation of Dynabeads by magnetization measurements and Mossbauer spectroscopy," *J. Magn. Magn. Mater.* 293, 41-47, 2005 — M-450 磁化量測 (VSM + Mossbauer)
6. Schlenker et al., "Magnetic Characterization of Dynabeads," *PLOS ONE*, 2012 (PMC3433070) — M-450 沉降/磁吸速度量測
