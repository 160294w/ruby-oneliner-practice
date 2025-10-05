<div align="center">

# Day 13: ログ分析・監視ワンライナー

[![難易度](https://img.shields.io/badge/難易度-中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-35分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: Linuxサーバーのログ監視で、セキュリティイベントやシステム異常を早期発見したい。

**問題**: syslog、journalctlの出力が膨大で手動確認が困難。重要なエラーやセキュリティイベントの見逃しが発生。

**解決**: Rubyでログを解析し、リアルタイム監視とアラート生成を自動化！

## 課題

systemdジャーナル、syslogの解析、リアルタイム監視、セキュリティイベント検出をワンライナーで実装してください。

### 期待する処理例
```bash
# ログからエラー検出
journalctl/syslog → エラーレベルの集計・分類

# セキュリティイベント検出
認証失敗、不正アクセス試行の検出

# リアルタイム監視
特定パターンのログ発生時にアラート
```

## 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `journalctl` | systemdログ解析 | ⭐⭐⭐⭐⭐ |
| `syslog/rsyslog` | 従来型ログ解析 | ⭐⭐⭐⭐⭐ |
| `正規表現` | ログパターンマッチ | ⭐⭐⭐⭐⭐ |
| `Time.parse` | ログタイムスタンプ処理 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
ログファイルの基本解析から始めましょう：

```ruby
# ヒント: この構造を完成させてください
log_lines = File.readlines("sample_data/syslog.log")
errors = log_lines.select { |line| line.include?("ERROR") || line.include?("FAIL") }
puts "エラー件数: #{errors.size}"
```

### 応用レベル

<details>
<summary><strong>1. ログレベル別集計</strong></summary>

```ruby
# INFO、WARN、ERROR、CRITICALの件数を集計
log_levels = Hash.new(0)
log_lines.each { |line|
  log_levels[:error] += 1 if line =~ /ERROR|error/
  log_levels[:warn] += 1 if line =~ /WARN|warning/
}
```

</details>

<details>
<summary><strong>2. セキュリティイベント検出</strong></summary>

```ruby
# 認証失敗、sudoコマンド、SSH接続を検出
security_events = log_lines.select do |line|
  line =~ /authentication failure|Failed password|sudo:|sshd/
end
```

</details>

### 実務レベル

<details>
<summary><strong>包括的ログ監視システム</strong></summary>

エラー集計、セキュリティイベント検出、異常パターン分析、アラート生成を統合した監視システムを1行で実装。

</details>

## 実際の業務での使用例

- 🔍 **リアルタイム監視** - エラーログの即時検出とアラート
- 🔒 **セキュリティ監査** - 不正アクセス試行、権限昇格の検出
- 📈 **傾向分析** - エラー発生パターンの統計分析
- 🚨 **障害予兆検出** - ディスク満杯、メモリ不足の早期発見

## 前提条件

このコースを実施するには以下が必要です：

- Linux環境（systemd使用環境推奨）
- journalctlコマンドまたはsyslogファイルへのアクセス
- 基本的なログ形式の理解

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
