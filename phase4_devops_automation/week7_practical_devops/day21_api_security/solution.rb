# Day 21: API連携とセキュリティ監査 - 解答例

require 'json'
require 'net/http'

puts "=== 基本レベル解答 ==="
# 基本: API レスポンスの解析

if File.exist?("sample_data/api_response.json")
  response = File.read("sample_data/api_response.json")
  data = JSON.parse(response)

  puts "API Response Status: #{data['status']}"
  puts "Total Users: #{data['data']['total']}"

  data['data']['users'].each do |user|
    status = user['active'] ? "✅" : "❌"
    puts "  #{status} #{user['name']} (#{user['email']})"
  end
else
  puts "⚠️  サンプルデータファイルが見つかりません"
end

puts "\n=== 応用レベル解答 ==="

# 応用1: Webhook通知のシミュレーション
puts "Webhook通知の例:"

def send_notification(message, service = "slack")
  # 実際のWebhook URLは環境変数から取得
  webhook_url = ENV["#{service.upcase}_WEBHOOK"] || "https://hooks.example.com/webhook"

  payload = {
    text: message,
    timestamp: Time.now.to_i,
    service: service
  }

  puts "📢 通知送信:"
  puts "  Service: #{service}"
  puts "  Message: #{message}"
  puts "  Payload: #{payload.to_json}"

  # 実際の送信コード（環境変数が設定されている場合のみ実行）
  if ENV["#{service.upcase}_WEBHOOK"]
    uri = URI(webhook_url)
    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request.body = payload.to_json

    begin
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
      puts "  ✅ 送信成功 (HTTP #{response.code})"
    rescue => e
      puts "  ❌ 送信失敗: #{e.message}"
    end
  else
    puts "  ℹ️  Webhook URLが設定されていないため、実際の送信はスキップしました"
  end
end

send_notification("デプロイ完了！ 🚀")

# 応用2: Gemfile.lock解析
puts "\nGemfile.lock 解析:"

if File.exist?("sample_data/gemfile.lock")
  lockfile = File.read("sample_data/gemfile.lock")

  # Gem とバージョンの抽出
  gems = {}
  lockfile.each_line do |line|
    if line =~ /^    (\w+) \(([\d.]+)\)/
      gems[$1] = $2
    end
  end

  puts "  インストール済みgem: #{gems.size}個"

  # 主要なgemを表示
  important_gems = ["rails", "nokogiri", "rack"]
  important_gems.each do |gem_name|
    if gems[gem_name]
      puts "  #{gem_name}: #{gems[gem_name]}"
    end
  end
end

puts "\n=== 実務レベル解答 ==="

# 実務1: 脆弱性チェック
puts "脆弱性チェック:"

VULNERABLE_GEMS = {
  "rails" => { min_safe_version: "6.1.7", cve: "CVE-2023-22795", severity: "HIGH" },
  "nokogiri" => { min_safe_version: "1.13.10", cve: "CVE-2022-XXXX", severity: "CRITICAL" },
  "rack" => { min_safe_version: "2.2.6.4", cve: "CVE-2023-27530", severity: "MEDIUM" }
}

def version_compare(v1, v2)
  # 簡易バージョン比較（実際にはGem::Versionを使用すべき）
  parts1 = v1.split('.').map(&:to_i)
  parts2 = v2.split('.').map(&:to_i)
  parts1 <=> parts2
end

