# Day 11: データ移行マスター - 解答例

require 'csv'
require 'json'
require 'time'
require 'fileutils'

puts "=== 基本レベル解答 ==="
# 基本: 固定長フォーマットからCSVへ変換

FIELD_DEFINITIONS = [
  { name: :id, start: 0, length: 5 },
  { name: :name, start: 5, length: 20 },
  { name: :age, start: 25, length: 3 },
  { name: :email, start: 28, length: 30 },
  { name: :phone, start: 58, length: 13 }
]

puts "固定長フォーマット → CSV変換:"
if File.exist?("sample_data/fixed_length.txt")
  records = File.readlines("sample_data/fixed_length.txt").map do |line|
    FIELD_DEFINITIONS.map do |field|
      value = line[field[:start], field[:length]].to_s.strip
      [field[:name], value]
    end.to_h
  end

  puts "変換レコード数: #{records.size}"
  puts "サンプル (最初の3件):"
  records.first(3).each { |r| puts "  #{r}" }
end

puts "\n=== 応用レベル解答 ==="

# 応用1: レガシーCSVからJSON変換（検証付き）
puts "レガシーCSV → JSON変換（検証付き）:"

def valid_email?(email)
  email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
end

def valid_phone?(phone)
  phone =~ /\A\d{2,4}-\d{2,4}-\d{4}\z/
end

if File.exist?("sample_data/legacy_users.csv")
  users = []
  errors = []

  CSV.foreach("sample_data/legacy_users.csv", headers: true) do |row|
    user = {
      id: row["user_id"].to_i,
      name: row["name"].strip,
      email: row["email"].strip.downcase,
      phone: row["phone"].gsub(/[^\d-]/, ''),
      age: row["age"].to_i,
      created_at: row["created_at"]
    }

    # 検証
    row_errors = []
    row_errors << "Invalid email: #{user[:email]}" unless valid_email?(user[:email])
    row_errors << "Invalid phone: #{user[:phone]}" unless valid_phone?(user[:phone])
    row_errors << "Invalid age: #{user[:age]}" unless user[:age] > 0 && user[:age] < 150

    if row_errors.empty?
      users << user
    else
      errors << "User #{user[:id]}: #{row_errors.join(', ')}"
    end
  end

  puts "  変換成功: #{users.size}件"
  puts "  エラー: #{errors.size}件"
  errors.first(3).each { |e| puts "    - #{e}" } if errors.any?
end

# 応用2: データクレンジングと正規化
puts "\nデータクレンジング:"

def normalize_phone(phone)
  digits = phone.gsub(/\D/, '')
  case digits.length
  when 10
    "0#{digits[0..1]}-#{digits[2..5]}-#{digits[6..9]}"
  when 11
    "#{digits[0..2]}-#{digits[3..6]}-#{digits[7..10]}"
  else
    phone
  end
end

def normalize_name(name)
  name.strip.gsub(/\s+/, ' ').split.map(&:capitalize).join(' ')
end

if File.exist?("sample_data/dirty_data.csv")
  cleaned = []
  CSV.foreach("sample_data/dirty_data.csv", headers: true) do |row|
    cleaned << {
      name: normalize_name(row["name"]),
      email: row["email"].strip.downcase,
      phone: normalize_phone(row["phone"]),
      age: row["age"].to_i
    }
  end

  puts "  クレンジング完了: #{cleaned.size}件"
  puts "  サンプル:"
  cleaned.first(2).each { |c| puts "    #{c}" }
end

# 応用3: 差分検出
puts "\nデータ差分検出:"

if File.exist?("sample_data/old_users.json") && File.exist?("sample_data/new_users.json")
  old_data = JSON.parse(File.read("sample_data/old_users.json"))
  new_data = JSON.parse(File.read("sample_data/new_users.json"))

  old_ids = old_data.map { |u| u["id"] }
  new_ids = new_data.map { |u| u["id"] }

  added = new_data.select { |u| !old_ids.include?(u["id"]) }
  removed = old_data.select { |u| !new_ids.include?(u["id"]) }
  updated = new_data.select do |nu|
    old_u = old_data.find { |ou| ou["id"] == nu["id"] }
    old_u && old_u != nu
  end

  puts "  追加: #{added.size}件"
  puts "  削除: #{removed.size}件"
  puts "  更新: #{updated.size}件"
  puts "  変更なし: #{new_ids.size - added.size - updated.size}件"
