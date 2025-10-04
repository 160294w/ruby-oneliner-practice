# Day 19: Git操作・バージョン管理自動化 - 解答例

require 'json'

puts "=== 基本レベル解答 ==="
# 基本: コミット履歴の取得

# サンプルデータを使用（実際のGitリポジトリがない場合）
if File.exist?("sample_data/git_log_sample.txt")
  log_data = File.readlines("sample_data/git_log_sample.txt")
  puts "サンプルデータから最近のコミット:"
  log_data.first(10).each { |line| puts "  #{line}" }
else
  # 実際のGitリポジトリで実行
  commits = `git log --oneline -10 2>/dev/null`.lines
  if commits.any?
    puts "最近のコミット: #{commits.size}件"
    commits.each { |c| puts "  #{c}" }
  else
    puts "⚠️  Gitリポジトリではないか、コミットがありません"
  end
end

puts "\n=== 応用レベル解答 ==="

# 応用1: 著者別コミット統計
puts "著者別コミット統計:"

if File.exist?("sample_data/git_log_sample.txt")
  # サンプルデータから著者を抽出
  authors = File.readlines("sample_data/git_log_sample.txt").map do |line|
    line.split[1]  # 2番目の要素が著者名
  end

  author_stats = authors.tally.sort_by { |_, count| -count }

  author_stats.each do |author, count|
    bar = "█" * (count / 2 + 1)
    puts "  #{author.ljust(10)}: #{bar} (#{count}件)"
  end
else
  # 実際のGitログから取得
  author_commits = `git log --format="%an" 2>/dev/null`.lines
    .map(&:chomp)
    .tally
    .sort_by { |_, count| -count }

  if author_commits.any?
    author_commits.first(5).each do |author, count|
      puts "  #{author}: #{count}件"
    end
  end
end

# 応用2: 日付別コミット統計（シミュレート）
puts "\n日付別コミット統計（過去7日間）:"

# サンプルデータを生成
dates = (0..6).map { |i| (Date.today - i).to_s }
commit_counts = [5, 8, 3, 12, 7, 9, 4]

dates.zip(commit_counts).reverse.each do |date, count|
  bar = "●" * count
  puts "  #{date}: #{bar} (#{count}件)"
end

# 応用3: マージ済みブランチの検出（シミュレート）
puts "\nマージ済みブランチの検出:"

# サンプルデータから読み込み
if File.exist?("sample_data/multi_repo_config.json")
  config = JSON.parse(File.read("sample_data/multi_repo_config.json"))

  config["merged_branches"].each do |repo, branches|
    if branches.any?
      puts "  #{repo}: #{branches.size}個のマージ済みブランチ"
      branches.each { |b| puts "    - #{b}" }
    else
      puts "  #{repo}: マージ済みブランチなし ✅"
    end
  end
else
  # 実際のGitリポジトリで確認
  merged_branches = `git branch --merged main 2>/dev/null`.lines
    .map(&:chomp)
    .map(&:strip)
    .reject { |b| b =~ /^\*|^main$|^master$|^develop$/ }

  if merged_branches.any?
    puts "マージ済みブランチ: #{merged_branches.join(', ')}"
  else
    puts "削除可能なブランチはありません"
  end
end

puts "\n=== 実務レベル解答 ==="

# 実務1: 複数リポジトリの状態監視
puts "複数リポジトリの状態監視:"

if File.exist?("sample_data/multi_repo_config.json")
  config = JSON.parse(File.read("sample_data/multi_repo_config.json"))

  config["repositories"].each do |repo|
    status_icon = repo["status"] == "clean" ? "✅" : "⚠️"
    unpushed = repo["unpushed_commits"]

    puts "\n#{status_icon} #{repo['name']} (#{repo['branch']})"
    puts "   Path: #{repo['path']}"

    case repo["status"]
    when "clean"
      puts "   Status: クリーン"
    when "modified"
      puts "   Status: #{repo['modified_files'].size}個のファイルが変更されています"
      repo["modified_files"].each { |file| puts "     - #{file}" }
    when "untracked"
      puts "   Status: 未追跡ファイルがあります"
      repo["untracked_files"]&.each { |file| puts "     - #{file}" }
    end

    if unpushed > 0
      puts "   ⚠️  未pushコミット: #{unpushed}件"
    end
  end
else
  # 実際のディレクトリを走査
  home_dir = ENV['HOME'] || ENV['USERPROFILE']
  projects_dir = File.join(home_dir, 'projects')

  if Dir.exist?(projects_dir)
    repo_dirs = Dir.glob("#{projects_dir}/*").select { |d| Dir.exist?("#{d}/.git") }

    if repo_dirs.any?
      repo_dirs.each do |repo|
        Dir.chdir(repo) do
          name = File.basename(repo)
          branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.chomp
          status = `git status --porcelain 2>/dev/null`
          unpushed = `git log @{u}.. --oneline 2>/dev/null`.lines.size

          status_icon = status.empty? ? "✅" : "⚠️"
          puts "#{status_icon} #{name} (#{branch})"

          if !status.empty?
            puts "   #{status.lines.size}個の変更"
          end

          if unpushed > 0
            puts "   ⚠️  未pushコミット: #{unpushed}件"
          end
        end
      end
    else
      puts "⚠️  Gitリポジトリが見つかりません"
    end
  else
    puts "⚠️  プロジェクトディレクトリが存在しません: #{projects_dir}"
  end
