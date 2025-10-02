# Day 15: ディスク・ネットワーク監視ワンライナー - 解答例

puts "=== 基本レベル解答 ==="
# 基本: ディスク使用率のチェック

if File.exist?("sample_data/df_output.txt")
  df_output = File.read("sample_data/df_output.txt")
else
  # サンプルデータがない場合のシミュレーション
  df_output = <<~DF
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sda1       100G   45G   50G  48% /
    /dev/sda2       500G  420G   55G  89% /var
    /dev/sdb1       1.0T  856G  123G  88% /data
    /dev/sdc1       2.0T  1.2T  752G  62% /backup
    tmpfs           8.0G  1.2G  6.8G  15% /tmp
  DF
end

puts "ディスク使用率チェック（閾値: 80%）:"
df_lines = df_output.lines[1..]

df_lines.each do |line|
  cols = line.split
  filesystem = cols[0]
  size = cols[1]
  used = cols[2]
  avail = cols[3]
  usage_percent = cols[4].to_i
  mount = cols[5]

  if usage_percent >= 90
    puts "🔴 CRITICAL: #{filesystem} (#{mount}) - #{usage_percent}% 使用中 (残り: #{avail})"
  elsif usage_percent >= 80
    puts "🟡 WARNING: #{filesystem} (#{mount}) - #{usage_percent}% 使用中 (残り: #{avail})"
  elsif usage_percent >= 70
    puts "📊 INFO: #{filesystem} (#{mount}) - #{usage_percent}% 使用中"
  end
end

puts "\n=== 応用レベル解答 ==="

# 応用1: ディスク使用量の詳細分析
puts "ディスク使用量分析:"

disk_info = []
df_lines.each do |line|
  cols = line.split
  next if cols.size < 6

  disk_info << {
    filesystem: cols[0],
    size_gb: cols[1].gsub(/[A-Z]/, '').to_f,
    used_gb: cols[2].gsub(/[A-Z]/, '').to_f,
    avail_gb: cols[3].gsub(/[A-Z]/, '').to_f,
    usage_percent: cols[4].to_i,
    mount: cols[5]
  }
end

total_size = disk_info.sum { |d| d[:size_gb] }
total_used = disk_info.sum { |d| d[:used_gb] }
total_avail = disk_info.sum { |d| d[:avail_gb] }

puts "総容量: #{total_size.round(1)}GB"
puts "使用量: #{total_used.round(1)}GB"
puts "空き容量: #{total_avail.round(1)}GB"
puts "全体使用率: #{((total_used / total_size) * 100).round(1)}%"

# 応用2: ネットワーク接続監視
puts "\nネットワーク接続状態監視:"

if File.exist?("sample_data/ss_output.txt")
  ss_output = File.read("sample_data/ss_output.txt")
else
  # サンプルデータがない場合のシミュレーション
  ss_output = <<~SS
    State      Recv-Q Send-Q Local Address:Port    Peer Address:Port
    LISTEN     0      128    0.0.0.0:22            0.0.0.0:*
    LISTEN     0      128    0.0.0.0:80            0.0.0.0:*
    LISTEN     0      128    0.0.0.0:443           0.0.0.0:*
    ESTAB      0      0      192.168.1.10:22       192.168.1.50:52341
    ESTAB      0      0      192.168.1.10:443      203.0.113.45:48392
    ESTAB      0      0      192.168.1.10:3306     192.168.1.20:59876
    ESTAB      0      0      192.168.1.10:443      198.51.100.23:61234
    TIME-WAIT  0      0      192.168.1.10:80       203.0.113.89:54321
    SYN-SENT   0      1      192.168.1.10:45678    203.0.113.100:3306
  SS
end

connection_stats = {
  listen: 0,
  established: 0,
  time_wait: 0,
  syn_sent: 0,
  close_wait: 0
}

ss_lines = ss_output.lines[1..]
ss_lines.each do |line|
  state = line.split.first
  connection_stats[:listen] += 1 if state == "LISTEN"
  connection_stats[:established] += 1 if state == "ESTAB"
  connection_stats[:time_wait] += 1 if state == "TIME-WAIT"
  connection_stats[:syn_sent] += 1 if state == "SYN-SENT"
  connection_stats[:close_wait] += 1 if state == "CLOSE-WAIT"
end

puts "接続状態の統計:"
puts "  LISTEN: #{connection_stats[:listen]}ポート"
puts "  ESTABLISHED: #{connection_stats[:established]}接続"
puts "  TIME-WAIT: #{connection_stats[:time_wait]}接続"
puts "  SYN-SENT: #{connection_stats[:syn_sent]}接続"

if connection_stats[:established] > 100
  puts "⚠️ WARNING: ESTABLISHED接続が多い (#{connection_stats[:established]})"
