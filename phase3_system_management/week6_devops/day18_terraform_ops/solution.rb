# Day 18: Terraform運用管理ワンライナー - 解答例

require 'json'

puts "=== 基本レベル解答 ==="
# 基本: tfstateからリソース一覧を取得

if File.exist?("sample_data/tfstate.json")
  state = JSON.parse(File.read("sample_data/tfstate.json"))
else
  puts "⚠️ sample_data/tfstate.json が見つかりません"
  puts "シミュレーションデータを使用します\n"

  # シミュレーションデータ
  state = {
    "values" => {
      "root_module" => {
        "resources" => [
          {
            "type" => "aws_instance",
            "name" => "web_server",
            "values" => {
              "id" => "i-1234567890abcdef0",
              "instance_type" => "t3.medium",
              "tags" => { "Name" => "WebServer", "Environment" => "production" }
            }
          },
          {
            "type" => "aws_security_group",
            "name" => "web_sg",
            "values" => {
              "id" => "sg-0123456789abcdef0",
              "ingress" => [
                { "from_port" => 80, "to_port" => 80, "protocol" => "tcp", "cidr_blocks" => ["0.0.0.0/0"] },
                { "from_port" => 22, "to_port" => 22, "protocol" => "tcp", "cidr_blocks" => ["0.0.0.0/0"] }
              ]
            }
          }
        ]
      }
    }
  }
end

resources = state.dig("values", "root_module", "resources") || []

puts "管理中のリソース一覧:"
resources.each do |resource|
  resource_id = "#{resource['type']}.#{resource['name']}"
  real_id = resource.dig('values', 'id') || 'N/A'
  puts "  #{resource_id} (ID: #{real_id})"
end

puts "\n=== 応用レベル解答 ==="

# 応用1: リソースタイプ別集計
puts "リソースタイプ別集計:"
by_type = resources.group_by { |r| r["type"] }

by_type.sort_by { |type, list| -list.size }.each do |type, list|
  puts "  #{type}: #{list.size}個"
  list.each { |r| puts "    - #{r['name']}" }
end

# 応用2: タグ付けの確認
puts "\nタグ付け状況:"
resources_with_tags = resources.select { |r| r.dig("values", "tags") }
resources_without_tags = resources.reject { |r| r.dig("values", "tags") }

puts "✅ タグ付き: #{resources_with_tags.size}個"
if resources_without_tags.any?
  puts "⚠️ タグなし: #{resources_without_tags.size}個"
  resources_without_tags.each do |r|
    puts "    - #{r['type']}.#{r['name']}"
  end
end

# 応用3: セキュリティグループ監査
puts "\nセキュリティグループ監査:"
security_groups = resources.select { |r| r["type"] == "aws_security_group" }

security_groups.each do |sg|
  sg_name = sg["name"]
  ingress_rules = sg.dig("values", "ingress") || []

  # 0.0.0.0/0からのアクセスを許可しているルールを検出
  open_rules = ingress_rules.select do |rule|
    cidr_blocks = rule["cidr_blocks"] || []
    cidr_blocks.include?("0.0.0.0/0")
  end

  if open_rules.any?
    puts "🚨 #{sg_name}:"
    open_rules.each do |rule|
      port_range = rule["from_port"] == rule["to_port"] ?
                   rule["from_port"] :
                   "#{rule['from_port']}-#{rule['to_port']}"
      puts "  ⚠️ ポート#{port_range}/#{rule['protocol']} が 0.0.0.0/0 に公開"
    end
  else
    puts "✅ #{sg_name}: 問題なし"
  end
end

puts "\n=== 実務レベル解答 ==="

# 実務1: 包括的なインフラ分析レポート
puts "包括的インフラ分析レポート:"

def analyze_infrastructure(state)
  resources = state.dig("values", "root_module", "resources") || []

  report = {
    total_resources: resources.size,
    by_type: Hash.new(0),
    security_issues: [],
    cost_warnings: [],
    tagging_compliance: { compliant: 0, non_compliant: 0 },
    regions: Hash.new(0)
  }

  resources.each do |resource|
    # タイプ別集計
    report[:by_type][resource["type"]] += 1

    # タグ付けコンプライアンス
    if resource.dig("values", "tags")
      report[:tagging_compliance][:compliant] += 1
    else
      report[:tagging_compliance][:non_compliant] += 1
    end

    # セキュリティ問題検出
    if resource["type"] == "aws_security_group"
      ingress = resource.dig("values", "ingress") || []
      ingress.each do |rule|
        if (rule["cidr_blocks"] || []).include?("0.0.0.0/0")
          report[:security_issues] << {
            type: "open_security_group",
            resource: "#{resource['type']}.#{resource['name']}",
            detail: "ポート#{rule['from_port']}が全世界に公開"
          }
        end
      end
    end

    # S3バケット公開設定チェック
    if resource["type"] == "aws_s3_bucket"
      acl = resource.dig("values", "acl")
      if acl == "public-read" || acl == "public-read-write"
        report[:security_issues] << {
          type: "public_s3_bucket",
          resource: "#{resource['type']}.#{resource['name']}",
          detail: "バケットが公開設定 (ACL: #{acl})"
        }
      end
    end

    # コスト警告（大きいインスタンス）
    if resource["type"] == "aws_instance"
      instance_type = resource.dig("values", "instance_type")
      if instance_type =~ /^(m5|c5|r5)\.(2xlarge|4xlarge|8xlarge)/
        report[:cost_warnings] << {
          resource: "#{resource['type']}.#{resource['name']}",
          detail: "大型インスタンス使用: #{instance_type}"
        }
      end
    end

    # リージョン分布
    region = resource.dig("values", "availability_zone")&.match(/^([a-z]+-[a-z]+-\d+)/)&.[](1) ||
             resource.dig("values", "region") || "unknown"
    report[:regions][region] += 1
  end

  report
