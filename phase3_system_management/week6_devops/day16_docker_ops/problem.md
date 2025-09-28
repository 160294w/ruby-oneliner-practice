<div align="center">

# 🐳 Day 16: Docker運用管理ワンライナー

[![難易度](https://img.shields.io/badge/難易度-🔴%20上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-40分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: Docker環境でのコンテナ監視、メンテナンス、トラブルシューティングを効率化したい。

**問題**: 複数コンテナの状態確認、ログ分析、リソース使用量の監視が手動で面倒。

**解決**: RubyとDockerコマンドを組み合わせた運用自動化！

## 📝 課題

Dockerコンテナの状態監視、ログ分析、メンテナンス作業をワンライナーで自動化してください。

### 🎯 期待する処理例
```bash
# コンテナ健康状態チェック
docker ps → 異常コンテナの特定・通知

# リソース使用量監視
メモリ・CPU使用率の高いコンテナ特定

# ログ分析
複数コンテナからエラーログを一括抽出
```

## 💡 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `docker ps/stats` | コンテナ状態監視 | ⭐⭐⭐⭐⭐ |
| `docker logs` | ログ分析 | ⭐⭐⭐⭐⭐ |
| `backtick/system` | Rubyからシェル実行 | ⭐⭐⭐⭐ |
| `JSON.parse` | Docker JSON出力解析 | ⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
Docker情報の基本取得から始めましょう：

```ruby
# ヒント: この構造を完成させてください
containers = `docker ps --format "table {{.Names}}\t{{.Status}}"`.lines[1..]
containers.each { |line| puts line.strip }
```

### 🟡 応用レベル

<details>
<summary><strong>1. 異常コンテナ検出</strong></summary>

```ruby
# Exitedまたは異常ステータスのコンテナを特定
abnormal = `docker ps -a --format "{{.Names}},{{.Status}}"`.lines
           .select { |line| line.include?("Exited") || line.include?("Dead") }
```

</details>

<details>
<summary><strong>2. リソース使用量監視</strong></summary>

```ruby
# CPU使用率50%以上のコンテナを特定
require 'json'
stats = `docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"`
high_cpu = stats.lines[1..].select { |line| line.split[1].to_f > 50.0 }
```

</details>

### 🔴 実務レベル

<details>
<summary><strong>包括的監視システム</strong></summary>

健康状態チェック、リソース監視、ログ分析、アラート通知を統合した監視システムを1行で実装。

</details>

## 📊 実際の業務での使用例

- 🔍 **コンテナ健康監視** - 異常終了、リソース枯渇の早期発見
- 📋 **ログ集約分析** - 複数コンテナからのエラーログ収集
- 🔄 **自動メンテナンス** - 不要イメージ削除、ログローテーション
- 🚨 **アラート通知** - Slackやメール通知との連携

## 🛠️ 前提条件

このコースを実施するには以下が必要です：

- Docker環境（Docker Desktop推奨）
- 実行権限のあるDockerコマンド
- 基本的なLinuxコマンドの知識

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>