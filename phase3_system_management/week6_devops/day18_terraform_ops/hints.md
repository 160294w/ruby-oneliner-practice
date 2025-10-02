# Day 18: ヒントとステップガイド

## 🔍 段階的に考えてみよう

### Step 1: Terraform状態の基本取得
```ruby
require 'json'

# terraform show -json で状態をJSON形式で取得
state_json = `terraform show -json`
state = JSON.parse(state_json)

# リソース一覧へのアクセス
resources = state["values"]["root_module"]["resources"] || []
```

### Step 2: リソースの基本情報表示
```ruby
# リソースタイプと名前の一覧
resources.each do |resource|
  puts "#{resource['type']}.#{resource['name']}"
end

# リソース数のカウント
puts "総リソース数: #{resources.size}"
```

### Step 3: リソースタイプ別の集計
```ruby
# タイプ別にグループ化
by_type = resources.group_by { |r| r["type"] }

# タイプごとの件数を表示
by_type.each do |type, res_list|
  puts "#{type}: #{res_list.size}件"
end
```

## 💡 よく使うパターン

### パターン1: tfstateファイルの直接読み込み
```ruby
require 'json'

# terraform.tfstateファイルを直接読み込み
if File.exist?("terraform.tfstate")
  state = JSON.parse(File.read("terraform.tfstate"))
  resources = state["resources"] || []

  # tfstate形式では構造が異なる
  resources.each do |resource|
    resource["instances"].each do |instance|
      puts "#{resource['type']}.#{resource['name']}"
      # attributes にリソースの詳細情報
      attrs = instance["attributes"]
    end
  end
end
```

### パターン2: セキュリティグループの監査
```ruby
# AWSセキュリティグループの検査
security_groups = resources.select { |r|
  r["type"] == "aws_security_group"
}

security_groups.each do |sg|
  name = sg["name"]
  values = sg["values"]

  # インバウンドルールの検査
  ingress_rules = values["ingress"] || []
  ingress_rules.each do |rule|
    cidr_blocks = rule["cidr_blocks"] || []

    if cidr_blocks.include?("0.0.0.0/0")
      from_port = rule["from_port"]
      to_port = rule["to_port"]
      protocol = rule["protocol"]

      puts "⚠️  #{name}: 0.0.0.0/0 から #{protocol}/#{from_port}-#{to_port} が開放"
    end
  end
end
```

### パターン3: リソース依存関係の分析
```ruby
# depends_onを解析
resources_with_deps = resources.select { |r|
  r["depends_on"]&.any?
}

puts "依存関係があるリソース:"
resources_with_deps.each do |resource|
  deps = resource["depends_on"]
  puts "#{resource['address']}:"
  deps.each { |dep| puts "  → #{dep}" }
end
```

## 🚫 よくある間違い

### 間違い1: terraform showとtfstateの構造の違い
```ruby
# ❌ terraform show -jsonとtfstateの構造を混同
state = JSON.parse(File.read("terraform.tfstate"))
resources = state["values"]["root_module"]["resources"]  # nilになる

# ✅ それぞれの構造に合わせる
# terraform show -json の場合
show_output = JSON.parse(`terraform show -json`)
resources = show_output["values"]["root_module"]["resources"]

# terraform.tfstate の場合
tfstate = JSON.parse(File.read("terraform.tfstate"))
resources = tfstate["resources"]
```

### 間違い2: モジュール内のリソースを見逃す
```ruby
# ❌ ルートモジュールのリソースのみ
resources = state["values"]["root_module"]["resources"]

# ✅ 子モジュールも含める
def get_all_resources(module_data, resources = [])
  resources += module_data["resources"] || []

  child_modules = module_data["child_modules"] || []
  child_modules.each do |child|
    get_all_resources(child, resources)
  end

  resources
end

all_resources = get_all_resources(state["values"]["root_module"])
```

### 間違い3: null値の考慮不足
```ruby
# ❌ null値でエラー
ingress_rules = sg["values"]["ingress"].each { ... }  # nilの場合エラー

# ✅ null値を考慮
ingress_rules = sg["values"]["ingress"] || []
ingress_rules.each { |rule| ... }
```

## 🎯 応用のヒント

