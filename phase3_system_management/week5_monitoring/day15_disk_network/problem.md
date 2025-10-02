<div align="center">

# 💾 Day 15: ディスク・ネットワーク監視ワンライナー

[![難易度](https://img.shields.io/badge/難易度-🔴%20上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-40分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: サーバーのディスク容量不足やネットワーク異常を早期発見し、障害を予防したい。

**問題**: ディスク使用率、I/O性能、ネットワーク通信の監視が手動で困難。障害発生後の対応になりがち。

**解決**: Rubyでディスク・ネットワーク情報を解析し、予防保守を実現！

## 📝 課題

ディスク使用量・I/O監視、ネットワーク通信監視、閾値監視、予防保守をワンライナーで実装してください。

### 🎯 期待する処理例
```bash
# ディスク監視
df/iostat → 容量不足・I/O遅延の検出

# ネットワーク監視
ss/netstat → 異常接続・ポート監視

# 閾値監視
使用率80%超の自動アラート
```

## 💡 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `df -h` | ディスク使用量 | ⭐⭐⭐⭐⭐ |
| `iostat` | I/O統計 | ⭐⭐⭐⭐ |
| `ss/netstat` | ネットワーク状態 | ⭐⭐⭐⭐⭐ |
| `閾値判定` | アラート生成 | ⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
ディスク情報の基本取得から始めましょう：

```ruby
# ヒント: この構造を完成させてください
df_output = `df -h`.lines[1..]
df_output.each do |line|
  cols = line.split
  usage = cols[4].to_i
  puts "⚠️ #{cols[0]}: #{cols[4]}" if usage > 80
end
```

### 🟡 応用レベル

<details>
<summary><strong>1. ディスク容量予測</strong></summary>

```ruby
# 使用率の増加傾向から容量不足時期を予測
# 過去データと現在を比較して増加率を計算
```

</details>

<details>
<summary><strong>2. ネットワーク接続監視</strong></summary>

```ruby
# ESTABLISHED接続数、LISTEN ポート、異常接続の検出
connections = `ss -tan`.lines[1..]
established = connections.count { |line| line.include?("ESTAB") }
```

</details>

### 🔴 実務レベル

<details>
<summary><strong>統合監視システム</strong></summary>

ディスク・ネットワーク・I/Oを包括的に監視し、予測分析とアラート生成を行うシステムを1行で実装。

</details>

## 📊 実際の業務での使用例

- 💾 **容量管理** - ディスク容量不足の予防
- 🔍 **I/O監視** - ディスクボトルネック検出
- 🌐 **ネットワーク監視** - 異常接続・DDoS検出
- 📈 **傾向分析** - 容量増加予測、予防保守

## 🛠️ 前提条件

このコースを実施するには以下が必要です：

- Linux環境
- df、ss/netstat、iostat等のコマンド
- システム監視の基礎知識

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
