# Day 12: パフォーマンス最適化 - 解答例

require 'benchmark'

puts "=== 基本レベル解答 ==="
# 基本: ストリーミング処理（メモリ効率的）

puts "ストリーミング処理の例:"
if File.exist?("sample_data/large_log.txt")
  error_count = 0
  File.foreach("sample_data/large_log.txt") do |line|
    error_count += 1 if line.include?("ERROR")
  end
  puts "  エラー件数: #{error_count}"
end

# 悪い例（メモリを大量消費）
puts "\n❌ 悪い例（全ファイルをメモリに読み込み）:"
puts 'data = File.read("huge_file.log")  # 10GBのファイルなら10GBのメモリを消費'

# 良い例（メモリ効率的）
puts "\n✅ 良い例（ストリーミング処理）:"
puts 'File.foreach("huge_file.log") { |line| process(line) }  # メモリ使用量は一定'

puts "\n=== 応用レベル解答 ==="

# 応用1: 遅延評価による効率化
puts "遅延評価の活用:"
if File.exist?("sample_data/data.csv")
  # 最初の10件のみ処理（全データを読まない）
  results = File.foreach("sample_data/data.csv")
    .lazy
    .map { |line| line.strip.split(',') }
    .select { |fields| fields.size >= 3 && fields[2].to_i > 100 }
    .take(10)
    .to_a

  puts "  条件に合う最初の10件を取得: #{results.size}件"
end