### IAMポリシーの監査
```ruby
# IAMポリシーの過度な権限を検出
iam_policies = resources.select { |r|
  r["type"] == "aws_iam_policy" || r["type"] == "aws_iam_role_policy"
}

iam_policies.each do |policy|
  policy_doc = policy["values"]["policy"]

  # JSON文字列の場合はパース
  if policy_doc.is_a?(String)
    policy_doc = JSON.parse(policy_doc)
  end

  statements = policy_doc["Statement"] || []
  statements.each do |stmt|
    actions = stmt["Action"] || []
    resources = stmt["Resource"] || []

    # ワイルドカード権限の検出
    if actions.include?("*") || actions.any? { |a| a.end_with?(":*") }
      if resources.include?("*")
        puts "🚨 #{policy['name']}: 全リソースへの広範な権限が付与されています"
      end
    end
  end
end
```

### コスト分析
```ruby
# リソースタイプ別のコスト見積もり（簡易版）
COST_ESTIMATES = {
  "aws_instance" => { base: 50, unit: "month" },
  "aws_db_instance" => { base: 100, unit: "month" },
  "aws_s3_bucket" => { base: 1, unit: "month" },
  "aws_lb" => { base: 20, unit: "month" }
}

total_cost = 0
cost_breakdown = {}

resources.each do |resource|
  type = resource["type"]
  if COST_ESTIMATES[type]
    cost = COST_ESTIMATES[type][:base]
    total_cost += cost
    cost_breakdown[type] ||= 0
    cost_breakdown[type] += cost
  end
end

puts "月額コスト見積もり:"
cost_breakdown.sort_by { |_, cost| -cost }.each do |type, cost|
  puts "  #{type}: $#{cost}"
end
puts "合計: $#{total_cost}/月"
```

### 変更影響分析（terraform plan）
```ruby
# terraform plan -json で変更内容を解析
plan_json = `terraform plan -json`
changes = plan_json.lines.map { |line|
  JSON.parse(line) rescue nil
}.compact

# 変更タイプ別の集計
change_summary = {
  create: [],
  update: [],
  delete: [],
  replace: []
}

changes.each do |change|
  next unless change["type"] == "resource_drift" || change["type"] == "planned_change"

  if change_info = change["change"]
    actions = change_info["actions"]
    resource_address = change_info["resource"]["addr"]

    case actions
    when ["create"]
      change_summary[:create] << resource_address
    when ["update"]
      change_summary[:update] << resource_address
    when ["delete"]
      change_summary[:delete] << resource_address
    when ["delete", "create"]
      change_summary[:replace] << resource_address
    end
  end
end

puts "変更サマリー:"
change_summary.each do |action, resources|
  next if resources.empty?
  puts "  #{action.upcase}: #{resources.size}件"
  resources.each { |r| puts "    - #{r}" }
end
```

### タグポリシーの検証
```ruby
# 必須タグの確認
REQUIRED_TAGS = ["Environment", "Owner", "CostCenter"]

resources_without_tags = []

resources.each do |resource|
  # タグをサポートするリソースタイプのみチェック
  next unless resource["values"]["tags"]

  tags = resource["values"]["tags"] || {}
  missing_tags = REQUIRED_TAGS - tags.keys

  if missing_tags.any?
    resources_without_tags << {
      resource: "#{resource['type']}.#{resource['name']}",
      missing_tags: missing_tags
    }
  end
end

if resources_without_tags.any?
  puts "⚠️  必須タグが不足しているリソース:"
  resources_without_tags.each do |item|
    puts "  #{item[:resource]}"
    puts "    不足: #{item[:missing_tags].join(', ')}"
  end
end
```

## 🔧 デバッグのコツ

### JSON構造の確認
```ruby
# 状態ファイルの構造を確認
def explore_json(obj, indent = 0)
  case obj
  when Hash
    obj.each do |key, value|
      puts "  " * indent + "#{key}: #{value.class}"
      explore_json(value, indent + 1) if value.is_a?(Hash) || value.is_a?(Array)
    end
  when Array
    puts "  " * indent + "[#{obj.size} items]"
    explore_json(obj.first, indent + 1) if obj.any?
  end
end

state = JSON.parse(`terraform show -json`)
explore_json(state)
```

### 特定リソースの詳細表示
```ruby
# リソースの全属性を表示
def show_resource_details(resource_type, resource_name)
  state = JSON.parse(`terraform show -json`)
  resources = state["values"]["root_module"]["resources"] || []

  resource = resources.find { |r|
    r["type"] == resource_type && r["name"] == resource_name
  }

  if resource
    puts "=== #{resource_type}.#{resource_name} ==="
    puts JSON.pretty_generate(resource["values"])
  else
    puts "リソースが見つかりません"
  end
end

# 使用例
show_resource_details("aws_instance", "web_server")
```

