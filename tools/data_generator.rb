#!/usr/bin/env ruby
# 練習用データ生成ツール

require 'fileutils'
require 'csv'
require 'json'

class DataGenerator
  def initialize
    @output_dir = File.expand_path('../generated_data', __dir__)
    FileUtils.mkdir_p(@output_dir)
  end

  def generate_all
    puts "🎲 練習用データを生成中..."

    generate_text_files
    generate_csv_files
    generate_log_files
    generate_json_files
    generate_code_files

    puts "✅ データ生成完了: #{@output_dir}"
  end

  def generate_text_files
    puts "📄 テキストファイル生成中..."

    # 様々なサイズのテキストファイル
    files = {
      'small.txt' => 10,
      'medium.txt' => 50,
      'large.txt' => 200,
      'huge.txt' => 1000
    }

    files.each do |filename, line_count|
      content = (1..line_count).map { |i| "This is line #{i} of #{filename}" }.join("\n")
      File.write(File.join(@output_dir, filename), content)
    end

    # 特殊文字を含むファイル
    special_content = [
      "ファイル名: 日本語.txt",
      "特殊文字: !@#$%^&*()_+-={}[]|\\:;\"'<>?,./ ",
      "空行テスト:",
      "",
      "  スペース付き行  ",
      "\t\tタブ付き行\t\t",
      "最終行"
    ].join("\n")

    File.write(File.join(@output_dir, 'special_chars.txt'), special_content)
  end

  def generate_csv_files
    puts "📊 CSVファイル生成中..."

    # ユーザーデータCSV
    CSV.open(File.join(@output_dir, 'users.csv'), 'w') do |csv|
      csv << ['id', 'name', 'email', 'age', 'department']

      100.times do |i|
        csv << [
          i + 1,
          "ユーザー#{i + 1}",
          "user#{i + 1}@example.com",
          rand(20..65),
          %w[開発 営業 マーケティング 人事 総務].sample
        ]
      end
    end

    # 売上データCSV
    CSV.open(File.join(@output_dir, 'sales.csv'), 'w') do |csv|
      csv << ['date', 'product', 'amount', 'region']

      30.times do |i|
        csv << [
          (Date.today - i).strftime('%Y-%m-%d'),
          "商品#{rand(1..10)}",
          rand(1000..50000),
          %w[東京 大阪 名古屋 福岡 札幌].sample
        ]
      end
    end
  end

  def generate_log_files
    puts "📋 ログファイル生成中..."

    # アクセスログ
    access_log = (1..500).map do |i|
      ip = "192.168.#{rand(1..10)}.#{rand(1..254)}"
      timestamp = (Time.now - rand(0..86400)).strftime('%d/%b/%Y:%H:%M:%S %z')
      method = %w[GET POST PUT DELETE].sample
      path = %w[/ /api/users /api/products /login /logout /admin].sample
      status = [200, 201, 404, 500, 403].sample
      size = rand(100..5000)

      "#{ip} - - [#{timestamp}] \"#{method} #{path} HTTP/1.1\" #{status} #{size}"
    end.join("\n")

    File.write(File.join(@output_dir, 'access.log'), access_log)

    # エラーログ
    error_log = (1..100).map do |i|
      timestamp = (Time.now - rand(0..86400)).strftime('%Y-%m-%d %H:%M:%S')
      level = %w[INFO WARN ERROR FATAL].sample
      message = [
        "Database connection timeout",
        "User authentication failed",
        "File not found: config.yml",
        "Memory usage exceeds threshold",
        "API rate limit exceeded"
      ].sample

      "[#{timestamp}] #{level}: #{message}"
    end.join("\n")

    File.write(File.join(@output_dir, 'error.log'), error_log)
  end

  def generate_json_files
    puts "🔧 JSONファイル生成中..."

    # 設定ファイル
    config = {
      app_name: "Ruby Practice App",
      version: "1.0.0",
      database: {
        host: "localhost",
        port: 5432,
        name: "practice_db"
      },
      features: {
        logging: true,
        caching: false,
        debug: true
      }
    }

    File.write(File.join(@output_dir, 'config.json'), JSON.pretty_generate(config))

    # ユーザーデータJSON
    users = (1..20).map do |i|
      {
        id: i,
        name: "User #{i}",
        email: "user#{i}@example.com",
        profile: {
          age: rand(20..50),
          hobbies: %w[reading gaming cooking traveling].sample(rand(1..3))
        },
        created_at: (Time.now - rand(0..31536000)).iso8601
      }
    end

    File.write(File.join(@output_dir, 'users.json'), JSON.pretty_generate(users))
  end

  def generate_code_files
    puts "💻 コードファイル生成中..."

    # Ruby files with varying complexity
    simple_rb = <<~RUBY
      # Simple Ruby class
      class Calculator
        def add(a, b)
          a + b
        end

        def subtract(a, b)
          a - b
        end
      end
    RUBY

    File.write(File.join(@output_dir, 'simple.rb'), simple_rb)

    complex_rb = <<~RUBY
      # Complex Ruby class with multiple methods
      class UserManager
        attr_reader :users

        def initialize
          @users = []
        end

        def add_user(name, email)
          return false if email_exists?(email)

          user = {
            id: generate_id,
            name: name,
            email: email,
            created_at: Time.now
          }

          @users << user
          true
        end

        def find_user(id)
          @users.find { |user| user[:id] == id }
        end

        def delete_user(id)
          @users.reject! { |user| user[:id] == id }
        end

        def list_users_by_domain(domain)
          @users.select { |user| user[:email].end_with?(domain) }
        end

        private

        def email_exists?(email)
          @users.any? { |user| user[:email] == email }
        end

        def generate_id
          @users.empty? ? 1 : @users.map { |u| u[:id] }.max + 1
        end
      end

      # Usage example
      manager = UserManager.new
      manager.add_user("Alice", "alice@example.com")
      manager.add_user("Bob", "bob@company.com")
      manager.add_user("Charlie", "charlie@example.com")

      puts manager.list_users_by_domain("@example.com")
    RUBY

    File.write(File.join(@output_dir, 'complex.rb'), complex_rb)
  end

  def clean_generated_data
    if Dir.exist?(@output_dir)
      FileUtils.rm_rf(@output_dir)
      puts "🗑️  生成データを削除しました"
    else
      puts "削除対象のデータがありません"
    end
  end

  def list_generated_files
    if Dir.exist?(@output_dir)
      files = Dir.glob("#{@output_dir}/*").sort
      puts "📁 生成済みファイル:"
      files.each { |file| puts "  - #{File.basename(file)} (#{File.size(file)} bytes)" }
    else
      puts "生成済みデータがありません"
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  generator = DataGenerator.new

  case ARGV[0]
  when 'generate', 'gen', nil
    generator.generate_all
  when 'clean'
    generator.clean_generated_data
  when 'list'
    generator.list_generated_files
  else
    puts "使用方法:"
    puts "  ruby data_generator.rb generate  # データ生成"
    puts "  ruby data_generator.rb clean     # データ削除"
    puts "  ruby data_generator.rb list      # ファイル一覧"
  end
end