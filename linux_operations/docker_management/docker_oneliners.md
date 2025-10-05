# 🐳 Docker運用ワンライナー集

実際のDevOps現場で使われているDocker運用ワンライナーを厳選しました。

## コンテナ監視

### 異常コンテナの検出・通知
```ruby
# 停止中または異常なコンテナをSlackに通知
ruby -rjson -e 'containers = `docker ps -a --format "{{.Names}},{{.Status}}"`.lines.select { |l| !l.include?("Up") }; system(%Q{curl -X POST -H "Content-type: application/json" --data "{\\"text\\":\\"異常コンテナ: #{containers.map(&:strip).join(", \\")}\\"}" YOUR_SLACK_WEBHOOK}) if containers.any?'
```

### リソース使用率の監視
```ruby
# CPU使用率80%以上のコンテナを特定
docker stats --no-stream --format "{{.Container}},{{.CPUPerc}},{{.MemUsage}}" | ruby -e 'STDIN.readlines.each { |line| name, cpu, mem = line.strip.split(","); puts "🔥 #{name}: CPU #{cpu}, Memory #{mem}" if cpu.to_f > 80.0 }'
```

### メモリ使用量アラート
```ruby
# メモリ使用量が1GB以上のコンテナを警告
docker stats --no-stream --format "{{.Container}},{{.MemUsage}}" | ruby -e 'STDIN.readlines.each { |line| name, mem = line.strip.split(","); usage = mem.split("/")[0]; puts "⚠️  #{name}: #{usage}" if usage.include?("GiB") && usage.to_f > 1.0 }'
```

## ログ分析

### エラーログの一括収集
```ruby
# 全コンテナから過去1時間のエラーログを抽出
docker ps --format "{{.Names}}" | ruby -e 'STDIN.readlines.each { |name| puts "=== #{name.strip} ==="; system("docker logs --since=1h #{name.strip} 2>&1 | grep -i error | tail -5") }'
```

### アクセスログの解析
```ruby
# Nginxコンテナの5xxエラーをカウント
docker logs nginx-container | ruby -e 'errors = STDIN.readlines.count { |line| line.match(/\s5\d\d\s/) }; puts "5xxエラー数: #{errors}"'
```

### ログのJSON解析
```ruby
# 構造化ログからエラーレベルを抽出
docker logs app-container | ruby -rjson -ne 'begin; data = JSON.parse($_); puts "#{data["timestamp"]}: #{data["message"]}" if data["level"] == "ERROR"; rescue; end'
```

## 🧹 メンテナンス

### 未使用リソースの一括削除
```ruby
# 未使用イメージ、コンテナ、ネットワーク、ボリュームを削除
ruby -e 'puts "🧹 Docker クリーンアップ開始..."; %w[container image volume network].each { |type| puts "#{type} 削除中..."; system("docker #{type} prune -f") }; puts "✅ クリーンアップ完了"'
```

### 古いイメージの削除
```ruby
# 7日以上前のイメージを削除
docker images --format "{{.Repository}},{{.Tag}},{{.CreatedAt}}" | ruby -e 'require "time"; STDIN.readlines.each { |line| repo, tag, created = line.strip.split(","); next if repo == "<none>"; if Time.parse(created) < Time.now - 7*24*3600; system("docker rmi #{repo}:#{tag}"); puts "削除: #{repo}:#{tag}"; end }'
```

