
# 京安救護氧氣計算 (Flutter)

這個專案只有兩個重點檔案：

- `pubspec.yaml`
- `lib/main.dart`

## 在雲端 (例如 Codemagic) 編譯 iOS 的建議流程

1. 建一個新的 Flutter 專案 Repo（或直接上傳這個 ZIP）。
2. 在 CI（例如 Codemagic）的第一個步驟加入：

   ```bash
   flutter create .
   ```

   讓它自動幫你產生 android/ 與 ios/ 等平台相關資料夾。

3. 再執行：

   ```bash
   flutter pub get
   flutter build ios --release
   ```

4. 用你的 Apple ID / App Store Connect 做 TestFlight 發佈。

你可以只用手機操作 Codemagic 的網頁介面。
