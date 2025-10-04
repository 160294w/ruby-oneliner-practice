<div align="center">

# 🔄 Day 20: CI/CDパイプライン管理

[![難易度](https://img.shields.io/badge/難易度-🔴%20上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-45分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: GitHub ActionsやGitLab CIでCI/CDパイプラインを運用しているが、ビルド失敗の原因分析やテスト結果の集計に時間がかかっている。

**問題**:
- ビルドログが膨大で失敗原因の特定が困難
- テスト結果を手動で確認するのは非効率
- パイプライン実行時間の最適化ポイントが不明

**解決**: Rubyワンライナーで CI/CDログ解析、テスト結果集計、パフォーマンス分析を自動化！

## 📝 課題

CI/CDパイプラインのログ解析、ビルド失敗分析、テスト結果レポート生成をワンライナーで実装してください。

### 🎯 期待する処理例
```bash
# GitHub Actions ログ解析
ビルド失敗の原因を自動抽出

# テスト結果サマリー
成功/失敗/スキップの統計を生成

# パイプライン実行時間分析
ステップ別の実行時間を可視化
```

## 💡 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `JSON.parse` | CI/CDログのJSON解析 | ⭐⭐⭐⭐⭐ |
| `正規表現` | エラーメッセージ抽出 | ⭐⭐⭐⭐⭐ |
| `統計処理` | テスト結果の集計 | ⭐⭐⭐⭐ |
| `時間計算` | 実行時間の分析 | ⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
CI/CDログの基本解析から始めましょう：

```ruby
# ヒント: この構造を完成させてください
# ログファイルからエラーを抽出
log_lines = File.readlines("ci_log.txt")
errors = log_lines.select { |line| line =~ /ERROR|FAIL|error/ }
puts "エラー: #{errors.size}件"
```

<details>
<summary>💡 基本レベルのヒント</summary>

- GitHub ActionsのログはJSON形式で取得可能
- `gh run view <run_id> --log` でログ取得
- エラーパターンは`ERROR`, `FAIL`, `✗`など

</details>

### 🟡 応用レベル

<details>
<summary><strong>1. テスト結果の集計</strong></summary>

```ruby
# JUnit XML形式のテスト結果を解析
require 'rexml/document'

xml = File.read("test_results.xml")
doc = REXML::Document.new(xml)

tests = doc.elements["testsuites"].attributes["tests"].to_i
failures = doc.elements["testsuites"].attributes["failures"].to_i
errors = doc.elements["testsuites"].attributes["errors"].to_i
skipped = doc.elements["testsuites"].attributes["skipped"].to_i

puts "テスト結果:"
puts "  成功: #{tests - failures - errors - skipped}"
puts "  失敗: #{failures}"
puts "  エラー: #{errors}"
puts "  スキップ: #{skipped}"
```

</details>

<details>
<summary><strong>2. ビルド失敗の原因分析</strong></summary>

```ruby
# GitHub Actions ログからエラー原因を抽出
log = File.read("github_actions_log.txt")

error_patterns = {
  "依存関係エラー" => /npm ERR!|bundle install failed|pip install error/,
  "テスト失敗" => /FAILED|Test.*failed|AssertionError/,
  "ビルドエラー" => /build failed|compilation error|webpack.*error/,
  "Lint エラー" => /ESLint|rubocop|flake8.*error/
}

error_patterns.each do |category, pattern|
  matches = log.scan(pattern)
  puts "#{category}: #{matches.size}件" if matches.any?
end
```

</details>

<details>
<summary><strong>3. パイプライン実行時間の分析</strong></summary>

```ruby
# ステップ別実行時間の抽出
require 'json'

workflow_log = JSON.parse(File.read("workflow_run.json"))
steps = workflow_log["jobs"]["build"]["steps"]

steps.each do |step|
  name = step["name"]
  started = Time.parse(step["started_at"])
  completed = Time.parse(step["completed_at"])
  duration = completed - started

  puts "#{name}: #{duration.to_i}秒"
end
```

</details>

### 🔴 実務レベル

<details>
<summary><strong>CI/CD統合監視システム</strong></summary>

ビルド状態監視、失敗原因分析、テスト結果レポート、パフォーマンス最適化提案を統合したシステムを1行で実装。

</details>

## 📊 実際の業務での使用例

- 🔍 **ビルド失敗分析** - エラーパターンの自動分類と対策提案
- 📈 **テストレポート** - テスト結果の日次レポート自動生成
- ⏱️ **パフォーマンス監視** - パイプライン実行時間の推移追跡
- 🚨 **アラート通知** - ビルド失敗時の自動通知とチケット作成

## 🛠️ 前提条件

このコースを実施するには以下が必要です：

- CI/CDツール（GitHub Actions / GitLab CI / CircleCI等）
- `gh` CLI（GitHub Actions利用時）
- 基本的なCI/CD概念の理解

## 💡 実用ワンライナー例

```bash
# GitHub Actions最新のrunのログを取得してエラー抽出
gh run view $(gh run list --limit 1 --json databaseId -q '.[0].databaseId') --log | ruby -ne 'puts $_ if /ERROR|FAIL/'

# テスト成功率の計算
ruby -rrexml/document -e 'doc = REXML::Document.new(File.read("test_results.xml")); ts = doc.elements["testsuites"]; total = ts.attributes["tests"].to_i; failed = ts.attributes["failures"].to_i; puts "成功率: #{"%.1f" % ((total - failed) * 100.0 / total)}%"'

# ビルド時間TOP5ステップ
jq '.jobs.build.steps[] | {name: .name, duration: (.completed_at | fromdateiso8601) - (.started_at | fromdateiso8601)}' workflow.json | ruby -rjson -e 'steps = STDIN.readlines.map { |l| JSON.parse(l) }; steps.sort_by { |s| -s["duration"] }.first(5).each { |s| puts "#{s["name"]}: #{s["duration"]}秒" }'

# 失敗したジョブのみ抽出
gh run view --json jobs | ruby -rjson -e 'data = JSON.parse(STDIN.read); data["jobs"].select { |j| j["conclusion"] == "failure" }.each { |j| puts j["name"] }'
```

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
