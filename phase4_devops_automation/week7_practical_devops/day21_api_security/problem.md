<div align="center">

# 🔐 Day 21: API連携とセキュリティ監査

[![難易度](https://img.shields.io/badge/難易度-🔴%20上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-50分-blue?style=flat-square)](#)

</div>

---

## 🎯 実用場面

**シチュエーション**: REST APIのテスト、Webhook通知の自動化、セキュリティ脆弱性のチェックを日常的に行う必要がある。

**問題**:
- APIテストを手動で実行するのは非効率
- 依存パッケージの脆弱性を手動チェックできない
- SSL証明書やSSH鍵の有効期限管理が煩雑

**解決**: Rubyワンライナーで API連携、セキュリティ監査を自動化！

## 📝 課題

REST API操作、Webhook通知、セキュリティ監査（依存関係、証明書、鍵管理）をワンライナーで実装してください。

### 🎯 期待する処理例
```bash
# API レスポンスの検証
REST API呼び出しとレスポンス解析

# Webhook 通知
Slack/Discordへの自動通知

# セキュリティ監査
Gemfile.lockの脆弱性チェック
SSL証明書の有効期限確認
```

## 💡 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `Net::HTTP` | HTTP通信 | ⭐⭐⭐⭐⭐ |
| `JSON.parse` | APIレスポンス解析 | ⭐⭐⭐⭐⭐ |
| `OpenSSL` | SSL証明書検証 | ⭐⭐⭐⭐ |
| `正規表現` | ログ・設定ファイル解析 | ⭐⭐⭐⭐ |

## 🚀 レベル別チャレンジ

### 🟢 基本レベル
APIの基本操作から始めましょう：

```ruby
# ヒント: この構造を完成させてください
require 'net/http'
require 'json'

uri = URI('https://api.example.com/users')
response = Net::HTTP.get(uri)
data = JSON.parse(response)
puts "Users: #{data.size}"
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `Net::HTTP.get` で簡単にGET リクエスト
- `Net::HTTP.post` でPOSTリクエスト
- レスポンスは文字列なので `JSON.parse` で変換

</details>

### 🟡 応用レベル

<details>
<summary><strong>1. Slack Webhook通知</strong></summary>

```ruby
require 'net/http'
require 'json'

def send_slack_notification(webhook_url, message)
  uri = URI(webhook_url)
  request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  request.body = { text: message }.to_json

  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
end

send_slack_notification(ENV['SLACK_WEBHOOK'], "デプロイ完了！")
```

</details>

<details>
<summary><strong>2. API健全性チェック</strong></summary>

```ruby
def check_api_health(endpoints)
  endpoints.each do |name, url|
    start_time = Time.now
    response = Net::HTTP.get_response(URI(url))
    duration = ((Time.now - start_time) * 1000).to_i

    if response.code == "200"
      puts "✅ #{name}: #{duration}ms"
    else
      puts "❌ #{name}: HTTP #{response.code}"
    end
  end
end

endpoints = {
  "API Server" => "https://api.example.com/health",
  "Database" => "https://api.example.com/db/ping"
}
check_api_health(endpoints)
```

</details>

<details>
<summary><strong>3. Gemfile.lock脆弱性チェック</strong></summary>

```ruby
# Gemfile.lockから脆弱なgemバージョンを検出
vulnerable_gems = {
  "rails" => { vulnerable: ["< 6.1.7"], cve: "CVE-2023-XXXX" },
  "nokogiri" => { vulnerable: ["< 1.13.10"], cve: "CVE-2022-XXXX" }
}

lockfile = File.read("Gemfile.lock")
vulnerable_gems.each do |gem_name, info|
  if lockfile =~ /#{gem_name} \(([\d.]+)\)/
    version = $1
    puts "#{gem_name} #{version} をチェック中..."
    # バージョン比較ロジック
  end
end
```

</details>

### 🔴 実務レベル

<details>
<summary><strong>包括的セキュリティ監査システム</strong></summary>

API監視、依存関係監査、SSL証明書チェック、SSH鍵管理を統合した自動化システムを1行で実装。

</details>

## 📊 実際の業務での使用例

- 🌐 **API監視** - エンドポイントの定期ヘルスチェック
- 📢 **通知自動化** - ビルド/デプロイ結果のSlack通知
- 🔒 **脆弱性検出** - 依存パッケージの自動スキャン
- 📅 **証明書管理** - SSL/SSH有効期限の監視

## 🛠️ 前提条件

このコースを実施するには以下が必要です：

- Ruby 3.0以上（Net::HTTP, OpenSSL標準ライブラリ）
- Webhook URL（Slack/Discord等）
- 基本的なHTTP/REST APIの理解

## 💡 実用ワンライナー例

```bash
# API ヘルスチェック
ruby -rnet/http -rjson -e 'r=Net::HTTP.get_response(URI("https://api.example.com/health")); puts r.code=="200" ? "✅ OK" : "❌ NG"'

# Slack通知
ruby -rnet/http -rjson -e 'uri=URI(ENV["SLACK_WEBHOOK"]); req=Net::HTTP::Post.new(uri,"Content-Type"=>"application/json"); req.body={text:"Deploy完了"}.to_json; Net::HTTP.start(uri.hostname,uri.port,use_ssl:true){|h| h.request(req)}'

# SSL証明書の有効期限確認
ruby -ropenssl -rnet/http -e 'tcp=TCPSocket.new("example.com",443); ssl=OpenSSL::SSL::SSLSocket.new(tcp); ssl.connect; cert=ssl.peer_cert; days=(cert.not_after-Time.now)/86400; puts "有効期限まで #{days.to_i}日"'

# Gemfile.lockのgem一覧
ruby -e 'File.readlines("Gemfile.lock").each{|l| puts $1 if l=~/^    (\w+) \(/}'
```

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