end

# 実務2: チーム全体のコミット活動レポート
puts "\n\nチーム全体のコミット活動レポート:"

if File.exist?("sample_data/multi_repo_config.json")
  config = JSON.parse(File.read("sample_data/multi_repo_config.json"))

  puts "\n過去7日間のコミット統計:"
  stats_7d = config["commit_stats"]["last_7_days"]
  total_7d = stats_7d.values.sum

  stats_7d.sort_by { |_, count| -count }.each do |author, count|
    percentage = (count * 100.0 / total_7d).round(1)
    bar = "█" * (count / 2 + 1)
    puts "  #{author.ljust(10)}: #{bar} #{count}件 (#{percentage}%)"
  end
  puts "  合計: #{total_7d}件"

  puts "\n過去30日間のコミット統計:"
  stats_30d = config["commit_stats"]["last_30_days"]
  total_30d = stats_30d.values.sum

  stats_30d.sort_by { |_, count| -count }.each do |author, count|
    percentage = (count * 100.0 / total_30d).round(1)
    puts "  #{author.ljust(10)}: #{count}件 (#{percentage}%)"
  end
  puts "  合計: #{total_30d}件"
end

# 実務3: Git hooks自動化（概念実装）
puts "\n\nGit hooks自動化の例:"

hooks_examples = {
  "pre-commit" => "コミット前のlint/format チェック",
  "commit-msg" => "コミットメッセージ形式の検証",
  "pre-push" => "push前のテスト実行",
  "post-merge" => "マージ後の依存関係更新"
}

puts "推奨されるGit hooks:"
hooks_examples.each do |hook, description|
  puts "  #{hook}: #{description}"
end

# 実務4: コミットメッセージの品質チェック
puts "\n\nコミットメッセージ品質チェック:"

if File.exist?("sample_data/git_log_sample.txt")
  messages = File.readlines("sample_data/git_log_sample.txt").map do |line|
    line.split(' ', 3)[2]  # コミットメッセージ部分
  end

  # 長さチェック
  long_messages = messages.select { |msg| msg && msg.length > 72 }
  short_messages = messages.select { |msg| msg && msg.length < 10 }

  puts "コミットメッセージ統計:"
  puts "  総数: #{messages.size}"
  puts "  長すぎる (>72文字): #{long_messages.size}件"
  puts "  短すぎる (<10文字): #{short_messages.size}件"

  if long_messages.any?
    puts "\n長すぎるメッセージの例:"
    long_messages.first(3).each do |msg|
      puts "  - #{msg[0..60]}..."
    end
  end

  # Conventional Commits形式の使用率
  conventional = messages.count { |msg| msg =~ /^(feat|fix|docs|style|refactor|test|chore):/ }
  if conventional > 0
    percentage = (conventional * 100.0 / messages.size).round(1)
    puts "\nConventional Commits形式: #{percentage}% (#{conventional}/#{messages.size})"
  end
end

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# 今日のコミット一覧
git log --since="midnight" --format="%h %an %s"

# 今週の著者別コミット数
git log --since="1 week ago" --format="%an" | ruby -e 'puts STDIN.readlines.map(&:chomp).tally'

# 複数リポジトリの一括pull
find ~/projects -name .git -type d | ruby -e 'STDIN.readlines.each { |git_dir| repo = File.dirname(git_dir.chomp); Dir.chdir(repo) { puts "#{File.basename(repo)}:"; system("git pull") } }'

# マージ済みブランチを一括削除
git branch --merged main | ruby -ne 'b = $_.strip; system("git branch -d #{b}") unless b =~ /^\*|main|master|develop/'

# 未pushコミット数
git log @{u}.. --oneline | ruby -ne 'BEGIN{c=0}; c+=1; END{puts "未push: #{c}件"}'

# ファイル変更頻度TOP10
git log --format= --name-only | ruby -e 'puts STDIN.readlines.map(&:chomp).reject(&:empty?).tally.sort_by { |_,v| -v }.first(10).to_h'

# コミットメッセージから特定のissue番号を抽出
git log --format="%s" | ruby -ne 'puts $_.scan(/#(\d+)/).flatten.uniq' | ruby -e 'puts STDIN.readlines.map(&:chomp).tally'

# ブランチの最終更新日時
git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)' | head -10

# 複数リポジトリの未pushコミット検出
find ~/projects -name .git -type d | ruby -e 'STDIN.readlines.each { |git_dir| repo = File.dirname(git_dir.chomp); Dir.chdir(repo) { unpushed = `git log @{u}.. --oneline 2>/dev/null`.lines.size; puts "#{File.basename(repo)}: #{unpushed}件" if unpushed > 0 } }'
ONELINERS

puts "\n💡 運用Tips:"
puts <<~TIPS
1. 複数リポジトリ管理
   - projects/配下に全リポジトリを配置
   - 定期的にスクリプトで一括pull/status確認

2. ブランチ戦略
   - main/develop/feature/* の命名規則を統一
   - マージ済みブランチは週次で自動削除

3. コミット規約
   - Conventional Commits形式を推奨
   - pre-commit hookでメッセージ形式を検証

4. 監視項目
   - 未pushコミットの検出
   - 未追跡ファイルの警告
   - リモートとの乖離チェック
TIPS
