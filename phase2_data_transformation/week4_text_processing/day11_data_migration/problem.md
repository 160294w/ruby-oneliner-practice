<div align="center">

# 🔄 Day 11: データ移行マスター

[![難易度](https://img.shields.io/badge/難易度-🔴%20上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-45分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: レガシーシステムから新システムへのデータ移行、異なるフォーマット間のデータ変換が必要。

**問題**: データ形式が異なる、データの整合性チェックが必要、エラーハンドリングが複雑。大量データの処理で時間がかかる。

**解決**: Rubyワンライナーで安全かつ高速なデータ移行！検証機能付き！

## 📝 課題

レガシーフォーマットからモダンなフォーマットへのデータ変換、整合性チェック、エラーハンドリングをワンライナーで実現してください。

### 🎯 期待する処理例
```bash
# レガシーCSVから新形式JSONへ変換
legacy_users.csv → users.json (検証付き)

# 固定長フォーマットからCSVへ変換
legacy_records.txt → records.csv

# データクレンジングと正規化
不正なデータの検出・修正・レポート生成

# 差分検出とマージ
新旧データの比較、差分抽出、マージ処理
```

## 💡 学習ポイント

| テクニック | 用途 | 重要度 |
|-----------|------|--------|
| データ検証 | 整合性チェック | ⭐⭐⭐⭐⭐ |
| エラーハンドリング | 例外処理 | ⭐⭐⭐⭐⭐ |
| データ正規化 | フォーマット統一 | ⭐⭐⭐⭐ |
| トランザクション処理 | データ整合性保証 | ⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
固定長フォーマットのパースから始めましょう：

```ruby
# ヒント: この構造を完成させてください
File.readlines("sample_data/fixed_length.txt").each do |line|
  id = line[0..4].strip
  name = line[5..24].strip
  age = line[25..27].strip
  # データ処理
end
```

<details>
<summary>💡 基本レベルのヒント</summary>

- 固定長フォーマット: 各フィールドの位置と長さが決まっている
- `String#[]` で部分文字列を抽出
- `strip` で前後の空白を除去
- CSV形式で出力

</details>

### 🟡 応用レベル

<details>
<summary><strong>1. レガシーCSVからJSONへ変換（検証付き）</strong></summary>

```ruby
require 'csv'
require 'json'

# データ検証関数
def valid_email?(email)
  email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
end

def valid_phone?(phone)
  phone =~ /\A\d{2,4}-\d{2,4}-\d{4}\z/
end

# 変換処理
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
  errors << "Invalid email for user #{user[:id]}: #{user[:email]}" unless valid_email?(user[:email])
  errors << "Invalid phone for user #{user[:id]}: #{user[:phone]}" unless valid_phone?(user[:phone])
  errors << "Invalid age for user #{user[:id]}: #{user[:age]}" unless user[:age] > 0 && user[:age] < 150

  users << user if errors.empty?
end

# 結果出力
File.write("output/users.json", JSON.pretty_generate(users))
File.write("output/errors.log", errors.join("\n")) if errors.any?

puts "変換完了: #{users.size}件"
puts "エラー: #{errors.size}件" if errors.any?
```

**学習ポイント**: バリデーション、エラー収集、結果レポート

</details>

<details>
<summary><strong>2. 固定長フォーマット変換</strong></summary>

```ruby
require 'csv'

# フィールド定義
FIELDS = [
  { name: :id, start: 0, length: 5 },
  { name: :name, start: 5, length: 20 },
  { name: :age, start: 25, length: 3 },
  { name: :email, start: 28, length: 30 },
  { name: :phone, start: 58, length: 13 }
]

records = File.readlines("sample_data/fixed_length.txt").map do |line|
  FIELDS.map do |field|
    value = line[field[:start], field[:length]].to_s.strip
    [field[:name], value]
  end.to_h
end

CSV.open("output/converted.csv", "w", headers: FIELDS.map { |f| f[:name] }, write_headers: true) do |csv|
  records.each { |record| csv << record.values }
end

puts "変換完了: #{records.size}件"
```

**学習ポイント**: フィールド定義の構造化、メタデータ駆動処理

</details>

<details>
<summary><strong>3. データクレンジングと正規化</strong></summary>

```ruby
require 'csv'

# 正規化関数
def normalize_phone(phone)
  digits = phone.gsub(/\D/, '')
  case digits.length
  when 10
    "0#{digits[0..1]}-#{digits[2..5]}-#{digits[6..9]}"
  when 11
    "#{digits[0..2]}-#{digits[3..6]}-#{digits[7..10]}"
  else
    phone # 修正不可の場合は元の値を返す
  end
end

def normalize_name(name)
  name.strip.gsub(/\s+/, ' ').split.map(&:capitalize).join(' ')
end

# クレンジング処理
cleaned = []
CSV.foreach("sample_data/dirty_data.csv", headers: true) do |row|
  cleaned << {
    name: normalize_name(row["name"]),
    email: row["email"].strip.downcase,
    phone: normalize_phone(row["phone"]),
    age: row["age"].to_i
  }
end

puts "クレンジング完了: #{cleaned.size}件"
```

**学習ポイント**: データ正規化、複数の変換ルール適用

</details>

<details>
<summary><strong>4. 差分検出とマージ</strong></summary>

```ruby
require 'json'

# 新旧データの読み込み
old_data = JSON.parse(File.read("sample_data/old_users.json"))
new_data = JSON.parse(File.read("sample_data/new_users.json"))

old_ids = old_data.map { |u| u["id"] }
new_ids = new_data.map { |u| u["id"] }

# 差分検出
added = new_data.select { |u| !old_ids.include?(u["id"]) }
removed = old_data.select { |u| !new_ids.include?(u["id"]) }
updated = new_data.select do |nu|
  old_u = old_data.find { |ou| ou["id"] == nu["id"] }
  old_u && old_u != nu
end

puts "追加: #{added.size}件"
puts "削除: #{removed.size}件"
puts "更新: #{updated.size}件"
```

**学習ポイント**: 差分抽出、データ比較アルゴリズム

</details>

### 🔴 実務レベル

<details>
<summary><strong>包括的データ移行システム</strong></summary>

複数のレガシーフォーマットから新システムへの移行を、検証・ロギング・ロールバック機能付きで実装。

```ruby
require 'csv'
require 'json'
require 'time'
require 'fileutils'

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
    puts "=== データ移行開始 ==="
    puts "入力: #{input_file}"
    puts "出力: #{output_file}"

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
        @errors << { row: @stats[:total], error: e.message }
        @stats[:errors] += 1
      end
    end

    # 出力
    File.write(output_file, JSON.pretty_generate(records))

    # レポート生成
    generate_report
  end

  private

  def transform_record(row)
    {
      id: row["id"].to_i,
      name: normalize_name(row["name"]),
      email: normalize_email(row["email"]),
      phone: normalize_phone(row["phone"]),
      age: row["age"].to_i,
      status: row["status"] || "active",
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
    backup_name = "#{file}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    FileUtils.cp(file, backup_name)
    puts "バックアップ作成: #{backup_name}"
  end

  def generate_report
    puts "\n=== 移行完了レポート ==="
    puts "総レコード数: #{@stats[:total]}"
    puts "成功: #{@stats[:success]} (#{success_rate}%)"
    puts "エラー: #{@stats[:errors]}"
    puts "警告: #{@stats[:warnings]}"
    puts "スキップ: #{@stats[:skipped]}"

    if @errors.any?
      puts "\n=== エラー詳細 ==="
      @errors.each { |err| puts "Row #{err[:row]}: #{err[:error]}" }
    end

    if @warnings.any?
      puts "\n=== 警告詳細 ==="
      @warnings.first(10).each { |w| puts "- #{w}" }
      puts "(他#{@warnings.size - 10}件)" if @warnings.size > 10
    end
  end

  def success_rate
    return 0 if @stats[:total] == 0
    ((@stats[:success].to_f / @stats[:total]) * 100).round(2)
  end
end

# 実行例
migration = DataMigration.new
migration.migrate_from_csv(
  "sample_data/legacy_users.csv",
  "output/migrated_users.json"
)
```

</details>

## 📊 実際の業務での使用例

- 🔄 **システムリプレース** - 旧システムから新システムへのデータ移行
- 📊 **データ統合** - 複数のデータソースの統合・正規化
- 🧹 **データクレンジング** - 不正データの検出・修正・削除
- 📈 **ETL処理** - Extract, Transform, Load の自動化
- 🔍 **データ品質管理** - データ品質の継続的な監視と改善

## 🎓 次のステップ

- ✅ 基本レベルクリア → [Day 12: パフォーマンス最適化](../day12_performance/problem.md)
- 🔗 関連する実用例 → [実世界での使用例](../../../resources/real_world_examples.md#データ移行)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
