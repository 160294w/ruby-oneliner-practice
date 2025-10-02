# Day 5: ログファイルからエラー行抽出 - 解答例

puts "=== 基本レベル解答 ==="
# 基本: エラー行のみ抽出
puts "エラー行:"
File.readlines("sample_data/app.log").each do |line|
  puts line if line.include?("ERROR")
end

puts "\n=== 応用レベル解答 ==="

# 応用1: レベル別カウント
puts "ログレベル別統計:"
logs = File.readlines("sample_data/app.log")
levels = Hash.new(0)
logs.each do |line|
  case line
  when /\[ERROR\]/
    levels["ERROR"] += 1
  when /\[WARNING\]/
    levels["WARNING"] += 1
  when /\[INFO\]/
    levels["INFO"] += 1
  end
end
levels.each { |level, count| puts "#{level}: #{count}件" }

# 応用2: 時間範囲指定（14時台のエラー）
puts "\n14時台のエラー:"
File.readlines("sample_data/app.log")
  .select { |line| line.match?(/2024-\d{2}-\d{2} 14:/) && line.include?("ERROR") }
  .each { |line| puts line.strip }

# 応用3: エラーメッセージのパターン分析
puts "\nエラーメッセージ頻度分析:"
error_messages = File.readlines("sample_data/app.log")
  .select { |line| line.include?("ERROR") }
  .map { |line| line.match(/\[ERROR\] (.+)$/)[1] rescue "Unknown" }
  .group_by(&:itself)
  .transform_values(&:size)
  .sort_by { |_, count| -count }

error_messages.first(5).each_with_index do |(msg, count), i|
  puts "#{i+1}. #{msg[0..60]}... (#{count}回)"
end

# 応用4: 時系列でのエラー発生推移
puts "\n時間帯別エラー発生件数:"
error_by_hour = File.readlines("sample_data/app.log")
  .select { |line| line.include?("ERROR") }
  .map { |line| line.match(/\d{2}:\d{2}/)[0][0..1] rescue nil }
  .compact
  .group_by(&:itself)
  .transform_values(&:size)
  .sort

error_by_hour.each { |hour, count| puts "#{hour}時台: #{'■' * count} (#{count}件)" }

puts "\n=== 実務レベル解答 ==="

# 実務1: 重大度別の詳細レポート
puts "重大度別詳細レポート:"
severity_report = {
  critical: [],
  high: [],
  medium: []
}

File.readlines("sample_data/app.log").each do |line|
  if line.include?("ERROR")
    case line
    when /crashed|failed|fault/i
      severity_report[:critical] << line.strip
    when /timeout|connection|deadlock/i
      severity_report[:high] << line.strip
    else
      severity_report[:medium] << line.strip
    end
  end
end

severity_report.each do |level, errors|
  puts "\n#{level.upcase} (#{errors.size}件):"
  errors.first(3).each { |error| puts "  - #{error[20..90]}..." }
end

# 実務2: 連続エラーの検出
puts "\n連続エラー検出:"
consecutive_errors = []
error_streak = 0

File.readlines("sample_data/app.log").each do |line|
  if line.include?("ERROR")
    error_streak += 1
    consecutive_errors << line.strip if error_streak >= 2
  else
    error_streak = 0
  end
end

puts "連続して発生したエラー: #{consecutive_errors.size}件"
consecutive_errors.first(3).each { |error| puts "  #{error[0..80]}..." }

# 実務3: 異常パターンの検出
puts "\n異常パターン検出:"
warnings = File.readlines("sample_data/app.log").grep(/WARNING/)
errors = File.readlines("sample_data/app.log").grep(/ERROR/)

puts "WARNING → ERROR への遷移:"
warnings.each_with_index do |warning, i|
  warning_time = warning.match(/\d{2}:\d{2}:\d{2}/)[0]
  related_errors = errors.select do |error|
    error_time = error.match(/\d{2}:\d{2}:\d{2}/)[0]
    (Time.parse(error_time) - Time.parse(warning_time)).abs < 60 # 1分以内
  end

  if related_errors.any?
    puts "#{warning_time} の警告後にエラー発生:"
    puts "  警告: #{warning.match(/WARNING\] (.+)$/)[1]}"
    puts "  エラー: #{related_errors.first.match(/ERROR\] (.+)$/)[1]}"
  end
end

# 実務4: サマリーレポート生成
puts "\n=== エラーサマリーレポート ==="
puts "生成日時: #{Time.now}"
puts "対象ログ: sample_data/app.log"
puts "総行数: #{logs.size}"
puts "エラー件数: #{errors.size}"
puts "警告件数: #{warnings.size}"
puts "エラー率: #{(errors.size * 100.0 / logs.size).round(2)}%"
puts "\nトップ3エラー:"
error_messages.first(3).each_with_index do |(msg, count), i|
  puts "#{i+1}. #{msg[0..50]}... (#{count}回)"
end

puts "\n🚀 ワンライナー版:"

# 超短縮版コレクション
puts "\nエラー件数: " + File.readlines("sample_data/app.log").count { |line| line.include?("ERROR") }.to_s

puts "最多エラー: " + File.readlines("sample_data/app.log").grep(/ERROR/).map { |line| line.match(/ERROR\] (.+)$/)[1] }.group_by(&:itself).max_by { |_, v| v.size }[0][0..40]

puts "14時台エラー: " + File.readlines("sample_data/app.log").count { |line| line.match?(/14:/) && line.include?("ERROR") }.to_s + "件"

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # エラーのみ抽出してファイル出力
  ruby -ne 'print if /ERROR/' app.log > errors.log

  # レベル別カウント
  ruby -e 'h=Hash.new(0); File.readlines("app.log").each{|l| h["ERROR"]+=1 if l.include?("ERROR"); h["WARNING"]+=1 if l.include?("WARNING")}; p h'

  # 時間範囲指定（14時～15時のエラー）
  ruby -ne 'print if /2024-\\d{2}-\\d{2} 1[4-5]:/ && /ERROR/' app.log

  # エラーメッセージ頻度トップ5
  ruby -e 'puts File.readlines("app.log").grep(/ERROR/).map{|l| l[/ERROR\\] (.+)$/,1]}.group_by(&:itself).transform_values(&:size).sort_by{|_,v|-v}.first(5).to_h'

  # リアルタイム監視（新しいエラーを監視）
  tail -f app.log | ruby -ne 'puts "\\e[31m#{$_}\\e[0m" if /ERROR/'
EXAMPLES