end

puts "\n=== 実務レベル解答 ==="

# データ移行クラス
class DataMigration
  attr_reader :stats

  def initialize(config = {})
    @config = config
    @stats = {
      total: 0,
      success: 0,
      errors: 0,
      warnings: 0,
      skipped: 0
    }
    @errors = []
    @warnings = []
  end

  def migrate_from_csv(input_file, output_file)
    puts "\n=== データ移行開始 ==="
    puts "入力: #{input_file}"
    puts "出力: #{output_file}"

    unless File.exist?(input_file)
      puts "エラー: 入力ファイルが見つかりません"
      return
    end

    # バックアップ作成
    create_backup(output_file) if File.exist?(output_file)

    records = []
    CSV.foreach(input_file, headers: true) do |row|
      @stats[:total] += 1

      begin
        record = transform_record(row)
        if validate_record(record)
          records << record
          @stats[:success] += 1
        else
          @stats[:skipped] += 1
        end
      rescue => e
        @errors << { row: @stats[:total], error: e.message, data: row.to_h }
        @stats[:errors] += 1
      end
    end

    # 出力ディレクトリ作成
    FileUtils.mkdir_p(File.dirname(output_file))

    # 出力
    File.write(output_file, JSON.pretty_generate(records))

    # レポート生成
    generate_report
    save_error_log(output_file)
  end

  private

  def transform_record(row)
    {
      id: row["user_id"].to_i,
      name: normalize_name(row["name"]),
      email: normalize_email(row["email"]),
      phone: normalize_phone(row["phone"]),
      age: row["age"].to_i,
      status: row["status"] || "active",
      department: row["department"],
      created_at: parse_date(row["created_at"]),
      updated_at: Time.now.iso8601
    }
  end

  def validate_record(record)
    valid = true

    unless valid_email?(record[:email])
      @warnings << "Invalid email for ID #{record[:id]}: #{record[:email]}"
      @stats[:warnings] += 1
      valid = false
    end

    unless record[:age] > 0 && record[:age] < 150
      @warnings << "Invalid age for ID #{record[:id]}: #{record[:age]}"
      @stats[:warnings] += 1
      valid = false
    end

    if record[:name].empty?
      @warnings << "Empty name for ID #{record[:id]}"
      @stats[:warnings] += 1
      valid = false
    end

    valid
  end

  def normalize_name(name)
    return "" if name.nil?
    name.strip.gsub(/\s+/, ' ')
  end

  def normalize_email(email)
    return "" if email.nil?
    email.strip.downcase
  end

  def normalize_phone(phone)
    return "" if phone.nil?
    digits = phone.gsub(/\D/, '')

    case digits.length
    when 10
      "#{digits[0..2]}-#{digits[3..6]}-#{digits[7..9]}"
    when 11
      "#{digits[0..2]}-#{digits[3..6]}-#{digits[7..10]}"
    else
      phone
    end
  end

  def valid_email?(email)
    email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  end

  def parse_date(date_str)
    Time.parse(date_str).iso8601
  rescue
    Time.now.iso8601
  end

  def create_backup(file)
    backup_dir = "#{File.dirname(file)}/backups"
    FileUtils.mkdir_p(backup_dir)
    backup_name = "#{backup_dir}/#{File.basename(file)}.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    FileUtils.cp(file, backup_name)
    puts "バックアップ作成: #{backup_name}"
  end

  def generate_report
    puts "\n=== 移行完了レポート ==="
    puts "=" * 50
    puts "総レコード数: #{@stats[:total]}"
    puts "成功: #{@stats[:success]} (#{success_rate}%)"
    puts "エラー: #{@stats[:errors]}"
    puts "警告: #{@stats[:warnings]}"
    puts "スキップ: #{@stats[:skipped]}"

    if @errors.any?
      puts "\n=== エラー詳細（最初の5件）==="
      @errors.first(5).each { |err| puts "Row #{err[:row]}: #{err[:error]}" }
      puts "(他#{@errors.size - 5}件)" if @errors.size > 5
    end

    if @warnings.any?
      puts "\n=== 警告詳細（最初の5件）==="
      @warnings.first(5).each { |w| puts "- #{w}" }
      puts "(他#{@warnings.size - 5}件)" if @warnings.size > 5
    end

    puts "=" * 50
  end

  def save_error_log(output_file)
    return if @errors.empty? && @warnings.empty?

    log_file = "#{File.dirname(output_file)}/migration_errors.log"
    File.open(log_file, 'w') do |f|
      f.puts "データ移行エラーログ"
      f.puts "生成日時: #{Time.now}"
      f.puts "=" * 60

      if @errors.any?
        f.puts "\n【エラー】"
        @errors.each { |err| f.puts "Row #{err[:row]}: #{err[:error]}" }
      end

      if @warnings.any?
        f.puts "\n【警告】"
        @warnings.each { |w| f.puts "- #{w}" }
      end
    end

    puts "\nエラーログ: #{log_file}"
  end

  def success_rate
    return 0 if @stats[:total] == 0
    ((@stats[:success].to_f / @stats[:total]) * 100).round(2)
  end
