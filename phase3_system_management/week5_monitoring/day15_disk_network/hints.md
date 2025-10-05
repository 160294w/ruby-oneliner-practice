# Day 15: ヒントとステップガイド

## 段階的に考えてみよう

### Step 1: ディスク使用量の基本取得
```ruby
# df コマンドでディスク使用状況取得
disk_info = `df -h`.lines

# ヘッダー行を除外
disk_data = disk_info[1..]

# 各カラムの意味
# Filesystem Size Used Avail Use% Mounted on
```

### Step 2: 使用率でフィルタリング
```ruby
# 使用率80%以上のファイルシステムを検出
high_usage = disk_data.select do |line|
  cols = line.split
  usage_percent = cols[4].to_i  # "85%" → 85
  usage_percent >= 80
end

high_usage.each do |disk|
  cols = disk.split
  puts "⚠️  #{cols[0]}: #{cols[4]} (#{cols[5]})"
end
```

### Step 3: ネットワーク接続の確認
```ruby
# ssコマンドで接続状態取得
connections = `ss -tan`.lines[1..]

# ESTABLISHED状態の接続数
established = connections.count { |line| line.include?("ESTAB") }
puts "アクティブ接続: #{established}件"
```

## よく使うパターン

### パターン1: ディスク情報の構造化
```ruby
def parse_df_line(line)
  cols = line.split
  {
    filesystem: cols[0],
    size: cols[1],
    used: cols[2],
    available: cols[3],
    use_percent: cols[4].to_i,
    mounted_on: cols[5]
  }
end

disks = `df -h`.lines[1..].map { |line| parse_df_line(line) }

# 使用率でソート
sorted_disks = disks.sort_by { |d| -d[:use_percent] }
```

### パターン2: I/O統計の取得
```ruby
# iostat コマンド（sysstatパッケージ必要）
io_stats = `iostat -x 1 2`.lines

# デバイス別のI/O待ち時間（%util）を確認
io_stats.each do |line|
  if line =~ /^(sd\w+|nvme\w+)/
    cols = line.split
    device = cols[0]
    util_percent = cols[-1].to_f
    puts "⚠️  #{device}: I/O使用率 #{util_percent}%" if util_percent > 80
  end
end
```

### パターン3: ネットワーク接続の詳細分析
```ruby
def parse_ss_line(line)
  cols = line.split
  {
    state: cols[0],
    recv_q: cols[1].to_i,
    send_q: cols[2].to_i,
    local_address: cols[3],
    peer_address: cols[4]
  }
end

connections = `ss -tan`.lines[1..]
  .map { |line| parse_ss_line(line) rescue nil }
  .compact

# 状態別の接続数
by_state = connections.group_by { |c| c[:state] }
  .transform_values(&:size)

# ポート別の接続数
by_port = connections.group_by { |c|
  c[:local_address].split(':').last
}.transform_values(&:size)
```

## よくある間違い

### 間違い1: ディスク容量の単位を無視
```ruby
# ❌ 単位を考慮せず比較
if used > available  # "1.5G" と "500M" を文字列比較

# ✅ 数値に変換（-BKオプションでバイト単位）
disk_info = `df -BK`.lines[1..]
disk_info.each do |line|
  cols = line.split
  used_kb = cols[2].to_i
  available_kb = cols[3].to_i
  # 正しく比較可能
end
```

### 間違い2: ネットワーク接続の重複カウント
```ruby
# ❌ LISTENとESTABLISHEDを区別しない
total = connections.size  # すべての状態を含む

# ✅ 状態を区別
established = connections.count { |c| c[:state] == "ESTAB" }
listen = connections.count { |c| c[:state] == "LISTEN" }
```

### 間違い3: tmpfsなどの仮想ファイルシステムを含む
```ruby
# ❌ すべてのファイルシステムを監視
all_disks = `df -h`.lines[1..]

# ✅ 実ディスクのみをフィルタ
real_disks = `df -h -x tmpfs -x devtmpfs`.lines[1..]
# または
real_disks = all_disks.reject { |line|
  line.start_with?('tmpfs', 'devtmpfs', 'udev')
}
```

## 応用のヒント

### ディスク容量の予測
```ruby
# 過去のデータと比較して増加率を計算
# （実際には定期的にデータを保存する必要がある）

def predict_disk_full(current_used, daily_increase_gb, total_capacity_gb)
  available = total_capacity_gb - current_used
  days_until_full = available / daily_increase_gb
  full_date = Time.now + (days_until_full * 24 * 60 * 60)

  {
    days_remaining: days_until_full.round(1),
    estimated_full_date: full_date.strftime("%Y-%m-%d")
  }
end

# 使用例
prediction = predict_disk_full(450, 5, 500)
puts "残り約#{prediction[:days_remaining]}日でディスク満杯予測"
puts "満杯予定日: #{prediction[:estimated_full_date]}"
```

