<div align="center">

# 📊 Day 10: ログ分析マスター

[![難易度](https://img.shields.io/badge/難易度-🟠%20中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-40分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: Webサーバー（Apache/Nginx）のアクセスログから、トラフィック分析、異常検知、パフォーマンス監視を行いたい。

**問題**: 巨大なログファイルをGUIツールで開くのは困難。専用の分析ツールは高価で導入が大変。

**解決**: Rubyワンライナーで高速ログ分析！リアルタイム監視も可能！

## 📝 課題

Apache/Nginxアクセスログから統計情報の抽出、異常検出、トラフィック分析をワンライナーで実現してください。

### 🎯 期待する処理例
```bash
# アクセス統計
access.log → リクエスト数、ユニークIP数、人気URL

# エラー分析
access.log → 404エラー、500エラーの集計

# トラフィックパターン
時間帯別アクセス数、ピーク時間の特定

# 異常検出
急激なアクセス増加、特定IPからの大量アクセス
```

## 💡 学習ポイント

| テクニック | 用途 | 重要度 |
|-----------|------|--------|
| ログパース（正規表現） | 構造化データ抽出 | ⭐⭐⭐⭐⭐ |
| `group_by/tally` | 統計集計 | ⭐⭐⭐⭐⭐ |
| `Time.parse` | 時系列分析 | ⭐⭐⭐⭐ |
| 閾値判定 | 異常検出 | ⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
アクセスログの基本解析から始めましょう：

```ruby
# ヒント: この構造を完成させてください
File.readlines("sample_data/access.log").each do |line|
  if line =~ /^(\S+) .* "(\w+) ([^"]+)" (\d+)/
    ip, method, path, status = $1, $2, $3, $4.to_i
    # 統計情報を集計
  end
end
```

<details>
<summary>💡 基本レベルのヒント</summary>

- Apache/Nginxログの標準フォーマット: `IP - - [時刻] "METHOD PATH" STATUS SIZE`
- 正規表現でログをパース
- ハッシュで統計情報を集計

</details>

### 🟡 応用レベル

<details>
<summary><strong>1. ステータスコード別集計</strong></summary>

```ruby
# HTTPステータスコード別にリクエスト数を集計
logs = File.readlines("sample_data/access.log")
status_counts = logs.map { |line| line[/"(\w+) [^"]+" (\d+)/, 2] }
                   .compact
                   .group_by(&:itself)
                   .transform_values(&:size)
                   .sort_by { |k, v| -v }

status_counts.each { |status, count| puts "#{status}: #{count}件" }
```

**学習ポイント**: パターン抽出、集計、ソート

</details>

<details>
<summary><strong>2. 時間帯別トラフィック分析</strong></summary>

```ruby
require 'time'

# 時間帯別アクセス数
hourly_traffic = File.readlines("sample_data/access.log")
  .map { |line| line[/\[(.*?)\]/, 1] }
  .compact
  .map { |time_str| Time.parse(time_str.split[0].tr('/', '-')).hour }
  .tally
  .sort

puts "時間帯別アクセス:"
hourly_traffic.each { |hour, count| puts "#{hour}時台: #{count}件" }
```

**学習ポイント**: 時刻パース、時系列分析

</details>

<details>
<summary><strong>3. 人気URLランキング</strong></summary>

```ruby
# アクセス数上位10件のURL
top_urls = File.readlines("sample_data/access.log")
  .map { |line| line[/"(?:GET|POST) ([^"?]+)/, 1] }
  .compact
  .tally
  .sort_by { |url, count| -count }
  .first(10)

puts "人気URLトップ10:"
top_urls.each_with_index do |(url, count), i|
  puts "#{i+1}. #{url} (#{count}アクセス)"
end
```

**学習ポイント**: URL抽出、ランキング生成

</details>

<details>
<summary><strong>4. IPアドレス分析</strong></summary>

```ruby
# ユニークIP数と最多アクセスIP
ips = File.readlines("sample_data/access.log")
  .map { |line| line[/^(\S+)/, 1] }
  .compact

puts "ユニークIP数: #{ips.uniq.size}"
puts "総アクセス数: #{ips.size}"

top_ip = ips.tally.max_by { |ip, count| count }
puts "最多アクセスIP: #{top_ip[0]} (#{top_ip[1]}回)"
```

**学習ポイント**: IP抽出、重複除去、最頻値検出

</details>

### 🔴 実務レベル

<details>
<summary><strong>包括的ログ分析レポート生成</strong></summary>

複数の観点からログを分析し、Markdown形式のレポートを自動生成するシステムを実装。

```ruby
require 'time'

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
          time: Time.parse($2.split[0].tr('/', '-')),
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
    puts "\n## 基本統計"
    basic_stats
    puts "\n## HTTPステータス分布"
    status_distribution
    puts "\n## 時間帯別トラフィック"
    hourly_traffic
    puts "\n## 人気URL"
    popular_urls
    puts "\n## IPアドレス分析"
    ip_analysis
    puts "\n## 異常検出"
    anomaly_detection
  end

  def basic_stats
    puts "- 総アクセス数: #{@parsed_logs.size}"
    puts "- ユニークIP数: #{@parsed_logs.map { |l| l[:ip] }.uniq.size}"
    puts "- 総転送量: #{(@parsed_logs.sum { |l| l[:size] } / 1024.0 / 1024).round(2)} MB"
  end

  def status_distribution
    @parsed_logs.map { |l| l[:status] }
      .tally
      .sort
      .each { |status, count| puts "- #{status}: #{count}件" }
  end

  def hourly_traffic
    @parsed_logs.map { |l| l[:time].hour }
      .tally
      .sort
      .each { |hour, count| puts "- #{hour}時台: #{count}件" }
  end

  def popular_urls
    @parsed_logs.map { |l| l[:path].split('?').first }
      .tally
      .sort_by { |url, count| -count }
      .first(5)
      .each_with_index { |(url, count), i| puts "#{i+1}. #{url} (#{count})" }
  end

  def ip_analysis
    ip_counts = @parsed_logs.map { |l| l[:ip] }.tally
    puts "- 最多アクセスIP: #{ip_counts.max_by { |k, v| v }.join(' - ')}"

    # 疑わしいIP（100回以上アクセス）
    suspicious = ip_counts.select { |ip, count| count > 100 }
    if suspicious.any?
      puts "- 疑わしいIP (100回以上アクセス):"
      suspicious.each { |ip, count| puts "  - #{ip}: #{count}回" }
    end
  end

  def anomaly_detection
    # エラー率の計算
    error_rate = @parsed_logs.count { |l| l[:status] >= 400 }.to_f / @parsed_logs.size * 100
    puts "- エラー率: #{error_rate.round(2)}%"

    if error_rate > 10
      puts "  ⚠️ 警告: エラー率が10%を超えています"
    end
  end
end

# 使用例
analyzer = LogAnalyzer.new("sample_data/access.log")
analyzer.report
```

</details>

## 📊 実際の業務での使用例

- 🌐 **Webサイト分析** - トラフィックパターン、人気コンテンツ特定
- 🚨 **異常検知** - DDoS攻撃、不正アクセスの早期発見
- 📈 **パフォーマンス監視** - レスポンスタイム、エラー率の追跡
- 🔍 **SEO分析** - 検索エンジンクローラーの活動監視
- 💰 **コスト最適化** - 転送量の把握、CDN効果測定

## 🎓 次のステップ

- ✅ 基本レベルクリア → [Day 11: データ移行](../day11_data_migration/problem.md)
- 🔗 関連する実用例 → [実世界での使用例](../../../resources/real_world_examples.md#ログ分析)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
