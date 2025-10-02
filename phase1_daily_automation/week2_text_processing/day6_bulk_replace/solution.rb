# Day 6: 複数ファイルの文字列一括置換 - 解答例

require 'fileutils'

puts "=== 基本レベル解答 ==="
# 基本: 1つのファイルの文字列置換
puts "単一ファイル置換:"
content = File.read("sample_data/config.txt")
original_count = content.scan("localhost").size
new_content = content.gsub("localhost", "production.example.com")
File.write("sample_data/config_replaced.txt", new_content)
puts "✅ config.txt を config_replaced.txt に出力 (#{original_count}箇所置換)"

puts "\n=== 応用レベル解答 ==="

# 応用1: 複数ファイル一括置換
puts "複数ファイル一括置換:"
Dir.glob("sample_data/*.txt").each do |file|
  next if file.include?("_replaced")  # 既に置換済みファイルはスキップ

  content = File.read(file)
  count = content.scan("localhost").size

  if count > 0
    new_content = content.gsub("localhost", "production-server.example.com")
    File.write(file, new_content)
    puts "✅ #{File.basename(file)}: #{count}箇所置換"
  else
    puts "⏭️  #{File.basename(file)}: 置換対象なし"
  end
end

# 元の状態に戻す（デモ用）
Dir.glob("sample_data/*.txt").each do |file|
  content = File.read(file)
  content.gsub!("production-server.example.com", "localhost")
  File.write(file, content)
end

# 応用2: バックアップ付き置換
puts "\nバックアップ付き置換:"
Dir.glob("sample_data/*.txt").each do |file|
  next if file.end_with?(".bak") || file.include?("_replaced")

  # バックアップ作成
  backup_file = "#{file}.bak"
  FileUtils.cp(file, backup_file)

  content = File.read(file)
  changes = []

  # 複数パターン置換
  patterns = {
    "localhost" => "production.example.com",
    "development" => "production",
    "DEBUG" => "INFO"
  }

  patterns.each do |old, new|
    count = content.scan(old).size
    content.gsub!(old, new)
    changes << "#{old}→#{new}(#{count})" if count > 0
  end

  File.write(file, content)
  puts "✅ #{File.basename(file)}: #{changes.join(', ')} [backup: #{File.basename(backup_file)}]"
end

# 応用3: 正規表現パターン置換
puts "\n正規表現パターン置換:"
Dir.glob("sample_data/*.txt").each do |file|
  next if file.end_with?(".bak") || file.include?("_replaced")

  content = File.read(file)

  # http:// を https:// に置換
  http_count = content.scan(/http:\/\//).size
  content.gsub!(/http:\/\//, "https://")

  # localhost:ポート番号 を production.example.com:ポート番号 に置換
  port_patterns = content.scan(/localhost:\d+/)
  content.gsub!(/localhost:(\d+)/, 'production.example.com:\\1')

  puts "#{File.basename(file)}: http→https(#{http_count}), localhost:port(#{port_patterns.size})"
end

puts "\n=== 実務レベル解答 ==="

# 実務1: プレビュー機能
puts "変更プレビュー:"
replacements = {
  "localhost" => "prod-server.example.com",
  "http://" => "https://",
  "development" => "production"
}

preview_changes = {}
Dir.glob("sample_data/*.txt").each do |file|
  next if file.end_with?(".bak") || file.include?("_replaced")

  content = File.read(file)
  file_changes = []

  replacements.each do |old, new|
    matches = content.scan(old)
    file_changes << {old: old, new: new, count: matches.size} if matches.any?
  end

  preview_changes[file] = file_changes if file_changes.any?
end

preview_changes.each do |file, changes|
  puts "\n📄 #{File.basename(file)}:"
  changes.each do |change|
    puts "  #{change[:old]} → #{change[:new]} (#{change[:count]}箇所)"
  end
end

# 実務2: 確認プロンプト付き実行（シミュレート）
puts "\n確認プロンプト付き実行:"
puts "以下の変更を適用しますか？ (yes/no)"
puts "（このデモでは自動的にyesとして処理します）"

confirmation = "yes"  # 実際は STDIN.gets.chomp

if confirmation.downcase == "yes"
  applied_count = 0
  preview_changes.each do |file, changes|
    content = File.read(file)
    FileUtils.cp(file, "#{file}.bak") unless File.exist?("#{file}.bak")

    changes.each do |change|
      content.gsub!(change[:old], change[:new])
    end

    File.write(file, content)
    applied_count += 1
  end
  puts "✅ #{applied_count}ファイルを更新しました"
else
  puts "❌ 変更をキャンセルしました"
end

# 実務3: ロールバック機能
puts "\nロールバック機能:"
backup_files = Dir.glob("sample_data/*.bak")

if backup_files.any?
  puts "バックアップファイルが見つかりました:"
  backup_files.each { |bak| puts "  #{File.basename(bak)}" }

  puts "\nロールバックを実行しますか？ (yes/no)"
  puts "（このデモでは自動的にyesとして処理します）"

  rollback = "yes"  # 実際は STDIN.gets.chomp

  if rollback.downcase == "yes"
    backup_files.each do |bak|
      original = bak.gsub(".bak", "")
      FileUtils.cp(bak, original)
      puts "🔙 #{File.basename(original)} を復元しました"
    end
    puts "✅ ロールバック完了"
  end
end

# バックアップファイルのクリーンアップ
Dir.glob("sample_data/*.bak").each { |bak| File.delete(bak) }

puts "\n🚀 ワンライナー版:"

# 超短縮版コレクション
puts "\n単純置換:"
puts 'Dir.glob("*.txt").each { |f| c=File.read(f); File.write(f, c.gsub("localhost","prod.com")) }'

puts "\nバックアップ付き:"
puts 'require "fileutils"; Dir["*.txt"].each { |f| FileUtils.cp(f,"#{f}.bak"); File.write(f,File.read(f).gsub("old","new")) }'

puts "\n正規表現置換:"
puts 'Dir["*.txt"].each { |f| File.write(f, File.read(f).gsub(/http:\/\/(\w+)/, "https://\\1")) }'

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # 開発→本番環境への一括置換
  ruby -i.bak -pe 'gsub(/localhost/, "production.example.com")' config/*.txt

  # 複数パターン同時置換
  ruby -e 'Dir["*.txt"].each{|f| c=File.read(f); c.gsub!("dev","prod"); c.gsub!("http:","https:"); File.write(f,c)}'

  # プレビューのみ（変更しない）
  ruby -e 'Dir["*.txt"].each{|f| puts "#{f}: #{File.read(f).scan("localhost").size} matches"}'

  # 特定ディレクトリ配下を再帰的に置換
  ruby -e 'Dir["**/*.txt"].each{|f| File.write(f, File.read(f).gsub("old_api", "new_api"))}'

  # 環境変数を使った動的置換
  ruby -e 'target=ENV["TARGET_ENV"]||"prod"; Dir["*.txt"].each{|f| File.write(f, File.read(f).gsub("localhost","#{target}.example.com"))}'
EXAMPLES