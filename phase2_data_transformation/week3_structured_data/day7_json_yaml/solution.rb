# Day 7: JSON/YAML データ変換 - 解答例

require 'json'
require 'yaml'

puts "=== 基本レベル解答 ==="
# 基本: JSON → YAML変換
json_data = JSON.parse(File.read("sample_data/users.json"))
puts "JSON → YAML変換:"
puts YAML.dump(json_data[0]) # 最初のユーザーのみ表示

puts "\n=== 応用レベル解答 ==="

# 応用1: 条件フィルタリング（30歳以上）
puts "30歳以上のユーザー:"
senior_users = json_data.select { |user| user["age"] >= 30 }
puts YAML.dump(senior_users.map { |u| { name: u["name"], age: u["age"], department: u["department"] } })

# 応用2: 必要なフィールドのみ抽出
puts "\n名前とメールのみ抽出:"
simple_users = json_data.map { |u| { name: u["name"], email: u["email"] } }
puts JSON.pretty_generate(simple_users)

# 応用3: ネストデータの展開（全スキル一覧）
puts "\n全ユーザーのスキル一覧:"
all_skills = json_data.flat_map { |u| u.dig("profile", "skills") }.compact.uniq.sort
puts YAML.dump(all_skills)

# 応用4: 部門別グループ化
puts "\n部門別ユーザー数:"
dept_count = json_data.group_by { |u| u["department"] }.transform_values(&:size)
puts YAML.dump(dept_count)

puts "\n=== 実務レベル解答 ==="

# 実務1: YAML設定ファイルの読み込みと環境別変換
config = YAML.load_file("sample_data/config.yaml")
puts "本番環境用設定生成:"
production_config = config.dup
production_config["application"]["environment"] = "production"
production_config["database"]["host"] = "prod-db.example.com"
production_config["features"]["debug"] = false
production_config["features"]["caching"] = true

puts JSON.pretty_generate(production_config)

# 実務2: 複数ファイルの設定マージ
puts "\n設定ファイルマージ例:"
base_config = { "app" => { "name" => "MyApp", "debug" => true } }
env_config = { "app" => { "debug" => false }, "database" => { "host" => "prod-db" } }
merged = base_config.merge(env_config) { |key, old, new| new.is_a?(Hash) ? old.merge(new) : new }
puts YAML.dump(merged)

# 実務3: データ検索・抽出
puts "\nDocker経験者の検索:"
docker_users = json_data.select { |u| u.dig("profile", "skills")&.include?("Docker") }
puts docker_users.map { |u| "#{u['name']} (#{u['department']})" }.join(", ")

puts "\n🚀 ワンライナー版:"

# 超短縮版コレクション
puts "JSON→YAML: " + YAML.dump(JSON.parse(File.read("sample_data/users.json")).first)

puts "30歳以上抽出: " + JSON.parse(File.read("sample_data/users.json")).select { |u| u["age"] >= 30 }.map { |u| u["name"] }.join(", ")

puts "全スキル: " + JSON.parse(File.read("sample_data/users.json")).flat_map { |u| u.dig("profile", "skills") }.uniq.sort.join(", ")

# 設定ファイル本番化
puts "本番設定: " + YAML.load_file("sample_data/config.yaml").tap { |c| c["application"]["environment"] = "production"; c["features"]["debug"] = false }.to_yaml

puts "\n💡 実用ワンライナー例:"
puts <<~EXAMPLES
  # Kubernetes ConfigMap生成
  kubectl create configmap app-config --from-literal="config.yaml=$(ruby -ryaml -rjson -e 'puts YAML.dump(JSON.parse(STDIN.read))' < config.json)"

  # 環境変数を設定ファイルに注入
  ruby -ryaml -e 'config = YAML.load_file("config.yaml"); config["database"]["password"] = ENV["DB_PASSWORD"]; puts YAML.dump(config)'

  # JSONログの特定フィールド抽出
  cat app.log | ruby -rjson -ne 'begin; data = JSON.parse($_); puts "#{data["timestamp"]}: #{data["message"]}" if data["level"] == "ERROR"; rescue; end'
EXAMPLES