### 差分の可視化
```ruby
# 2つのtfstate間の差分を表示
def compare_states(old_state_path, new_state_path)
  old_state = JSON.parse(File.read(old_state_path))
  new_state = JSON.parse(File.read(new_state_path))

  old_resources = old_state["resources"].map { |r|
    "#{r['type']}.#{r['name']}"
  }.to_set

  new_resources = new_state["resources"].map { |r|
    "#{r['type']}.#{r['name']}"
  }.to_set

  added = new_resources - old_resources
  removed = old_resources - new_resources
  unchanged = old_resources & new_resources

  puts "追加: #{added.size}件"
  added.each { |r| puts "  + #{r}" }

  puts "\n削除: #{removed.size}件"
  removed.each { |r| puts "  - #{r}" }

  puts "\n変更なし: #{unchanged.size}件"
end
```

## 📋 実用的なワンライナー集

```bash
# 全リソースの一覧
terraform show -json | ruby -rjson -e 'puts JSON.parse(STDIN.read)["values"]["root_module"]["resources"].map { |r| "#{r["type"]}.#{r["name"]}" }'

# リソースタイプ別の集計
terraform show -json | ruby -rjson -e 'puts JSON.parse(STDIN.read)["values"]["root_module"]["resources"].group_by { |r| r["type"] }.transform_values(&:size)'

# セキュリティグループの0.0.0.0/0開放を検出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); state["values"]["root_module"]["resources"].select { |r| r["type"] == "aws_security_group" }.each { |sg| (sg["values"]["ingress"] || []).each { |rule| puts "⚠️ #{sg["name"]}: #{rule["from_port"]}-#{rule["to_port"]}" if (rule["cidr_blocks"] || []).include?("0.0.0.0/0") } }'

# IAMポリシーの"*"権限を検出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); state["values"]["root_module"]["resources"].select { |r| r["type"] =~ /aws_iam/ }.each { |p| policy = p["values"]["policy"]; policy_doc = policy.is_a?(String) ? JSON.parse(policy) : policy; (policy_doc["Statement"] || []).each { |s| puts "🚨 #{p["name"]}: Wildcard permissions" if (s["Action"] || []).include?("*") && (s["Resource"] || []).include?("*") } }'

# タグが付いていないリソースを検出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); state["values"]["root_module"]["resources"].each { |r| puts "⚠️ #{r["type"]}.#{r["name"]}: No tags" if r["values"]["tags"].nil? || r["values"]["tags"].empty? }'

# リソースの依存関係を可視化
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); state["values"]["root_module"]["resources"].each { |r| next unless r["depends_on"]; puts "#{r["address"]}:"; r["depends_on"].each { |d| puts "  → #{d}" } }'

# terraform planの変更サマリー
terraform plan -json | ruby -rjson -e 'actions = {"create" => 0, "update" => 0, "delete" => 0}; STDIN.each_line { |line| change = JSON.parse(line) rescue nil; next unless change && change["type"] == "planned_change"; (change["change"]["actions"] || []).each { |a| actions[a] += 1 if actions.key?(a) } }; actions.each { |k, v| puts "#{k.upcase}: #{v}" }'

# S3バケットのパブリックアクセス設定を確認
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); state["values"]["root_module"]["resources"].select { |r| r["type"] == "aws_s3_bucket" }.each { |b| acl = b["values"]["acl"]; puts "⚠️ #{b["name"]}: Public bucket (#{acl})" if acl =~ /public/ }'
```

## 🎯 高度なテクニック

