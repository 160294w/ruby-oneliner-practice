# Day 13: ヒントとステップガイド

## 段階的に考えてみよう

### Step 1: ログファイルの基本読み込み
```ruby
# 方法1: 全行読み込み
log_lines = File.readlines("/var/log/syslog")

# 方法2: journalctlコマンド出力を読み込み
log_output = `journalctl --since today --no-pager`
log_lines = log_output.lines
```

### Step 2: エラーログの抽出
```ruby
# 基本的なエラー検出
errors = log_lines.select { |line| line =~ /ERROR|error|FAIL|Failed/ }

# 複数パターンのマッチング
critical_patterns = /CRITICAL|FATAL|Out of memory|segfault/
critical_logs = log_lines.select { |line| line =~ critical_patterns }
```

### Step 3: ログレベル別の分類
```ruby
log_stats = Hash.new(0)

log_lines.each do |line|
  case line
  when /CRITICAL|FATAL/
    log_stats[:critical] += 1
  when /ERROR|error/
    log_stats[:error] += 1
  when /WARN|warning/
    log_stats[:warning] += 1
  when /INFO|info/
    log_stats[:info] += 1
  end
end
```

## よく使うパターン

### パターン1: タイムスタンプ解析
```ruby
require 'time'

# syslog形式のタイムスタンプ
# "Jan 15 10:23:45"
log_lines.each do |line|
  if line =~ /(\w{3}\s+\d+\s+\d{2}:\d{2}:\d{2})/
    timestamp = $1
    # Time.parseでパース可能
  end
end

# journalctl JSON出力
require 'json'
logs = `journalctl -o json --since today`.lines.map { |l| JSON.parse(l) }
logs.each do |entry|
  timestamp = Time.at(entry["__REALTIME_TIMESTAMP"].to_i / 1000000)
end
```

### パターン2: セキュリティイベント検出
```ruby
# SSH認証失敗
auth_failures = log_lines.select { |line|
  line =~ /Failed password|authentication failure/
}

# IPアドレス抽出
suspicious_ips = auth_failures.map { |line|
  line[/from (\d+\.\d+\.\d+\.\d+)/, 1]
}.compact.tally

# TOP攻撃元IP
top_attackers = suspicious_ips.sort_by { |_, count| -count }.first(5)
```

### パターン3: エラー頻度分析
```ruby
# エラーメッセージのグループ化
error_messages = log_lines
  .select { |line| line =~ /ERROR/ }
  .map { |line| line[/ERROR[:\s]+(.+?)(\s|$)/, 1] }
  .compact
  .tally
  .sort_by { |_, count| -count }

# TOP3エラー
top_errors = error_messages.first(3)
```

## よくある間違い

### 間違い1: 正規表現のエスケープ忘れ
```ruby
# ❌ 特殊文字のエスケープ忘れ
line =~ /192.168.1.1/  # . が任意文字にマッチ

# ✅ 適切にエスケープ
line =~ /192\.168\.1\.1/
```

### 間違い2: タイムゾーンの考慮不足
```ruby
# ❌ ローカルタイムとUTCの混在
timestamp = Time.parse(log_time)  # タイムゾーン不明

# ✅ タイムゾーンを明示
timestamp = Time.parse(log_time + " UTC")
```

### 間違い3: 大容量ログファイルの全読み込み
```ruby
# ❌ 大きなファイルで全読み込み
log_lines = File.readlines("/var/log/huge.log")  # メモリ不足

# ✅ 1行ずつ処理
File.foreach("/var/log/huge.log") do |line|
  process(line) if line =~ /ERROR/
end

# または tail で最新のみ
recent_logs = `tail -n 1000 /var/log/app.log`
```

## 応用のヒント

### 時間範囲での集計
```ruby
# 時間帯別のエラー集計
hourly_stats = Hash.new(0)

log_lines.each do |line|
  if line =~ /(\d{2}):(\d{2}):(\d{2})/ && line =~ /ERROR/
    hour = $1
    hourly_stats[hour] += 1
  end
end

# 結果の可視化
hourly_stats.sort.each do |hour, count|
  bar = "■" * (count / 10 + 1)
  puts "#{hour}時: #{bar} (#{count}件)"
end
```

