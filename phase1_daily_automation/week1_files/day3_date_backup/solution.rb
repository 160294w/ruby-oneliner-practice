# Day 3: 日付付きバックアップディレクトリ作成 - 解答例

require 'fileutils'

puts "=== 基本レベル解答 ==="
# 基本: 日付付きディレクトリ作成
backup_dir = "backup_#{Time.now.strftime('%Y%m%d')}"
Dir.mkdir(backup_dir) unless Dir.exist?(backup_dir)
puts "✅ 作成: #{backup_dir}"

puts "\n=== 応用レベル解答 ==="

# 応用1: 階層ディレクトリ（日付/時刻）
date_dir = "backup_#{Time.now.strftime('%Y%m%d')}"
time_dir = "#{date_dir}/backup_#{Time.now.strftime('%H%M%S')}"
FileUtils.mkdir_p(time_dir)
puts "✅ 階層作成: #{time_dir}"

# 応用2: 複数ディレクトリを一度に作成
base_dir = "backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
directories = ["#{base_dir}/data", "#{base_dir}/logs", "#{base_dir}/temp"]
directories.each { |dir| FileUtils.mkdir_p(dir) }
puts "✅ 複数ディレクトリ作成: #{directories.join(', ')}"

# 応用3: 既存チェック付き連番作成
base_name = "backup_#{Time.now.strftime('%Y%m%d')}"
counter = 1
final_dir = base_name
while Dir.exist?(final_dir)
  final_dir = "#{base_name}_#{counter}"
  counter += 1
end
Dir.mkdir(final_dir)
puts "✅ 連番付き作成: #{final_dir}"

# 応用4: ファイルコピー付き
backup_with_files = "backup_with_files_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
FileUtils.mkdir_p(backup_with_files)
Dir.glob("sample_data/*").each { |file| FileUtils.cp(file, backup_with_files) }
puts "✅ ファイルコピー付き: #{backup_with_files}"

puts "\n=== 実務レベル解答 ==="

# 実務レベル: 完全バックアップシステム
backup_root = "backups"
date_str = Time.now.strftime('%Y%m%d_%H%M%S')
full_backup_dir = "#{backup_root}/backup_#{date_str}"

begin
  # バックアップディレクトリ作成
  FileUtils.mkdir_p("#{full_backup_dir}/data")
  FileUtils.mkdir_p("#{full_backup_dir}/logs")

  # ファイルコピー
  Dir.glob("sample_data/*").each { |file| FileUtils.cp(file, "#{full_backup_dir}/data/") }

  # ログ出力
  log_file = "#{full_backup_dir}/logs/backup.log"
  File.write(log_file, "バックアップ作成: #{Time.now}\nファイル数: #{Dir.glob("#{full_backup_dir}/data/*").size}\n")

  puts "✅ 完全バックアップ作成: #{full_backup_dir}"
  puts "📊 ログファイル: #{log_file}"

  # 古いバックアップの削除（7日前より古いもの）
  if Dir.exist?(backup_root)
    old_backups = Dir.glob("#{backup_root}/backup_*").select do |dir|
      dir_date = File.basename(dir).scan(/backup_(\d{8})/).flatten.first
      next false unless dir_date
      Date.strptime(dir_date, '%Y%m%d') < Date.today - 7
    end

    old_backups.each { |dir| FileUtils.rm_rf(dir); puts "🗑️  削除: #{dir}" }
  end

rescue => e
  puts "❌ エラー: #{e.message}"
end

puts "\n🚀 ワンライナー版:"
# 超短縮版
puts Dir.mkdir("backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}").inspect

# 実用ワンライナー版（階層 + ファイルコピー）
puts "📁 実用版:"
eval %Q{
  require 'fileutils'
  dir = "backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
  FileUtils.mkdir_p(dir)
  Dir.glob("sample_data/*").each { |f| FileUtils.cp(f, dir) }
  puts "✅ #{dir} (#{Dir.glob("\#{dir}/*").size}ファイル)"
}