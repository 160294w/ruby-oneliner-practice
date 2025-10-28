<div align="center">

# Day 8: CSV高度データ操作

[![難易度](https://img.shields.io/badge/難易度-中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-30分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: 売上データ、ユーザー行動ログ、システムメトリクスなど、大量のCSVデータを分析する必要がある。

**問題**: Excel開くと重い、SQLは複雑、PythonやRは別途環境構築が必要。

**解決**: Rubyワンライナーで高速データ分析・集計・変換！

## 課題

複数のCSVファイルから統計情報の抽出、データ結合、条件集計をワンライナーで実現してください。

### 期待する処理例
```bash
# 売上の部門別集計
sales.csv → 部門ごとの売上合計

# 時系列データの分析
日別売上の推移、前日比計算

# 複数CSVファイルのマージ
users.csv + orders.csv → 顧客別注文統計
```

## 学習ポイント

| メソッド/機能 | 用途 | 重要度 |
|--------------|------|--------|
| `CSV.read/foreach` | CSV読み込み | ⭐⭐⭐⭐⭐ |
| `group_by` | グループ集計 | ⭐⭐⭐⭐⭐ |
| `sum/max/min` | 統計計算 | ⭐⭐⭐⭐ |
| `join/merge` | データ結合 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
売上データの基本集計から始めましょう：

```ruby
# ヒント: この構造を完成させてください
require 'csv'
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  # 売上合計を計算
end
```

### 応用レベル

<details>
<summary><strong>1. 部門別売上集計</strong></summary>

```ruby
require 'csv'
sales = CSV.read("sample_data/sales.csv", headers: true)
dept_sales = sales.group_by { |row| row["department"] }
              .transform_values { |rows| rows.sum { |r| r["amount"].to_i } }
```

</details>

<details>
<summary><strong>2. 時系列分析</strong> - 月別推移</summary>

```ruby
# 月別売上の推移
monthly = sales.group_by { |row| row["date"][0..6] } # YYYY-MM
               .transform_values { |rows| rows.sum { |r| r["amount"].to_i } }
```

</details>

### 実務レベル

<details>
<summary><strong>顧客分析システム</strong></summary>

複数CSVから顧客のLTV（Life Time Value）計算、購入パターン分析を1行で実装。

</details>

## 実際の業務での使用例

- **売上分析** - 部門別、期間別パフォーマンス分析
- 👥 **顧客分析** - 購買行動、セグメント分析
- 🖥️ **システムメトリクス** - サーバー使用率、レスポンス時間分析
- 🔄 **データ移行** - レガシーシステムからの大量データ変換

---

<div align="center">

[メインページに戻る](../../../README.md) | [ヒントを見る](hints.md) | [解答例を確認](solution.rb)

</div>