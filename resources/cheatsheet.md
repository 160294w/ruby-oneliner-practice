# Rubyワンライナー チートシート

## 🎯 基本パターン

### ファイル・ディレクトリ操作

```ruby
# ファイル一覧取得
Dir.glob("*.txt")                    # カレントディレクトリの.txtファイル
Dir["**/*.rb"]                       # 再帰的に.rbファイル検索
Dir.entries(".")                     # 全ファイル・ディレクトリ（.と..含む）

# ファイル情報
File.size("file.txt")                # ファイルサイズ（バイト）
File.basename("/path/to/file.txt")   # ファイル名のみ
File.dirname("/path/to/file.txt")    # ディレクトリ部分
File.exist?("file.txt")              # ファイル存在確認

# ファイル読み書き
File.read("file.txt")                # ファイル全体を文字列で読み込み
File.readlines("file.txt")           # ファイルを行の配列で読み込み
File.write("file.txt", "content")    # ファイルに書き込み
```

### 配列操作

```ruby
# 基本操作
[1,2,3,4,5].map(&:to_s)             # 各要素を文字列に変換
[1,2,3,4,5].select(&:even?)         # 偶数のみ選択
[1,2,3,4,5].reject(&:odd?)          # 奇数を除外
[1,2,3,4,5].find { |n| n > 3 }      # 条件に合う最初の要素

# 集計・統計
[1,2,3,4,5].sum                     # 合計
[1,2,3,4,5].min                     # 最小値
[1,2,3,4,5].max                     # 最大値
[1,2,3,4,5].size                    # 要素数

# ソート
[3,1,4,1,5].sort                    # 昇順ソート
[3,1,4,1,5].sort.reverse            # 降順ソート
files.sort_by { |f| File.size(f) }  # ファイルサイズでソート
```

### 文字列操作

```ruby
# 基本変換
"hello".upcase                       # 大文字変換
"HELLO".downcase                     # 小文字変換
"hello world".capitalize             # 最初の文字のみ大文字
" hello ".strip                      # 前後の空白削除

# 分割・結合
"a,b,c".split(",")                   # カンマで分割
["a","b","c"].join("-")              # ハイフンで結合
"hello world".split                  # 空白で分割（デフォルト）

# パターンマッチ
"hello@example.com".include?("@")    # 部分文字列の存在確認
"hello123".match?(/\d+/)            # 正規表現マッチ
"hello world".gsub("world", "Ruby")  # 文字列置換
```

### 日時操作

```ruby
# 現在日時
Time.now                             # 現在時刻
Date.today                           # 今日の日付

# フォーマット
Time.now.strftime("%Y%m%d")          # 20241229
Time.now.strftime("%H%M%S")          # 143025
Time.now.strftime("%Y-%m-%d %H:%M")  # 2024-12-29 14:30

# 計算
Date.today - 7                       # 7日前
Time.now + 3600                      # 1時間後
```

## ⚡ よく使う組み合わせパターン

### ファイルサイズ一覧（ソート付き）

```ruby
Dir.glob("*.txt").sort_by { |f| -File.size(f) }.each { |f| puts "#{f}: #{File.size(f)} bytes" }
```

### 行数カウント（統計付き）

```ruby
files = Dir["**/*.rb"]; puts files.map { |f| File.readlines(f).size }.then { |counts| "合計: #{counts.sum}, 平均: #{counts.sum/counts.size.to_f}" }
```

### 日付付きバックアップディレクトリ作成

```ruby
require 'fileutils'; FileUtils.mkdir_p("backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}")
```

### CSVデータ抽出

```ruby
require 'csv'; CSV.read("data.csv").select { |row| row[2].to_i > 1000 }.each { |row| puts row.join(", ") }
```

## 🔧 便利なイディオム

### 条件付き実行

```ruby
# ファイルが存在する場合のみ実行
File.exist?("config.txt") && puts File.read("config.txt")

# ディレクトリが存在しない場合は作成
Dir.mkdir("backup") unless Dir.exist?("backup")
```

### 一時的なディレクトリ変更

```ruby
Dir.chdir("some_dir") { puts Dir.glob("*") }  # some_dirで実行後、元のディレクトリに戻る
```

### エラーハンドリング付き

```ruby
begin; File.read("file.txt"); rescue => e; puts "Error: #{e.message}"; end
```

### 複数の処理を1行で

```ruby
# tapを使った複数処理
Dir.glob("*.txt").tap { |files| puts "Found #{files.size} files" }.each { |f| puts File.size(f) }
```

## 📊 パフォーマンス最適化

### ファイル読み込み

```ruby
# 大きなファイルは lazy を使用
File.foreach("large.txt").lazy.select { |line| line.include?("ERROR") }.first(10)

# 行数のみ必要な場合
`wc -l file.txt`.to_i  # システムコマンド利用（高速）
```

### メモリ効率

```ruby
# 大量ファイル処理はeach使用（mapは全てメモリに展開）
Dir.glob("**/*.txt").each { |f| process_file(f) }  # Good
Dir.glob("**/*.txt").map { |f| process_file(f) }   # Memory intensive
```

## 🚫 よくある間違い

### パス指定ミス

```ruby
# ❌ 相対パスの混乱
Dir.glob("*.txt").each { |f| File.size(f) }  # sample_data内ファイルは見つからない

# ✅ 正しいパス指定
Dir.glob("sample_data/*.txt").each { |f| File.size(f) }
```

### ファイル名表示

```ruby
# ❌ フルパス表示
puts "#{file}: #{File.size(file)} bytes"

# ✅ ファイル名のみ表示
puts "#{File.basename(file)}: #{File.size(file)} bytes"
```

### 型変換忘れ

```ruby
# ❌ 文字列のまま計算
total = csv_data.map { |row| row[3] }.sum  # 文字列結合になる

# ✅ 数値に変換
total = csv_data.map { |row| row[3].to_i }.sum
```

## 🎭 デバッグ技巧

### 中間結果確認

```ruby
# pでデバッグ出力
Dir.glob("*.txt").map { |f| p f; File.size(f) }

# tap で途中結果確認
Dir.glob("*.txt").tap { |files| p "Found: #{files}" }.map { |f| File.size(f) }
```

### 例外情報の詳細出力

```ruby
begin
  # 処理
rescue => e
  puts "Error: #{e.class} - #{e.message}"
  puts e.backtrace.first(3)  # スタックトレースの最初の3行
end
```