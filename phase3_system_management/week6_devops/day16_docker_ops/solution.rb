# Day 16: Docker運用管理ワンライナー - 解答例

puts "=== 基本レベル解答 ==="
# 基本: 実行中コンテナの状態表示
puts "実行中のコンテナ一覧:"
containers = `docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`.lines
containers.each { |line| puts line.strip }

puts "\n=== 応用レベル解答 ==="

# 応用1: 異常コンテナの検出
puts "異常状態のコンテナ検出:"
all_containers = `docker ps -a --format "{{.Names}},{{.Status}},{{.Image}}"`.lines
abnormal_containers = all_containers.select do |line|
  status = line.split(',')[1]
  status.include?("Exited") || status.include?("Dead") || status.include?("Paused")
end

if abnormal_containers.any?
  abnormal_containers.each { |container| puts "⚠️  #{container.strip}" }
else
  puts "✅ 全コンテナが正常に動作中"
end

# 応用2: リソース使用量の監視（シミュレート）
puts "\n高リソース使用コンテナの検出（シミュレート）:"
# 実際の環境では: docker stats --no-stream を使用
sample_stats = [
  "web-server,45.2%,256MB/1GB",
  "database,78.9%,512MB/2GB",
  "redis-cache,23.1%,128MB/512MB",
  "api-gateway,67.3%,384MB/1GB"
]

high_resource_containers = sample_stats.select do |stat|
  cpu_usage = stat.split(',')[1].to_f
  cpu_usage > 60.0
end

high_resource_containers.each { |container| puts "🔥 高CPU使用: #{container}" }

# 応用3: Docker イメージのクリーンアップ候補
puts "\n未使用イメージの検出:"
all_images = `docker images --format "{{.Repository}},{{.Tag}},{{.Size}}"`.lines
dangling_images = `docker images -f "dangling=true" -q`.lines
puts "削除候補のイメージ数: #{dangling_images.size}個"

puts "\n=== 実務レベル解答 ==="

# 実務1: 包括的なコンテナ健康チェック
puts "コンテナ健康診断レポート:"

def container_health_check
  report = {
    running: 0,
    stopped: 0,
    errors: [],
    high_resource: [],
    warnings: []
  }

  # 実行中コンテナ数
  running_containers = `docker ps -q`.lines.size
  all_containers = `docker ps -a -q`.lines.size

  report[:running] = running_containers
  report[:stopped] = all_containers - running_containers

  # 異常コンテナチェック（シミュレート）
  if report[:stopped] > 0
    report[:warnings] << "#{report[:stopped]}個のコンテナが停止中"
  end

  # ディスク使用量チェック
  system_df = `docker system df 2>/dev/null || echo "Images,0,0\nContainers,0,0\nLocal Volumes,0,0"`.lines
  images_line = system_df.find { |line| line.start_with?("Images") }
  if images_line && images_line.include?("GB")
    report[:warnings] << "イメージサイズが大きくなっています"
  end

  report
end

health = container_health_check
puts "実行中: #{health[:running]}個, 停止中: #{health[:stopped]}個"
health[:warnings].each { |warning| puts "⚠️  #{warning}" }

# 実務2: ログ分析（エラー検出）
puts "\nコンテナログからエラー検出（シミュレート）:"
sample_logs = [
  "[ERROR] Database connection failed",
  "[INFO] Request processed successfully",
  "[ERROR] Memory allocation failed",
  "[WARN] High CPU usage detected",
  "[INFO] Container started"
]

error_logs = sample_logs.select { |log| log.include?("[ERROR]") }
warn_logs = sample_logs.select { |log| log.include?("[WARN]") }

puts "🔴 エラー数: #{error_logs.size}"
error_logs.each { |log| puts "   #{log}" }
puts "🟡 警告数: #{warn_logs.size}"

# 実務3: Docker環境の最適化提案
puts "\n最適化提案:"
optimization_tips = [
  "未使用イメージの削除: docker image prune -a",
  "停止コンテナの削除: docker container prune",
  "未使用ボリュームの削除: docker volume prune",
  "ビルドキャッシュの削除: docker builder prune"
]

optimization_tips.each { |tip| puts "💡 #{tip}" }

puts "\n🚀 実用ワンライナー例:"

puts <<~ONELINERS
# 異常コンテナのslack通知
ruby -e 'containers = `docker ps -a --format "{{.Names}},{{.Status}}"`.lines.select { |l| l.include?("Exited") }; system("curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"異常コンテナ: #{containers.join(\", \")}\"" 'YOUR_SLACK_WEBHOOK' if containers.any?"

# リソース使用率TOP3
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | ruby -e 'puts STDIN.readlines[1..].sort_by { |line| line.split[1].to_f }.reverse[0..2]'

# 全コンテナのログエラー集約
docker ps --format "{{.Names}}" | ruby -e 'STDIN.readlines.each { |name| puts "=== #{name.strip} ==="; system("docker logs #{name.strip} 2>&1 | grep ERROR | tail -5") }'

# Docker環境の一括クリーンアップ
ruby -e 'puts "クリーンアップ中..."; %w[container image volume network].each { |type| system("docker #{type} prune -f") }; puts "完了"'

# CPU使用率90%以上のコンテナを自動再起動（危険：本番使用注意）
docker stats --no-stream --format "{{.Container}},{{.CPUPerc}}" | ruby -e 'STDIN.readlines.each { |line| name, cpu = line.strip.split(","); system("docker restart #{name}") if cpu.to_f > 90.0 }'
ONELINERS

puts "\n📋 運用チェックリスト:"
checklist = [
  "コンテナの健康状態確認",
  "リソース使用量監視",
  "エラーログの確認",
  "ディスク使用量チェック",
  "セキュリティアップデート確認",
  "バックアップ状況確認"
]

checklist.each_with_index { |item, i| puts "#{i+1}. [ ] #{item}" }

puts "\n🎯 本番運用での注意点:"
puts "- 自動再起動スクリプトは十分にテストしてから使用"
puts "- リソース監視の閾値は環境に応じて調整"
puts "- ログ分析は正規表現でより精密にフィルタリング"
puts "- 定期実行はcronジョブで自動化"