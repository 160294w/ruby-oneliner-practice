# Day 14: ヒントとステップガイド

## 段階的に考えてみよう

### Step 1: プロセス情報の基本取得
```ruby
# ps コマンドでプロセス一覧取得
processes = `ps aux`.lines

# ヘッダー行を除外
process_data = processes[1..]

# 各カラムの意味
# USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
```

### Step 2: CPU使用率でソート
```ruby
# CPU使用率が高い順に並べる
top_cpu = processes[1..].sort_by do |line|
  cols = line.split
  -cols[2].to_f  # %CPU (マイナスで降順)
end

# TOP5を表示
top_cpu.first(5).each do |p|
  puts p
end
```

### Step 3: メモリ使用率でフィルタ
```ruby
# メモリ使用率10%以上のプロセス
high_memory = processes[1..].select do |line|
  cols = line.split
  cols[3].to_f >= 10.0  # %MEM
end
```

## よく使うパターン

### パターン1: プロセス情報の構造化
```ruby
# プロセス情報をハッシュに変換
def parse_ps_line(line)
  cols = line.split(nil, 11)  # 最大11分割
  {
    user: cols[0],
    pid: cols[1].to_i,
    cpu: cols[2].to_f,
    mem: cols[3].to_f,
    vsz: cols[4].to_i,
    rss: cols[5].to_i,
    tty: cols[6],
    stat: cols[7],
    start: cols[8],
    time: cols[9],
    command: cols[10]
  }
end

processes = `ps aux`.lines[1..].map { |line| parse_ps_line(line) }
```

### パターン2: プロセスのフィルタリング
```ruby
# 特定ユーザーのプロセスのみ
user_processes = processes.select { |p| p[:user] == "www-data" }

# 特定コマンドを含むプロセス
nginx_processes = processes.select { |p| p[:command] =~ /nginx/ }

# ゾンビプロセスの検出
zombie_processes = processes.select { |p| p[:stat] =~ /Z/ }
```

### パターン3: リソース使用量の集計
```ruby
# ユーザー別のCPU使用率合計
user_cpu = processes.group_by { |p| p[:user] }
  .transform_values { |ps| ps.sum { |p| p[:cpu] } }
  .sort_by { |_, cpu| -cpu }

# コマンド別のメモリ使用量
command_mem = processes.group_by { |p|
    p[:command].split.first  # コマンド名のみ
  }
  .transform_values { |ps| ps.sum { |p| p[:mem] } }
```

## よくある間違い

### 間違い1: スペース区切りの処理ミス
```ruby
# ❌ COMMANDにスペースが含まれる場合に問題
cols = line.split  # 引数もすべて分割されてしまう

# ✅ 最大分割数を指定
cols = line.split(nil, 11)  # 11個までに分割
```

### 間違い2: 文字列と数値の混同
```ruby
# ❌ 文字列のまま比較
if cpu_usage > 50.0  # cpu_usageが文字列だとエラー

# ✅ 数値に変換
cpu_usage = cols[2].to_f
if cpu_usage > 50.0
```

### 間違い3: プロセス状態の誤解
```ruby
# ❌ 単純な文字列マッチ
zombie = line.include?("Z")  # コマンド名にZがあると誤検出

# ✅ STAT列のみをチェック
cols = line.split(nil, 11)
zombie = cols[7] =~ /^Z/  # STATの先頭がZ
```

## 応用のヒント

### プロセスツリーの表示
```ruby
# pstreeコマンドの活用
process_tree = `pstree -p`

# 特定プロセスの子プロセスを取得
def get_child_processes(parent_pid)
  all_processes = `ps -eo pid,ppid,command`.lines[1..]
  all_processes.select { |line|
    cols = line.split(nil, 3)
    cols[1].to_i == parent_pid  # PPIDが親プロセスのPID
  }
end

# 再帰的にプロセスツリーを取得
def get_process_tree(pid, indent = 0)
  children = get_child_processes(pid)
  children.each do |child|
    puts "  " * indent + child
    child_pid = child.split.first.to_i
    get_process_tree(child_pid, indent + 1)
  end
end
```

### 異常プロセスの検出
```ruby
# CPU使用率が異常に高いプロセス
cpu_threshold = 80.0
cpu_hogs = processes.select { |p| p[:cpu] > cpu_threshold }

# メモリ使用量が異常に多いプロセス
mem_threshold = 20.0  # 20%以上
mem_hogs = processes.select { |p| p[:mem] > mem_threshold }

# 長時間実行されているプロセス
# TIME列が大きい（例: 10:00:00以上）
long_running = processes.select do |p|
  time_parts = p[:time].split(':')
  hours = time_parts[0].to_i
  hours >= 10
end
```

### プロセスの自動管理
```ruby
# リソース使用量に基づく自動対応
def monitor_and_act(threshold_cpu: 90, threshold_mem: 80)
  processes = `ps aux`.lines[1..].map { |l| parse_ps_line(l) }

  critical_processes = processes.select do |p|
    p[:cpu] > threshold_cpu || p[:mem] > threshold_mem
  end

  critical_processes.each do |p|
    puts "⚠️  PID #{p[:pid]} (#{p[:command]}): CPU #{p[:cpu]}%, MEM #{p[:mem]}%"

    # 条件に応じたアクション
    if p[:cpu] > threshold_cpu && p[:mem] > threshold_mem
      puts "  → CRITICAL: CPU & Memory両方が高負荷"
      # 例: kill -9 #{p[:pid]} (実際の実行は慎重に)
    end
  end
end
```

