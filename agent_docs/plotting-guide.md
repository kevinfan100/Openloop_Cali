# 階段三：繪圖呈現

> 詳細參考文檔。核心 style 常數見 CLAUDE.md。

## 3.1 全域 Style

```matlab
% Font
FontSize:   tick=24, label=40, legend=22, title=24
FontWeight: bold (all)

% Axis
XAxis.LineWidth = 3;
YAxis.LineWidth = 3;
box on;

% Plot
LineWidth = 3.5;
MarkerSize = 12;
MarkerFaceColor = 'none';
```

## 3.2 Legend 規則

- 預設: 頂端水平有框 (`Box='on'`, `Orientation='horizontal'`)
- 正規化 Bode: `Location='southwest'`，只在 Magnitude subplot，DisplayName 含 `H(0.1)=value`
  - 格式: `sprintf('%s (H(0.1)=%.4f)', display_name, H_ref)`
- 非正規化 Bode: `Location='northoutside'`，水平排列
- TS Lissajous / TS TimeDomain: 手動定位 `[0.5-w/2, 0.92, w, h]`，放在圖頂中央
- **Legend 手動定位流程**: 必須先 `drawnow`，再讀取 `lgd.Position` 取得實際寬高，再計算置中位置

## 3.3 固定顏色方案

```matlab
% 角色統一配色 (pair/yoke 比較圖)
single           = [1,0,0]     red    's'   % NTU='single', Hung_single_yoke='single yoke'
excite           = [0,0,1]     blue   'o'   % Hung_pair_2, NTU_pair_2
coupled          = [0,0.6,0]   green  'd'   % Hung_pair_3, NTU_pair_3

% 多組實驗比較 (Hung/NoWasher/SpringWasher/NTU)
Hung             = [0,0,1]     blue   'o'
NoWasher         = [0,0.6,0]   green  'd'
SpringWasher     = [0.6,0,0.8] purple '^'   % display_name='Hung (SpringWasher)'
NTU              = [1,0,0]     red    's'   % display_name='single'

% TS 雙通道
NTU_t            = [0,0,1]     blue   'o'   % V_{tip}
NTU_s            = [1,0,0]     red    's'   % V_{surface}

% 6x6 通道
P1=k, P2=b, P3=g, P4=r, P5=m, P6=c

% 多頻率: lines(N) MATLAB 預設色板
% Charge 用高對比色 (藍/紅/綠) 而非 lines(N)
```

## 3.4 圖表規格 (20 種)

| 圖表 | Size | Layout | X scale | Grid | Legend |
|------|------|--------|---------|------|--------|
| Bode Data Only | [900,720] | 2x1 | log | off | sw, mag only |
| Bode Model+Data | [900,720] | 2x1 | log | off | sw, mag only |
| Bode Comparison | [1050,820] | 2x1 | log | off | sw, mag only |
| Vm Spectrum | [1200,1200] | 3x1 | loglog | on | top horizontal |
| Lissajous | [1800,600] | 1x3 | linear | on | top horizontal |
| Dashboard | [1600,900] | 2x2 | mixed | on | per-subplot |
| Fitting Residuals | [900,720] | 2x1 | semilogx | on | best, RMSE in legend |
| Ratio | [900,720] | 2x1 | semilogx | on | best |
| Cross-Channel | [1800,600] | 1xN | linear | on | per-subplot axis labels |
| TS Lissajous | [1800,650] | 1xN | linear | on | top center manual, LW=2 |
| TS Lissajous Norm | [1800,650] | 1xN | linear | on | top center manual, LW=2, detrend+norm |
| TS TimeDomain | [1800,700] | 1xN | linear | on | top center manual, LW=2 |
| MIMO Per-Excitation Bode | [1000,900] | 2x1 | log | off | sw, P1~P6 colors, skip paired ch |
| MIMO B Matrix | [800,700] | 1x1 | N/A | off | colorbar, blue-white-red |
| MIMO Shared Hypothesis | [1200,500] | 1x2 | linear | on | per-subplot, xline for mean/MIMO |
| MIMO Phase Correction | [1200,500] | 1x2 | N/A | off | correction_map + raw phase bar |
| Charge Fit Overlay | [1200,800] | 1x1 | linear | off | northeast, 高對比色, 遞減線寬 |
| Charge Fit Summary | [1200,700] | 2x1 | semilogx | on | per-subplot |
| Charge Fit Single | [1200,800] | 1x1 | linear | off | northoutside horizontal, 黑 Model 線 |
| Charge Physics | [1200,900] | 2x2 | linear+semilogy | on | northeast per-subplot, R_a xline |

## 3.5 子圖規則

- **Subplot 順序 ALWAYS**: Hung → Hung(NoWasher) → Hung(SpringWasher) → Hung(SingleYoke) → NTU → NTU_t → NTU_s → Hung_pair_2 → Hung_pair_3 → NTU_pair_2 → NTU_pair_3
- **Legend 順序必須 match subplot 順序**
- 多子圖: 共用水平 legend 放在圖頂
- **xlabel 只放最底圖** — 上面的子圖不要重複

## 繪圖注意事項

- `exportgraphics` 可能顯示 "axes toolbar" 警告 — 純外觀問題
- `pbaspect([1 1 1])` 會壓縮 subplot 面積 — 標題可能被截斷
- 不要在每個 subplot 各放 legend — 會擋住標題；改用共用水平 legend 放圖頂
- `subplot()` 呼叫會重建 axes — 改用 `ax_handles = gobjects(1,n)` 存 handle
- TS Lissajous 正規化必須先去 DC: 先 `x - mean(x)` 再 `/ max(abs(...))`
- Charge Overlay: 遞減線寬 `linspace(LW+2, LW-1, N)`；curves 和 markers 分兩個 loop (markers on top)
- Charge legend: `'0.1 Hz (b=1979.3 um)'` 不含 R^2
- MATLAB 中用 `\mum` 產生 um 符號