### 包括的なセキュリティ監査スクリプト
```ruby
#!/usr/bin/env ruby
require 'json'

class TerraformSecurityAuditor
  def initialize(state_file = nil)
    if state_file
      @state = JSON.parse(File.read(state_file))
      @resources = @state["resources"]
    else
      state_json = `terraform show -json`
      @state = JSON.parse(state_json)
      @resources = @state["values"]["root_module"]["resources"] || []
    end

    @findings = []
  end

  def audit
    check_security_groups
    check_iam_policies
    check_s3_buckets
    check_encryption
    check_tags

    generate_report
  end

  private

  def check_security_groups
    sgs = @resources.select { |r| r["type"] == "aws_security_group" }

    sgs.each do |sg|
      ingress = sg["values"]["ingress"] || []
      ingress.each do |rule|
        if (rule["cidr_blocks"] || []).include?("0.0.0.0/0")
          @findings << {
            severity: "HIGH",
            resource: "#{sg['type']}.#{sg['name']}",
            issue: "0.0.0.0/0 からのアクセスが許可されています",
            port: "#{rule['from_port']}-#{rule['to_port']}"
          }
        end
      end
    end
  end

  def check_iam_policies
    policies = @resources.select { |r|
      r["type"] =~ /aws_iam.*policy/
    }

    policies.each do |policy|
      policy_doc = policy["values"]["policy"]
      policy_doc = JSON.parse(policy_doc) if policy_doc.is_a?(String)

      (policy_doc["Statement"] || []).each do |stmt|
        actions = [stmt["Action"]].flatten
        resources = [stmt["Resource"]].flatten

        if actions.include?("*") && resources.include?("*")
          @findings << {
            severity: "CRITICAL",
            resource: "#{policy['type']}.#{policy['name']}",
            issue: "全リソースへの全権限が付与されています"
          }
        end
      end
    end
  end

  def check_s3_buckets
    buckets = @resources.select { |r| r["type"] == "aws_s3_bucket" }

    buckets.each do |bucket|
      acl = bucket["values"]["acl"]
      if acl =~ /public/
        @findings << {
          severity: "HIGH",
          resource: "#{bucket['type']}.#{bucket['name']}",
          issue: "S3バケットがパブリックアクセス可能です"
        }
      end
    end
  end

  def check_encryption
    # RDSの暗号化チェック
    dbs = @resources.select { |r| r["type"] == "aws_db_instance" }

    dbs.each do |db|
      unless db["values"]["storage_encrypted"]
        @findings << {
          severity: "MEDIUM",
          resource: "#{db['type']}.#{db['name']}",
          issue: "ストレージが暗号化されていません"
        }
      end
    end
  end

  def check_tags
    required_tags = ["Environment", "Owner", "CostCenter"]

    @resources.each do |resource|
      next unless resource["values"]["tags"]

      tags = resource["values"]["tags"] || {}
      missing = required_tags - tags.keys

      if missing.any?
        @findings << {
          severity: "LOW",
          resource: "#{resource['type']}.#{resource['name']}",
          issue: "必須タグが不足: #{missing.join(', ')}"
        }
      end
    end
  end

  def generate_report
    puts "=" * 60
    puts "Terraform セキュリティ監査レポート"
    puts "生成日時: #{Time.now}"
    puts "=" * 60

    by_severity = @findings.group_by { |f| f[:severity] }

    ["CRITICAL", "HIGH", "MEDIUM", "LOW"].each do |severity|
      findings = by_severity[severity] || []
      next if findings.empty?

      puts "\n#{severity} (#{findings.size}件):"
      findings.each do |finding|
        puts "  ⚠️  #{finding[:resource]}"
        puts "      #{finding[:issue]}"
        puts "      #{finding[:port]}" if finding[:port]
      end
    end

    puts "\n" + "=" * 60
    puts "総検出数: #{@findings.size}件"
  end
end

# 実行
auditor = TerraformSecurityAuditor.new
auditor.audit
```

### コスト最適化レポート
```ruby
class TerraformCostOptimizer
  INSTANCE_COSTS = {
    "t2.micro" => 0.0116,
    "t2.small" => 0.023,
    "t2.medium" => 0.0464,
    "t3.micro" => 0.0104,
    "t3.small" => 0.0208,
    # ... more instance types
  }

  def analyze(state_json)
    state = JSON.parse(state_json)
    resources = state["values"]["root_module"]["resources"] || []

    instances = resources.select { |r| r["type"] == "aws_instance" }

    puts "コスト最適化の推奨事項:"

    instances.each do |instance|
      instance_type = instance["values"]["instance_type"]
      cost_per_hour = INSTANCE_COSTS[instance_type] || 0

      # t2 → t3への移行を提案
      if instance_type.start_with?("t2.")
        t3_equivalent = instance_type.sub("t2.", "t3.")
        t3_cost = INSTANCE_COSTS[t3_equivalent]

        if t3_cost && t3_cost < cost_per_hour
          savings = (cost_per_hour - t3_cost) * 730  # 月額
          puts "💡 #{instance['name']}: #{instance_type} → #{t3_equivalent}"
          puts "   月額 $#{'%.2f' % savings} の削減が可能"
        end
      end
    end
  end
end
```
