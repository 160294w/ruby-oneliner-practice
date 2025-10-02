<div align="center">

# ⚡ Day 12: パフォーマンス最適化

[![難易度](https://img.shields.io/badge/難易度-🔴%20上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-50分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: 大量データ（数GB〜数十GB）の処理で、メモリ不足やパフォーマンス問題が発生している。

**問題**: 全データをメモリに読み込むと OOM エラー。処理に数時間かかる。効率的な方法がわからない。

**解決**: ストリーミング処理、遅延評価、並列処理でメモリ効率と速度を劇的改善！

## 📝 課題

大量データの効率的処理、メモリ最適化、ストリーミング処理をワンライナーで実現してください。

### 🎯 期待する処理例
```bash
# メモリ効率的な大量ログ処理
100GB access.log → 統計情報（メモリ使用量 < 100MB）

# ストリーミング処理
リアルタイムログ監視 → 即座に異常検知

# 並列処理による高速化
複数ファイルの並列処理 → 処理時間を1/4に短縮

# 遅延評価による効率化
必要なデータのみ処理 → 不要な計算を回避
```

## 💡 学習ポイント

| テクニック | 用途 | 重要度 |
|-----------|------|--------|
| `File.foreach` | ストリーミング読み込み | ⭐⭐⭐⭐⭐ |
| `Enumerator::Lazy` | 遅延評価 | ⭐⭐⭐⭐ |
| メモリプロファイリング | メモリ使用量監視 | ⭐⭐⭐⭐ |
| 並列処理 | 処理速度向上 | ⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
ストリーミング処理の基本から始めましょう：

```ruby
# ヒント: この構造を完成させてください
# メモリを消費しない行単位処理
File.foreach("large_file.log") do |line|
  # 各行を処理（全ファイルをメモリに載せない）
  puts line if line.include?("ERROR")
end
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `File.read` は全ファイルをメモリに読み込む（NG）
- `File.foreach` は1行ずつ処理（OK）
- `File.readlines` も全行をメモリに載せる（NG）
- ストリーミング処理でメモリ使用量を一定に保つ

</details>

### 🟡 応用レベル

<details>
<summary><strong>1. 遅延評価による効率化</strong></summary>

```ruby
# 大量データから条件に合う最初の100件のみ処理
results = File.foreach("huge_file.csv")
  .lazy
  .map { |line| line.split(',') }
  .select { |fields| fields[3].to_i > 1000 }
  .take(100)
  .to_a

puts "処理件数: #{results.size}"
```

**学習ポイント**:
- `lazy` で遅延評価を有効化
- 必要な分だけ処理して早期終了
- 無駄な計算を回避してパフォーマンス向上

</details>

<details>
<summary><strong>2. メモリ効率的な集計処理</strong></summary>

```ruby
# 大量ログの統計情報をメモリ効率的に計算
stats = { total: 0, errors: 0, by_hour: Hash.new(0) }

File.foreach("access.log") do |line|
  stats[:total] += 1
  stats[:errors] += 1 if line =~ /ERROR/

  if hour = line[/\[.*?:(\d{2}):/, 1]
    stats[:by_hour][hour] += 1
  end
end

puts "総アクセス数: #{stats[:total]}"
puts "エラー数: #{stats[:errors]}"
puts "時間帯別アクセス:"
stats[:by_hour].sort.each { |h, count| puts "  #{h}時: #{count}" }
```

**学習ポイント**:
- インクリメンタル集計でメモリ使用量を最小化
- 必要な統計情報のみを保持

</details>

<details>
<summary><strong>3. バッチ処理による効率化</strong></summary>

```ruby
# 1000行ずつバッチ処理
File.foreach("large_data.csv")
  .each_slice(1000) do |batch|
    # バッチ単位で処理（データベース挿入など）
    process_batch(batch)
    puts "#{batch.size}件処理完了"
  end
```

**学習ポイント**:
- 適切なバッチサイズで効率化
- トランザクション処理との組み合わせ

</details>

<details>
<summary><strong>4. パイプライン処理</strong></summary>

```ruby
# 複数の処理をパイプラインで効率的に実行
File.foreach("data.log")
  .lazy
  .map { |line| parse_log_line(line) }
  .select { |log| log[:status] >= 400 }
  .group_by { |log| log[:path] }
  .map { |path, logs| [path, logs.size] }
  .sort_by { |path, count| -count }
  .first(10)
  .each { |path, count| puts "#{path}: #{count}" }
```

**学習ポイント**:
- 処理の連鎖を効率的に実行
- 各ステージで必要なデータのみ渡す

</details>

### 🔴 実務レベル

<details>
<summary><strong>大規模データ処理システム</strong></summary>

メモリ効率、処理速度、エラーハンドリングを考慮した本格的なデータ処理システムを実装。

```ruby
require 'benchmark'

class EfficientDataProcessor
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
    puts "=== 大規模データ処理開始 ==="
    puts "ファイル: #{@input_file}"
    puts "バッチサイズ: #{@batch_size}"

    time = Benchmark.measure do
      process_in_batches(&block)
    end

    report(time)
  end

  def process_streaming(filter: nil, transform: nil, output: nil)
    File.foreach(@input_file).lazy.each_with_index do |line, index|
      @stats[:total_lines] += 1

      begin
        # フィルタリング
        next if filter && !filter.call(line)

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
    rate = @stats[:total_lines] / elapsed
    puts "処理中: #{@stats[:total_lines]}行 (#{rate.round(0)}行/秒)"
  end

  def report(time)
    puts "\n=== 処理完了レポート ==="
    puts "総行数: #{@stats[:total_lines]}"
    puts "処理成功: #{@stats[:processed]}"
    puts "エラー: #{@stats[:errors]}"
    puts "スキップ: #{@stats[:skipped]}"
    puts "処理時間: #{time.real.round(2)}秒"
    puts "処理速度: #{(@stats[:total_lines] / time.real).round(0)}行/秒"
  end
end

# 使用例1: バッチ処理
processor = EfficientDataProcessor.new("large_file.log", batch_size: 1000)
processor.process do |batch, batch_index|
  # バッチ単位の処理
  errors = batch.count { |line| line.include?("ERROR") }
  puts "Batch #{batch_index}: #{errors}件のエラー"
end

# 使用例2: ストリーミング処理
processor = EfficientDataProcessor.new("large_file.log")
error_count = 0

processor.process_streaming(
  filter: ->(line) { line.include?("ERROR") },
  transform: ->(line) { line.strip },
  output: ->(data) { error_count += 1 }
)

puts "総エラー数: #{error_count}"
```

</details>

## 📊 実際の業務での使用例

- 📊 **大規模ログ分析** - TB級のログファイルを効率的に処理
- 🔄 **ETL処理** - 大量データの抽出・変換・ロード
- 📈 **リアルタイム監視** - ストリーミングデータの即座な分析
- 💾 **データマイグレーション** - メモリ効率的な大量データ移行
- 🎯 **バッチ処理最適化** - 夜間バッチの高速化

## 🎓 次のステップ

- ✅ Phase 2 完了 → [Phase 3: システム管理](../../../phase3_system_management/README.md)
- 🔗 関連する実用例 → [実世界での使用例](../../../resources/real_world_examples.md#パフォーマンス最適化)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
