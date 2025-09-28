# 🏗️ Terraform運用ワンライナー集

Infrastructure as Codeの運用で実際に使われているTerraformワンライナーを収録しました。

## 🔍 状態管理・監査

### tfstateファイルの分析
```ruby
# tfstateから全リソースの一覧を抽出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); resources = state["values"]["root_module"]["resources"] || []; resources.each { |r| puts "#{r["type"]}.#{r["name"]}: #{r["values"]["id"] || "N/A"}" }'
```

### リソース間の依存関係分析
```ruby
# リソースの依存関係をグラフ形式で表示
terraform graph | ruby -e 'STDIN.readlines.each { |line| if line.match(/\"(.+)\"\s*->\s*\"(.+)\"/); puts "#{$1} → #{$2}"; end }'
```

### 使用されていないリソースの特定
```ruby
# terraform planで削除予定のリソースを抽出
terraform plan -no-color | ruby -e 'in_destroy = false; STDIN.readlines.each { |line| if line.include?("will be destroyed"); in_destroy = true; resource = line.match(/# (.+) will be destroyed/)[1]; puts "🗑️  削除予定: #{resource}"; elsif line.match(/^[[:space:]]*#/) || line.strip.empty?; next; else; in_destroy = false; end }'
```

## 💰 コスト分析・最適化

### AWS EC2インスタンスのコスト分析
```ruby
# EC2インスタンスタイプ別の月額コスト概算（簡易版）
terraform show -json | ruby -rjson -e 'costs = {"t3.micro" => 8.5, "t3.small" => 17, "t3.medium" => 34, "m5.large" => 70, "m5.xlarge" => 140}; state = JSON.parse(STDIN.read); ec2s = (state["values"]["root_module"]["resources"] || []).select { |r| r["type"] == "aws_instance" }; total = 0; ec2s.each { |ec2| instance_type = ec2["values"]["instance_type"]; cost = costs[instance_type] || 50; puts "#{ec2["name"]} (#{instance_type}): $#{cost}/月"; total += cost }; puts "総計: $#{total}/月"'
```

### 未使用のElastic IPの検出
```ruby
# 割り当てられていないElastic IPを特定
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); eips = (state["values"]["root_module"]["resources"] || []).select { |r| r["type"] == "aws_eip" }; unattached = eips.select { |eip| !eip["values"]["instance"] }; unattached.each { |eip| puts "💰 未使用EIP: #{eip["values"]["public_ip"]} (月額 $3.6)" }'
```

### RDSインスタンスの使用率分析
```ruby
# RDSインスタンスのサイズと推定コスト
terraform show -json | ruby -rjson -e 'rds_costs = {"db.t3.micro" => 15, "db.t3.small" => 30, "db.m5.large" => 150}; state = JSON.parse(STDIN.read); rdss = (state["values"]["root_module"]["resources"] || []).select { |r| r["type"] == "aws_db_instance" }; rdss.each { |rds| instance_class = rds["values"]["instance_class"]; cost = rds_costs[instance_class] || 100; puts "#{rds["name"]} (#{instance_class}): $#{cost}/月" }'
```

## 🔄 デプロイメント・自動化

### 変更影響の事前分析
```ruby
# terraform planの変更をカテゴリ別に分類
terraform plan -no-color | ruby -e 'changes = {create: [], update: [], destroy: []}; STDIN.readlines.each { |line| if line.match(/# (.+) will be created/); changes[:create] << $1; elsif line.match(/# (.+) will be updated/); changes[:update] << $1; elsif line.match(/# (.+) will be destroyed/); changes[:destroy] << $1; end }; puts "📊 変更サマリー:"; changes.each { |type, resources| puts "  #{type}: #{resources.size}件"; resources.each { |r| puts "    - #{r}" } }'
```

### 環境別設定の自動切り替え
```ruby
# 環境変数に基づくworkspaceとtfvarsの自動選択
ruby -e 'env = ENV["DEPLOY_ENV"] || "dev"; puts "🌍 環境: #{env}"; system("terraform workspace select #{env}"); var_file = "#{env}.tfvars"; if File.exist?(var_file); system("terraform plan -var-file=#{var_file}"); puts "✅ #{env}環境でプラン実行完了"; else; puts "❌ #{var_file}が見つかりません"; exit 1; end'
```

