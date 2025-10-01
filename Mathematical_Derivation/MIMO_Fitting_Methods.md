# MIMO (多輸入多輸出) 系統識別方法

## 現有方法的問題

### 1. 當前方法 (Model_6_6_Continuous.m)
- **假設**：所有通道共享相同的極點 (A1, A2)
- **模型**：G(s) = B × A2/(s² + A1×s + A2)
- **問題**：ω² 加權導致高頻主導擬合

### 2. 為什麼會有 ω² 加權？
- 來自最小二乘法的正規方程
- 不是錯誤，但對寬頻帶系統不理想

## 實務上的 MIMO 系統識別方法

### 方法 1: 子空間識別 (Subspace Identification)
最常用於 MIMO 系統

```matlab
% MATLAB System Identification Toolbox
data = iddata(Y, U, Ts);  % Y:輸出, U:輸入, Ts:取樣時間
model = n4sid(data, order);  % 子空間方法
```

**優點**：
- 直接處理 MIMO
- 不需要迭代
- 數值穩定

**缺點**：
- 需要時域數據
- 黑箱模型

### 方法 2: 頻域識別 (Frequency Domain)
適合您現有的頻率響應數據

```matlab
% 方法 2a: 個別通道擬合
for i = 1:6
    for j = 1:6
        H_ij = squeeze(H_mag(i,j,:)) .* exp(1j*H_phase(i,j,:));
        % 對每個通道單獨擬合
        [num, den] = invfreqs(H_ij, W, n, m, weight);
    end
end

% 方法 2b: 矩陣分式描述 (Matrix Fraction Description)
% G(s) = N(s) × D(s)^(-1)
% 其中 N(s) 和 D(s) 是多項式矩陣
```

### 方法 3: 向量擬合 (Vector Fitting)
業界標準方法，特別適合寬頻帶

```matlab
% Vector Fitting Algorithm (Gustavsen & Semlyen, 1999)
% 迭代求解極點和留數

% 步驟 1: 初始極點猜測
poles_init = linspace(-1, -1000, N) * 2*pi;

% 步驟 2: 迭代優化
for iter = 1:max_iter
    % 求解留數
    [residues, poles] = solve_vf(H_data, W, poles_init);
    poles_init = poles;
end
```

**優點**：
- 適合寬頻帶 (Hz 到 GHz)
- 保證穩定性
- 廣泛應用於電力系統和電磁模擬

### 方法 4: 加權最小二乘法
修正現有方法的 ω² 問題

```matlab
% 方法 4a: 對數頻率加權
weight = 1 ./ W;  % 或 1./sqrt(W)

% 方法 4b: 均勻加權
weight = ones(size(W));

% 方法 4c: 自定義加權 (重視低頻)
weight = exp(-W/100);  % 指數衰減
```

### 方法 5: 共同極點約束 (Common Poles)
類似現有方法但改進

```matlab
% 使用正確的加權
A_weighted = zeros(38, 38);
Y_weighted = zeros(38, 1);

% 修改構建方程時的權重
for k = 1:num_freq
    wt = 1;  % 均勻權重，而非 w_k^2
    A_weighted(1,1) = A_weighted(1,1) + h_Lk(L,k)^2 * wt;
    % ...
end
```

## 推薦方案

### 對您的情況：

1. **短期修正**：修改現有代碼的加權
   ```matlab
   % 將 w_k(k)^2 改為合適的權重
   weight = ones(size(w_k));  % 均勻
   % 或
   weight = 1 ./ w_k;  % 補償 ω²
   ```

2. **中期改進**：個別通道擬合
   - 每個 Hij 單獨擬合
   - 可以有不同的階數

3. **長期最佳**：Vector Fitting
   - 業界標準
   - 有開源實現

## 實用建議

### 1. 檢查系統特性
```matlab
% 檢查是否真的需要共同極點
% 計算各通道的共振頻率
for i = 1:6
    for j = 1:6
        [pks, locs] = findpeaks(squeeze(H_mag(i,j,:)));
        fprintf('Channel (%d,%d): Peak at %.1f Hz\n', i, j, W(locs));
    end
end
```

### 2. 驗證擬合品質
```matlab
% 不只看總誤差，要分頻段檢查
error_low = mean(abs(H_model(1:5) - H_measured(1:5)));
error_mid = mean(abs(H_model(6:10) - H_measured(6:10)));
error_high = mean(abs(H_model(11:end) - H_measured(11:end)));
```

### 3. 物理意義
- 對角線元素：直接耦合
- 非對角線：交叉耦合
- 可能需要不同模型

## 結論

現有方法不是錯誤，但可以改進：
1. **ω² 加權**是數學推導的結果，可通過修改權重解決
2. **共同極點假設**可能過於簡化
3. **Vector Fitting** 是業界最佳實踐

## 參考文獻
1. Gustavsen & Semlyen (1999) - Vector Fitting
2. Van Overschee & De Moor (1996) - Subspace Identification
3. Pintelon & Schoukens (2012) - System Identification: A Frequency Domain Approach