### ディレクトリ別の容量分析
```ruby
# 特定ディレクトリ配下の容量を調査
def analyze_directory_usage(path, depth: 1)
  `du -h --max-depth=#{depth} #{path}`.lines
    .map { |line|
      size, dir = line.split("\t")
      { size: size.strip, directory: dir.strip }
    }
    .sort_by { |d|
      # サイズでソート（簡易版、正確にはバイト変換が必要）
      size_value = d[:size].to_f
      unit = d[:size][-1]
      multiplier = case unit
                   when 'G' then 1024 * 1024
                   when 'M' then 1024
                   when 'K' then 1
                   else 0
                   end
      -(size_value * multiplier)
    }
end

# 使用例
large_dirs = analyze_directory_usage("/var", depth: 1)
puts "容量が大きいディレクトリ TOP5:"
large_dirs.first(5).each do |dir|
  puts "  #{dir[:size].rjust(6)} #{dir[:directory]}"
end
```

### ネットワーク異常検出
```ruby
# 異常な接続パターンの検出
def detect_network_anomalies
  connections = `ss -tan`.lines[1..]
    .map { |l| parse_ss_line(l) rescue nil }
    .compact

  anomalies = []

  # 1. 同一IPからの大量接続
  connections_by_ip = connections
    .group_by { |c| c[:peer_address].split(':').first }
    .transform_values(&:size)

  high_connection_ips = connections_by_ip.select { |_, count| count > 50 }
  anomalies << {
    type: "High connection count",
    details: high_connection_ips
  } if high_connection_ips.any?

  # 2. 送受信キューの滞留
  queued = connections.select { |c|
    c[:recv_q] > 0 || c[:send_q] > 0
  }
  anomalies << {
    type: "Queued data",
    details: "#{queued.size} connections with queued data"
  } if queued.any?

  # 3. TIME_WAIT状態の異常な増加
  time_wait = connections.count { |c| c[:state] == "TIME-WAIT" }
  anomalies << {
    type: "Excessive TIME_WAIT",
    details: "#{time_wait} connections"
  } if time_wait > 1000

  anomalies