end

report = analyze_infrastructure(state)

puts "\n📊 インフラストラクチャサマリー:"
puts "  総リソース数: #{report[:total_resources]}"
puts "  リソースタイプ数: #{report[:by_type].size}"

puts "\n📋 リソースタイプ内訳:"
report[:by_type].sort_by { |_, count| -count }.first(10).each do |type, count|
  puts "  #{type}: #{count}個"
end

puts "\n🏷️ タグ付けコンプライアンス:"
total = report[:tagging_compliance][:compliant] + report[:tagging_compliance][:non_compliant]
compliance_rate = total > 0 ? (report[:tagging_compliance][:compliant].to_f / total * 100).round(1) : 0
puts "  準拠率: #{compliance_rate}%"
puts "  準拠: #{report[:tagging_compliance][:compliant]}個"
puts "  非準拠: #{report[:tagging_compliance][:non_compliant]}個"

if report[:security_issues].any?
  puts "\n🚨 セキュリティ問題:"
  report[:security_issues].each do |issue|
    puts "  [#{issue[:type]}] #{issue[:resource]}"
    puts "    → #{issue[:detail]}"
  end
else
  puts "\n✅ セキュリティ問題なし"
end

if report[:cost_warnings].any?
  puts "\n💰 コスト最適化の提案:"
  report[:cost_warnings].each do |warning|
    puts "  #{warning[:resource]}"
    puts "    → #{warning[:detail]}"
  end
end

puts "\n🌍 リージョン分布:"
report[:regions].each do |region, count|
  puts "  #{region}: #{count}リソース"
end

# 実務2: terraform planの変更分析
puts "\n変更分析（terraform plan出力の解析）:"

# サンプルのplan出力を読み込み
plan_output = if File.exist?("sample_data/plan_output.txt")
  File.read("sample_data/plan_output.txt")
else
  <<~PLAN
    Terraform will perform the following actions:

      # aws_instance.web_server will be updated in-place
      ~ resource "aws_instance" "web_server" {
            id            = "i-1234567890abcdef0"
          ~ instance_type = "t3.small" -> "t3.medium"
            tags          = {
                "Name" = "WebServer"
            }
        }

      # aws_security_group.db_sg will be created
      + resource "aws_security_group" "db_sg" {
          + id          = (known after apply)
          + name        = "database-sg"
          + ingress {
              + from_port   = 3306
              + to_port     = 3306
              + protocol    = "tcp"
              + cidr_blocks = ["10.0.0.0/8"]
            }
        }

      # aws_instance.old_server will be destroyed
      - resource "aws_instance" "old_server" {
          - id            = "i-9876543210fedcba0"
          - instance_type = "t2.micro"
        }

    Plan: 1 to add, 1 to change, 1 to destroy.
  PLAN
end

changes = {
  create: [],
  update: [],
  destroy: [],
  replace: []
}

plan_output.lines.each do |line|
  if line =~ /# (.+) will be created/
    changes[:create] << $1
  elsif line =~ /# (.+) will be updated/
    changes[:update] << $1
  elsif line =~ /# (.+) will be destroyed/
    changes[:destroy] << $1
  elsif line =~ /# (.+) must be replaced/
    changes[:replace] << $1
  end
end

puts "\n📊 変更サマリー:"
puts "  追加: #{changes[:create].size}個"
puts "  変更: #{changes[:update].size}個"
puts "  削除: #{changes[:destroy].size}個"
puts "  置換: #{changes[:replace].size}個"

changes.each do |type, resources|
  next if resources.empty?

  icon = case type
         when :create then "➕"
         when :update then "🔄"
         when :destroy then "🗑️"
         when :replace then "♻️"
         end

  puts "\n#{icon} #{type.to_s.upcase}:"
  resources.each { |r| puts "  - #{r}" }
end

# リスク評価
puts "\n⚠️ リスク評価:"
if changes[:destroy].any?
  puts "  HIGH: #{changes[:destroy].size}個のリソースが削除されます"
  puts "  → 削除前にバックアップを確認してください"
end

if changes[:replace].any?
  puts "  MEDIUM: #{changes[:replace].size}個のリソースが置換されます"
  puts "  → ダウンタイムが発生する可能性があります"
end

if changes[:update].any?
  puts "  LOW: #{changes[:update].size}個のリソースが更新されます"
end

