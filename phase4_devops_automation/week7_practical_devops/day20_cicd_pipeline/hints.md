# Day 20: ヒントとステップガイド

## 段階的に考えてみよう

### Step 1: GitHub Actions JSONログの基本解析
```ruby
require 'json'

# JSONログの読み込み
workflow = JSON.parse(File.read("github_actions_log.json"))

# 基本情報の取得
status = workflow["workflow_run"]["conclusion"]
puts "ワークフロー結果: #{status}"

# ジョブの確認
jobs = workflow["jobs"]
jobs.each do |job_name, job_data|
  puts "#{job_name}: #{job_data["conclusion"]}"
end
```

### Step 2: ステップ別実行時間の計算
```ruby
steps = workflow["jobs"]["build"]["steps"]

steps.each do |step|
  next if step["status"] == "skipped"

  name = step["name"]
  started = Time.parse(step["started_at"])
  completed = Time.parse(step["completed_at"])
  duration = (completed - started).to_i

  puts "#{name}: #{duration}秒"
end
```

### Step 3: テスト結果XMLの解析
```ruby
require 'rexml/document'

xml = File.read("test_results.xml")
doc = REXML::Document.new(xml)

# テストスイート全体の統計
testsuites = doc.elements["testsuites"]
total = testsuites.attributes["tests"].to_i
failures = testsuites.attributes["failures"].to_i
errors = testsuites.attributes["errors"].to_i
skipped = testsuites.attributes["skipped"].to_i

success = total - failures - errors - skipped
success_rate = (success * 100.0 / total).round(1)

puts "テスト結果: #{success}/#{total} (#{success_rate}%)"
```

## よく使うパターン

### パターン1: エラーメッセージの抽出
```ruby
# ログファイルからエラー行を抽出
errors = File.readlines("ci_log.txt").select do |line|
  line =~ /ERROR|FAIL|error:|failed/i
end

# エラータイプ別に分類
error_types = Hash.new(0)
errors.each do |error|
  case error
  when /npm ERR!/
    error_types["npm エラー"] += 1
  when /bundle install failed/
    error_types["bundle エラー"] += 1
  when /test.*failed/i
    error_types["テスト失敗"] += 1
  else
    error_types["その他"] += 1
  end
end

error_types.each { |type, count| puts "#{type}: #{count}件" }
```

### パターン2: テストスイート別の統計
```ruby
doc.elements.each("testsuites/testsuite") do |suite|
  name = suite.attributes["name"]
  tests = suite.attributes["tests"].to_i
  failures = suite.attributes["failures"].to_i
  time = suite.attributes["time"].to_f

  success_rate = ((tests - failures) * 100.0 / tests).round(1)
  puts "#{name}: #{success_rate}% (#{time}秒)"
end
```

### パターン3: パイプライン実行時間の可視化
```ruby
steps = workflow["jobs"]["build"]["steps"]

# 実行時間でソート
sorted_steps = steps
  .reject { |s| s["status"] == "skipped" }
  .map do |step|
    duration = Time.parse(step["completed_at"]) - Time.parse(step["started_at"])
    { name: step["name"], duration: duration.to_i }
  end
  .sort_by { |s| -s[:duration] }

# 可視化
puts "実行時間TOP5:"
sorted_steps.first(5).each_with_index do |step, i|
  bar = "█" * (step[:duration] / 10 + 1)
  puts "#{i+1}. #{step[:name]}: #{bar} #{step[:duration]}秒"
end
```

## よくある間違い

### 間違い1: タイムスタンプのパース忘れ
```ruby
# ❌ 文字列のまま計算
duration = step["completed_at"] - step["started_at"]  # エラー

# ✅ Time.parseで変換
completed = Time.parse(step["completed_at"])
started = Time.parse(step["started_at"])
duration = completed - started
```

### 間違い2: スキップされたステップの考慮不足
```ruby
# ❌ スキップステップでエラー
steps.each do |step|
  duration = Time.parse(step["completed_at"]) - Time.parse(step["started_at"])
end

# ✅ スキップステップを除外
steps.reject { |s| s["status"] == "skipped" }.each do |step|
  # 処理
end
```

### 間違い3: XML属性のnil処理
```ruby
# ❌ nil値でエラー
failures = doc.elements["testsuites"].attributes["failures"].to_i

# ✅ nilチェック
failures = doc.elements["testsuites"]&.attributes&.[]("failures")&.to_i || 0
```

## 応用のヒント

