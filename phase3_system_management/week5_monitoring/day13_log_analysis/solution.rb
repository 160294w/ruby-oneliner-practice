# Day 13: ログ分析・監視ワンライナー - 解答例

puts "=== 基本レベル解答 ==="
# 基本: ログファイルからエラー抽出
puts "ログファイルからエラーを検出:"

if File.exist?("sample_data/syslog.log")
  log_lines = File.readlines("sample_data/syslog.log")
else
  # サンプルデータがない場合のシミュレーション
  log_lines = [
    "Jan 15 10:23:45 server1 sshd[1234]: Failed password for root from 192.168.1.100",
    "Jan 15 10:24:12 server1 kernel: Out of memory: Kill process 5678",
    "Jan 15 10:25:30 server1 systemd[1]: Started Application Server",
    "Jan 15 10:26:45 server1 app[9012]: ERROR: Database connection timeout",
    "Jan 15 10:27:15 server1 sshd[3456]: Accepted publickey for admin from 192.168.1.50"
  ]
end

# エラーログの抽出
errors = log_lines.select { |line| line =~ /ERROR|error|FAIL|Failed|fail/ }
puts "検出されたエラー: #{errors.size}件"
errors.each { |err| puts "  🔴 #{err.strip}" }

puts "\n=== 応用レベル解答 ==="

# 応用1: ログレベル別集計
puts "ログレベル別集計:"
log_stats = {
  critical: 0,
  error: 0,
  warning: 0,
  info: 0
}

log_lines.each do |line|
  log_stats[:critical] += 1 if line =~ /CRITICAL|critical|FATAL|fatal|Out of memory/
  log_stats[:error] += 1 if line =~ /ERROR|error|Failed/
  log_stats[:warning] += 1 if line =~ /WARN|warning|deprecated/
  log_stats[:info] += 1 if line =~ /INFO|info|Started|Accepted/
end

log_stats.each { |level, count| puts "  #{level.to_s.upcase}: #{count}件" }

# 応用2: セキュリティイベント検出
puts "\nセキュリティイベント検出:"
security_events = log_lines.select do |line|
  line =~ /Failed password|authentication failure|sudo:|Invalid user|Connection closed|refused/
end

if security_events.any?
  puts "🚨 セキュリティ関連イベント: #{security_events.size}件"
  security_events.each { |event| puts "  ⚠️  #{event.strip}" }
else
  puts "✅ セキュリティ異常は検出されませんでした"
end

# 応用3: タイムスタンプ解析（時間帯別集計）
puts "\n時間帯別エラー発生統計:"
hourly_errors = Hash.new(0)

log_lines.each do |line|
  if line =~ /(\d{2}):(\d{2}):(\d{2})/ && (line =~ /ERROR|Failed/)
    hour = $1
    hourly_errors[hour] += 1
  end
end

hourly_errors.sort.each { |hour, count| puts "  #{hour}時台: #{count}件" }

puts "\n=== 実務レベル解答 ==="

# 実務1: 包括的ログ分析レポート
puts "包括的ログ分析レポート:"

def analyze_logs(log_lines)
  report = {
    total_lines: log_lines.size,
    errors: [],
    warnings: [],
    security_events: [],
    top_errors: Hash.new(0),
    suspicious_ips: Hash.new(0)
  }

  log_lines.each do |line|
    # エラー分類
    if line =~ /ERROR|error|Failed|FAIL/
      report[:errors] << line.strip
      # エラータイプを抽出
      if line =~ /(ERROR|Failed|FAIL)[:\s]+(.+?)(\s|$)/
        error_type = $2.split(/[:\.,]/).first
        report[:top_errors][error_type] += 1
      end
    end

    # 警告検出
    if line =~ /WARN|warning|deprecated/
      report[:warnings] << line.strip
    end

    # セキュリティイベント
    if line =~ /Failed password|authentication failure|sudo:|Invalid user/
      report[:security_events] << line.strip
      # IPアドレス抽出
      if line =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
        report[:suspicious_ips][$1] += 1
      end
    end
  end

  report
end

report = analyze_logs(log_lines)

puts "\n📊 統計サマリー:"
puts "  総ログ行数: #{report[:total_lines]}"
puts "  エラー件数: #{report[:errors].size}"
puts "  警告件数: #{report[:warnings].size}"
puts "  セキュリティイベント: #{report[:security_events].size}"

if report[:top_errors].any?
  puts "\n🔥 頻出エラー TOP3:"
  report[:top_errors].sort_by { |_, count| -count }.first(3).each do |error, count|
    puts "  #{count}回: #{error}"
  end
end

