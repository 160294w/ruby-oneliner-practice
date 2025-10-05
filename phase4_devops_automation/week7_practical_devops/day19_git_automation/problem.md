<div align="center">

# Day 19: Git操作・バージョン管理自動化

[![難易度](https://img.shields.io/badge/難易度-中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-40分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: 複数のGitリポジトリを管理しており、日々の運用（pull、status確認、ブランチ整理）に時間がかかっている。

**問題**:
- 10個以上のリポジトリを手動で更新するのは非効率
- マージ済みブランチが溜まってリポジトリが肥大化
- コミット履歴の分析が手作業で面倒

**解決**: Rubyワンライナーで複数リポジトリの一括操作とバージョン管理を自動化！

## 課題

複数リポジトリの一括操作、コミット履歴分析、ブランチ管理をワンライナーで実装してください。

### 期待する処理例
```bash
# 複数リポジトリの一括pull
~/projects/* → すべて最新に更新

# コミット統計の生成
著者別、日付別のコミット数を集計

# マージ済みブランチの自動削除
mainにマージ済みのローカルブランチをクリーンアップ
```

## 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `git log --format` | コミット履歴の解析 | ⭐⭐⭐⭐⭐ |
| `git branch --merged` | マージ済みブランチ検出 | ⭐⭐⭐⭐⭐ |
| `git status --porcelain` | 変更状態の取得 | ⭐⭐⭐⭐ |
| `Dir.glob` | 複数リポジトリ走査 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
単一リポジトリの基本操作から始めましょう：

```ruby
# ヒント: この構造を完成させてください
# コミット履歴の取得
commits = `git log --oneline -10`.lines
puts "最近のコミット: #{commits.size}件"
commits.each { |c| puts c }
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `git log --format="%h %an %s"` でカスタムフォーマット
- `git branch` でブランチ一覧
- `git status --short` で変更ファイル確認

</details>

### 応用レベル

<details>
<summary><strong>1. 複数リポジトリの一括status確認</strong></summary>

```ruby
# ~/projects配下の全リポジトリの状態確認
Dir.glob("#{ENV['HOME']}/projects/*").each do |repo|
  next unless Dir.exist?("#{repo}/.git")

  Dir.chdir(repo) do
    status = `git status --porcelain`
    branch = `git rev-parse --abbrev-ref HEAD`.chomp

    if status.empty?
      puts "✅ #{File.basename(repo)} (#{branch}): クリーン"
    else
      puts "⚠️  #{File.basename(repo)} (#{branch}): #{status.lines.size}個の変更"
    end
  end
end
```

</details>

<details>
<summary><strong>2. コミット履歴の統計分析</strong></summary>

```ruby
# 著者別コミット数
author_stats = `git log --format="%an"`.lines
  .map(&:chomp)
  .tally
  .sort_by { |_, count| -count }

puts "著者別コミット数:"
author_stats.first(5).each do |author, count|
  puts "  #{author}: #{count}件"
end
```

</details>

<details>
<summary><strong>3. マージ済みブランチの削除</strong></summary>

```ruby
# mainにマージ済みのローカルブランチを削除
merged_branches = `git branch --merged main`.lines
  .map(&:chomp)
  .map(&:strip)
  .reject { |b| b =~ /^\*|^main$|^master$/ }

if merged_branches.any?
  puts "マージ済みブランチ: #{merged_branches.join(', ')}"
  merged_branches.each { |branch| system("git branch -d #{branch}") }
else
  puts "削除可能なブランチはありません"
end
```

</details>

### 実務レベル

<details>
<summary><strong>包括的なGit管理システム</strong></summary>

複数リポジトリの状態監視、コミット統計、ブランチ管理、未pushコミット検出を統合したシステムを1行で実装。

</details>

## 実際の業務での使用例

- **複数リポジトリ管理** - マイクロサービス環境での一括更新
- **コントリビューション分析** - チームメンバーの活動量可視化
- **リポジトリクリーンアップ** - 不要なブランチの自動削除
- **変更追跡** - 未コミット・未pushの変更検出

## 前提条件

このコースを実施するには以下が必要です：

- Git環境（コマンドラインツール）
- 複数のGitリポジトリ（練習用に作成可能）
- 基本的なGitコマンドの理解

## 実用ワンライナー例

```bash
# 全リポジトリを一括pull
for d in ~/projects/*; do (cd "$d" && git pull); done | ruby -ne 'puts $_'

# 今週のコミット数
git log --since="1 week ago" --format="%an" | ruby -e 'puts STDIN.readlines.tally'

# リモートにpushされていないコミット数
git log @{u}.. --oneline | ruby -ne 'BEGIN{c=0}; c+=1; END{puts "未push: #{c}件"}'

# 過去30日のコミット日別統計
git log --since="30 days ago" --format="%ad" --date=short | ruby -e 'puts STDIN.readlines.map(&:chomp).tally.sort'
```

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