### ログファイルのローテーション
```ruby
# 大きくなったコンテナログの確認
docker ps --format "{{.Names}}" | ruby -e 'STDIN.readlines.each { |name| log_path = "/var/lib/docker/containers/$(docker inspect --format=\"{{.Id}}\" #{name.strip})/#{name.strip}-json.log"; size = `ls -lh "#{log_path}" 2>/dev/null | awk \"{print \\$5}\"`.strip; puts "#{name.strip}: #{size}" if !size.empty? && size.match(/[0-9]+[GM]/) }'
```

## 自動化

### ヘルスチェック失敗時の自動再起動
```ruby
# unhealthyなコンテナを自動再起動
docker ps --format "{{.Names}},{{.Status}}" | ruby -e 'STDIN.readlines.each { |line| name, status = line.strip.split(","); if status.include?("unhealthy"); puts "🔄 再起動中: #{name}"; system("docker restart #{name}"); end }'
```

### 動的なコンテナスケーリング
```ruby
# CPU使用率に基づく自動スケーリング（水平スケーリング例）
docker stats --no-stream nginx --format "{{.CPUPerc}}" | ruby -e 'cpu = STDIN.read.strip.to_f; if cpu > 80; puts "🚀 スケールアウト実行"; system("docker run -d --name nginx-#{Time.now.to_i} nginx"); elsif cpu < 20; extra = `docker ps --filter name=nginx- --format \"{{.Names}}\"`.lines[1]; system("docker stop #{extra.strip}") if extra; end'
```

### 環境別設定の動的生成
```ruby
# 環境変数に基づくDockerコンテナ起動
ruby -e 'env = ENV["RAILS_ENV"] || "development"; db_host = env == "production" ? "prod-db.example.com" : "localhost"; system("docker run -e DATABASE_HOST=#{db_host} -e RAILS_ENV=#{env} --name app-#{env} my-app:latest")'
```

## 高度な運用

### マルチステージビルドの最適化分析
```ruby
# ビルド時間とサイズの分析
docker images --format "{{.Repository}},{{.Tag}},{{.Size}},{{.CreatedAt}}" | ruby -e 'require "time"; STDIN.readlines.each { |line| repo, tag, size, created = line.strip.split(","); next if repo == "<none>"; age_days = (Time.now - Time.parse(created)) / 86400; puts "#{repo}:#{tag} - #{size} (#{age_days.round}日前)" if age_days < 30 }'
```

### セキュリティスキャン結果の解析
```ruby
# Docker securityスキャン結果をSeverity別に集計
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image my-app:latest --format json | ruby -rjson -e 'data = JSON.parse(STDIN.read); vulnerabilities = data["Results"][0]["Vulnerabilities"] || []; severity_count = vulnerabilities.group_by { |v| v["Severity"] }.transform_values(&:count); puts "🔒 セキュリティスキャン結果:"; severity_count.each { |sev, count| puts "  #{sev}: #{count}件" }'
```

### ネットワーク使用量の監視
```ruby
# コンテナ間通信の監視
docker network ls --format "{{.Name}}" | ruby -e 'STDIN.readlines.each { |network| puts "=== #{network.strip} ==="; containers = `docker network inspect #{network.strip} --format "{{range .Containers}}{{.Name}} {{end}}"`.strip; puts "接続中コンテナ: #{containers.empty? ? "なし" : containers}" }'
```

## 運用のベストプラクティス

### 1. 定期的な健康チェック
```bash
# crontabに追加（毎5分実行）
*/5 * * * * ruby -e 'abnormal = `docker ps -a --format "{{.Names}},{{.Status}}"`.lines.select { |l| l.include?("Exited") }; system("echo \"異常コンテナ: #{abnormal.join(\", \")}\" | mail -s \"Docker Alert\" admin@example.com") if abnormal.any?'
```

### 2. リソース使用量の監視
```bash
# 毎時実行でリソースレポート生成
0 * * * * docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | ruby -e 'puts "#{Time.now}: Docker Resource Report"; puts STDIN.read' >> /var/log/docker-resources.log
```

### 3. 自動バックアップ
```ruby
# 重要なコンテナのボリュームバックアップ
ruby -e 'containers = %w[database redis]; containers.each { |name| backup_file = "/backup/#{name}-#{Time.now.strftime(\"%Y%m%d\")}.tar"; system("docker run --rm -v #{name}_data:/data -v /backup:/backup alpine tar czf #{backup_file} /data"); puts "✅ #{name} バックアップ完了: #{backup_file}" }'
```

## ⚠️ 注意事項

1. **本番環境での使用前に十分テストしてください**
2. **自動再起動スクリプトは慎重に設計してください**
3. **リソース監視の閾値は環境に応じて調整してください**
4. **セキュリティ情報を含むログは適切に保護してください**

---

**これらのワンライナーを組み合わせることで、Dockerの運用効率を大幅に向上させることができます。**