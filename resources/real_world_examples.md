# 実世界でのRubyワンライナー使用例

## 🏢 開発・運用業務での活用

### 1. ログ解析

#### アクセスログからエラーをカウント
```ruby
# Nginxアクセスログから5xxエラーの時間別集計
File.readlines("access.log").select { |line| line.match(/\s5\d\d\s/) }.map { |line| line.match(/\[([^\]]+)\]/)[1][0..13] }.group_by(&:itself).transform_values(&:size)
```

#### エラーログから特定期間のエラー抽出
```ruby
# 過去24時間のERRORレベルログ抽出
cutoff = (Time.now - 86400).strftime("%Y-%m-%d %H:%M")
File.readlines("app.log").select { |line| line.include?("ERROR") && line[0..15] >= cutoff }
```

### 2. システム監視

#### ディスク使用量チェック
```ruby
# 大きなファイルの特定（100MB以上）
Dir.glob("**/*").select { |f| File.file?(f) && File.size(f) > 100_000_000 }.sort_by { |f| -File.size(f) }.each { |f| puts "#{f}: #{(File.size(f) / 1024.0 / 1024).round(1)}MB" }
```

#### プロセス監視
```ruby
# 特定プロセスのメモリ使用量チェック
`ps aux`.lines.select { |line| line.include?("ruby") }.map { |line| line.split[5].to_i }.sum
```

### 3. データ処理・分析

#### CSVデータの集計
```ruby
# 売上CSVから部門別合計売上
require 'csv'
CSV.read("sales.csv", headers: true).group_by { |row| row["department"] }.transform_values { |rows| rows.sum { |row| row["amount"].to_i } }
```

#### ファイル整理
```ruby
# 古い画像ファイルを特定ディレクトリに移動
require 'fileutils'
Dir.glob("*.{jpg,png,gif}").select { |f| File.mtime(f) < Time.now - 30*24*3600 }.each { |f| FileUtils.mv(f, "archive/#{f}") }
```

## 🎯 プロジェクト管理での活用

### 4. コードベース分析

#### 技術的負債の特定
```ruby
# 巨大なファイル（200行以上）の特定
Dir.glob("**/*.rb").select { |f| File.readlines(f).size > 200 }.sort_by { |f| -File.readlines(f).size }.each { |f| puts "#{f}: #{File.readlines(f).size} lines" }
```

#### TODOコメントの抽出
```ruby
# TODO/FIXMEコメントの一覧
Dir.glob("**/*.rb").flat_map { |f| File.readlines(f).map.with_index { |line, i| [f, i+1, line.strip] if line.match?(/TODO|FIXME/i) }.compact }
```

### 5. デプロイ・リリース作業

#### バックアップの自動作成
```ruby
# デプロイ前バックアップ
require 'fileutils'
backup_dir = "deploy_backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
FileUtils.mkdir_p(backup_dir)
%w[config app public].each { |dir| FileUtils.cp_r(dir, backup_dir) if Dir.exist?(dir) }
```

#### 設定ファイルの検証
```ruby
# 本番環境用設定の確認
require 'yaml'
config = YAML.load_file("config/production.yml")
missing = %w[database redis cache].select { |key| config[key].nil? }
puts missing.empty? ? "設定OK" : "設定不足: #{missing.join(', ')}"
```

## 📊 データ分析での活用

### 6. レポート生成

#### ユーザー活動の集計
```ruby
# アクセスログからユーザー別アクセス数
File.readlines("access.log").map { |line| line.split[0] }.group_by(&:itself).transform_values(&:size).sort_by { |k,v| -v }
```

#### パフォーマンス分析
```ruby
# レスポンス時間の統計
response_times = File.readlines("access.log").map { |line| line.split.last.to_f }.sort
puts "平均: #{response_times.sum / response_times.size}ms, 中央値: #{response_times[response_times.size/2]}ms"
```

### 7. メンテナンス作業

#### 一括ファイル名変更
```ruby
# スペースをアンダースコアに置換
Dir.glob("* *").each { |f| File.rename(f, f.gsub(' ', '_')) }
```

#### 重複ファイルの検出
```ruby
# ファイルサイズが同じファイルの検出
require 'digest'
Dir.glob("**/*").select { |f| File.file?(f) }.group_by { |f| File.size(f) }.select { |size, files| files.size > 1 }
```

## 🔍 トラブルシューティング

### 8. 問題調査

#### メモリリークの調査
```ruby
# 大きなファイルのプロセスを特定
`ps aux`.lines.select { |line| line.split[5].to_i > 100000 }.sort_by { |line| -line.split[5].to_i }
```

#### ネットワーク接続の確認
```ruby
# 特定ポートでリッスンしているプロセス
`netstat -tlnp`.lines.select { |line| line.include?(":3000") }
```

### 9. 自動化スクリプト

#### 定期清掃作業
```ruby
# 一時ファイルの削除（7日以上古い）
Dir.glob("/tmp/*").select { |f| File.mtime(f) < Time.now - 7*24*3600 }.each { |f| File.delete(f) rescue nil }
```

#### 環境チェック
```ruby
# 必要なgemのインストール確認
required_gems = %w[rails redis sidekiq]
missing = required_gems.select { |gem| `gem list #{gem}`.empty? }
puts missing.empty? ? "環境OK" : "未インストール: #{missing.join(', ')}"
```

## 💡 効率化のコツ

### 10. ワンライナーからスクリプトへ

複雑になったワンライナーは段階的にスクリプト化：

```ruby
# ワンライナー
Dir.glob("**/*.rb").select { |f| File.readlines(f).size > 100 }.sort_by { |f| -File.readlines(f).size }

# スクリプト化
files = Dir.glob("**/*.rb")
large_files = files.select { |f| File.readlines(f).size > 100 }
sorted_files = large_files.sort_by { |f| -File.readlines(f).size }
sorted_files.each { |f| puts "#{f}: #{File.readlines(f).size} lines" }
```

### エイリアス活用

よく使うワンライナーはシェルエイリアスに：

```bash
# .bashrc や .zshrc に追加
alias rbfiles='ruby -e "puts Dir.glob(\"**/*.rb\").size"'
alias logsize='ruby -e "puts File.size(\"log/production.log\") / 1024 / 1024"'
```

## 🎪 応用テクニック

### 11. 複雑なデータ変換

#### JSONデータの変換
```ruby
# APIレスポンスの変換
require 'json'
JSON.parse(File.read("api_response.json")).map { |item| { id: item["id"], name: item["attributes"]["name"] } }
```

#### 設定ファイルのマージ
```ruby
# 複数設定ファイルのマージ
require 'yaml'
Dir.glob("config/*.yml").map { |f| YAML.load_file(f) }.reduce(&:merge)
```

これらの例は実際の開発・運用現場で頻繁に使われるパターンです。
ワンライナーで素早く情報を取得し、必要に応じてスクリプト化することで、
日常業務の効率化を図ることができます。