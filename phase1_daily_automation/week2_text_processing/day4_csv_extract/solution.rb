# Day 4: CSVから特定列抽出 - 解答例

require 'csv'

puts "=== 基本レベル解答 ==="
# 基本: CSVの全データ表示（名前と金額のみ）
puts "売上データ一覧:"
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  puts "#{row['name']}: #{row['amount']}円"
end

puts "\n=== 応用レベル解答 ==="

# 応用1: 特定部門のフィルタリング（営業部のみ）
puts "営業部の売上:"
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  if row['department'] == '営業部'
    puts "#{row['date']} - #{row['name']}: #{row['product']} (#{row['amount']}円)"
  end
end

# 応用2: 金額フィルタリング（50,000円以上）
puts "\n高額売上（50,000円以上）:"
sales = CSV.read("sample_data/sales.csv", headers: true)
high_sales = sales.select { |row| row['amount'].to_i >= 50000 }
high_sales.each { |row| puts "#{row['name']}: #{row['product']} - #{row['amount']}円" }

# 応用3: 部門別売上集計
puts "\n部門別売上合計:"
dept_totals = sales.group_by { |row| row['department'] }
                   .transform_values { |rows| rows.sum { |r| r['amount'].to_i } }
dept_totals.each { |dept, total| puts "#{dept}: #{total.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}円" }

# 応用4: 地域別売上集計
puts "\n地域別売上合計:"
region_totals = sales.group_by { |row| row['region'] }
                     .transform_values { |rows| rows.sum { |r| r['amount'].to_i } }
region_totals.sort_by { |_, total| -total }.each do |region, total|
  puts "#{region}: #{total.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}円"
end

puts "\n=== 実務レベル解答 ==="

# 実務1: トップ5商品の特定
puts "売上トップ5:"
product_sales = sales.group_by { |row| row['product'] }
                     .transform_values { |rows| rows.sum { |r| r['amount'].to_i } }
product_sales.sort_by { |_, total| -total }.first(5).each_with_index do |(product, total), i|
  puts "#{i+1}. #{product}: #{total.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}円"
end

# 実務2: 営業担当者ランキング
puts "\n営業担当者別売上ランキング:"
salesperson_sales = sales.select { |row| row['department'] == '営業部' }
                         .group_by { |row| row['name'] }
                         .transform_values { |rows| rows.sum { |r| r['amount'].to_i } }
salesperson_sales.sort_by { |_, total| -total }.each_with_index do |(name, total), i|
  puts "#{i+1}. #{name}: #{total.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}円"
end

# 実務3: 月別売上推移
puts "\n月別売上推移:"
monthly_sales = sales.group_by { |row| row['date'][0..6] } # YYYY-MM
                     .transform_values { |rows| rows.sum { |r| r['amount'].to_i } }
monthly_sales.sort.each do |month, total|
  puts "#{month}: #{total.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}円"
end

# 実務4: CSV出力（営業部のみ）
puts "\n営業部データをCSV出力:"
CSV.open("sales_department_only.csv", "w") do |csv|
  csv << ["日付", "担当者", "商品", "金額", "地域"]
  sales.select { |row| row['department'] == '営業部' }.each do |row|
    csv << [row['date'], row['name'], row['product'], row['amount'], row['region']]
  end
end
puts "✅ sales_department_only.csv を生成しました"

puts "\n🚀 ワンライナー版:"

# 超短縮版コレクション
puts "\n営業部合計: " + CSV.read("sample_data/sales.csv", headers: true).select { |r| r['department'] == '営業部' }.sum { |r| r['amount'].to_i }.to_s + "円"

puts "トップ商品: " + CSV.read("sample_data/sales.csv", headers: true).group_by { |r| r['product'] }.transform_values { |rows| rows.sum { |r| r['amount'].to_i } }.max_by { |_, v| v }[0]

puts "高額売上件数: " + CSV.read("sample_data/sales.csv", headers: true).count { |r| r['amount'].to_i >= 80000 }.to_s + "件"

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # 営業部のみ抽出してCSV出力
  ruby -rcsv -e 'CSV.open("output.csv","w"){|o| CSV.foreach("sales.csv",headers:true){|r| o << r if r["department"]=="営業部"}}'

  # 部門別集計をJSON出力
  ruby -rcsv -rjson -e 'puts CSV.read("sales.csv",headers:true).group_by{|r|r["department"]}.transform_values{|rows|rows.sum{|r|r["amount"].to_i}}.to_json'

  # 月別売上をグラフ用データで出力
  ruby -rcsv -e 'CSV.read("sales.csv",headers:true).group_by{|r|r["date"][0..6]}.transform_values{|rows|rows.sum{|r|r["amount"].to_i}}.sort.each{|m,t| puts "#{m},#{t}"}'
EXAMPLES