end

if connection_stats[:time_wait] > 50
  puts "⚠️ WARNING: TIME-WAIT接続が多い (#{connection_stats[:time_wait]})"
end

# 応用3: ポート別接続数
puts "\nポート別接続数:"
port_connections = Hash.new(0)

ss_lines.each do |line|
  cols = line.split
  next if cols.size < 5

  local_addr = cols[3]
  if local_addr =~ /:(\d+)$/
    port = $1
    port_connections[port] += 1
  end
end

port_connections.sort_by { |_, count| -count }.first(10).each do |port, count|
  service_name = case port
                 when "22" then "SSH"
                 when "80" then "HTTP"
                 when "443" then "HTTPS"
                 when "3306" then "MySQL"
                 when "5432" then "PostgreSQL"
                 when "6379" then "Redis"
                 else "不明"
                 end
  puts "  ポート #{port} (#{service_name}): #{count}接続"
end

puts "\n=== 実務レベル解答 ==="

# 実務1: ディスク容量予測
puts "ディスク容量予測分析:"

# 過去データのシミュレーション（実際は履歴データを保存して使用）
historical_data = [
  { date: "2025-01-08", usage: 75 },
  { date: "2025-01-09", usage: 77 },
  { date: "2025-01-10", usage: 80 },
  { date: "2025-01-11", usage: 82 },
  { date: "2025-01-12", usage: 85 },
  { date: "2025-01-13", usage: 87 },
  { date: "2025-01-14", usage: 88 },
  { date: "2025-01-15", usage: 89 }
]

if historical_data.size >= 2
  # 単純線形予測
  first_usage = historical_data.first[:usage]
  last_usage = historical_data.last[:usage]
  days = historical_data.size - 1
  daily_increase = (last_usage - first_usage).to_f / days

  puts "/var パーティション容量予測:"
  puts "  現在の使用率: #{last_usage}%"
  puts "  日次増加率: #{daily_increase.round(2)}%/日"

  if daily_increase > 0
    days_to_90 = ((90 - last_usage) / daily_increase).round
    days_to_95 = ((95 - last_usage) / daily_increase).round

    if days_to_90 > 0 && days_to_90 < 30
      puts "  🟡 90%到達予測: 約#{days_to_90}日後"
    end

    if days_to_95 > 0 && days_to_95 < 30
      puts "  🔴 95%到達予測: 約#{days_to_95}日後"
    end

    if days_to_90 <= 7
      puts "  ⚠️ アクション必要: 容量増設またはクリーンアップ推奨"
    end
  end
end

# 実務2: I/O統計分析（シミュレート）
puts "\nディスクI/O統計:"

iostat_data = [
  { device: "sda", read_mbps: 25.3, write_mbps: 42.1, util: 35.6 },
  { device: "sdb", read_mbps: 128.7, write_mbps: 85.4, util: 78.9 },
  { device: "sdc", read_mbps: 12.5, write_mbps: 8.3, util: 15.2 }
]

iostat_data.each do |disk|
  status = if disk[:util] > 80
             "🔴 高負荷"
           elsif disk[:util] > 60
             "🟡 注意"
           else
             "✅ 正常"
           end

  puts "#{status} #{disk[:device]}: 読込#{disk[:read_mbps]}MB/s 書込#{disk[:write_mbps]}MB/s 使用率#{disk[:util]}%"
end

# 実務3: ネットワークトラフィック監視
puts "\nネットワークトラフィック監視:"

network_interfaces = [
  { name: "eth0", rx_mbps: 245.6, tx_mbps: 128.3, errors: 0 },
  { name: "eth1", rx_mbps: 856.2, tx_mbps: 423.1, errors: 2 },
  { name: "lo", rx_mbps: 12.5, tx_mbps: 12.5, errors: 0 }
]

network_interfaces.each do |iface|
  total_mbps = iface[:rx_mbps] + iface[:tx_mbps]
  status = if iface[:errors] > 0
             "🔴 エラーあり"
           elsif total_mbps > 800
             "🟡 高トラフィック"
           else
             "✅ 正常"
           end

  puts "#{status} #{iface[:name]}: 受信#{iface[:rx_mbps]}Mbps 送信#{iface[:tx_mbps]}Mbps エラー#{iface[:errors]}件"
end

# 実務4: 総合監視レポート
puts "\n📊 総合監視レポート:"

