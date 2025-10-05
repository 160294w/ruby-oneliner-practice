# Day 19: ヒントとステップガイド

## 段階的に考えてみよう

### Step 1: Git logの基本取得
```ruby
# 基本的なログ取得
commits = `git log --oneline -10`.lines
commits.each { |c| puts c }

# カスタムフォーマット
commits = `git log --format="%h %an %ad %s" --date=short -10`.lines
```

### Step 2: コミット情報のパース
```ruby
# コミット情報を構造化
commits = `git log --format="%h|%an|%ad|%s" --date=short -20`.lines.map do |line|
  hash, author, date, subject = line.chomp.split('|')
  { hash: hash, author: author, date: date, subject: subject }
end

commits.each do |commit|
  puts "#{commit[:author]} (#{commit[:date]}): #{commit[:subject]}"
end
```

### Step 3: ブランチ情報の取得
```ruby
# 全ブランチ一覧
branches = `git branch`.lines.map { |b| b.strip.sub(/^\* /, '') }

# カレントブランチ
current_branch = `git rev-parse --abbrev-ref HEAD`.chomp

# マージ済みブランチ
merged = `git branch --merged main`.lines.map(&:strip)
```

## よく使うパターン

### パターン1: 著者別コミット統計
```ruby
# 著者別コミット数
author_commits = `git log --format="%an"`.lines
  .map(&:chomp)
  .tally
  .sort_by { |_, count| -count }

puts "著者別コミット数:"
author_commits.each do |author, count|
  puts "  #{author}: #{count}件"
end

# 著者別・期間指定
recent_authors = `git log --since="1 week ago" --format="%an"`.lines
  .map(&:chomp)
  .tally
```

### パターン2: 日付別コミット統計
```ruby
# 日付別コミット数
commits_by_date = `git log --format="%ad" --date=short`.lines
  .map(&:chomp)
  .tally
  .sort
  .reverse

puts "日付別コミット数:"
commits_by_date.first(10).each do |date, count|
  puts "  #{date}: #{count}件"
end

# 曜日別統計
commits_by_dow = `git log --format="%ad" --date=format:"%A"`.lines
  .map(&:chomp)
  .tally
  .sort_by { |_, count| -count }
```

### パターン3: 複数リポジトリの一括操作
```ruby
# リポジトリディレクトリを走査
repo_dirs = Dir.glob("#{ENV['HOME']}/projects/*").select do |path|
  Dir.exist?("#{path}/.git")
end

repo_dirs.each do |repo|
  Dir.chdir(repo) do
    puts "\n=== #{File.basename(repo)} ==="

    # 状態確認
    status = `git status --porcelain`
    branch = `git rev-parse --abbrev-ref HEAD`.chomp

    if status.empty?
      puts "✅ #{branch}: クリーン"
    else
      puts "⚠️  #{branch}: #{status.lines.size}個の変更"
      puts status.lines.first(3)
    end
  end
end
```

## よくある間違い

### 間違い1: 改行の処理忘れ
```ruby
# ❌ 改行が含まれたまま
commits = `git log --format="%an"`.lines
authors = commits.map { |a| a }  # 改行付き

# ✅ chompで改行削除
commits = `git log --format="%an"`.lines.map(&:chomp)
```

### 間違い2: カレントディレクトリの考慮不足
```ruby
# ❌ ディレクトリ移動が残る
Dir.chdir("/path/to/repo1")
status = `git status`
Dir.chdir("/path/to/repo2")  # repo1に影響

# ✅ ブロックで自動的に元に戻る
Dir.chdir("/path/to/repo1") do
  status = `git status`
end  # 自動的に元のディレクトリに戻る
```

### 間違い3: 空のGitリポジトリ
```ruby
# ❌ .gitディレクトリの存在確認のみ
Dir.glob("*").each do |dir|
  Dir.chdir(dir) { `git status` }  # Gitリポジトリでないとエラー
end

# ✅ .gitディレクトリの存在を確認
Dir.glob("*").select { |d| Dir.exist?("#{d}/.git") }.each do |repo|
  Dir.chdir(repo) { `git status` }
end
```

## 応用のヒント