if report[:suspicious_ips].any?
  puts "\n🚨 要注意IPアドレス:"
  report[:suspicious_ips].sort_by { |_, count| -count }.first(5).each do |ip, count|
    puts "  #{ip}: #{count}回の失敗"
  end
end

# 実務2: リアルタイム監視シミュレーション
puts "\nリアルタイム監視パターン例:"

monitoring_rules = [
  { pattern: /Failed password/, severity: "HIGH", action: "アカウントロック検討" },
  { pattern: /Out of memory/, severity: "CRITICAL", action: "メモリ増設必要" },
  { pattern: /disk.*full/, severity: "CRITICAL", action: "ディスク容量確保" },
  { pattern: /Connection refused/, severity: "MEDIUM", action: "サービス再起動確認" },
  { pattern: /sudo:.*command/, severity: "INFO", action: "権限操作を記録" }
]

puts "\n設定済み監視ルール:"
monitoring_rules.each_with_index do |rule, idx|
  puts "#{idx + 1}. [#{rule[:severity]}] #{rule[:pattern].inspect} → #{rule[:action]}"
end

# ルールに基づくログマッチング
puts "\n🔍 検出されたイベント:"
log_lines.each do |line|
  monitoring_rules.each do |rule|
    if line =~ rule[:pattern]
      puts "  [#{rule[:severity]}] #{line.strip}"
      puts "  → アクション: #{rule[:action]}"
    end
  end
end

# 実務3: ログローテーション状況確認
puts "\n📁 ログファイル管理状況（シミュレート）:"
log_files = [
  { name: "syslog", size: "128MB", age: "3日", rotated: true },
  { name: "auth.log", size: "64MB", age: "5日", rotated: true },
  { name: "kern.log", size: "256MB", age: "1日", rotated: false },
  { name: "application.log", size: "512MB", age: "7日", rotated: false }
]

log_files.each do |file|
  status = file[:rotated] ? "✅" : "⚠️"
  puts "#{status} #{file[:name]} (#{file[:size]}, #{file[:age]}前)"
  puts "   → ローテーション推奨" if file[:size].to_i > 200 || !file[:rotated]
end

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# 過去1時間のエラーログを集計
journalctl --since "1 hour ago" --priority=err | ruby -e 'puts STDIN.readlines.group_by { |l| l[/\w+\[\d+\]/] }.transform_values(&:size).sort_by { |_,v| -v }'

# SSH認証失敗を検出してSlack通知
tail -f /var/log/auth.log | ruby -e 'STDIN.each { |line| system("curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"SSH認証失敗: #{line}\"} ' WEBHOOK_URL") if line =~ /Failed password/ }'

# systemdサービスの失敗を検出
journalctl -u myapp.service -p err --since today --no-pager | ruby -e 'errors = STDIN.readlines; puts "エラー: #{errors.size}件"; errors.each { |e| puts e }'

# ログファイルサイズ監視（100MB超を検出）
ruby -e 'Dir["/var/log/*.log"].each { |f| size = File.size(f) / 1024 / 1024; puts "⚠️ #{f}: #{size}MB" if size > 100 }'

# セキュリティイベントの日次レポート
ruby -e 'lines = File.readlines("/var/log/auth.log"); failed = lines.count { |l| l =~ /Failed password/ }; ips = lines.map { |l| l[/from (\d+\.\d+\.\d+\.\d+)/, 1] }.compact.tally; puts "認証失敗: #{failed}件"; puts "TOP攻撃元IP: #{ips.sort_by { |_,v| -v }.first(5).to_h}"'

# journalctlでエラーを時系列表示
journalctl --since today -p err --no-pager -o json | ruby -e 'require "json"; STDIN.readlines.map { |l| JSON.parse(l) }.group_by { |e| Time.at(e["__REALTIME_TIMESTAMP"].to_i / 1000000).strftime("%H") }.each { |h, events| puts "#{h}時: #{events.size}件" }'
ONELINERS

puts "\n📋 ログ監視チェックリスト:"
checklist = [
  "システムログのエラーレベル確認",
  "認証失敗・不正アクセス試行の検出",
  "ディスク・メモリ関連の警告確認",
  "アプリケーションログのエラー分析",
  "ログファイルサイズ・ローテーション確認",
  "重要イベントのアラート設定確認"
]

checklist.each_with_index { |item, i| puts "#{i+1}. [ ] #{item}" }

puts "\n🎯 本番運用での注意点:"
puts "- ログ監視は定期実行（cron/systemd timer）で自動化"
puts "- アラートは重要度に応じて通知先を分ける"
puts "- ログローテーション設定を適切に管理"
puts "- 長期保存が必要なログは外部ストレージへ"
puts "- セキュリティログは改ざん防止対策を実施"
