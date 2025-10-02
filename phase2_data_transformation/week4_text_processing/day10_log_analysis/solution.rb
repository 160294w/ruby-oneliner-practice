# Day 10: ログ分析マスター - 解答例

require 'time'

puts "=== 基本レベル解答 ==="
# 基本: アクセスログの基本統計
logs = File.readlines("sample_data/access.log")

total_requests = logs.size
puts "総リクエスト数: #{total_requests}"

unique_ips = logs.map { |line| line[/^(\S+)/, 1] }.compact.uniq
puts "ユニークIP数: #{unique_ips.size}"

puts "\n=== 応用レベル解答 ==="

# 応用1: HTTPステータスコード別集計
puts "HTTPステータスコード別集計:"
status_counts = logs.map { |line| line[/"(?:GET|POST|PUT|DELETE) [^"]+" (\d+)/, 1] }
                   .compact
                   .tally
                   .sort_by { |status, count| -count }

status_counts.each do |status, count|
  percentage = (count.to_f / total_requests * 100).round(2)
  puts "  #{status}: #{count}件 (#{percentage}%)"
end

# 応用2: 時間帯別トラフィック分析
puts "\n時間帯別アクセス数:"
hourly_traffic = logs.map { |line| line[/\[(.*?)\]/, 1] }
                    .compact
                    .map { |time_str| Time.parse(time_str.split[0].tr('/', '-')).hour rescue nil }
                    .compact
                    .tally
                    .sort

hourly_traffic.each do |hour, count|
  bar = "█" * (count / 10)
  puts "  #{hour.to_s.rjust(2)}時: #{bar} #{count}件"
end

# ピーク時間帯の特定
peak_hour = hourly_traffic.max_by { |hour, count| count }
puts "\nピーク時間帯: #{peak_hour[0]}時 (#{peak_hour[1]}件)"

# 応用3: 人気URLランキング
puts "\n人気URLトップ10:"
top_urls = logs.map { |line| line[/"(?:GET|POST) ([^"?]+)/, 1] }
              .compact
              .tally
              .sort_by { |url, count| -count }
              .first(10)

top_urls.each_with_index do |(url, count), i|
  puts "  #{(i+1).to_s.rjust(2)}. #{url.ljust(30)} (#{count}回)"
end

# 応用4: IPアドレス分析
puts "\nIPアドレス分析:"
ip_counts = logs.map { |line| line[/^(\S+)/, 1] }
               .compact
               .tally

puts "  ユニークIP数: #{ip_counts.size}"
puts "  総アクセス数: #{ip_counts.values.sum}"

top_ips = ip_counts.sort_by { |ip, count| -count }.first(5)
puts "\n  アクセス数上位5IP:"
top_ips.each_with_index do |(ip, count), i|
  puts "    #{i+1}. #{ip.ljust(15)} - #{count}回"
end

# 疑わしいIP（100回以上アクセス）
suspicious_ips = ip_counts.select { |ip, count| count > 100 }
if suspicious_ips.any?
  puts "\n  ⚠️  疑わしいIP (100回以上):"
  suspicious_ips.each { |ip, count| puts "    #{ip}: #{count}回" }
end

puts "\n=== 実務レベル解答 ==="