### 複数リポジトリの一括pull
```ruby
# 全リポジトリをpull
repo_dirs.each do |repo|
  puts "\n📥 #{File.basename(repo)}"
  Dir.chdir(repo) do
    branch = `git rev-parse --abbrev-ref HEAD`.chomp
    puts "  Current branch: #{branch}"

    # pullの実行
    result = `git pull 2>&1`
    if result.include?("Already up to date")
      puts "  ✅ 最新です"
    elsif result.include?("error") || result.include?("fatal")
      puts "  ❌ エラー: #{result.lines.first}"
    else
      puts "  ✅ 更新しました"
      puts result.lines.grep(/file changed|insertion|deletion/).first
    end
  end
end
```

### 未pushコミットの検出
```ruby
# リモートに存在しないローカルコミット
unpushed = `git log @{u}.. --oneline 2>/dev/null`.lines

if unpushed.any?
  puts "⚠️  未pushのコミット: #{unpushed.size}件"
  unpushed.each { |commit| puts "  #{commit}" }
else
  puts "✅ すべてpush済み"
end

# 複数リポジトリで確認
repo_dirs.each do |repo|
  Dir.chdir(repo) do
    unpushed = `git log @{u}.. --oneline 2>/dev/null`.lines
    if unpushed.any?
      puts "⚠️  #{File.basename(repo)}: #{unpushed.size}件の未pushコミット"
    end
  end
end
```

### マージ済みブランチの自動削除
```ruby
def cleanup_merged_branches(base_branch = "main")
  # マージ済みブランチを取得
  merged = `git branch --merged #{base_branch}`.lines
    .map { |b| b.strip.sub(/^\* /, '') }
    .reject { |b| b =~ /^#{base_branch}$|^master$|^develop$/ }

  if merged.empty?
    puts "削除可能なブランチはありません"
    return
  end

  puts "マージ済みブランチ (#{merged.size}個):"
  merged.each { |b| puts "  - #{b}" }

  # 削除確認（実際はSTDIN.gets.chompで入力受付）
  confirm = "yes"  # デモ用

  if confirm == "yes"
    merged.each do |branch|
      result = `git branch -d #{branch} 2>&1`
      if result.include?("Deleted")
        puts "✅ #{branch} を削除しました"
      else
        puts "❌ #{branch} の削除に失敗: #{result}"
      end
    end
  end
end
```

### コミットメッセージの分析
```ruby
# コミットメッセージのパターン分析
messages = `git log --format="%s"`.lines.map(&:chomp)

# プレフィックス別集計（Conventional Commits）
prefix_stats = messages.map { |msg|
  case msg
  when /^feat:/i then "feature"
  when /^fix:/i then "bugfix"
  when /^docs:/i then "documentation"
  when /^refactor:/i then "refactor"
  when /^test:/i then "test"
  else "other"
  end
}.tally

puts "コミットタイプ別統計:"
prefix_stats.sort_by { |_, count| -count }.each do |type, count|
  puts "  #{type}: #{count}件"
end

# 長すぎるコミットメッセージの検出
long_messages = messages.select { |msg| msg.length > 72 }
if long_messages.any?
  puts "\n⚠️  長すぎるコミットメッセージ (#{long_messages.size}件):"
  long_messages.first(5).each do |msg|
    puts "  #{msg[0..80]}..."
  end
end
```

## デバッグのコツ

### Git コマンドのエラーハンドリング
```ruby
# コマンドの成功/失敗を判定
def git_command(cmd)
  output = `#{cmd} 2>&1`
  success = $?.success?

  {
    success: success,
    output: output,
    exit_code: $?.exitstatus
  }
end

# 使用例
result = git_command("git status")
if result[:success]
  puts "✅ 成功"
  puts result[:output]
else
  puts "❌ 失敗 (exit code: #{result[:exit_code]})"
  puts result[:output]
end
```

### リポジトリ状態の詳細確認
```ruby
def repo_status_detailed(repo_path)
  Dir.chdir(repo_path) do
    {
      name: File.basename(repo_path),
      branch: `git rev-parse --abbrev-ref HEAD`.chomp,
      clean: `git status --porcelain`.empty?,
      modified_files: `git status --porcelain`.lines.size,
      unpushed_commits: `git log @{u}.. --oneline 2>/dev/null`.lines.size,
      behind_remote: `git log ..@{u} --oneline 2>/dev/null`.lines.size,
      stashes: `git stash list`.lines.size
    }
  end
end

# 使用例
status = repo_status_detailed("~/projects/my-app")
puts "Repository: #{status[:name]}"
puts "  Branch: #{status[:branch]}"
puts "  Modified files: #{status[:modified_files]}"
puts "  Unpushed commits: #{status[:unpushed_commits]}"
puts "  Behind remote: #{status[:behind_remote]}"
puts "  Stashes: #{status[:stashes]}"
```

### コミット履歴のグラフ表示
```ruby
# 簡易的なコミットグラフ
commits = `git log --format="%h %an %s" --graph --oneline -20`.lines

puts "コミットグラフ:"
commits.each { |line| puts line }

# 著者ごとに色分け（仮想）
commits_detailed = `git log --format="%h|%an|%s" -20`.lines.map do |line|
  hash, author, subject = line.chomp.split('|', 3)
  author_mark = case author
                when /Alice/ then "🔵"
                when /Bob/ then "🟢"
                when /Charlie/ then "🟡"
                else "⚪"
                end
  "#{author_mark} #{hash} (#{author}): #{subject}"
end

puts "\n著者別コミット:"
commits_detailed.each { |c| puts c }
```

## 実用的なワンライナー集

```bash
# 今日のコミット一覧
git log --since="midnight" --format="%h %an %s"

# 著者別コミット数（今週）
git log --since="1 week ago" --format="%an" | ruby -e 'puts STDIN.readlines.map(&:chomp).tally'

# マージ済みブランチを一括削除
git branch --merged main | ruby -ne 'puts $_.strip unless $_ =~ /^\*|main|master|develop/' | xargs git branch -d

# 未pushコミット数
git log @{u}.. --oneline | ruby -ne 'BEGIN{c=0}; c+=1; END{puts "未push: #{c}件"}'

# 複数リポジトリの状態確認
find ~/projects -name .git -type d | ruby -e 'STDIN.readlines.each { |git_dir| repo = File.dirname(git_dir.chomp); Dir.chdir(repo) { puts "#{File.basename(repo)}: #{`git status --short`.lines.size} changes" } }'

# コミットメッセージの検索
git log --all --grep="fix" --format="%h %an %s"

# ファイル変更頻度TOP10
git log --format= --name-only | ruby -e 'puts STDIN.readlines.map(&:chomp).reject(&:empty?).tally.sort_by { |_,v| -v }.first(10).to_h'

# 1時間以内のコミット
git log --since="1 hour ago" --format="%h %an %ar %s"

# ブランチの最終更新日時
git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)'
```

## 高度なテクニック

### 複数リポジトリ管理スクリプト
```ruby
#!/usr/bin/env ruby

