<div align="center">

# Day 6: 複数ファイルの文字列一括置換

[![難易度](https://img.shields.io/badge/難易度-中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-25分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: 開発環境から本番環境への移行時、複数の設定ファイルのホスト名やAPIエンドポイントを一括変更する必要がある。

**問題**: 手動で各ファイルを開いて置換するのは時間がかかり、ミスも発生しやすい。

**解決**: Rubyワンライナーで安全・確実に一括置換！

## 課題

複数ファイルの文字列を一括置換し、バックアップ作成、プレビュー機能をワンライナーで実現してください。

### 期待する処理例
```bash
# 開発環境→本番環境への置換
localhost → production.example.com

# API URLの一括更新
http://dev-api.com → https://api.example.com

# バックアップ付き安全な置換
元ファイルは .bak として保存
```

## 学習ポイント

| メソッド/機能 | 用途 | 重要度 |
|--------------|------|--------|
| `Dir.glob` | ファイル検索 | ⭐⭐⭐⭐⭐ |
| `gsub` | 文字列置換 | ⭐⭐⭐⭐⭐ |
| `File.write` | ファイル書き込み | ⭐⭐⭐⭐ |
| `FileUtils.cp` | バックアップ作成 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
1つのファイルの文字列置換から始めましょう：

```ruby
# ヒント: この構造を完成させてください
content = File.read("sample_data/config.txt")
new_content = content.gsub("localhost", "production.example.com")
File.write("sample_data/config.txt", new_content)
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `File.read` でファイル内容を取得
- `gsub` で全ての該当文字列を置換
- `File.write` で変更を保存

</details>

### 応用レベル

<details>
<summary><strong>1. 複数ファイル一括置換</strong></summary>

```ruby
Dir.glob("sample_data/*.txt").each do |file|
  content = File.read(file)
  new_content = content.gsub("localhost", "production.example.com")
  File.write(file, new_content)
  puts "✅ #{file} を更新しました"
end
```

</details>

<details>
<summary><strong>2. バックアップ付き置換</strong></summary>

```ruby
require 'fileutils'
Dir.glob("sample_data/*.txt").each do |file|
  FileUtils.cp(file, "#{file}.bak")
  content = File.read(file)
  new_content = content.gsub("localhost", "production.example.com")
  File.write(file, new_content)
  puts "✅ #{file} 更新 (バックアップ: #{file}.bak)"
end
```

</details>

<details>
<summary><strong>3. 正規表現パターン置換</strong></summary>

```ruby
# URLパターンの置換
content.gsub(/http:\/\/[\w.-]+/, "https://production.example.com")

# 環境変数形式の置換
content.gsub(/\$\{(\w+)_HOST\}/, 'production-\\1.example.com')
```

</details>

### 実務レベル

<details>
<summary><strong>安全な一括置換システム</strong></summary>

プレビュー、確認プロンプト、ロールバック機能付きの置換システムを実装。

</details>

## 実際の業務での使用例

- 🚀 **環境移行** - 開発→ステージング→本番への設定変更
- 🔧 **リファクタリング** - 変数名・関数名の一括変更
- 📝 **ドキュメント更新** - 製品名・バージョン番号の一括更新
- 🔐 **セキュリティ対応** - APIキー・認証情報の更新

## 🎓 次のステップ

- ✅ 基本レベルクリア → [Phase2: データ変換マスター](../../../phase2_data_transformation/)
- 🔗 関連する実用例 → [チートシート](../../../resources/cheatsheet.md)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>