function [super_period_samples, min_periods] = compute_super_period(freq, fs)
%COMPUTE_SUPER_PERIOD 計算精確的 super-period (整數 samples 且包含整數週期)
%
% 對於 fs/freq 非整數的頻率 (如 1200 Hz @ 20kHz → 16.667 samples/period)，
% 找到最小整數 N 使得 N*fs/freq 為整數 → 消除 FFT 頻譜洩漏。
%
% 公式: min_periods = freq / gcd(fs, freq)
%        super_period_samples = min_periods * fs / freq
%
% Input:
%   freq - 頻率 (Hz), 可為非整數 (如 0.1)
%   fs   - 取樣率 (Hz)
%
% Output:
%   super_period_samples - 最小整數 samples 包含整數週期 (保證為整數)
%   min_periods          - 對應的最小週期數
%
% Examples:
%   [sp, mp] = compute_super_period(100, 20000)   → sp=200, mp=1  (整除)
%   [sp, mp] = compute_super_period(1200, 20000)  → sp=50,  mp=3  (非整除)
%   [sp, mp] = compute_super_period(0.1, 20000)   → sp=200000, mp=1

    % 用 rat() 將 freq 表示為精確分數 num_f/den_f
    [num_f, den_f] = rat(freq, 1e-12);

    % 等效整數化: fs_scaled = fs * den_f, freq_int = num_f
    % 原始 fs/freq = fs_scaled/num_f
    fs_scaled = fs * den_f;
    g = gcd(fs_scaled, num_f);

    min_periods = num_f / g;
    super_period_samples = fs_scaled / g;
end
