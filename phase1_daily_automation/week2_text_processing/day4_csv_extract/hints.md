# Day 4: ヒントとステップガイド

## 🔍 段階的に考えてみよう

### Step 1: CSVファイルの基本読み込み
```ruby
require 'csv'

# 方法1: 全データを一度に読み込み（小さいファイル向け）
data = CSV.read("sample_data/sales.csv", headers: true)

# 方法2: 1行ずつ処理（大きいファイル向け・メモリ効率良）
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  puts row
end
```

### Step 2: 特定の列にアクセス
```ruby
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  # 列名でアクセス
  puts row['name']        # 名前
  puts row['department']  # 部門
  puts row['amount']      # 金額
end
```

### Step 3: 条件でフィルタリング
```ruby
# 営業部のみ表示
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  puts row if row['department'] == '営業部'
end

# 金額で条件指定
CSV.foreach("sample_data/sales.csv", headers: true) do |row|
  puts row if row['amount'].to_i >= 50000
end
```

## 💡 よく使うパターン

### パターン1: selectでフィルタリング
```ruby
require 'csv'
sales = CSV.read("sample_data/sales.csv", headers: true)

# 営業部のみ抽出
sales_dept = sales.select { |row| row['department'] == '営業部' }
```

### パターン2: mapで列を変換
```ruby
# 名前と金額だけの配列を作成
name_amounts = sales.map { |row| [row['name'], row['amount']] }
```

### パターン3: group_byで集計
```ruby
# 部門別にグループ化
by_department = sales.group_by { |row| row['department'] }

# 部門別の合計金額
dept_totals = by_department.transform_values do |rows|
  rows.sum { |row| row['amount'].to_i }
end
```

## 🚫 よくある間違い

### 間違い1: 文字列を数値として扱う
```ruby
# ❌ 文字列のまま計算
total = row['amount'] + 1000  # "85000" + 1000 → エラー

# ✅ 数値に変換してから計算
total = row['amount'].to_i + 1000  # 86000
```

### 間違い2: ヘッダーの指定忘れ
```ruby
# ❌ ヘッダーなしで読み込み
CSV.read("sales.csv")  # row['name']が使えない

# ✅ ヘッダーを指定
CSV.read("sales.csv", headers: true)  # row['name']が使える
```

### 間違い3: メモリ効率の悪い処理
```ruby
# ❌ 大きなファイルで全読み込み
data = CSV.read("huge_file.csv", headers: true)
data.each { |row| process(row) }  # メモリを大量消費

# ✅ foreachで1行ずつ処理
CSV.foreach("huge_file.csv", headers: true) do |row|
  process(row)  # メモリ効率が良い
end
```

## 🎯 応用のヒント

### 集計処理
```ruby
# 合計
total = sales.sum { |row| row['amount'].to_i }

# 平均
average = total / sales.size.to_f

# 最大・最小
max_sale = sales.max_by { |row| row['amount'].to_i }
min_sale = sales.min_by { |row| row['amount'].to_i }
```

### 複数条件のフィルタリング
```ruby
# ANDの場合
result = sales.select do |row|
  row['department'] == '営業部' && row['amount'].to_i >= 50000
end

# ORの場合
result = sales.select do |row|
  row['department'] == '営業部' || row['region'] == '東京'
end
```

### CSV出力
```ruby
# 結果をCSVファイルに書き出し
CSV.open("output.csv", "w") do |csv|
  csv << ["名前", "金額"]  # ヘッダー
  filtered_sales.each do |row|
    csv << [row['name'], row['amount']]
  end
end
```

### 数値のフォーマット
```ruby
# カンマ区切りの表示
amount = 1234567
formatted = amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
# => "1,234,567"
```

## 🔧 デバッグのコツ

### データの確認
```ruby
# ヘッダーの確認
CSV.open("sales.csv", headers: true) do |csv|
  puts csv.headers.inspect
end

# 最初の数行だけ確認
CSV.foreach("sales.csv", headers: true).first(3).each do |row|
  puts row.inspect
end
```

### 中間結果の確認
```ruby
# tapを使って途中経過を確認
result = sales
  .select { |row| row['department'] == '営業部' }
  .tap { |data| puts "営業部: #{data.size}件" }
  .select { |row| row['amount'].to_i >= 50000 }
  .tap { |data| puts "高額: #{data.size}件" }
```