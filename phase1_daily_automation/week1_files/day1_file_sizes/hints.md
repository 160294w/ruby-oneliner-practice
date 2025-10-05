# Day 1: ヒントとステップガイド

## 段階的に考えてみよう

### Step 1: ファイル一覧を取得
```ruby
# まずは.txtファイルを見つける
Dir.glob("*.txt")
# => ["sample1.txt", "sample2.txt", "sample3.txt"]
```

### Step 2: ファイルサイズを取得
```ruby
# 1つのファイルのサイズを確認
File.size("sample1.txt")
# => 52
```

### Step 3: 組み合わせて表示
```ruby
# each で繰り返して表示
Dir.glob("*.txt").each { |file| puts "#{file}: #{File.size(file)} bytes" }
```

## よく使うパターン

### パターン1: `each`でシンプルに
```ruby
Dir.glob("*.txt").each { |f| puts "#{f}: #{File.size(f)} bytes" }
```

### パターン2: `map`で変換してから表示
```ruby
puts Dir.glob("*.txt").map { |f| "#{f}: #{File.size(f)} bytes" }
```

## よくある間違い

### 間違い1: パスの問題
```ruby
# ❌ ファイルが見つからない
Dir.glob("*.txt").each { |f| puts File.size(f) }
# sample_dataフォルダ内のファイルの場合、パスが必要

# ✅ 正しいパス指定
Dir.glob("sample_data/*.txt").each { |f| puts File.size(f) }
```

### 間違い2: ファイル名表示の問題
```ruby
# ❌ フルパスが表示される
puts "#{file}: #{File.size(file)} bytes"
# => "sample_data/sample1.txt: 52 bytes"

# ✅ ファイル名のみ表示
puts "#{File.basename(file)}: #{File.size(file)} bytes"
# => "sample1.txt: 52 bytes"
```

## 応用のヒント

### ソート
```ruby
# サイズで降順ソート
.sort_by { |f| -File.size(f) }

# サイズで昇順ソート
.sort_by { |f| File.size(f) }
```

### 単位変換
```ruby
size >= 1024 ? "#{(size/1024.0).round(1)} KB" : "#{size} bytes"
```

### 合計計算
```ruby
total = Dir.glob("*.txt").sum { |f| File.size(f) }
```