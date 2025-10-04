# Day 20: CI/CDパイプライン管理 - 解答例

require 'json'
require 'rexml/document'

puts "=== 基本レベル解答 ==="
# 基本: CI/CDログからエラー抽出

if File.exist?("sample_data/gitlab_ci_log.txt")
  log = File.readlines("sample_data/gitlab_ci_log.txt")
  errors = log.select { |line| line =~ /ERROR|error|failed/i }

  puts "エラー行: #{errors.size}件"
  errors.each { |err| puts "  #{err.strip}" }
else
  puts "⚠️  サンプルログファイルが見つかりません"
end

puts "\n=== 応用レベル解答 ==="

# 応用1: GitHub Actions ワークフローの解析
puts "GitHub Actions ワークフロー解析:"

if File.exist?("sample_data/github_actions_log.json")
  workflow = JSON.parse(File.read("sample_data/github_actions_log.json"))

  run = workflow["workflow_run"]
  puts "\nワークフロー: #{run['name']}"
  puts "  Status: #{run['conclusion']}"

  # ステップ別実行時間
  puts "\nステップ実行時間:"
  workflow["jobs"]["build"]["steps"].each do |step|
    if step["status"] == "skipped"
      puts "  #{step['name']}: スキップ"
    else
      started = Time.parse(step["started_at"])
      completed = Time.parse(step["completed_at"])
      duration = (completed - started).to_i

      icon = step["conclusion"] == "success" ? "✅" : "❌"
      puts "  #{icon} #{step['name']}: #{duration}秒"
    end
  end
end

# 応用2: テスト結果XMLの解析
puts "\nテスト結果解析:"

if File.exist?("sample_data/test_results.xml")
  xml = File.read("sample_data/test_results.xml")
  doc = REXML::Document.new(xml)

  testsuites = doc.elements["testsuites"]
  total = testsuites.attributes["tests"].to_i
  failures = testsuites.attributes["failures"].to_i
  errors = testsuites.attributes["errors"].to_i
  skipped = testsuites.attributes["skipped"].to_i

  success = total - failures - errors - skipped
  success_rate = (success * 100.0 / total).round(1)

  puts "  総テスト数: #{total}"
  puts "  ✅ 成功: #{success} (#{success_rate}%)"
  puts "  ❌ 失敗: #{failures}"
  puts "  🔴 エラー: #{errors}"
  puts "  ⏭️  スキップ: #{skipped}"

  # スイート別統計
  puts "\nテストスイート別:"
  doc.elements.each("testsuites/testsuite") do |suite|
    name = suite.attributes["name"]
    tests = suite.attributes["tests"].to_i
    fails = suite.attributes["failures"].to_i
    time = suite.attributes["time"].to_f

    suite_success = ((tests - fails) * 100.0 / tests).round(1)
    puts "  #{name}: #{suite_success}% (#{tests}tests, #{time.round(2)}s)"
  end
end

puts "\n=== 実務レベル解答 ==="

# 実務1: ビルド失敗原因の分析
puts "ビルド失敗原因の分析:"

def analyze_failure_cause(log_text)
  patterns = {
    "依存関係エラー" => /npm ERR!|bundle.*failed|Could not find compatible/i,
    "テスト失敗" => /test.*failed|FAILED|AssertionError/i,
    "ビルドエラー" => /build failed|compilation error/i,
    "タイムアウト" => /timeout|timed out/i,
    "権限エラー" => /permission denied|access denied/i
  }

  results = {}
  patterns.each do |category, pattern|
    matches = log_text.scan(pattern)
    results[category] = matches.size if matches.any?
  end
  results
end

if File.exist?("sample_data/gitlab_ci_log.txt")
  log = File.read("sample_data/gitlab_ci_log.txt")
  failures = analyze_failure_cause(log)

  if failures.any?
    failures.each { |category, count| puts "  #{category}: #{count}件" }
  else
    puts "  ✅ エラーパターンが見つかりません"
  end
end

# 実務2: パフォーマンスボトルネックの検出
puts "\nパフォーマンスボトルネック検出:"

if File.exist?("sample_data/github_actions_log.json")
  workflow = JSON.parse(File.read("sample_data/github_actions_log.json"))
  steps = workflow["jobs"]["build"]["steps"]

  durations = steps.reject { |s| s["status"] == "skipped" }.map do |step|
    duration = Time.parse(step["completed_at"]) - Time.parse(step["started_at"])
    { name: step["name"], duration: duration.to_i }
  end.sort_by { |s| -s[:duration] }

  threshold = 60  # 60秒
  bottlenecks = durations.select { |s| s[:duration] > threshold }

  if bottlenecks.any?
    puts "  ⚠️  60秒超のステップ:"
    bottlenecks.each do |step|
      bar = "█" * (step[:duration] / 30 + 1)
      puts "    #{step[:name]}: #{bar} #{step[:duration]}秒"
    end
  else
    puts "  ✅ 重大なボトルネックは検出されませんでした"
  end
end

# 実務3: テスト失敗の詳細レポート
puts "\nテスト失敗の詳細:"

if File.exist?("sample_data/test_results.xml")
  doc = REXML::Document.new(File.read("sample_data/test_results.xml"))

  failed_tests = []
  doc.elements.each("//testcase[failure or error]") do |testcase|
    name = testcase.attributes["name"]
    classname = testcase.attributes["classname"]
    failure = testcase.elements["failure"] || testcase.elements["error"]
    message = failure.attributes["message"] if failure

    failed_tests << {
      class: classname,
      name: name,
      message: message
    }
  end

  if failed_tests.any?
    puts "  失敗したテスト: #{failed_tests.size}件"
    failed_tests.first(5).each do |test|
      puts "\n  ❌ #{test[:class]}::#{test[:name]}"
      puts "     #{test[:message]}"
    end
  end
end

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# テスト成功率
ruby -rrexml/document -e 'd=REXML::Document.new(File.read("test.xml")); ts=d.elements["testsuites"]; t=ts.attributes["tests"].to_i; f=ts.attributes["failures"].to_i; puts "#{"%.1f"%((t-f)*100.0/t)}%"'

# GitHub Actions最新runの失敗ステップ
gh run view $(gh run list --limit 1 --json databaseId -q '.[0].databaseId') --json jobs | ruby -rjson -e 'data=JSON.parse(STDIN.read); data["jobs"][0]["steps"].select{|s| s["conclusion"]=="failure"}.each{|s| puts s["name"]}'

# CI失敗率（過去10run）
gh run list --limit 10 --json conclusion | ruby -rjson -e 'runs=JSON.parse(STDIN.read); failed=runs.count{|r| r["conclusion"]=="failure"}; total=runs.size; puts "失敗率: #{"%.1f"%(failed*100.0/total)}%"'
ONELINERS

puts "\n💡 運用Tips:"
puts <<~TIPS
1. CI/CD監視
   - ビルド失敗時はSlack/Discord通知
   - テスト成功率を定期的にレポート

2. パフォーマンス最適化
   - 60秒超のステップを重点的に調査
   - キャッシュの活用で依存関係インストールを高速化

3. テスト管理
   - 失敗したテストを自動的にissue化
   - flaky testの検出と対応
TIPS
