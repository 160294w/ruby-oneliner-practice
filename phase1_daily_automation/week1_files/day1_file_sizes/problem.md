<div align="center">

# 📏 Day 1: ファイルサイズ一覧表示

[![難易度](https://img.shields.io/badge/難易度-🟢%20基本-green?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-15分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: 開発チームのプロジェクトで、ディスク容量を圧迫しているファイルを素早く見つけたい。

**問題**: 手動で一つずつファイルサイズを確認するのは時間がかかりすぎる。

**解決**: Rubyワンライナーで瞬時にファイルサイズ一覧を表示！

## 📝 課題

カレントディレクトリ内の`.txt`ファイルすべてのファイルサイズを一覧表示するRubyワンライナーを書いてください。

### 🎯 期待する出力例
```bash
sample1.txt: 52 bytes
sample2.txt: 95 bytes
sample3.txt: 11 bytes
large_sample.txt: 462 bytes
```

## 💡 学習ポイント

この課題で習得できるスキル：

| メソッド | 用途 | 重要度 |
|----------|------|--------|
| `Dir.glob()` | ファイルパターンマッチング | ⭐⭐⭐⭐⭐ |
| `File.size()` | ファイルサイズ取得 | ⭐⭐⭐⭐ |
| `each` | 繰り返し処理 | ⭐⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
まずは基本的な形から始めましょう：

```ruby
# ヒント: この構造を完成させてください
Dir.glob("sample_data/*.txt").each { |file| puts "#{File.basename(file)}: #{___} bytes" }
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `File.size(ファイルパス)` でファイルサイズを取得できます
- `File.basename(パス)` でファイル名のみを取得できます

</details>

### 🟡 応用レベル
基本ができたら、これらにも挑戦してみてください：

<details>
<summary><strong>1. ファイルサイズでソート</strong> - 大きいファイルから順に表示</summary>

```ruby
# ヒント: sort_by を使って、サイズの降順でソート
Dir.glob("sample_data/*.txt").sort_by { |f| -File.size(f) }.each { |file| ... }
```

</details>

<details>
<summary><strong>2. 単位変換</strong> - 1KB以上はKB表示に変換</summary>

```ruby
# ヒント: 三項演算子で条件分岐
size >= 1024 ? "#{(size/1024.0).round(1)} KB" : "#{size} bytes"
```

</details>

<details>
<summary><strong>3. 合計サイズ表示</strong> - 全ファイルの合計サイズも表示</summary>

```ruby
# ヒント: sum メソッドでファイルサイズの合計を計算
files = Dir.glob("sample_data/*.txt")
total = files.sum { |f| File.size(f) }
```

</details>

### 🔴 実務レベル
より実践的な機能を追加：

<details>
<summary><strong>ワンライナーで全機能実装</strong></summary>

ソート、単位変換、合計表示をすべて1行で実現してみましょう。

</details>

## 📊 実際の業務での使用例

この技術が活躍する場面：

- 🗂️ **ログファイルのサイズ監視**
- 💾 **バックアップファイルの容量チェック**
- 🎨 **プロジェクトのアセットファイル管理**
- 📈 **ディスク使用量の定期チェック**

## 🎓 次のステップ

- ✅ 基本レベルクリア → [Day 2: ファイル行数カウント](../day2_line_count/problem.md)
- 🔗 関連する実用例 → [チートシート](../../../resources/cheatsheet.md#ファイルディレクトリ操作)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>