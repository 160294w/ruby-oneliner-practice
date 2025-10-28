<div align="center">

# Day 5: ログファイルからエラー行抽出

[![難易度](https://img.shields.io/badge/難易度-中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-25分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: 本番環境でエラーが発生。数万行のログファイルから原因を素早く特定する必要がある。

**問題**: ログファイルが大きすぎてエディタで開けない。手動でのエラー検索は時間がかかりすぎる。

**解決**: Rubyワンライナーで瞬時にエラー行を抽出・分析！

## 課題

ログファイルからエラー・警告を抽出し、時間範囲指定、統計情報生成をワンライナーで実現してください。

### 期待する処理例
```bash
# エラーレベル別にカウント
ERROR: 15件, WARNING: 32件, INFO: 2,453件

# 特定時間範囲のエラー抽出
14:00～15:00のエラーログ

# エラーパターンの分析
"Database connection failed" が5回発生
```

## 学習ポイント

| メソッド/機能 | 用途 | 重要度 |
|--------------|------|--------|
| `File.readlines` | ログファイル読み込み | ⭐⭐⭐⭐⭐ |
| `select/grep` | パターンマッチ | ⭐⭐⭐⭐⭐ |
| `match/scan` | 正規表現抽出 | ⭐⭐⭐⭐ |
| `group_by/count` | 統計処理 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
ログからエラー行を抽出することから始めましょう：

```ruby
# ヒント: この構造を完成させてください
File.readlines("sample_data/app.log").each do |line|
  puts line if line.include?("ERROR")
end
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `File.readlines` で全行を配列として取得
- `include?` で文字列の含有チェック
- `grep` でパターンマッチング

</details>

### 応用レベル

<details>
<summary><strong>1. レベル別カウント</strong> - ERROR/WARNING/INFO の統計</summary>

```ruby
logs = File.readlines("sample_data/app.log")
levels = {ERROR: 0, WARNING: 0, INFO: 0}
logs.each do |line|
  levels[:ERROR] += 1 if line.include?("ERROR")
  levels[:WARNING] += 1 if line.include?("WARNING")
  levels[:INFO] += 1 if line.include?("INFO")
end
puts levels
```

</details>

<details>
<summary><strong>2. 時間範囲指定</strong> - 特定時間帯のエラー抽出</summary>

```ruby
File.readlines("sample_data/app.log")
  .select { |line| line.match(/2024-\d{2}-\d{2} 14:/) && line.include?("ERROR") }
  .each { |line| puts line }
```

</details>

<details>
<summary><strong>3. エラーパターン分析</strong> - 頻出エラーメッセージの特定</summary>

```ruby
errors = File.readlines("sample_data/app.log")
  .select { |line| line.include?("ERROR") }
  .map { |line| line.match(/ERROR: (.+)$/)[1] rescue "Unknown" }
  .group_by(&:itself)
  .transform_values(&:size)
  .sort_by { |_, count| -count }
errors.each { |msg, count| puts "#{msg}: #{count}回" }
```

</details>

### 実務レベル

<details>
<summary><strong>包括的ログ分析システム</strong></summary>

複数ログファイルの統合分析、異常パターン検出、アラート生成を1行で実装。

</details>

## 実際の業務での使用例

- 🚨 **障害対応** - エラー原因の迅速な特定
- **パフォーマンス分析** - 応答時間の遅いリクエスト抽出
- 🔒 **セキュリティ監視** - 不正アクセスの検出
- 📊 **トレンド分析** - エラー発生傾向の把握

## 🎓 次のステップ

- 基本レベルクリア → [Day 6: 複数ファイルの文字列一括置換](../day6_bulk_replace/problem.md)
- 関連する実用例 → [ログ分析実践](../../../phase2_data_transformation/week4_text_processing/day10_log_analysis/problem.md)

---

<div align="center">

[メインページに戻る](../../../README.md) | [ヒントを見る](hints.md) | [解答例を確認](solution.rb)

</div>