end
```

### ポート別の接続監視
```ruby
# 特定ポートの接続状態を監視
def monitor_port(port)
  connections = `ss -tan`.lines.grep(/:#{port}\s/)

  states = Hash.new(0)
  connections.each do |conn|
    state = conn.split.first
    states[state] += 1
  end

  {
    port: port,
    total: connections.size,
    by_state: states,
    connections: connections
  }
end

# 使用例
web_connections = monitor_port(80)
puts "Port 80 接続状態:"
web_connections[:by_state].each do |state, count|
  puts "  #{state}: #{count}"
end
```

## デバッグのコツ

### ディスク情報の詳細確認
```ruby
# デバイスの詳細情報
def disk_details(mount_point)
  info = `df -h #{mount_point}`.lines[1].split
  inode_info = `df -i #{mount_point}`.lines[1].split

  {
    filesystem: info[0],
    size: info[1],
    used: info[2],
    available: info[3],
    use_percent: info[4],
    inode_used: inode_info[2],
    inode_available: inode_info[3],
    inode_use_percent: inode_info[4]
  }
end

# inode枯渇チェック
details = disk_details("/")
if details[:inode_use_percent].to_i > 90
  puts "⚠️  inode使用率が高い: #{details[:inode_use_percent]}"
end
```

### ネットワーク接続の追跡
```ruby
# 特定IPの接続を追跡
def track_ip_connections(ip)
  connections = `ss -tan | grep #{ip}`.lines

  puts "IP #{ip} の接続状態:"
  connections.each do |conn|
    cols = conn.split
    puts "  #{cols[0]} #{cols[3]} → #{cols[4]}"
  end
end

# プロセスと接続の関連付け（root権限必要）
def connections_with_process
  `ss -tanp`.lines[1..].map do |line|
    # users:(("nginx",pid=1234,fd=6)) のような形式から抽出
    if line =~ /users:\(\("([^"]+)",pid=(\d+)/
      process = $1
      pid = $2
      { line: line.strip, process: process, pid: pid }
    end
  end.compact
end
```

### I/O性能の詳細分析
```ruby
# ディスクI/Oの詳細統計
def analyze_io_performance
  # iostat -x 1 2 で2秒間の平均を取得
  io_output = `iostat -x 1 2 2>/dev/null`

  # 最後のデバイス統計を解析
  devices = []
  parsing = false

  io_output.lines.reverse.each do |line|
    break if line =~ /^avg-cpu/

    if line =~ /^(sd\w+|nvme\w+)/
      cols = line.split
      devices << {
        device: cols[0],
        read_kb_s: cols[5].to_f,
        write_kb_s: cols[6].to_f,
        await: cols[9].to_f,  # 平均I/O待ち時間
        util: cols[-1].to_f   # 使用率
      }
    end
  end

  devices.reverse
end

# 使用例
devices = analyze_io_performance
devices.each do |dev|
  status = dev[:util] > 80 ? "⚠️" : "✅"
  puts "#{status} #{dev[:device]}: Util #{dev[:util]}%, Await #{dev[:await]}ms"
end
```

## 実用的なワンライナー集

```bash
# ディスク使用率80%以上を検出
df -h | ruby -ne 'cols = $_.split; puts "⚠️ #{cols[0]}: #{cols[4]}" if cols[4] && cols[4].to_i >= 80'

# ディレクトリサイズTOP10
du -sh /* 2>/dev/null | ruby -e 'puts STDIN.readlines.sort_by { |l| size, _ = l.split; unit = size[-1]; val = size.to_f; mult = (unit == "G" ? 1000 : unit == "M" ? 1 : 0.001); -(val * mult) }.first(10)'

# ポート別の接続数
ss -tan | ruby -e 'puts STDIN.readlines[1..].map { |l| l.split[3].split(":").last }.tally.sort_by { |_,v| -v }.first(10).to_h'

# ESTABLISHED接続のIP別集計
ss -tan state established | ruby -e 'puts STDIN.readlines.map { |l| l.split[4].split(":").first }.tally.sort_by { |_,v| -v }.to_h'

# TIME_WAIT状態の接続数監視
ss -tan state time-wait | ruby -e 'puts "TIME_WAIT: #{STDIN.readlines.size - 1} connections"'

# ディスク容量アラート（使用率90%以上）
df -h | ruby -ne 'cols = $_.split; system(%q{echo "Disk alert: #{cols[0]} at #{cols[4]}" | mail -s "Disk Alert" admin@example.com}) if cols[4] && cols[4].to_i >= 90'

# 全マウントポイントのinode使用率
df -i | ruby -e 'STDIN.readlines[1..].each { |l| cols = l.split; puts "#{cols[5]}: inode #{cols[4]}" if cols[4].to_i > 80 }'

# ネットワーク接続状態のサマリー
ss -tan | ruby -e 'lines = STDIN.readlines[1..]; states = lines.map { |l| l.split.first }.tally; total = lines.size; states.each { |s, c| puts "#{s}: #{c} (#{"%.1f" % (c*100.0/total)}%)" }'

# 5秒ごとのディスク使用率監視
watch -n 5 'df -h | ruby -ne "cols = \$_.split; puts \"\e[31m⚠️ \e[0m#{cols[0]}: #{cols[4]}\" if cols[4] && cols[4].to_i >= 80"'
```

## 高度なテクニック

### 統合監視スクリプト
```ruby
#!/usr/bin/env ruby

class SystemMonitor
  def initialize(disk_threshold: 80, io_threshold: 80, conn_threshold: 1000)
    @disk_threshold = disk_threshold
    @io_threshold = io_threshold
    @conn_threshold = conn_threshold
  end

  def monitor
    puts "=== システム監視レポート #{Time.now} ==="

    check_disk_usage
    check_io_performance
    check_network_connections
  end

  private

  def check_disk_usage
    puts "\n📁 ディスク使用状況:"
    disks = `df -h -x tmpfs -x devtmpfs`.lines[1..]

    alerts = disks.select do |line|
      cols = line.split
      cols[4].to_i >= @disk_threshold
    end

    if alerts.any?
      puts "  ⚠️  警告: 使用率が高いファイルシステム"
      alerts.each do |disk|
        cols = disk.split
        puts "    #{cols[0]}: #{cols[4]} (#{cols[2]}/#{cols[1]})"
      end
    else
      puts "  ✅ すべて正常（閾値: #{@disk_threshold}%未満）"
    end
  end

  def check_io_performance
    puts "\n💾 I/O性能:"
    # 簡易版（iostatが利用可能な場合）
    if system('which iostat > /dev/null 2>&1')
      io_stats = `iostat -x 1 2 2>/dev/null`.lines
      # I/O解析ロジック
      puts "  ✅ I/O統計取得完了"
    else
      puts "  ⚠️  iostatコマンドが見つかりません"
    end
  end

  def check_network_connections
    puts "\n🌐 ネットワーク接続:"
    connections = `ss -tan`.lines[1..]

    by_state = connections.map { |l| l.split.first }.tally
    total = connections.size

    puts "  総接続数: #{total}"
    by_state.each do |state, count|
      status = (state == "TIME-WAIT" && count > @conn_threshold) ? "⚠️" : "  "
      puts "  #{status}#{state}: #{count}"
    end
  end
end

# 実行
monitor = SystemMonitor.new
monitor.monitor
```

### 容量予測システム
```ruby
# 過去データを記録して容量予測
class DiskCapacityPredictor
  def initialize(data_file = "disk_history.json")
    @data_file = data_file
    @history = load_history
  end

  def record_current
    current = get_disk_usage
    @history << { timestamp: Time.now.to_i, data: current }
    save_history
  end

  def predict(days_ahead = 30)
    # 線形回帰で簡易予測
    recent_data = @history.last(30)  # 過去30日分
    # 予測ロジックの実装
  end

  private

  def get_disk_usage
    `df -BK`.lines[1..].map do |line|
      cols = line.split
      { fs: cols[0], used_kb: cols[2].to_i, total_kb: cols[1].to_i }
    end
  end

  def load_history
    File.exist?(@data_file) ? JSON.parse(File.read(@data_file)) : []
  end

  def save_history
    File.write(@data_file, JSON.pretty_generate(@history))
  end
end
```
