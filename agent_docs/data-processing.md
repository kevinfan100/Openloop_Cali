# 階段一：數據處理 → 頻域轉換

> 詳細參考文檔。核心規則見 CLAUDE.md。

## 1.1 read_hsdata()

- Input: `.dat` binary (V1~V8 格式)
- DAC→Voltage: `(da - 32768) * (20/65536)` [V] — 固定公式
- Sanity checks: freq, channel, fs, loop_mode 與 config 比對
- 壞點修復: 只有 100kHz 數據需要 (`config.enable_bad_point_repair`)
- **Vectorized fread-with-skip**: 每欄位 1 次 fseek + fread（共 3~5 次），1.5M records ~1.7s

### V8 格式 (目前預設)
```matlab
data.Vm             % [N×6] single — Hall sensor 量測電壓
data.vd             % [N×6] single — 期望電壓
data.da             % [N×6] uint16 — DAC 原始值
data.debug          % [N×10] single — DebugRecord (V5+)
data.adc_raw        % [N×12] uint16 — ADC 原始值 (V4+)
data.version        % scalar — 檔案版本 (1~8)
data.record_count   % scalar — 記錄數
data.frequency      % scalar — 激勵頻率 [Hz] (V3+)
data.channel        % scalar — 激勵通道 1-6 (V3+)
data.sampling_rate  % scalar — 取樣率 [Hz] (V6+)
data.loop_mode      % scalar — 0=closed, 1=open (V6+)
```
**注意**: 無 `data.channels` 欄位。單一通道的 Vm 用 `data.Vm(:, ch)`。

## 1.2 穩態檢測

- 方法: relative threshold (預設 0.2%)
- 策略: conservative — 所有分析通道都檢測，取最晚穩定
- `check_points`: `min(25, period_samples)` — 防高頻重複
- 低頻 fallback: 數據不足時用最後幾個週期

### API
```matlab
ss_info = detect_steady_state_relative(vm, freq, fs, 'Name', Value)
% 回傳 struct with .index (穩態起始 sample index, 1-based), .method
```

## 1.3 FFT (Super-Period 精確截斷)

- `H(jw) = Vm_fft(f_bin) / DA_fft(f_bin)` — DA 用激勵通道，Vm 用分析通道
- **Super-period 截斷**: `compute_super_period(freq, fs)` 計算包含整數週期的最小整數 samples
  - 公式: `min_periods = freq / gcd(fs, freq)`, `super_period = min_periods * fs / freq`
  - 例: 1200 Hz → super_period=50 samples (3 週期)
  - **Fallback**: 穩態段不夠長時退回 `round(fs/freq)` 近似截斷 (700/900/1400/1800 Hz in Hung)
- 不加窗
- THD: 2~10次諧波，上限 `0.8 * Nyquist`
- `full` 模式 (預設) / `averaged` 模式 (可選，未實作)

## 1.4 180 deg 相位修正

- 實驗觀測確定，硬體相關
- `self_correct_channels = [1,3,6]` — 修正 H_{excite,excite}
- `other_correct_channels = [2,4,5]` — 修正 H_{i,excite}, i!=excite
- Single ch2→ch2: 不需修正
- 修正後所有 H_ij 低頻相位趨近 0 deg

## 1.5 bode_table 輸出 (CSV)

欄位 (single-channel 模式):
```
Frequency_Hz | Magnitude_Linear | Magnitude_dB | Phase_deg | THD_percent
```
- 保留原始 Phase_deg（未正規化）
- Phase 正規化在 fitting/plotting 階段才計算（減去 Phase(w_min)）
- CSV 保留所有頻率，fitting 時才根據 `exclude_frequencies` 排除

## 1.6 數據可靠性驗證 (4 Levels)

- **L1**: Header 自動檢查 (每檔都跑)
- **L2**: 時域波形診斷 (可選)
- **L3**: FFT 品質指標 (THD + SNR)
- **L4**: Dashboard 總覽 + Console 文字摘要

## 注意事項

- THD 值會因穩態窗口選擇而略有不同 — 預期行為，不影響 fitting
- Super-period FFT: 整除頻率 zero diff，非整除頻率 0.3%~2% 改善
- Bode 比較圖 XLim/freq_max 自動從 CSV 取 max(freq)
