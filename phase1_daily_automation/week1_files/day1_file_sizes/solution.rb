# Day 1: ファイルサイズ一覧表示 - 解答例

puts "=== 基本レベル解答 ==="
# 基本: .txtファイルのサイズ一覧
Dir.glob("sample_data/*.txt").each { |file| puts "#{File.basename(file)}: #{File.size(file)} bytes" }

puts "\n=== 応用レベル解答 ==="

# 応用1: ファイルサイズでソート（大きいファイルから）
puts "📊 サイズ順（大→小）:"
Dir.glob("sample_data/*.txt").sort_by { |f| -File.size(f) }.each do |file|
  puts "#{File.basename(file)}: #{File.size(file)} bytes"
end

# 応用2: 単位変換（1KB以上はKB表示）
puts "\n📏 単位変換表示:"
Dir.glob("sample_data/*.txt").each do |file|
  size = File.size(file)
  display_size = size >= 1024 ? "#{(size/1024.0).round(1)} KB" : "#{size} bytes"
  puts "#{File.basename(file)}: #{display_size}"
end

# 応用3: 合計サイズも表示
puts "\n📈 合計サイズ付き:"
files = Dir.glob("sample_data/*.txt")
total_size = files.sum { |f| File.size(f) }
files.each { |file| puts "#{File.basename(file)}: #{File.size(file)} bytes" }
puts "---"
puts "合計: #{total_size} bytes (#{(total_size/1024.0).round(1)} KB)"

# 🚀 超上級: 1行で全部やる
puts "\n🚀 ワンライナー版（合計付き）:"
puts Dir.glob("sample_data/*.txt").tap { |files| files.each { |f| puts "#{File.basename(f)}: #{File.size(f)} bytes" }; puts "合計: #{files.sum { |f| File.size(f) }} bytes" }