### リアルタイム監視
```ruby
# tail -fのような動作
IO.popen("tail -f /var/log/app.log") do |io|
  io.each_line do |line|
    if line =~ /ERROR|CRITICAL/
      puts "🚨 #{Time.now}: #{line}"
      # アラート通知処理
    end
  end
end
```

### journalctlでの高度な検索
```ruby
# 特定サービスのログのみ
service_logs = `journalctl -u nginx.service --since today --no-pager`

# 優先度指定（エラー以上）
error_logs = `journalctl -p err --since "1 hour ago" --no-pager`

# JSON出力で構造化データとして処理
require 'json'
logs = `journalctl -o json --since today -p err`.lines.map { |l| JSON.parse(l) }
```

### アラート条件の設定
```ruby
# 監視ルールの定義
alert_rules = [
  {
    pattern: /Failed password/,
    threshold: 5,
    window: 300,  # 5分
    severity: "HIGH",
    action: -> { send_alert("Brute force attack detected") }
  },
  {
    pattern: /Out of memory/,
    threshold: 1,
    severity: "CRITICAL",
    action: -> { send_alert("Memory exhausted!") }
  }
]

# ルールベースの監視
def monitor_logs(log_lines, rules)
  rules.each do |rule|
    matches = log_lines.select { |line| line =~ rule[:pattern] }
    if matches.size >= rule[:threshold]
      puts "[#{rule[:severity]}] Rule triggered: #{rule[:pattern]}"
      rule[:action].call if rule[:action]
    end
  end
end
```

## デバッグのコツ

### ログフォーマットの確認
```ruby
# 最初の数行を確認
log_lines.first(5).each_with_index do |line, i|
  puts "#{i}: #{line.inspect}"
end

# パターンマッチのテスト
test_line = log_lines.first
if test_line =~ /(\w{3}\s+\d+)\s+(\d{2}:\d{2}:\d{2})\s+(\w+)\s+(.+)/
  puts "Date: #{$1}, Time: #{$2}, Host: #{$3}, Message: #{$4}"
end
```

### マッチング結果の検証
```ruby
# どのパターンにマッチしたか確認
log_lines.first(100).each do |line|
  matched = []
  matched << "ERROR" if line =~ /ERROR/
  matched << "WARNING" if line =~ /WARN/
  matched << "SECURITY" if line =~ /Failed password/
  puts "#{line.strip} → #{matched.join(', ')}" if matched.any?
end
```

### 統計情報の確認
```ruby
# 全体統計
stats = {
  total: log_lines.size,
  errors: log_lines.count { |l| l =~ /ERROR/ },
  warnings: log_lines.count { |l| l =~ /WARN/ },
  security: log_lines.count { |l| l =~ /Failed|Invalid/ }
}

puts "統計情報:"
stats.each { |k, v| puts "  #{k}: #{v}" }
puts "  エラー率: #{'%.2f' % (stats[:errors] * 100.0 / stats[:total])}%"
```

## 実用的なワンライナー集

```bash
# エラーログのみ抽出
journalctl --since today -p err | ruby -ne 'print if /ERROR/'

# SSH認証失敗の統計
ruby -e 'puts File.readlines("/var/log/auth.log").grep(/Failed password/).map { |l| l[/from (\d+\.\d+\.\d+\.\d+)/, 1] }.compact.tally.sort_by { |_,v| -v }.first(10).to_h'

# 時間帯別エラー集計
journalctl --since today -p err -o json | ruby -rjson -e 'STDIN.readlines.map { |l| JSON.parse(l) }.group_by { |e| Time.at(e["__REALTIME_TIMESTAMP"].to_i/1000000).hour }.each { |h,es| puts "#{h}時: #{es.size}件" }'

# セキュリティイベントのリアルタイム監視
tail -f /var/log/auth.log | ruby -ne 'puts "\e[31m#{$_}\e[0m" if /Failed|Invalid|refused/'

# サービス別エラー統計
journalctl -p err --since today | ruby -ne 'print if /\w+\[\d+\]/' | ruby -e 'puts STDIN.readlines.map { |l| l[/(\w+)\[\d+\]/, 1] }.compact.tally.sort_by { |_,v| -v }.first(10).to_h'
```
