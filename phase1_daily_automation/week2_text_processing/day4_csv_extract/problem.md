<div align="center">

# Day 4: CSVから特定列抽出

[![難易度](https://img.shields.io/badge/難易度-初級-yellow?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-20分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: 月次売上レポートから特定部門のデータだけを抽出したい。大きなCSVファイルからExcelで開くのは重い。

**問題**: 手動でのデータ抽出は時間がかかり、ミスも発生しやすい。

**解決**: Rubyワンライナーで瞬時に必要なデータを抽出！

## 課題

CSVファイルから特定の列を抽出し、条件フィルタリングしてレポート生成をワンライナーで実現してください。

### 期待する処理例
```bash
# 売上データから営業部のみ抽出
sales.csv → 営業部の売上一覧

# 金額でフィルタリング
50,000円以上の売上のみ抽出

# 集計処理
部門別の売上合計を計算
```

## 学習ポイント

| メソッド/機能 | 用途 | 重要度 |
|--------------|------|--------|
| `CSV.read/foreach` | CSV読み込み | ⭐⭐⭐⭐⭐ |
| `select/reject` | データフィルタリング | ⭐⭐⭐⭐⭐ |
| `map` | 列選択・変換 | ⭐⭐⭐⭐ |
| `group_by/sum` | 集計処理 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
CSVの基本読み込みと列抽出から始めましょう：

```ruby
# ヒント: この構造を完成させてください
require 'csv'
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  puts "#{row['name']}: #{row['amount']}"
end
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `headers: true` でヘッダー行を列名として使用
- `row['列名']` で特定の列にアクセス
- `CSV.foreach` はメモリ効率が良い

</details>

### 応用レベル

<details>
<summary><strong>1. 条件フィルタリング</strong> - 特定部門のみ抽出</summary>

```ruby
require 'csv'
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  puts row if row['department'] == '営業部'
end
```

</details>

<details>
<summary><strong>2. 金額でフィルタリング</strong> - 高額売上の抽出</summary>

```ruby
require 'csv'
CSV.read("sample_data/sales.csv", headers: true)
  .select { |row| row['amount'].to_i >= 50000 }
  .each { |row| puts "#{row['name']}: #{row['amount']}円" }
```

</details>

<details>
<summary><strong>3. 部門別集計</strong> - グループ化と合計計算</summary>

```ruby
require 'csv'
sales = CSV.read("sample_data/sales.csv", headers: true)
dept_totals = sales.group_by { |row| row['department'] }
                   .transform_values { |rows| rows.sum { |r| r['amount'].to_i } }
dept_totals.each { |dept, total| puts "#{dept}: #{total}円" }
```

</details>

### 実務レベル

<details>
<summary><strong>売上分析レポートシステム</strong></summary>

複数CSVファイルの統合、時系列分析、トップ10抽出を1行で実装。

</details>

## 実際の業務での使用例

- 📈 **月次レポート生成** - 部門別売上集計
- 👥 **顧客分析** - セグメント別データ抽出
- 💰 **予算管理** - 予算超過項目の特定
- 🔍 **データクレンジング** - 不正データの除外

## 🎓 次のステップ

- ✅ 基本レベルクリア → [Day 5: ログファイルからエラー行抽出](../day5_log_errors/problem.md)
- 🔗 関連する実用例 → [CSV高度操作](../../../phase2_data_transformation/week3_structured_data/day8_csv_advanced/problem.md)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>