if changes.values.all?(&:empty?)
  puts "  ✅ 変更なし"
end

# 実務3: コンプライアンスチェック
puts "\nコンプライアンスチェック:"

compliance_rules = [
  {
    name: "すべてのリソースにNameタグが必要",
    check: ->(resources) {
      resources.select { |r|
        tags = r.dig("values", "tags") || {}
        !tags.key?("Name")
      }
    }
  },
  {
    name: "本番環境リソースにEnvironmentタグが必要",
    check: ->(resources) {
      resources.select { |r|
        tags = r.dig("values", "tags") || {}
        tags["Environment"] == "production" && tags["Owner"].nil?
      }
    }
  },
  {
    name: "セキュリティグループで22番ポートを0.0.0.0/0に公開禁止",
    check: ->(resources) {
      resources.select { |r|
        next false unless r["type"] == "aws_security_group"
        ingress = r.dig("values", "ingress") || []
        ingress.any? { |rule|
          rule["from_port"] == 22 &&
          (rule["cidr_blocks"] || []).include?("0.0.0.0/0")
        }
      }
    }
  }
]

compliance_results = compliance_rules.map do |rule|
  violations = rule[:check].call(resources)
  {
    rule: rule[:name],
    compliant: violations.empty?,
    violations: violations
  }
end

compliance_results.each do |result|
  if result[:compliant]
    puts "✅ #{result[:rule]}"
  else
    puts "❌ #{result[:rule]}"
    result[:violations].each do |violation|
      puts "    - #{violation['type']}.#{violation['name']}"
    end
  end
end

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# tfstateから全EC2インスタンスのIDとタイプを抽出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); (state.dig("values", "root_module", "resources") || []).select { |r| r["type"] == "aws_instance" }.each { |ec2| puts "#{ec2["name"]}: #{ec2.dig("values", "instance_type")} (#{ec2.dig("values", "id")})" }'

# 0.0.0.0/0に公開されているセキュリティグループを検出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); (state.dig("values", "root_module", "resources") || []).select { |r| r["type"] == "aws_security_group" }.each { |sg| ingress = sg.dig("values", "ingress") || []; open = ingress.select { |rule| (rule["cidr_blocks"] || []).include?("0.0.0.0/0") }; puts "🚨 #{sg["name"]}: ポート#{open.map { |r| r["from_port"] }.join(", ")}が公開" if open.any? }'

# タグ付けされていないリソースを検出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); (state.dig("values", "root_module", "resources") || []).reject { |r| r.dig("values", "tags") }.each { |r| puts "⚠️ #{r["type"]}.#{r["name"]}" }'

# terraform planの変更を分類して集計
terraform plan -no-color | ruby -e 'changes = {add: 0, change: 0, destroy: 0}; STDIN.readlines.each { |l| changes[:add] += 1 if l.include?("will be created"); changes[:change] += 1 if l.include?("will be updated"); changes[:destroy] += 1 if l.include?("will be destroyed") }; puts "追加:#{changes[:add]} 変更:#{changes[:change]} 削除:#{changes[:destroy]}"'

# リソースタイプ別のコスト概算（EC2のみ簡易版）
terraform show -json | ruby -rjson -e 'costs = {"t3.micro" => 8.5, "t3.small" => 17, "t3.medium" => 34, "m5.large" => 70}; state = JSON.parse(STDIN.read); total = 0; (state.dig("values", "root_module", "resources") || []).select { |r| r["type"] == "aws_instance" }.each { |ec2| type = ec2.dig("values", "instance_type"); cost = costs[type] || 50; puts "#{ec2["name"]} (#{type}): $#{cost}/月"; total += cost }; puts "総計: $#{total}/月"'

# 依存関係グラフをシンプルに表示
terraform graph | ruby -e 'STDIN.readlines.each { |l| puts "#{$1} → #{$2}" if l =~ /"(.+)"\s*->\s*"(.+)"/ }'

# 本番環境のリソースのみ抽出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); (state.dig("values", "root_module", "resources") || []).select { |r| r.dig("values", "tags", "Environment") == "production" }.each { |r| puts "#{r["type"]}.#{r["name"]}" }'
ONELINERS

puts "\n📋 Terraform運用チェックリスト:"
checklist = [
  "terraform planで変更内容を確認",
  "セキュリティグループの公開ルール監査",
  "全リソースのタグ付けコンプライアンス確認",
  "コスト最適化の余地確認",
  "terraform state listで管理リソース確認",
  "tfstateファイルのバックアップ確認",
  "破壊的変更のリスク評価"
]

checklist.each_with_index { |item, i| puts "#{i+1}. [ ] #{item}" }

puts "\n🎯 本番運用での注意点:"
puts "- terraform applyの前に必ずplanで確認"
puts "- 破壊的変更（destroy/replace）は特に慎重に"
puts "- tfstateファイルは必ずリモートバックエンド（S3等）で管理"
puts "- セキュリティグループは定期的に監査"
puts "- タグ付けルールを組織で統一し、コンプライアンスチェックを自動化"
puts "- コスト分析を定期実行し、無駄なリソースを削減"