class GitMultiRepoManager
  def initialize(base_dir = "#{ENV['HOME']}/projects")
    @base_dir = base_dir
    @repos = find_git_repos
  end

  def find_git_repos
    Dir.glob("#{@base_dir}/*").select { |d| Dir.exist?("#{d}/.git") }
  end

  def status_all
    @repos.each do |repo|
      Dir.chdir(repo) do
        name = File.basename(repo)
        branch = `git rev-parse --abbrev-ref HEAD`.chomp
        status = `git status --porcelain`
        unpushed = `git log @{u}.. --oneline 2>/dev/null`.lines.size

        status_icon = status.empty? ? "✅" : "⚠️"
        puts "#{status_icon} #{name} (#{branch})"
        puts "   #{status.lines.size} changes, #{unpushed} unpushed" if !status.empty? || unpushed > 0
      end
    end
  end

  def pull_all
    @repos.each do |repo|
      Dir.chdir(repo) do
        puts "\n📥 #{File.basename(repo)}"
        system("git pull")
      end
    end
  end

  def cleanup_all(base_branch = "main")
    @repos.each do |repo|
      Dir.chdir(repo) do
        puts "\n🧹 #{File.basename(repo)}"
        merged = `git branch --merged #{base_branch}`.lines
          .map { |b| b.strip.sub(/^\* /, '') }
          .reject { |b| b =~ /^#{base_branch}$|^master$|^develop$/ }

        if merged.any?
          puts "  削除: #{merged.join(', ')}"
          merged.each { |b| system("git branch -d #{b}") }
        else
          puts "  クリーン"
        end
      end
    end
  end

  def commit_stats
    all_commits = []
    @repos.each do |repo|
      Dir.chdir(repo) do
        commits = `git log --since="1 week ago" --format="%an"`.lines.map(&:chomp)
        all_commits.concat(commits)
      end
    end

    puts "今週のコミット統計 (全リポジトリ):"
    all_commits.tally.sort_by { |_, count| -count }.each do |author, count|
      puts "  #{author}: #{count}件"
    end
  end
end

# 使用例
manager = GitMultiRepoManager.new
manager.status_all
```