### リアルタイム監視
```ruby
# 定期的にプロセスをチェック
loop do
  system('clear')
  puts "=== プロセス監視 #{Time.now} ==="

  processes = `ps aux`.lines[1..].map { |l| parse_ps_line(l) }

  # CPU TOP5
  puts "\n🔥 CPU使用率 TOP5:"
  processes.sort_by { |p| -p[:cpu] }.first(5).each do |p|
    puts "  #{p[:pid]} #{p[:command][0..40]} - #{p[:cpu]}%"
  end

  # メモリ TOP5
  puts "\n💾 メモリ使用率 TOP5:"
  processes.sort_by { |p| -p[:mem] }.first(5).each do |p|
    puts "  #{p[:pid]} #{p[:command][0..40]} - #{p[:mem]}%"
  end

  sleep 5  # 5秒ごとに更新
end
```

## デバッグのコツ

### プロセス情報のフォーマット確認
```ruby
# サンプル行を詳細表示
sample_line = `ps aux`.lines[1]
puts "Raw: #{sample_line.inspect}"

cols = sample_line.split(nil, 11)
cols.each_with_index do |col, i|
  puts "Col #{i}: #{col}"
end
```

### 特定プロセスの追跡
```ruby
# プロセス名で検索
def find_process(name)
  `ps aux`.lines[1..].select { |line|
    line =~ /#{Regexp.escape(name)}/
  }
end

# PIDで詳細情報取得
def process_info(pid)
  info = `ps -p #{pid} -o pid,ppid,user,%cpu,%mem,vsz,rss,stat,start,time,command`
  puts info
end
```

### プロセス統計の可視化
```ruby
# CPU使用率のヒストグラム
cpu_ranges = {
  "0-20%"   => 0,
  "20-40%"  => 0,
  "40-60%"  => 0,
  "60-80%"  => 0,
  "80-100%" => 0
}

processes.each do |p|
  case p[:cpu]
  when 0...20   then cpu_ranges["0-20%"]   += 1
  when 20...40  then cpu_ranges["20-40%"]  += 1
  when 40...60  then cpu_ranges["40-60%"]  += 1
  when 60...80  then cpu_ranges["60-80%"]  += 1
  when 80..100  then cpu_ranges["80-100%"] += 1
  end
end

cpu_ranges.each do |range, count|
  bar = "■" * count
  puts "#{range}: #{bar} (#{count})"
end
```

## 実用的なワンライナー集

```bash
# CPU使用率TOP10
ps aux | ruby -e 'puts STDIN.readlines[1..].sort_by { |l| -l.split[2].to_f }.first(10)'

# メモリ使用率TOP10
ps aux | ruby -e 'puts STDIN.readlines[1..].sort_by { |l| -l.split[3].to_f }.first(10)'

# ユーザー別CPU使用率合計
ps aux | ruby -e 'puts STDIN.readlines[1..].group_by { |l| l.split[0] }.transform_values { |ls| ls.sum { |l| l.split[2].to_f } }.sort_by { |_,v| -v }.to_h'

# ゾンビプロセスの検出
ps aux | ruby -ne 'puts $_ if $_.split[7] =~ /^Z/'

# 特定ユーザーのプロセス数
ps aux | ruby -e 'puts STDIN.readlines[1..].group_by { |l| l.split[0] }.transform_values(&:size)'

# コマンド別メモリ使用量
ps aux | ruby -e 'puts STDIN.readlines[1..].group_by { |l| l.split[10].to_s.split.first }.transform_values { |ls| ls.sum { |l| l.split[3].to_f }.round(2) }.sort_by { |_,v| -v }.first(10).to_h'

# CPU 50%超のプロセスをkill（注意して使用）
ps aux | ruby -e 'STDIN.readlines[1..].each { |l| cols = l.split; system("kill #{cols[1]}") if cols[2].to_f > 50.0 }'

# プロセス数の監視（5秒ごと）
while true; do ps aux | ruby -e 'puts "#{Time.now}: #{STDIN.readlines.size - 1} processes"'; sleep 5; done
```

## 高度なテクニック

### プロセス監視スクリプト
```ruby
#!/usr/bin/env ruby

class ProcessMonitor
  def initialize(cpu_threshold: 80, mem_threshold: 70)
    @cpu_threshold = cpu_threshold
    @mem_threshold = mem_threshold
  end

  def monitor
    processes = get_processes
    alerts = check_thresholds(processes)
    generate_report(processes, alerts)
  end

  private

  def get_processes
    `ps aux`.lines[1..].map do |line|
      cols = line.split(nil, 11)
      {
        pid: cols[1].to_i,
        user: cols[0],
        cpu: cols[2].to_f,
        mem: cols[3].to_f,
        command: cols[10].split.first
      }
    end
  end

  def check_thresholds(processes)
    processes.select do |p|
      p[:cpu] > @cpu_threshold || p[:mem] > @mem_threshold
    end
  end

  def generate_report(processes, alerts)
    puts "=== プロセス監視レポート #{Time.now} ==="
    puts "総プロセス数: #{processes.size}"
    puts "アラート: #{alerts.size}件"

    if alerts.any?
      puts "\n⚠️  閾値超過プロセス:"
      alerts.each do |p|
        puts "  PID #{p[:pid]} (#{p[:user]}/#{p[:command]}): CPU #{p[:cpu]}%, MEM #{p[:mem]}%"
      end
    end
  end
end

# 使用例
monitor = ProcessMonitor.new(cpu_threshold: 80, mem_threshold: 70)
monitor.monitor
```
