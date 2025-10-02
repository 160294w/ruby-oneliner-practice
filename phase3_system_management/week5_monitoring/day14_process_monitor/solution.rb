# Day 14: プロセス監視ワンライナー - 解答例

puts "=== 基本レベル解答 ==="
# 基本: CPU使用率TOP5プロセス

# サンプルデータの読み込み（実環境では `ps aux` を使用）
if File.exist?("sample_data/ps_output.txt")
  ps_output = File.read("sample_data/ps_output.txt")
else
  # サンプルデータがない場合のシミュレーション
  ps_output = <<~PS
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    root         1  0.0  0.3 168820 12456 ?        Ss   08:15   0:01 /sbin/init
    www-data  1234 45.2  8.5 2048576 345678 ?      Sl   09:30   2:15 /usr/bin/nginx worker
    mysql     2345 38.7 15.2 4194304 618234 ?      Ssl  08:20   5:42 /usr/sbin/mysqld
    app       3456 62.3 12.8 1572864 520192 ?      Sl   10:15   1:23 ruby /var/www/app/server.rb
    root      4567  0.2  0.5 123456  20480 ?       Ss   08:15   0:03 /usr/sbin/sshd -D
    app       5678 28.4  5.2 524288  211456 ?      S    11:00   0:45 node /var/www/api/index.js
    redis     6789 15.6  3.2 262144  130048 ?      Ssl  08:25   1:12 redis-server *:6379
    root      7890  0.1  0.2  98304   8192 pts/0   Ss   12:00   0:00 -bash
    app       8901 98.5 22.3 3145728 907264 ?      R    12:15   0:58 python /opt/ml/train.py
    postgre   9012 22.1  9.8 2097152 398336 ?      Ss   08:30   2:34 postgres: main process
    root      9123  0.0  0.0      0      0 ?       Z    13:00   0:00 [defunct] <defunct>
  PS
end

puts "CPU使用率TOP5プロセス:"
processes = ps_output.lines[1..]  # ヘッダー行をスキップ
top_cpu = processes.sort_by { |line| line.split[2].to_f }.reverse.first(5)
top_cpu.each_with_index do |proc, idx|
  cols = proc.split
  puts "#{idx + 1}. PID:#{cols[1]} CPU:#{cols[2]}% MEM:#{cols[3]}% CMD:#{cols[10..-1].join(' ')}"
end

puts "\n=== 応用レベル解答 ==="

# 応用1: メモリ使用率の監視
puts "メモリ使用率の高いプロセス（10%以上）:"
high_memory = processes.select { |line| line.split[3].to_f >= 10.0 }

if high_memory.any?
  high_memory.each do |proc|
    cols = proc.split
    puts "⚠️  PID:#{cols[1]} MEM:#{cols[3]}% CMD:#{cols[10..-1].join(' ')}"
  end
else
  puts "✅ メモリ使用率10%以上のプロセスなし"
end

# 応用2: 異常プロセスの検出
puts "\n異常プロセスの検出:"
zombie_processes = processes.select { |line| line.include?("Z") || line.include?("<defunct>") }
runaway_processes = processes.select { |line| line.split[2].to_f > 80.0 }

if zombie_processes.any?
  puts "🧟 ゾンビプロセス検出:"
  zombie_processes.each do |proc|
    cols = proc.split
    puts "  PID:#{cols[1]} STAT:#{cols[7]} CMD:#{cols[10..-1].join(' ')}"
  end
end

if runaway_processes.any?
  puts "🔥 暴走プロセス検出（CPU80%以上）:"
  runaway_processes.each do |proc|
    cols = proc.split
    puts "  PID:#{cols[1]} CPU:#{cols[2]}% CMD:#{cols[10..-1].join(' ')}"
  end
end

# 応用3: ユーザー別プロセス集計
puts "\nユーザー別プロセス集計:"
user_processes = Hash.new(0)
user_cpu = Hash.new(0.0)
user_mem = Hash.new(0.0)

processes.each do |line|
  cols = line.split
  user = cols[0]
  cpu = cols[2].to_f
  mem = cols[3].to_f

  user_processes[user] += 1
  user_cpu[user] += cpu
  user_mem[user] += mem
end