# ログ解析クラス
class LogAnalyzer
  def initialize(log_file)
    @logs = File.readlines(log_file)
    @parsed_logs = parse_logs
  end

  def parse_logs
    @logs.map do |line|
      if line =~ /^(\S+) .* \[(.*?)\] "(\w+) ([^"]+)" (\d+) (\d+)/
        {
          ip: $1,
          time: Time.parse($2.split[0].tr('/', '-')) rescue nil,
          method: $3,
          path: $4,
          status: $5.to_i,
          size: $6.to_i
        }
      end
    end.compact
  end

  def report
    puts "# アクセスログ分析レポート"
    puts "=" * 60
    puts "\n## 📊 基本統計"
    basic_stats
    puts "\n## 🚦 HTTPステータス分布"
    status_distribution
    puts "\n## ⏰ 時間帯別トラフィック"
    hourly_traffic_report
    puts "\n## 🏆 人気URL"
    popular_urls
    puts "\n## 🌐 IPアドレス分析"
    ip_analysis
    puts "\n## ⚠️  異常検出"
    anomaly_detection
    puts "\n## 🔍 User-Agent分析"
    user_agent_analysis
  end

  def basic_stats
    total_size_mb = (@parsed_logs.sum { |l| l[:size] } / 1024.0 / 1024).round(2)
    avg_size_kb = (@parsed_logs.sum { |l| l[:size] }.to_f / @parsed_logs.size / 1024).round(2)

    puts "- 総アクセス数: #{@parsed_logs.size.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "- ユニークIP数: #{@parsed_logs.map { |l| l[:ip] }.uniq.size}"
    puts "- 総転送量: #{total_size_mb} MB"
    puts "- 平均転送量: #{avg_size_kb} KB/リクエスト"
  end

  def status_distribution
    status_groups = {
      '2xx (成功)' => (200..299),
      '3xx (リダイレクト)' => (300..399),
      '4xx (クライアントエラー)' => (400..499),
      '5xx (サーバーエラー)' => (500..599)
    }

    status_groups.each do |label, range|
      count = @parsed_logs.count { |l| range.include?(l[:status]) }
      percentage = (count.to_f / @parsed_logs.size * 100).round(2)
      puts "- #{label}: #{count}件 (#{percentage}%)"
    end
  end

  def hourly_traffic_report
    hourly = @parsed_logs.map { |l| l[:time].hour }.tally.sort
    max_count = hourly.map { |_, count| count }.max

    hourly.each do |hour, count|
      bar_length = (count.to_f / max_count * 40).round
      bar = "▓" * bar_length
      puts "  #{hour.to_s.rjust(2)}時: #{bar} #{count}"
    end
  end

  def popular_urls
    @parsed_logs.map { |l| l[:path].split('?').first }
      .tally
      .sort_by { |url, count| -count }
      .first(5)
      .each_with_index { |(url, count), i| puts "  #{i+1}. #{url} (#{count}回)" }
  end

  def ip_analysis
    ip_counts = @parsed_logs.map { |l| l[:ip] }.tally
    top_ip = ip_counts.max_by { |k, v| v }

    puts "- 最多アクセスIP: #{top_ip[0]} (#{top_ip[1]}回)"

    suspicious = ip_counts.select { |ip, count| count > 100 }
    if suspicious.any?
      puts "- 疑わしいIP (100回以上アクセス):"
      suspicious.each { |ip, count| puts "    - #{ip}: #{count}回" }
    else
      puts "- 疑わしいIPは検出されませんでした"
    end
  end

  def anomaly_detection
    error_count = @parsed_logs.count { |l| l[:status] >= 400 }
    error_rate = (error_count.to_f / @parsed_logs.size * 100).round(2)

    puts "- エラー率: #{error_rate}% (#{error_count}/#{@parsed_logs.size})"

    if error_rate > 10
      puts "  🚨 警告: エラー率が10%を超えています"
    elsif error_rate > 5
      puts "  ⚠️  注意: エラー率が5%を超えています"
    else
      puts "  ✅ エラー率は正常範囲内です"
    end

    # 404エラーの多いパス
    not_found = @parsed_logs.select { |l| l[:status] == 404 }
    if not_found.any?
      puts "\n- 404エラーが多いパス:"
      not_found.map { |l| l[:path] }
        .tally
        .sort_by { |path, count| -count }
        .first(3)
        .each { |path, count| puts "    - #{path}: #{count}回" }
    end
  end

  def user_agent_analysis
    # サンプル実装（ログにUser-Agentがある場合）
    puts "- User-Agent情報は詳細ログから解析可能です"
  end
end

# レポート生成
puts "\n包括的ログ分析レポート:"
puts "=" * 60
analyzer = LogAnalyzer.new("sample_data/access.log")
analyzer.report

puts "\n\n🚀 ワンライナー版:"

# 総アクセス数
puts "\n総アクセス数: " + File.readlines("sample_data/access.log").size.to_s

# ユニークIP数
puts "ユニークIP数: " + File.readlines("sample_data/access.log").map { |l| l[/^(\S+)/, 1] }.uniq.size.to_s

# ステータスコード集計
puts "\nステータスコード集計:"
puts File.readlines("sample_data/access.log").map { |l| l[/" (\d{3}) /, 1] }.compact.tally.sort_by { |k,v| -v }.inspect

# 最多アクセスIP
puts "\n最多アクセスIP: " + File.readlines("sample_data/access.log").map { |l| l[/^(\S+)/, 1] }.tally.max_by { |k,v| v }.inspect

# エラー率
total = File.readlines("sample_data/access.log").size
errors = File.readlines("sample_data/access.log").count { |l| l =~ /" [45]\d{2} / }
puts "\nエラー率: #{(errors.to_f / total * 100).round(2)}%"

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # リアルタイムログ監視（エラーのみ）
  tail -f access.log | ruby -ne 'puts $_ if /\" [45]\\d{2} /'

  # 特定時間帯のアクセス解析
  ruby -ne 'puts $_ if /\\[15\\/Jan\\/2024:09:/' access.log | wc -l

  # IPアドレス別アクセス集計（上位10件）
  ruby -ne 'puts $1 if /^(\\S+)/' access.log | sort | uniq -c | sort -rn | head -10

  # 404エラーのパス一覧
  ruby -ne 'puts $1 if /"GET ([^"]+)" 404/' access.log | sort | uniq -c | sort -rn

  # 時間帯別アクセスグラフ
  ruby -rtime -ne 'puts Time.parse($1.split[0].tr("/", "-")).hour if /\\[(.*?)\\]/' access.log | sort -n | uniq -c

  # レスポンスサイズの統計
  ruby -ne 'puts $1.to_i if /" \\d{3} (\\d+)/' access.log | ruby -e 'nums = STDIN.readlines.map(&:to_i); puts "合計: #{nums.sum / 1024.0 / 1024} MB, 平均: #{nums.sum / nums.size / 1024.0} KB"'

  # 疑わしいIPの検出（1分間に10回以上アクセス）
  ruby -rtime -ne 'if /^(\\S+) .* \\[(.*?)\\]/; puts "#{$1} #{Time.parse($2.split[0].tr("/", "-")).strftime("%Y-%m-%d %H:%M")}"; end' access.log | sort | uniq -c | awk '$1 > 10'

  # ボット・クローラーのアクセス集計
  grep -i "bot\\|crawler\\|spider" access.log | ruby -ne 'puts $1 if /^(\\S+)/' | sort | uniq -c | sort -rn
EXAMPLES
