# Git 分支工作流程指南

## 專案分支結構

- `main`: 主分支（穩定版本）
- `weighted-multi-curve-v2`: 加權多曲線分析開發分支

## 常用操作指令

### 1. 查看目前所在分支
```bash
git branch
```
或查看所有分支（包含遠端）：
```bash
git branch -a
```

### 2. 切換分支

#### 切換到主分支
```bash
git checkout main
```

#### 切換到開發分支
```bash
git checkout weighted-multi-curve-v2
```

### 3. 在分支上工作

#### 查看修改狀態
```bash
git status
```

#### 添加修改的檔案
```bash
# 添加所有修改
git add .

# 或添加特定檔案
git add <檔案名稱>
```

#### 提交修改
```bash
git commit -m "提交訊息說明"
```

#### 推送到 GitHub
```bash
# 第一次推送分支
git push -u origin weighted-multi-curve-v2

# 之後的推送
git push
```

### 4. 同步遠端更新

#### 拉取最新變更
```bash
git pull
```

#### 拉取主分支的最新變更
```bash
git checkout main
git pull origin main
```

### 5. 合併分支

#### 將開發分支合併到主分支
```bash
# 1. 先切換到主分支
git checkout main

# 2. 合併開發分支
git merge weighted-multi-curve-v2

# 3. 推送合併結果
git push origin main
```

### 6. 查看分支差異

#### 查看兩個分支的差異
```bash
git diff main..weighted-multi-curve-v2
```

#### 查看提交歷史
```bash
git log --oneline --graph --all
```

## 建議的工作流程

1. **開始新功能開發**
   ```bash
   git checkout weighted-multi-curve-v2
   git pull  # 確保是最新版本
   ```

2. **進行開發工作**
   - 修改程式碼
   - 測試功能

3. **提交變更**
   ```bash
   git add .
   git commit -m "描述你的修改"
   git push
   ```

4. **功能完成後合併到主分支**
   ```bash
   git checkout main
   git pull
   git merge weighted-multi-curve-v2
   git push
   ```

5. **切回開發分支繼續工作**
   ```bash
   git checkout weighted-multi-curve-v2
   ```

## 注意事項

- 在切換分支前，請確保目前的修改已提交或暫存（stash）
- 定期將開發分支推送到 GitHub，避免資料遺失
- 合併前建議先在開發分支測試完整功能
- 如果需要暫存目前修改：
  ```bash
  git stash        # 暫存修改
  git stash pop    # 恢復暫存的修改
  ```

## 目前分支狀態

目前你在 `weighted-multi-curve-v2` 分支上，已完成第一次提交。可以使用以下指令推送到 GitHub：

```bash
git push -u origin weighted-multi-curve-v2
```