user_processes.each do |user, count|
  puts "#{user}: #{count}プロセス (CPU合計:#{user_cpu[user].round(1)}%, MEM合計:#{user_mem[user].round(1)}%)"
end

puts "\n=== 実務レベル解答 ==="

# 実務1: 包括的プロセス分析レポート
puts "包括的プロセス監視レポート:"

def analyze_processes(ps_output)
  processes = ps_output.lines[1..]

  report = {
    total_count: processes.size,
    total_cpu: 0.0,
    total_mem: 0.0,
    high_cpu: [],
    high_mem: [],
    zombies: [],
    by_user: Hash.new { |h, k| h[k] = { count: 0, cpu: 0.0, mem: 0.0 } },
    by_state: Hash.new(0)
  }

  processes.each do |line|
    cols = line.split
    next if cols.size < 11

    user = cols[0]
    pid = cols[1]
    cpu = cols[2].to_f
    mem = cols[3].to_f
    state = cols[7]
    cmd = cols[10..-1].join(' ')

    report[:total_cpu] += cpu
    report[:total_mem] += mem

    # ユーザー別集計
    report[:by_user][user][:count] += 1
    report[:by_user][user][:cpu] += cpu
    report[:by_user][user][:mem] += mem

    # 状態別集計
    report[:by_state][state[0]] += 1

    # 高CPU使用プロセス
    report[:high_cpu] << { pid: pid, cpu: cpu, cmd: cmd } if cpu > 50.0

    # 高メモリ使用プロセス
    report[:high_mem] << { pid: pid, mem: mem, cmd: cmd } if mem > 15.0

    # ゾンビプロセス
    report[:zombies] << { pid: pid, cmd: cmd } if state.include?("Z") || cmd.include?("defunct")
  end

  report
end

report = analyze_processes(ps_output)

puts "\n📊 システムリソース概要:"
puts "  総プロセス数: #{report[:total_count]}"
puts "  総CPU使用率: #{report[:total_cpu].round(1)}%"
puts "  総メモリ使用率: #{report[:total_mem].round(1)}%"

puts "\n🔥 注意が必要なプロセス:"
if report[:high_cpu].any?
  puts "CPU高負荷プロセス（50%以上）:"
  report[:high_cpu].each { |p| puts "  PID:#{p[:pid]} CPU:#{p[:cpu]}% - #{p[:cmd]}" }
end

if report[:high_mem].any?
  puts "メモリ高使用プロセス（15%以上）:"
  report[:high_mem].each { |p| puts "  PID:#{p[:pid]} MEM:#{p[:mem]}% - #{p[:cmd]}" }
end

if report[:zombies].any?
  puts "🧟 ゾンビプロセス:"
  report[:zombies].each { |p| puts "  PID:#{p[:pid]} - #{p[:cmd]}" }
  puts "  → 親プロセスの確認と対処が必要"
end

puts "\n👥 ユーザー別リソース使用状況:"
report[:by_user].sort_by { |_, v| -v[:cpu] }.first(5).each do |user, stats|
  puts "#{user}: #{stats[:count]}プロセス CPU:#{stats[:cpu].round(1)}% MEM:#{stats[:mem].round(1)}%"
end

puts "\n📈 プロセス状態分布:"
state_names = {
  'S' => 'スリープ',
  'R' => '実行中',
  'D' => 'ディスクwait',
  'Z' => 'ゾンビ',
  'T' => '停止',
  'I' => 'アイドル'
}
report[:by_state].each do |state, count|
  puts "#{state_names[state] || state}: #{count}プロセス"
end

# 実務2: プロセスツリー分析（シミュレート）
puts "\nプロセスツリー例（主要プロセス）:"
process_tree = [
  { pid: 1, ppid: 0, cmd: "/sbin/init", children: [1234, 2345, 4567] },
  { pid: 1234, ppid: 1, cmd: "nginx: master", children: [1235, 1236] },
  { pid: 1235, ppid: 1234, cmd: "nginx: worker", children: [] },
  { pid: 2345, ppid: 1, cmd: "mysqld", children: [] },
  { pid: 3456, ppid: 1, cmd: "ruby server.rb", children: [3457, 3458] },
  { pid: 9123, ppid: 3456, cmd: "[defunct]", children: [] }
]