end

# 実行例
if File.exist?("sample_data/legacy_users.csv")
  FileUtils.mkdir_p("output")
  migration = DataMigration.new
  migration.migrate_from_csv(
    "sample_data/legacy_users.csv",
    "output/migrated_users.json"
  )
end

puts "\n🚀 ワンライナー版:"

# 固定長 → CSV変換
puts "\n固定長→CSV変換:"
puts 'ruby -e \'File.readlines("fixed.txt").each { |l| puts "#{l[0,5].strip},#{l[5,20].strip},#{l[25,3].strip}" }\' > output.csv'

# データ正規化
puts "\nデータ正規化（電話番号）:"
puts 'ruby -rcsv -e \'CSV.foreach("data.csv", headers: true) { |r| puts "#{r["name"]},#{r["phone"].gsub(/\\D/, "").sub(/^(\\d{3})(\\d{4})(\\d{4})$/, "\\1-\\2-\\3")}" }\''

# 差分抽出
puts "\nJSON差分抽出:"
puts 'ruby -rjson -e \'old = JSON.parse(File.read("old.json")); new = JSON.parse(File.read("new.json")); puts "Added: #{(new.map{|u|u["id"]} - old.map{|u|u["id"]}).size}"\''

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # CSVからJSONへ一括変換
  ruby -rcsv -rjson -e 'data = CSV.read("data.csv", headers: true).map(&:to_h); puts JSON.pretty_generate(data)' > output.json

  # 重複データの検出
  ruby -rcsv -e 'emails = CSV.read("users.csv", headers: true).map { |r| r["email"] }; puts emails.tally.select { |k,v| v > 1 }'

  # データ検証（メールアドレス）
  ruby -rcsv -e 'CSV.foreach("users.csv", headers: true) { |r| puts "Invalid: #{r["email"]}" unless r["email"] =~ /\\A[\\w+\\-.]+@[a-z\\d\\-]+(\\.[a-z\\d\\-]+)*\\.[a-z]+\\z/i }'

  # 欠損データのレポート
  ruby -rcsv -e 'CSV.foreach("data.csv", headers: true).with_index { |r, i| r.each { |k, v| puts "Row #{i+1}, Column #{k}: missing" if v.nil? || v.empty? } }'

  # フィールド型変換
  ruby -rcsv -e 'CSV.foreach("data.csv", headers: true) { |r| puts "#{r["id"].to_i},#{r["name"]},#{r["price"].to_f}" }'

  # データマージ（2つのCSVをIDで結合）
  ruby -rcsv -e 'users = CSV.read("users.csv", headers: true); orders = CSV.read("orders.csv", headers: true); users.each { |u| order = orders.find { |o| o["user_id"] == u["id"] }; puts "#{u["name"]}: #{order ? order["total"] : "No order"}" }'

  # バックアップ付きデータ更新
  cp data.json data.json.backup.$(date +%Y%m%d_%H%M%S) && ruby -rjson -e 'data = JSON.parse(File.read("data.json")); data.each { |u| u["updated_at"] = Time.now }; File.write("data.json", JSON.pretty_generate(data))'

  # 大量データの分割（1000件ごと）
  ruby -rcsv -e 'CSV.foreach("large.csv", headers: true).each_slice(1000).with_index { |batch, i| CSV.open("output_#{i+1}.csv", "w", headers: true) { |csv| batch.each { |row| csv << row } } }'
EXAMPLES
