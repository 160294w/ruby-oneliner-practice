<div align="center">

# Day 18: Terraform運用管理ワンライナー

[![難易度](https://img.shields.io/badge/難易度-上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-45分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: Terraformで管理しているインフラの状態監視、変更追跡、セキュリティ監査を効率化したい。

**問題**: tfstateファイルが複雑で全体像の把握が困難。変更の影響範囲が見えづらい。セキュリティリスクの検出が手動。

**解決**: Rubyでtfstate/planを解析し、運用管理を自動化！

## 課題

Terraform状態管理、変更追跡、コスト最適化、セキュリティ監査をワンライナーで実装してください。

### 期待する処理例
```bash
# 状態管理
terraform show -json → リソース一覧・依存関係分析

# 変更追跡
terraform plan → 変更影響の可視化・リスク評価

# セキュリティ監査
セキュリティグループ、IAMポリシーの検証
```

## 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `terraform show -json` | 状態ファイル解析 | ⭐⭐⭐⭐⭐ |
| `terraform plan` | 変更分析 | ⭐⭐⭐⭐⭐ |
| `JSON.parse` | tfstate解析 | ⭐⭐⭐⭐⭐ |
| `セキュリティ監査` | リスク検出 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
Terraform状態の基本取得から始めましょう：

```ruby
# ヒント: この構造を完成させてください
require 'json'
state = JSON.parse(`terraform show -json`)
resources = state["values"]["root_module"]["resources"] || []
resources.each { |r| puts "#{r['type']}.#{r['name']}" }
```

### 応用レベル

<details>
<summary><strong>1. リソースタイプ別集計</strong></summary>

```ruby
# AWS、GCPなどのリソースをタイプ別に集計
require 'json'
state = JSON.parse(File.read("sample_data/tfstate.json"))
resources = state["values"]["root_module"]["resources"]
by_type = resources.group_by { |r| r["type"] }
```

</details>

<details>
<summary><strong>2. セキュリティグループ監査</strong></summary>

```ruby
# 0.0.0.0/0からのインバウンドルールを検出
sgs = resources.select { |r| r["type"] == "aws_security_group" }
open_rules = sgs.select { |sg|
  sg["values"]["ingress"]&.any? { |rule| rule["cidr_blocks"]&.include?("0.0.0.0/0") }
}
```

</details>

### 実務レベル

<details>
<summary><strong>包括的運用管理システム</strong></summary>

状態監視、変更追跡、セキュリティ監査、コスト分析を統合した運用システムを1行で実装。

</details>

## 実際の業務での使用例

- 🔍 **状態監視** - リソース構成の可視化、ドリフト検出
- 📋 **変更管理** - 変更影響分析、承認プロセス支援
- 🔒 **セキュリティ監査** - 脆弱性検出、コンプライアンスチェック
- 💰 **コスト最適化** - リソース使用状況分析、削減提案

## 前提条件

このコースを実施するには以下が必要です：

- Terraform環境
- 基本的なTerraformの知識
- JSON形式の理解

---

<div align="center">

[メインページに戻る](../../../README.md) | [ヒントを見る](hints.md) | [解答例を確認](solution.rb)

</div>