### 安全なデプロイメント実行
```ruby
# 承認フローを含む自動デプロイ
ruby -e 'plan_file = "tfplan-#{Time.now.strftime(\"%Y%m%d-%H%M%S\")}"; puts "📋 デプロイプラン生成中..."; system("terraform plan -out=#{plan_file}"); print "🤔 このプランを適用しますか？ (yes/no): "; approval = STDIN.gets.chomp; if approval.downcase == "yes"; system("terraform apply #{plan_file}"); puts "✅ デプロイ完了"; File.delete(plan_file); else; puts "❌ デプロイをキャンセルしました"; end'
```

## 🔍 設定ファイル管理

### HCL設定の構文チェック
```ruby
# 全tfファイルの構文チェックと問題検出
Dir.glob("**/*.tf") | ruby -e 'STDIN.readlines.each { |file| file = file.strip; result = `terraform fmt -check #{file} 2>&1`; if $?.exitstatus != 0; puts "🔧 フォーマット修正必要: #{file}"; system("terraform fmt #{file}"); puts "✅ 修正完了: #{file}"; end }'
```

### モジュールの依存関係分析
```ruby
# moduleブロックの使用状況を分析
Dir.glob("**/*.tf").each { |file| content = File.read(file); modules = content.scan(/module\s+"([^"]+)"\s*{[^}]*source\s*=\s*"([^"]+)"/m); modules.each { |name, source| puts "#{File.basename(file)}: #{name} -> #{source}" } }
```

### 変数定義の一覧化
```ruby
# variables.tfから全変数の定義と説明を抽出
ruby -e 'content = File.read("variables.tf"); variables = content.scan(/variable\s+"([^"]+)"\s*{([^}]+)}/m); variables.each { |name, block| description = block.match(/description\s*=\s*"([^"]+)"/); type = block.match(/type\s*=\s*(\w+)/); puts "#{name}: #{type ? type[1] : "string"} - #{description ? description[1] : "説明なし"}" }'
```

## 🔐 セキュリティ・ベストプラクティス

### ハードコードされたシークレットの検出
```ruby
# .tfファイル内のハードコードされた機密情報を検出
Dir.glob("**/*.tf").each { |file| content = File.read(file); secrets = content.scan(/(password|secret|key)\s*=\s*"([^"]{8,})"/i); secrets.each { |type, value| puts "🚨 #{file}: #{type} がハードコード (#{value[0..5]}...)" } }
```

### IAMポリシーの権限監査
```ruby
# IAMポリシーで過大な権限を持つリソースを検出
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); iam_policies = (state["values"]["root_module"]["resources"] || []).select { |r| r["type"] == "aws_iam_policy" }; iam_policies.each { |policy| policy_doc = JSON.parse(policy["values"]["policy"]); statements = policy_doc["Statement"]; risky = statements.select { |s| s["Effect"] == "Allow" && (s["Action"] == "*" || s["Resource"] == "*") }; puts "⚠️  #{policy["name"]}: 過大権限の可能性" if risky.any? }'
```

### 暗号化設定の確認
```ruby
# S3バケットとRDSの暗号化設定を確認
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); resources = state["values"]["root_module"]["resources"] || []; s3_buckets = resources.select { |r| r["type"] == "aws_s3_bucket" }; rds_instances = resources.select { |r| r["type"] == "aws_db_instance" }; s3_buckets.each { |bucket| encryption = bucket["values"]["server_side_encryption_configuration"]; puts "S3 #{bucket["name"]}: #{encryption ? "✅暗号化済み" : "❌暗号化なし"}" }; rds_instances.each { |rds| encrypted = rds["values"]["storage_encrypted"]; puts "RDS #{rds["name"]}: #{encrypted ? "✅暗号化済み" : "❌暗号化なし"}" }'
```

## 📊 レポート・ドキュメント生成

### インフラ構成図の生成
```ruby
# 現在のインフラ構成をMarkdown表形式で出力
terraform show -json | ruby -rjson -e 'state = JSON.parse(STDIN.read); resources = state["values"]["root_module"]["resources"] || []; puts "# インフラ構成レポート"; puts "| リソースタイプ | 名前 | ID |"; puts "|---|---|---|"; resources.each { |r| puts "| #{r["type"]} | #{r["name"]} | #{r["values"]["id"] || "N/A"} |" }'
```

### コスト見積もりレポート
```ruby
# 月額コスト見積もりをCSV形式で出力
terraform show -json | ruby -rjson -rcsv -e 'costs = {"aws_instance" => {"t3.micro" => 8.5}, "aws_rds_instance" => {"db.t3.micro" => 15}}; state = JSON.parse(STDIN.read); CSV.open("cost_estimate.csv", "w") do |csv|; csv << ["Resource", "Type", "Instance", "Monthly_Cost"]; (state["values"]["root_module"]["resources"] || []).each { |r| resource_costs = costs[r["type"]]; if resource_costs; instance_type = r["values"]["instance_type"] || r["values"]["instance_class"]; cost = resource_costs[instance_type] || 0; csv << [r["name"], r["type"], instance_type, cost]; end }; end; puts "✅ cost_estimate.csv を生成しました"'
```

### 変更履歴の追跡
```ruby
# git logとterraform logを組み合わせた変更追跡
ruby -e 'commits = `git log --oneline --since="1 month ago" -- "*.tf" "*.tfvars"`.lines; puts "📅 過去1ヶ月のTerraform変更履歴:"; commits.each { |commit| hash, message = commit.strip.split(" ", 2); changed_files = `git diff-tree --no-commit-id --name-only -r #{hash}`.lines.map(&:strip).select { |f| f.end_with?(".tf", ".tfvars") }; puts "#{hash[0..7]}: #{message}"; changed_files.each { |file| puts "  - #{file}" } }'
```

## 🔄 CI/CD統合

### GitOpsワークフローの自動化
```ruby
# Pull Request時の自動terraform plan実行
ruby -e 'if ENV["CI"] == "true"; target_branch = ENV["GITHUB_BASE_REF"] || "main"; current_branch = ENV["GITHUB_HEAD_REF"] || `git branch --show-current`.strip; puts "🔍 #{current_branch} -> #{target_branch} のTerraform差分チェック"; system("terraform plan -no-color > plan_output.txt"); plan_summary = `grep -E "(Plan:|No changes)" plan_output.txt`.strip; puts "📊 プランサマリー: #{plan_summary}"; system("cat plan_output.txt >> $GITHUB_STEP_SUMMARY") if ENV["GITHUB_STEP_SUMMARY"]; end'
```

### 本番デプロイ前の最終確認
```ruby
# 本番環境デプロイ前のチェックリスト実行
ruby -e 'checks = [["terraform validate", "設定ファイル検証"], ["terraform plan", "変更プラン確認"], ["git diff --name-only HEAD~1", "変更ファイル確認"]]; all_passed = true; checks.each { |command, description| puts "⏳ #{description}..."; result = system("#{command} > /dev/null 2>&1"); if result; puts "✅ #{description}: 成功"; else; puts "❌ #{description}: 失敗"; all_passed = false; end }; if all_passed; puts "🚀 本番デプロイ準備完了"; else; puts "🛑 問題があります。デプロイを中止してください"; exit 1; end'
```

## 💡 運用ベストプラクティス

### 1. 定期的な状態監査
```bash
# 毎日午前6時に実行
0 6 * * * cd /path/to/terraform && terraform plan -detailed-exitcode > /dev/null 2>&1 && echo "Terraform状態: 同期済み" || echo "Terraform状態: ドリフト検出" | mail -s "Terraform Status" admin@example.com
```

### 2. バックアップの自動化
```ruby
# tfstateのS3バックアップ
ruby -e 'backup_key = "terraform-state-backup/#{Time.now.strftime(\"%Y/%m/%d\")}/terraform.tfstate"; system("aws s3 cp terraform.tfstate s3://my-terraform-backups/#{backup_key}"); puts "✅ tfstateバックアップ完了: #{backup_key}"'
```

### 3. ドキュメントの自動更新
```ruby
# terraform-docsを使ったREADME自動更新
ruby -e 'modules = Dir.glob("modules/*/"); modules.each { |module_dir| puts "📝 #{module_dir}のドキュメント更新中..."; system("cd #{module_dir} && terraform-docs markdown table --output-file README.md ."); puts "✅ #{module_dir}README.md更新完了" }'
```

## ⚠️ 注意事項

1. **tfstateファイルは必ずバックアップしてください**
2. **本番環境では必ずterraform planで事前確認してください**
3. **機密情報はterraform.tfvarsやSecrets Managerを使用してください**
4. **リモートバックエンド（S3等）を使用してください**
5. **terraform lockファイルは必ずバージョン管理に含めてください**

---

**これらのワンライナーでTerraformの運用効率を大幅に向上させることができます。**