def generate_health_report(disk_info, connection_stats, iostat_data)
  report = {
    status: "HEALTHY",
    alerts: [],
    warnings: [],
    info: []
  }

  # ディスクチェック
  critical_disks = disk_info.select { |d| d[:usage_percent] >= 90 }
  warning_disks = disk_info.select { |d| d[:usage_percent] >= 80 && d[:usage_percent] < 90 }

  if critical_disks.any?
    report[:status] = "CRITICAL"
    critical_disks.each do |d|
      report[:alerts] << "ディスク容量危機: #{d[:mount]} (#{d[:usage_percent]}%)"
    end
  end

  if warning_disks.any?
    report[:status] = "WARNING" if report[:status] == "HEALTHY"
    warning_disks.each do |d|
      report[:warnings] << "ディスク容量警告: #{d[:mount]} (#{d[:usage_percent]}%)"
    end
  end

  # I/Oチェック
  high_io = iostat_data.select { |d| d[:util] > 80 }
  if high_io.any?
    report[:status] = "WARNING" if report[:status] == "HEALTHY"
    high_io.each do |d|
      report[:warnings] << "ディスクI/O高負荷: #{d[:device]} (#{d[:util]}%)"
    end
  end

  # 接続数チェック
  if connection_stats[:established] > 100
    report[:warnings] << "確立済み接続数が多い: #{connection_stats[:established]}"
  end

  report
end

health_report = generate_health_report(disk_info, connection_stats, iostat_data)

puts "システムステータス: #{health_report[:status]}"

if health_report[:alerts].any?
  puts "\n🔴 緊急アラート:"
  health_report[:alerts].each { |alert| puts "  - #{alert}" }
end

if health_report[:warnings].any?
  puts "\n🟡 警告:"
  health_report[:warnings].each { |warning| puts "  - #{warning}" }
end

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# ディスク使用率80%以上をSlack通知
df -h | ruby -e 'STDIN.readlines[1..].each { |l| cols = l.split; system("curl -X POST -d \'{\"text\":\"Disk Alert: \#{cols[5]} at \#{cols[4]}\"}\' WEBHOOK") if cols[4].to_i > 80 }'

# ディスク使用率の日次記録（容量予測に使用）
ruby -e 'File.open("/var/log/disk_usage.log", "a") { |f| `df -h`.lines[1..].each { |l| cols = l.split; f.puts "#{Time.now.strftime("%Y-%m-%d")},#{cols[5]},#{cols[4]}" } }'

# ポート別接続数TOP10
ss -tan | ruby -e 'ports = Hash.new(0); STDIN.readlines[1..].each { |l| port = l.split[3][/:(\d+)$/, 1]; ports[port] += 1 if port }; ports.sort_by { |_,v| -v }.first(10).each { |p,c| puts "#{p}: #{c}" }'

# TIME-WAIT接続が多い場合に警告
ss -tan | ruby -e 'tw = STDIN.readlines.count { |l| l.include?("TIME-WAIT") }; puts "TIME-WAIT: #{tw}"; system("curl -X POST -d \'{\"text\":\"TIME-WAIT高: #{tw}\"}\' WEBHOOK") if tw > 1000'

# ディスクI/O使用率監視
iostat -x 1 5 | ruby -e 'STDIN.readlines.select { |l| l =~ /sd[a-z]/ }.each { |l| cols = l.split; puts "⚠️ #{cols[0]} 使用率:#{cols[-1]}%" if cols[-1].to_f > 80 }'

# ネットワーク接続の異常検出（外部IPからの大量接続）
ss -tan | ruby -e 'ips = Hash.new(0); STDIN.readlines.each { |l| ip = l[/(\d+\.\d+\.\d+\.\d+):\d+/, 1]; ips[ip] += 1 if ip && !ip.start_with?("192.168.", "10.", "172.") }; ips.select { |_,v| v > 10 }.each { |ip, count| puts "🚨 #{ip}: #{count}接続" }'

# ディスク容量の大きいディレクトリTOP10
du -h /var | sort -hr | head -10 | ruby -e 'puts STDIN.readlines.map.with_index { |l, i| "#{i+1}. #{l.strip}" }'
ONELINERS

puts "\n📋 ディスク・ネットワーク監視チェックリスト:"
checklist = [
  "ディスク使用率の確認（閾値: 80%）",
  "I/O使用率の確認",
  "ネットワーク接続数の確認",
  "TIME-WAIT接続の確認",
  "不審な外部接続の検出",
  "ディスク容量増加傾向の分析",
  "ログファイルサイズの確認"
]

checklist.each_with_index { |item, i| puts "#{i+1}. [ ] #{item}" }

puts "\n🎯 本番運用での注意点:"
puts "- ディスク使用率は定期的に記録し、容量予測に活用"
puts "- 閾値は環境に応じて調整（本番: 80%, 開発: 90%等）"
puts "- TIME-WAIT大量発生時はカーネルパラメータの調整を検討"
puts "- 外部からの異常接続はファイアウォールで遮断"
puts "- ログローテーション設定でディスク圧迫を防ぐ"
puts "- I/O高負荷時はアプリケーション最適化やSSD化を検討"
