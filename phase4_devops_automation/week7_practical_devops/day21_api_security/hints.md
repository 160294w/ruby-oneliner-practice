# Day 21: ヒントとステップガイド

## 段階的に考えてみよう

### Step 1: REST API の基本呼び出し
```ruby
require 'net/http'
require 'json'

# GET リクエスト
uri = URI('https://api.example.com/users')
response = Net::HTTP.get(uri)
data = JSON.parse(response)

# POST リクエスト
uri = URI('https://api.example.com/users')
request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
request.body = { name: "Alice", email: "alice@example.com" }.to_json

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end
```

### Step 2: Webhook 通知
```ruby
def send_webhook(webhook_url, message)
  uri = URI(webhook_url)
  request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  request.body = { text: message }.to_json

  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    response = http.request(request)
    response.code == "200"
  end
end

# Slack通知
send_webhook(ENV['SLACK_WEBHOOK'], "デプロイ完了！")
```

### Step 3: Gemfile.lock 解析
```ruby
# gemとバージョンの抽出
gems = {}
File.readlines("Gemfile.lock").each do |line|
  if line =~ /^    (\w+) \(([\d.]+)\)/
    gems[$1] = $2
  end
end

gems.each { |name, version| puts "#{name}: #{version}" }
```

## よく使うパターン

### パターン1: API ヘルスチェック
```ruby
def check_endpoint(url)
  start_time = Time.now
  response = Net::HTTP.get_response(URI(url))
  duration = ((Time.now - start_time) * 1000).to_i

  {
    url: url,
    status: response.code,
    ok: response.code == "200",
    duration_ms: duration
  }
rescue => e
  { url: url, ok: false, error: e.message }
end

# 使用例
result = check_endpoint("https://api.example.com/health")
puts result[:ok] ? "✅ OK (#{result[:duration_ms]}ms)" : "❌ NG"
```

### パターン2: 脆弱性データベース照合
```ruby
# 既知の脆弱なバージョン
VULNERABLE_GEMS = {
  "rails" => {
    versions: ["< 6.1.7", "< 7.0.4"],
    cve: "CVE-2023-XXXX",
    severity: "high"
  },
  "nokogiri" => {
    versions: ["< 1.13.10"],
    cve: "CVE-2022-XXXX",
    severity: "critical"
  }
}

def check_vulnerabilities(gemfile_lock_path)
  content = File.read(gemfile_lock_path)
  findings = []

  VULNERABLE_GEMS.each do |gem_name, vuln_info|
    if content =~ /#{gem_name} \(([\d.]+)\)/
      version = $1
      # バージョン比較（簡易版）
      findings << {
        gem: gem_name,
        version: version,
        cve: vuln_info[:cve],
        severity: vuln_info[:severity]
      }
    end
  end

  findings
end
```

### パターン3: SSL証明書の有効期限確認
```ruby
require 'openssl'
require 'socket'

def check_ssl_expiry(hostname, port = 443)
  tcp_socket = TCPSocket.new(hostname, port)
  ssl_context = OpenSSL::SSL::SSLContext.new
  ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
  ssl_socket.connect

  cert = ssl_socket.peer_cert
  days_until_expiry = ((cert.not_after - Time.now) / 86400).to_i

  {
    hostname: hostname,
    expires_at: cert.not_after,
    days_remaining: days_until_expiry,
    expired: days_until_expiry < 0
  }
ensure
  ssl_socket&.close
  tcp_socket&.close
end

# 使用例
result = check_ssl_expiry("example.com")
if result[:days_remaining] < 30
  puts "⚠️  証明書の有効期限が近づいています: #{result[:days_remaining]}日"
end
```

## よくある間違い

### 間違い1: SSL証明書検証の無効化
```ruby
# ❌ セキュリティリスク
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # 危険！

# ✅ 適切な証明書検証
http.verify_mode = OpenSSL::SSL::VERIFY_PEER
```

### 間違い2: タイムアウト設定なし
```ruby
# ❌ タイムアウトなし（無限待機の可能性）
response = Net::HTTP.get(URI(url))

# ✅ タイムアウト設定
http = Net::HTTP.new(uri.host, uri.port)
http.open_timeout = 5
http.read_timeout = 10
response = http.get(uri.path)
```

### 間違い3: エラーハンドリング不足
```ruby
# ❌ エラーを無視
response = Net::HTTP.get_response(URI(url))
data = JSON.parse(response.body)

# ✅ 適切なエラー処理
begin
  response = Net::HTTP.get_response(URI(url))
  if response.code == "200"
    data = JSON.parse(response.body)
  else
    puts "Error: HTTP #{response.code}"
  end
rescue JSON::ParserError => e
  puts "JSON parse error: #{e.message}"
rescue => e
  puts "Request failed: #{e.message}"
end
```

## 実用的なワンライナー集

```bash
# APIヘルスチェック
ruby -rnet/http -e 'puts Net::HTTP.get_response(URI("https://api.example.com/health")).code=="200" ? "✅" : "❌"'

# Slack通知（環境変数からWebhook URL取得）
ruby -rnet/http -rjson -e 'u=URI(ENV["SLACK_WEBHOOK"]);r=Net::HTTP::Post.new(u,"Content-Type"=>"application/json");r.body={text:"Deploy OK"}.to_json;Net::HTTP.start(u.hostname,u.port,use_ssl:true){|h|h.request(r)}'

# Gemfile.lockのgem一覧とバージョン
ruby -e 'File.readlines("Gemfile.lock").each{|l| puts "#{$1}: #{$2}" if l=~/^    (\w+) \(([\d.]+)\)/}'

# SSL証明書の残日数
ruby -ropenssl -rsocket -e 't=TCPSocket.new("example.com",443);s=OpenSSL::SSL::SSLSocket.new(t);s.connect;d=((s.peer_cert.not_after-Time.now)/86400).to_i;puts "残#{d}日";s.close;t.close'

# APIレスポンスからデータ抽出
curl -s https://api.example.com/users | ruby -rjson -e 'data=JSON.parse(STDIN.read);puts data["data"]["users"].map{|u|u["name"]}'
```

## 高度なテクニック

### API監視システム
```ruby
class APIMonitor
  def initialize(endpoints)
    @endpoints = endpoints
  end

  def check_all
    results = @endpoints.map do |name, url|
      result = check_endpoint(url)
      { name: name, url: url }.merge(result)
    end

    report(results)
    alert_if_needed(results)
  end

  private

  def check_endpoint(url)
    start = Time.now
    response = Net::HTTP.get_response(URI(url))
    duration = ((Time.now - start) * 1000).to_i

    {
      status: response.code,
      ok: response.code == "200",
      duration_ms: duration
    }
  rescue => e
    { ok: false, error: e.message }
  end

  def report(results)
    results.each do |r|
      icon = r[:ok] ? "✅" : "❌"
      puts "#{icon} #{r[:name]}: #{r[:duration_ms]}ms"
    end
  end

  def alert_if_needed(results)
    failed = results.reject { |r| r[:ok] }
    if failed.any?
      send_alert("API failures: #{failed.map { |f| f[:name] }.join(', ')}")
    end
  end
end
```
