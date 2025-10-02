<div align="center">

# 🔄 Day 14: プロセス監視ワンライナー

[![難易度](https://img.shields.io/badge/難易度-🟠%20中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-35分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: サーバーでCPU・メモリを大量消費するプロセスを特定し、適切に対処したい。

**問題**: 複数プロセスの監視が手動で面倒。異常プロセスの検出と対応が遅れる。

**解決**: Rubyでプロセス情報を解析し、リソース監視と自動対応を実装！

## 📝 課題

プロセスのCPU・メモリ使用量監視、異常プロセス検出、プロセスツリー分析をワンライナーで実装してください。

### 🎯 期待する処理例
```bash
# リソース使用量監視
ps/top → CPU・メモリ使用率の高いプロセス特定

# 異常プロセス検出
ゾンビプロセス、暴走プロセスの検出

# プロセス管理
プロセスツリー分析、親子関係の可視化
```

## 💡 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `ps aux` | プロセス情報取得 | ⭐⭐⭐⭐⭐ |
| `top/htop` | リアルタイム監視 | ⭐⭐⭐⭐⭐ |
| `pgrep/pkill` | プロセス検索・操作 | ⭐⭐⭐⭐ |
| `プロセスツリー` | 親子関係分析 | ⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
プロセス情報の基本取得から始めましょう：

```ruby
# ヒント: この構造を完成させてください
processes = `ps aux`.lines[1..]
top_cpu = processes.sort_by { |line| line.split[2].to_f }.reverse.first(5)
puts "CPU使用率TOP5:"
top_cpu.each { |p| puts p }
```

### 🟡 応用レベル

<details>
<summary><strong>1. メモリ使用量監視</strong></summary>

```ruby
# メモリ使用率の高いプロセスを検出
processes = `ps aux`.lines[1..]
high_memory = processes.select { |line| line.split[3].to_f > 10.0 }
```

</details>

<details>
<summary><strong>2. 異常プロセス検出</strong></summary>

```ruby
# ゾンビプロセスや異常状態のプロセスを検出
zombie_processes = `ps aux`.lines.select { |line| line.include?("<defunct>") || line.include?("Z") }
```

</details>

### 🔴 実務レベル

<details>
<summary><strong>包括的プロセス監視システム</strong></summary>

リソース監視、異常検出、プロセスツリー分析、自動対応アクションを統合した監視システムを1行で実装。

</details>

## 📊 実際の業務での使用例

- 🔍 **リソース監視** - CPU・メモリ使用率の異常検出
- 🔄 **自動対応** - 暴走プロセスの自動kill、再起動
- 📈 **傾向分析** - プロセス起動パターンの統計分析
- 🚨 **アラート通知** - リソース枯渇の予兆検出

## 🛠️ 前提条件

このコースを実施するには以下が必要です：

- Linux/Unix環境
- ps、top等の基本コマンドの理解
- プロセス管理の基礎知識

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