if File.exist?("sample_data/gemfile.lock")
  lockfile = File.read("sample_data/gemfile.lock")
  findings = []

  VULNERABLE_GEMS.each do |gem_name, vuln_info|
    if lockfile =~ /#{gem_name} \(([\d.]+)\)/
      installed_version = $1
      min_safe = vuln_info[:min_safe_version]

      if version_compare(installed_version, min_safe) < 0
        findings << {
          gem: gem_name,
          installed: installed_version,
          safe: min_safe,
          cve: vuln_info[:cve],
          severity: vuln_info[:severity]
        }
      end
    end
  end

  if findings.any?
    puts "  ⚠️  #{findings.size}個の脆弱性を検出:"
    findings.each do |f|
      icon = case f[:severity]
             when "CRITICAL" then "🔴"
             when "HIGH" then "🟠"
             when "MEDIUM" then "🟡"
             else "⚪"
             end
      puts "  #{icon} #{f[:gem]} #{f[:installed]} → #{f[:safe]}+ (#{f[:cve]})"
    end
  else
    puts "  ✅ 既知の脆弱性は検出されませんでした"
  end
end

# 実務2: SSL証明書情報の解析
puts "\nSSL証明書チェック:"

if File.exist?("sample_data/ssl_cert_info.txt")
  cert_info = File.read("sample_data/ssl_cert_info.txt")

  # 有効期限の抽出
  if cert_info =~ /Not After\s*:\s*(\w+)\s+(\d+)\s+\d+:\d+:\d+\s+(\d{4})/
    month_str, day, year = $1, $2.to_i, $3.to_i

    month_map = {
      "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
      "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
      "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12
    }

    month = month_map[month_str]
    expiry_date = Time.new(year, month, day) rescue nil

    if expiry_date
      days_remaining = ((expiry_date - Time.now) / 86400).to_i

      puts "  有効期限: #{expiry_date.strftime('%Y-%m-%d')}"
      puts "  残り日数: #{days_remaining}日"

      if days_remaining < 0
        puts "  🔴 期限切れ！"
      elsif days_remaining < 30
        puts "  ⚠️  まもなく期限切れ"
      else
        puts "  ✅ 有効"
      end
    end
  end
end

# 実務3: API健全性チェック（シミュレート）
puts "\nAPI健全性チェック:"

endpoints = {
  "Main API" => "https://api.example.com/health",
  "Database" => "https://api.example.com/db/ping",
  "Cache" => "https://api.example.com/cache/status"
}

puts "  監視対象: #{endpoints.size}エンドポイント"
endpoints.each do |name, url|
  # 実際の環境では Net::HTTP.get_response を使用
  # ここではシミュレーション
  simulated_status = ["200", "200", "503"].sample
  simulated_duration = rand(20..150)

  if simulated_status == "200"
    puts "  ✅ #{name}: #{simulated_duration}ms"
  else
    puts "  ❌ #{name}: HTTP #{simulated_status}"
  end
end

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# APIヘルスチェック
ruby -rnet/http -e 'r=Net::HTTP.get_response(URI("https://api.example.com/health")); puts r.code=="200" ? "✅ OK" : "❌ NG"'

# Slack通知
ruby -rnet/http -rjson -e 'u=URI(ENV["SLACK_WEBHOOK"]);req=Net::HTTP::Post.new(u,"Content-Type"=>"application/json");req.body={text:"Deploy完了"}.to_json;Net::HTTP.start(u.hostname,u.port,use_ssl:true){|h|h.request(req)}'

# Gemfile.lockからgem一覧
ruby -e 'File.readlines("Gemfile.lock").each{|l| puts "#{$1}: #{$2}" if l=~/^    (\w+) \(([\d.]+)\)/}'

# SSL証明書の残日数（実際のサイトをチェック）
ruby -ropenssl -rsocket -e 't=TCPSocket.new("example.com",443);s=OpenSSL::SSL::SSLSocket.new(t);s.connect;d=((s.peer_cert.not_after-Time.now)/86400).to_i;puts "残#{d}日"'
ONELINERS

puts "\n💡 運用Tips:"
puts <<~TIPS
1. API監視
   - ヘルスチェックを5分おきに実行
   - レスポンスタイムが100ms超で警告

2. セキュリティ監査
   - 週次でGemfile.lock脆弱性チェック
   - SSL証明書は期限30日前にアラート

3. 通知管理
   - 重要度に応じて通知先を分ける
   - Slack/Discord/Emailを使い分け
TIPS