# 応用2: メモリ効率的な集計
puts "\nメモリ効率的な統計集計:"
if File.exist?("sample_data/access_log.txt")
  stats = {
    total: 0,
    by_status: Hash.new(0),
    by_method: Hash.new(0),
    total_bytes: 0
  }

  File.foreach("sample_data/access_log.txt") do |line|
    stats[:total] += 1

    # HTTPステータス
    if status = line[/" (\d{3}) /, 1]
      stats[:by_status][status] += 1
    end

    # HTTPメソッド
    if method = line[/"(GET|POST|PUT|DELETE)/, 1]
      stats[:by_method][method] += 1
    end

    # バイト数
    if bytes = line[/ (\d+)$/, 1]
      stats[:total_bytes] += bytes.to_i
    end
  end

  puts "  総リクエスト数: #{stats[:total]}"
  puts "  総転送量: #{(stats[:total_bytes] / 1024.0 / 1024).round(2)} MB"
  puts "  ステータスコード別:"
  stats[:by_status].sort.each { |status, count| puts "    #{status}: #{count}" }
end

# 応用3: バッチ処理
puts "\nバッチ処理（1000行ごと）:"
if File.exist?("sample_data/data.csv")
  batch_count = 0
  File.foreach("sample_data/data.csv")
    .each_slice(1000) do |batch|
      batch_count += 1
      # バッチ単位で処理（例: データベース挿入）
    end
  puts "  処理バッチ数: #{batch_count}"
end

# 応用4: パイプライン処理
puts "\nパイプライン処理（効率的な処理の連鎖）:"
if File.exist?("sample_data/access_log.txt")
  top_errors = File.foreach("sample_data/access_log.txt")
    .lazy
    .select { |line| line =~ /" [45]\d{2} / }  # 4xx, 5xxエラー
    .map { |line| line[/"(GET|POST) ([^"?]+)/, 2] }  # パス抽出
    .compact
    .group_by { |path| path }
    .map { |path, paths| [path, paths.size] }
    .sort_by { |path, count| -count }
    .first(5)

  puts "  エラーが多いパスTop5:"
  top_errors.each_with_index { |(path, count), i| puts "    #{i+1}. #{path}: #{count}回" }
end

puts "\n=== 実務レベル解答 ==="

# 大規模データ処理クラス
class EfficientDataProcessor
  attr_reader :stats

  def initialize(input_file, options = {})
    @input_file = input_file
    @batch_size = options[:batch_size] || 1000
    @progress_interval = options[:progress_interval] || 10000
    @stats = {
      total_lines: 0,
      processed: 0,
      errors: 0,
      skipped: 0,
      start_time: Time.now
    }
  end

  def process(&block)
    puts "\n=== 大規模データ処理開始 ==="
    puts "ファイル: #{@input_file}"
    puts "バッチサイズ: #{@batch_size}"

    return unless File.exist?(@input_file)

    time = Benchmark.measure do
      process_in_batches(&block)
    end

    report(time)
  end

  def process_streaming(filter: nil, transform: nil, output: nil)
    return unless File.exist?(@input_file)

    File.foreach(@input_file).with_index do |line, index|
      @stats[:total_lines] += 1

      begin
        # フィルタリング
        if filter
          next unless filter.call(line)
        end

        # 変換
        data = transform ? transform.call(line) : line

        # 出力
        output.call(data) if output

        @stats[:processed] += 1
        show_progress if (@stats[:total_lines] % @progress_interval) == 0
      rescue => e
        @stats[:errors] += 1
        puts "Error at line #{index}: #{e.message}"
      end
    end
  end

  private

  def process_in_batches(&block)
    File.foreach(@input_file)
      .each_slice(@batch_size)
      .with_index do |batch, batch_index|
        begin
          block.call(batch, batch_index) if block
          @stats[:processed] += batch.size
          @stats[:total_lines] += batch.size

          show_progress if (batch_index % 10) == 0
        rescue => e
          @stats[:errors] += 1
          puts "Error in batch #{batch_index}: #{e.message}"
        end
      end
  end

  def show_progress
    elapsed = Time.now - @stats[:start_time]
    rate = elapsed > 0 ? (@stats[:total_lines] / elapsed).round(0) : 0
    puts "処理中: #{@stats[:total_lines]}行 (#{rate}行/秒)"
  end

  def report(time)
    elapsed = time.real > 0 ? time.real : 0.001
    puts "\n=== 処理完了レポート ==="
    puts "総行数: #{@stats[:total_lines]}"
    puts "処理成功: #{@stats[:processed]}"
    puts "エラー: #{@stats[:errors]}"
    puts "スキップ: #{@stats[:skipped]}"
    puts "処理時間: #{elapsed.round(2)}秒"
    puts "処理速度: #{(@stats[:total_lines] / elapsed).round(0)}行/秒"
    puts "メモリ効率: ストリーミング処理により一定のメモリ使用量を維持"
  end
end

# 実行例1: バッチ処理
if File.exist?("sample_data/large_log.txt")
  puts "\n【実行例1: バッチ処理】"
  processor = EfficientDataProcessor.new("sample_data/large_log.txt", batch_size: 100)

  error_summary = Hash.new(0)
  processor.process do |batch, batch_index|
    # バッチ単位でエラーカウント
    batch.each do |line|
      if line =~ /\[(ERROR|WARN|INFO)\]/
        error_summary[$1] += 1
      end
    end
  end

  puts "\nログレベル別集計:"
  error_summary.each { |level, count| puts "  #{level}: #{count}件" }
end

# 実行例2: ストリーミング処理
if File.exist?("sample_data/access_log.txt")
  puts "\n【実行例2: ストリーミング処理】"
  processor = EfficientDataProcessor.new("sample_data/access_log.txt")

  status_codes = Hash.new(0)
  processor.process_streaming(
    filter: ->(line) { line =~ /" \d{3} / },
    transform: ->(line) { line[/" (\d{3}) /, 1] },
    output: ->(status) { status_codes[status] += 1 if status }
  )

  puts "\nHTTPステータスコード集計:"
  status_codes.sort.each { |status, count| puts "  #{status}: #{count}件" }
end

# パフォーマンス比較
puts "\n=== パフォーマンス比較 ==="

if File.exist?("sample_data/data.csv")
  puts "\n【比較1: 全読み込み vs ストリーミング】"

  # 悪い例: 全読み込み
  time1 = Benchmark.measure do
    data = File.readlines("sample_data/data.csv")
    count = data.count { |line| line.include?("test") }
  end

  # 良い例: ストリーミング
  time2 = Benchmark.measure do
    count = 0
    File.foreach("sample_data/data.csv") { |line| count += 1 if line.include?("test") }
  end

  puts "  全読み込み: #{time1.real.round(4)}秒"
  puts "  ストリーミング: #{time2.real.round(4)}秒"
  puts "  メモリ使用量: 全読み込みはファイルサイズ分、ストリーミングは一定"
end

puts "\n【比較2: 通常処理 vs 遅延評価】"

if File.exist?("sample_data/data.csv")
  # 通常処理
  time1 = Benchmark.measure do
    results = File.readlines("sample_data/data.csv")
      .map { |line| line.strip.split(',') }
      .select { |fields| fields.size >= 2 }
      .first(10)
  end

  # 遅延評価
  time2 = Benchmark.measure do
    results = File.foreach("sample_data/data.csv")
      .lazy
      .map { |line| line.strip.split(',') }
      .select { |fields| fields.size >= 2 }
      .take(10)
      .to_a
  end

  puts "  通常処理: #{time1.real.round(4)}秒"
  puts "  遅延評価: #{time2.real.round(4)}秒"
end

puts "\n🚀 ワンライナー版:"

# ストリーミング処理
puts "\nストリーミングエラーカウント:"
puts 'ruby -ne \'$count ||= 0; $count += 1 if /ERROR/; END { puts "Errors: #{$count}" }\' large.log'

# 遅延評価で最初のN件
puts "\n条件に合う最初の10件:"
puts 'ruby -ne \'BEGIN { @results = [] }; @results << $_ if /ERROR/ && @results.size < 10; END { puts @results }\' app.log'

# バッチ処理
puts "\n1000行ごとのバッチ処理:"
puts 'ruby -ne \'BEGIN { @batch = []; @count = 0 }; @batch << $_; if @batch.size == 1000; process(@batch); @batch = []; end\' data.txt'

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # メモリ効率的なログ集計
  ruby -ne 'BEGIN { $stats = Hash.new(0) }; $stats[$1] += 1 if /\\[(\\w+)\\]/; END { $stats.each { |k,v| puts "#{k}: #{v}" } }' app.log

  # 遅延評価で大量データから条件抽出
  ruby -e 'File.foreach("huge.csv").lazy.select { |l| l.include?("target") }.take(100).each { |l| puts l }' > filtered.csv

  # ストリーミングでメモリ使用量を抑制
  ruby -ne 'puts $_ if /ERROR/' large.log | ruby -ne 'BEGIN { $c = 0 }; $c += 1; END { puts "Total: #{$c}" }'

  # バッチ処理でデータベース挿入（疑似コード）
  ruby -rcsv -e 'CSV.foreach("data.csv", headers: true).each_slice(1000) { |batch| insert_to_db(batch) }'

  # 並列処理で複数ファイルを高速処理
  ls *.log | xargs -P 4 -I {} ruby -ne 'puts $_ if /ERROR/' {} > errors.log

  # メモリ効率的な重複除去
  ruby -ne 'BEGIN { $seen = {} }; puts $_ unless $seen[$_]; $seen[$_] = true' data.txt > unique.txt

  # ストリーミングJSON処理（JSONLines形式）
  ruby -rjson -ne 'data = JSON.parse($_); puts data["name"] if data["age"] > 30' data.jsonl

  # 大量ファイルの効率的な統計
  find . -name "*.log" -type f -exec ruby -ne 'BEGIN { $c = 0 }; $c += 1; END { puts "#{ARGV[0]}: #{$c}" }' {} \\;
EXAMPLES

puts "\n=== パフォーマンスTips ==="
puts <<~TIPS

  1. ストリーミング処理を使う
     - File.read → ❌ (全ファイルをメモリに読み込み)
     - File.foreach → ✅ (1行ずつ処理)

  2. 遅延評価を活用
     - .lazy を使って必要な分だけ処理
     - 早期終了で無駄な計算を回避

  3. 適切なバッチサイズ
     - 小さすぎる: オーバーヘッドが大きい
     - 大きすぎる: メモリを消費
     - 目安: 100〜10000行

  4. メモリプロファイリング
     - 処理前後のメモリ使用量を確認
     - memory_profiler gemを活用

  5. 並列処理の活用
     - CPUバウンドな処理は並列化
     - I/Oバウンドな処理は注意が必要
TIPS