### ビルド失敗の原因別分類
```ruby
def analyze_build_failure(log_text)
  failure_patterns = {
    "依存関係": /npm ERR!|bundle.*failed|pip.*error|dependency/i,
    "テスト失敗": /test.*failed|assertion.*error|expected.*but.*got/i,
    "コンパイル": /compilation.*error|syntax.*error|parse.*error/i,
    "Lint": /eslint|rubocop|flake8|lint.*error/i,
    "タイムアウト": /timeout|timed out|killed/i,
    "権限": /permission denied|access denied/i
  }

  results = {}
  failure_patterns.each do |category, pattern|
    matches = log_text.scan(pattern)
    results[category] = matches.size if matches.any?
  end

  results
end

# 使用例
log = File.read("ci_log.txt")
failures = analyze_build_failure(log)
puts "ビルド失敗の原因:"
failures.each { |cat, count| puts "  #{cat}: #{count}件" }
```

### テスト失敗の詳細レポート
```ruby
doc.elements.each("//testcase[failure or error]") do |testcase|
  name = testcase.attributes["name"]
  classname = testcase.attributes["classname"]

  failure = testcase.elements["failure"] || testcase.elements["error"]
  message = failure.attributes["message"]

  puts "❌ #{classname}::#{name}"
  puts "   #{message}"
end
```

### パイプラインのボトルネック検出
```ruby
def find_bottlenecks(steps, threshold_seconds = 60)
  slow_steps = steps
    .reject { |s| s["status"] == "skipped" }
    .map do |step|
      duration = Time.parse(step["completed_at"]) - Time.parse(step["started_at"])
      { name: step["name"], duration: duration.to_i }
    end
    .select { |s| s[:duration] > threshold_seconds }
    .sort_by { |s| -s[:duration] }

  if slow_steps.any?
    puts "⚠️  ボトルネック検出 (#{threshold_seconds}秒超):"
    slow_steps.each do |step|
      puts "  #{step[:name]}: #{step[:duration]}秒"
    end
  else
    puts "✅ ボトルネックなし"
  end

  slow_steps
end
```

## 実用的なワンライナー集

```bash
# GitHub Actions最新runの失敗ステップのみ表示
gh api repos/:owner/:repo/actions/runs/:run_id/jobs | ruby -rjson -e 'data=JSON.parse(STDIN.read); data["jobs"][0]["steps"].select{|s| s["conclusion"]=="failure"}.each{|s| puts s["name"]}'

# テスト成功率の計算
ruby -rrexml/document -e 'd=REXML::Document.new(File.read("test.xml")); ts=d.elements["testsuites"]; t=ts.attributes["tests"].to_i; f=ts.attributes["failures"].to_i; puts "#{"%.1f"%((t-f)*100.0/t)}%"'

# ステップ実行時間の合計
jq '.jobs.build.steps[] | select(.status != "skipped") | (.completed_at | fromdateiso8601) - (.started_at | fromdateiso8601)' workflow.json | ruby -e 'puts STDIN.readlines.sum(&:to_f).to_i'

# CI失敗率の計算（過去10run）
gh run list --limit 10 --json conclusion | ruby -rjson -e 'runs=JSON.parse(STDIN.read); failed=runs.count{|r| r["conclusion"]=="failure"}; puts "失敗率: #{failed*10}%"'
```

## デバッグのコツ

### CI/CDログの構造確認
```ruby
# JSONの構造を可視化
def explore_json(obj, indent = 0)
  case obj
  when Hash
    obj.each do |key, value|
      puts "  " * indent + "#{key}: #{value.class}"
      explore_json(value, indent + 1) if [Hash, Array].include?(value.class)
    end
  when Array
    puts "  " * indent + "[#{obj.size} items]"
    explore_json(obj.first, indent + 1) if obj.any?
  end
end

workflow = JSON.parse(File.read("workflow.json"))
explore_json(workflow)
```

### テスト失敗のパターン分析
```ruby
failure_messages = []

doc.elements.each("//testcase/failure") do |failure|
  message = failure.attributes["message"]
  failure_messages << message
end

# 共通パターンの抽出
patterns = failure_messages.map { |msg|
  case msg
  when /Expected .* but got/
    "Assertion"
  when /NoMethodError/
    "Method"
  when /HTTP \d{3}/
    "API"
  else
    "Other"
  end
}.tally

puts "失敗パターン:"
patterns.each { |pattern, count| puts "  #{pattern}: #{count}件" }
```
