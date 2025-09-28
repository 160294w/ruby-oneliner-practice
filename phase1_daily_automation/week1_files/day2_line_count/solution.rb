# Day 2: ファイル行数カウント - 解答例

puts "=== 基本レベル解答 ==="
# 基本: .rbファイルの行数一覧
Dir.glob("sample_data/*.rb").each { |file| puts "#{File.basename(file)}: #{File.readlines(file).size} lines" }

puts "\n=== 応用レベル解答 ==="

# 応用1: 再帰的検索（サブディレクトリも含む）
puts "📁 再帰的検索:"
Dir.glob("sample_data/**/*.rb").each { |file| puts "#{file}: #{File.readlines(file).size} lines" }

# 応用2: 行数でソート（多い順）
puts "\n📊 行数順（多→少）:"
Dir.glob("sample_data/**/*.rb").sort_by { |f| -File.readlines(f).size }.each do |file|
  puts "#{File.basename(file)}: #{File.readlines(file).size} lines"
end

# 応用3: 統計情報付き
puts "\n📈 統計情報付き:"
files = Dir.glob("sample_data/**/*.rb")
line_counts = files.map { |f| File.readlines(f).size }
files.each { |file| puts "#{File.basename(file)}: #{File.readlines(file).size} lines" }
puts "---"
puts "合計行数: #{line_counts.sum} lines"
puts "平均行数: #{(line_counts.sum / line_counts.size.to_f).round(1)} lines"
puts "最大行数: #{line_counts.max} lines"
puts "最小行数: #{line_counts.min} lines"

# 応用4: 空行除外
puts "\n📝 空行除外版:"
Dir.glob("sample_data/**/*.rb").each do |file|
  non_empty_lines = File.readlines(file).reject { |line| line.strip.empty? }.size
  total_lines = File.readlines(file).size
  puts "#{File.basename(file)}: #{non_empty_lines}/#{total_lines} lines (空行除外/総行数)"
end

# 🚀 実務レベル: 複数拡張子対応 + 大きなファイル特定
puts "\n🚀 実務レベル（大きなファイル特定）:"
large_files = Dir.glob("sample_data/**/*.rb").select { |f| File.readlines(f).size >= 20 }
if large_files.any?
  large_files.each { |file| puts "⚠️  大きなファイル: #{File.basename(file)} (#{File.readlines(file).size} lines)" }
else
  puts "20行以上のファイルはありません"
end

# 🎯 ワンライナー版（統計付き）
puts "\n🎯 ワンライナー版:"
puts Dir.glob("sample_data/**/*.rb").tap { |files| files.each { |f| puts "#{File.basename(f)}: #{File.readlines(f).size} lines" }; puts "合計: #{files.sum { |f| File.readlines(f).size }} lines" }