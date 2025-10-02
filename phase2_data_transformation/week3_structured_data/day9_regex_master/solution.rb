# Day 9: 正規表現マスター - 解答例

puts "=== 基本レベル解答 ==="
# 基本: メールアドレス抽出
text = File.read("sample_data/contacts.txt")
emails = text.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)
puts "抽出されたメールアドレス:"
puts emails.uniq

puts "\n=== 応用レベル解答 ==="

# 応用1: URL抽出とドメイン別集計
puts "URL抽出とドメイン別集計:"
document = File.read("sample_data/document.txt")
urls = document.scan(%r{https?://[^\s<>"]+})
domains = urls.map { |url| url[%r{https?://([^/]+)}, 1] }
             .group_by(&:itself)
             .transform_values(&:size)
domains.each { |domain, count| puts "  #{domain}: #{count}件" }

# 応用2: 電話番号の統一フォーマット
puts "\n電話番号フォーマット統一:"
phones_raw = text.scan(/(\d{3})[-.\s]?(\d{4})[-.\s]?(\d{4})/)
phones_formatted = phones_raw.map { |parts| parts.join('-') }.uniq
puts phones_formatted

# 応用3: ログパターン解析（エラーのみ抽出）
puts "\nエラーログ分析:"
if File.exist?("sample_data/app.log")
  logs = File.readlines("sample_data/app.log")
  errors = logs.select { |line| line =~ /ERROR|FATAL/ }

  # エラータイプ別集計
  error_types = errors.map { |line| line[/\[(.*?)\]/, 1] }
                     .compact
                     .group_by(&:itself)
                     .transform_values(&:size)
  error_types.each { |type, count| puts "  [#{type}]: #{count}件" }

  # 最初の3件のエラーを表示
  puts "\n最初の3件のエラー:"
  errors.first(3).each { |e| puts "  #{e.strip}" }
end

# 応用4: IPアドレス抽出と検証
puts "\nIPアドレス抽出と検証:"
if File.exist?("sample_data/network.log")
  network_text = File.read("sample_data/network.log")
  ips = network_text.scan(/\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/)
  valid_ips = ips.select do |ip|
    ip.split('.').all? { |octet| (0..255).include?(octet.to_i) }
  end
  puts "有効なIPアドレス: #{valid_ips.uniq.join(', ')}"
end

puts "\n=== 実務レベル解答 ==="

# 実務: 包括的データ抽出システム
require 'json'

puts "包括的データ抽出システム:"
data = {
  emails: [],
  urls: {},
  phones: [],
  ips: []
}

Dir.glob("sample_data/*.txt").each do |file|
  content = File.read(file)

  # メールアドレス抽出
  data[:emails] += content.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)

  # URL抽出とドメイン別集計
  urls = content.scan(%r{https?://[^\s<>"]+})
  urls.each do |url|
    domain = url[%r{https?://([^/]+)}, 1]
    data[:urls][domain] ||= 0
    data[:urls][domain] += 1
  end

  # 電話番号抽出（統一フォーマット）
  phones = content.scan(/(\d{3})[-.\s]?(\d{4})[-.\s]?(\d{4})/)
  data[:phones] += phones.map { |parts| parts.join('-') }

  # IPアドレス抽出
  data[:ips] += content.scan(/\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/)
end

# 重複除去
data[:emails].uniq!
data[:phones].uniq!
data[:ips].uniq!

puts JSON.pretty_generate(data)

# 実務2: 名前付きキャプチャを使った構造化抽出
puts "\n名前付きキャプチャを使ったログ解析:"
log_pattern = /(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(?<level>\w+)\] (?<message>.*)/

sample_log = "2024-01-15 14:23:45 [ERROR] Database connection failed"
if match = sample_log.match(log_pattern)
  puts "  タイムスタンプ: #{match[:timestamp]}"
  puts "  レベル: #{match[:level]}"
  puts "  メッセージ: #{match[:message]}"
end

# 実務3: 複雑なパターンマッチング（クレジットカード番号のマスキング）
puts "\n機密情報のマスキング:"
sensitive_text = "クレジットカード: 1234-5678-9012-3456, マイナンバー: 123456789012"
masked = sensitive_text.gsub(/(\d{4})-(\d{4})-(\d{4})-(\d{4})/, '\1-****-****-\4')
                      .gsub(/マイナンバー: \d{12}/, 'マイナンバー: ************')
puts masked

puts "\n🚀 ワンライナー版:"

# メールアドレス抽出（重複除去）
puts "\nメール抽出: " + File.read("sample_data/contacts.txt").scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/).uniq.join(", ")

# URL抽出
puts "\nURL抽出: " + File.read("sample_data/document.txt").scan(%r{https?://[^\s<>"]+}).join(", ")

# 電話番号フォーマット統一
puts "\n電話番号統一: " + File.read("sample_data/contacts.txt").gsub(/(\d{3})[-.\s]?(\d{4})[-.\s]?(\d{4})/, '\1-\2-\3')

# エラーログカウント
if File.exist?("sample_data/app.log")
  puts "\nエラー件数: " + File.readlines("sample_data/app.log").count { |line| line =~ /ERROR|FATAL/ }.to_s
end

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # ログファイルから特定エラーパターン抽出
  ruby -ne 'puts $_ if /ERROR.*database/i' app.log

  # メールアドレス一括抽出（複数ファイル）
  ruby -e 'puts Dir["**/*.txt"].flat_map { |f| File.read(f).scan(/[\\w.+-]+@[\\w.-]+\\.\\w+/) }.uniq'

  # IPアドレスの重複チェック
  ruby -e 'ips = STDIN.read.scan(/\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b/); puts ips.group_by(&:itself).select { |k,v| v.size > 1 }' < access.log

  # URL抽出とHTTPS化提案
  ruby -ne 'puts $_.scan(/http:\\/\\/[^\\s<>"]+/).map { |u| "#{u} -> #{u.sub("http:", "https:")}" }' document.txt

  # ログからタイムスタンプとエラーメッセージのみ抽出
  ruby -ne 'if /^(\\S+ \\S+).*\\[ERROR\\] (.*)$/; puts "#{$1}: #{$2}"; end' app.log

  # 電話番号の妥当性チェック
  ruby -ne 'if /^(\\d{3})-(\\d{4})-(\\d{4})$/; puts "有効: #{$_}"; else puts "無効: #{$_}"; end' phones.txt

  # センシティブ情報の検出
  ruby -ne 'puts "#{ARGF.filename}:#{$.}: #{$_}" if /password|secret|api[_-]?key/i' **/*.{rb,yml,env}
EXAMPLES