def print_tree(tree, pid, indent = 0)
  node = tree.find { |n| n[:pid] == pid }
  return unless node

  prefix = "  " * indent
  marker = node[:cmd].include?("defunct") ? "🧟" : "├─"
  puts "#{prefix}#{marker} [#{node[:pid]}] #{node[:cmd]}"

  node[:children].each do |child_pid|
    print_tree(tree, child_pid, indent + 1)
  end
end

print_tree(process_tree, 1)

# 実務3: アラート条件判定
puts "\n🚨 アラート条件チェック:"
alerts = []

alerts << "CRITICAL: CPU使用率が高い（#{report[:total_cpu].round(1)}%）" if report[:total_cpu] > 200.0
alerts << "WARNING: メモリ使用率が高い（#{report[:total_mem].round(1)}%）" if report[:total_mem] > 80.0
alerts << "WARNING: ゾンビプロセスあり（#{report[:zombies].size}個）" if report[:zombies].any?
alerts << "INFO: 高CPU使用プロセスあり（#{report[:high_cpu].size}個）" if report[:high_cpu].any?

if alerts.any?
  alerts.each { |alert| puts "  #{alert}" }
else
  puts "  ✅ 問題なし"
end

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# CPU使用率TOP10をリアルタイム表示
watch -n 1 "ps aux --sort=-%cpu | head -11 | ruby -e 'puts STDIN.readlines[1..].map { |l| cols = l.split; \"PID:\#{cols[1]} CPU:\#{cols[2]}% \#{cols[10..-1].join(\" \")}\" }'"

# メモリ使用率10%以上のプロセスをSlack通知
ps aux | ruby -e 'high_mem = STDIN.readlines[1..].select { |l| l.split[3].to_f > 10 }; system("curl -X POST -d \'{\"text\":\"High Memory: \#{high_mem.size} processes\"}\' WEBHOOK") if high_mem.any?'

# ゾンビプロセス検出と親プロセス特定
ps aux | ruby -e 'zombies = STDIN.readlines.select { |l| l =~ /Z|defunct/ }; zombies.each { |z| pid = z.split[1]; ppid = `ps -o ppid= -p #{pid}`.strip; puts "Zombie PID:#{pid} Parent:#{ppid}" }'

# 特定プロセスの子プロセス一覧
ruby -e 'pid = ARGV[0]; children = `pgrep -P #{pid}`.lines.map(&:strip); puts "Children of #{pid}:"; children.each { |c| puts `ps -p #{c} -o pid,cmd --no-headers` }' 1234

# CPU使用率80%以上のプロセスを自動kill（危険：本番注意）
ps aux | ruby -e 'STDIN.readlines[1..].each { |l| cols = l.split; system("kill -9 #{cols[1]}") if cols[2].to_f > 80 && cols[0] == "app" }'

# プロセス起動時刻順ソート
ps -eo pid,lstart,cmd --sort=start_time | ruby -e 'puts STDIN.readlines.first(20)'

# ユーザー別CPU使用率集計
ps aux | ruby -e 'users = Hash.new(0.0); STDIN.readlines[1..].each { |l| cols = l.split; users[cols[0]] += cols[2].to_f }; users.sort_by { |_,v| -v }.each { |u,cpu| puts "#{u}: #{cpu.round(1)}%" }'
ONELINERS

puts "\n📋 プロセス監視チェックリスト:"
checklist = [
  "CPU使用率の高いプロセス確認",
  "メモリ使用率の高いプロセス確認",
  "ゾンビプロセスの検出と親プロセス特定",
  "ディスクI/O待ちプロセスの確認",
  "長時間実行プロセスの確認",
  "異常な子プロセス生成の検出"
]

checklist.each_with_index { |item, i| puts "#{i+1}. [ ] #{item}" }

puts "\n🎯 本番運用での注意点:"
puts "- 自動killは慎重に。必ず条件を厳密に設定"
puts "- プロセス監視は定期実行で自動化（cron/systemd timer）"
puts "- CPU/メモリの閾値は環境に応じて調整"
puts "- ゾンビプロセスは親プロセスの再起動で解決"
puts "- プロセスツリーで依存関係を把握してから操作"
