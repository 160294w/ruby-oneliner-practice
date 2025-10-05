# ⚙️ SystemCtl サービス管理ワンライナー集

Linux システム管理で実際に使われているsystemctl運用ワンライナーを収録しました。

## サービス監視・状態確認

### 全サービスの健康状態チェック
```ruby
# 失敗状態のサービスを一覧表示
systemctl list-units --state=failed --no-pager | ruby -e 'STDIN.readlines[1..-2].each { |line| parts = line.strip.split; service = parts[0]; puts "❌ #{service}: #{parts[3..-1].join(" ")}" if parts[2] == "failed" }'
```

### 高負荷サービスの特定
```ruby
# CPU使用率でサービスをソート表示
systemctl list-units --type=service --state=running --no-pager | ruby -e 'services = STDIN.readlines[1..-2].map { |line| line.split[0] }; services.each { |service| cpu = `systemctl show #{service} --property=CPUUsageNSec --value`.strip.to_i; puts "#{service}: #{cpu / 1_000_000}ms CPU時間" if cpu > 0 }.sort'
```

### メモリ使用量の監視
```ruby
# メモリ使用量が多いサービスを特定
systemctl list-units --type=service --state=running --no-pager | ruby -e 'services = STDIN.readlines[1..-2].map { |line| line.split[0] }; memory_usage = []; services.each { |service| memory = `systemctl show #{service} --property=MemoryCurrent --value`.strip.to_i; memory_usage << [service, memory] if memory > 0 }; memory_usage.sort_by { |_, mem| -mem }.first(10).each { |service, mem| puts "#{service}: #{mem / 1024 / 1024}MB" }'
```

## 🚨 障害検出・自動復旧

### 異常なサービスの自動再起動
```ruby
# 失敗したサービスを自動で再起動
systemctl list-units --state=failed --no-pager | ruby -e 'STDIN.readlines[1..-2].each { |line| service = line.split[0]; puts "🔄 #{service} を再起動中..."; system("sudo systemctl restart #{service}"); status = `systemctl is-active #{service}`.strip; puts status == "active" ? "✅ #{service} 復旧成功" : "❌ #{service} 復旧失敗" }'
```

### サービス依存関係の確認
```ruby
# サービスの依存関係を表示
ruby -e 'service = ARGV[0] || "nginx"; puts "#{service} の依存関係:"; deps = `systemctl list-dependencies #{service} --plain --no-pager`.lines[1..]; deps.each { |dep| puts "  #{dep.strip}" }' nginx
```

### 再起動が必要なサービスの検出
```ruby
# 最近のログでエラーが多いサービスを特定
journalctl --since="1 hour ago" --priority=3 --no-pager | ruby -e 'services = {}; STDIN.readlines.each { |line| if match = line.match(/(\w+\.service)/); services[match[1]] = (services[match[1]] || 0) + 1; end }; puts "⚠️  過去1時間でエラーが多いサービス:"; services.sort_by { |_, count| -count }.first(5).each { |service, count| puts "  #{service}: #{count}件のエラー" }'
```

## パフォーマンス分析

### サービス起動時間の分析
```ruby
# 起動時間が遅いサービスを特定
systemd-analyze blame | ruby -e 'STDIN.readlines.first(10).each { |line| time, service = line.strip.split(" ", 2); puts "🐌 #{service}: #{time}" }'
```

### リソース使用状況のレポート
```ruby
# 全サービスのリソース使用状況をCSV形式で出力
systemctl list-units --type=service --state=running --no-pager | ruby -rcsv -e 'services = STDIN.readlines[1..-2].map { |line| line.split[0] }; CSV.open("service_resources.csv", "w") do |csv|; csv << ["Service", "Memory_MB", "CPU_Time_MS", "Tasks"]; services.each { |service| memory = `systemctl show #{service} --property=MemoryCurrent --value`.strip.to_i / 1024 / 1024; cpu = `systemctl show #{service} --property=CPUUsageNSec --value`.strip.to_i / 1_000_000; tasks = `systemctl show #{service} --property=TasksCurrent --value`.strip.to_i; csv << [service, memory, cpu, tasks] }; end; puts "✅ service_resources.csv を生成しました"'
```

### システム全体の稼働状況
```ruby
# システム稼働時間とサービス統計
systemctl list-units --type=service --no-pager | ruby -e 'lines = STDIN.readlines[1..-2]; total = lines.size; active = lines.count { |line| line.include?(" active ") }; failed = lines.count { |line| line.include?(" failed ") }; uptime = `uptime -p`.strip; puts "📊 システム稼働状況:"; puts "  稼働時間: #{uptime}"; puts "  サービス統計: #{active}/#{total} 稼働中, #{failed}件の障害"'
```

## 🔄 自動化・スケジューリング

### 定期的なサービス健康チェック
```ruby
# 重要サービスの死活監視
critical_services = %w[nginx mysql redis ssh]; critical_services.each { |service| status = `systemctl is-active #{service}`.strip; if status != "active"; puts "🚨 CRITICAL: #{service} が停止中"; system("sudo systemctl start #{service}"); new_status = `systemctl is-active #{service}`.strip; puts new_status == "active" ? "✅ #{service} 復旧完了" : "❌ #{service} 復旧失敗"; else; puts "✅ #{service} 正常稼働中"; end }
```

### ログローテーション後の処理
```ruby
# ログローテーション後にサービスをリロード
services_to_reload = %w[nginx apache2 rsyslog]; services_to_reload.each { |service| if `systemctl is-active #{service}`.strip == "active"; puts "🔄 #{service} をリロード中..."; system("sudo systemctl reload #{service}"); puts "✅ #{service} リロード完了"; end }
```

### 月次メンテナンスの自動化
```ruby
# 月次メンテナンス: ログクリーンアップとサービス再起動
ruby -e 'puts "🧹 月次メンテナンス開始 - #{Time.now}"; system("sudo journalctl --vacuum-time=30d"); puts "✅ ジャーナルログクリーンアップ完了"; maintenance_services = %w[logrotate rsyslog cron]; maintenance_services.each { |service| puts "🔄 #{service} 再起動中..."; system("sudo systemctl restart #{service}"); sleep 2; status = `systemctl is-active #{service}`.strip; puts status == "active" ? "✅ #{service} 再起動成功" : "❌ #{service} 再起動失敗" }; puts "🎉 月次メンテナンス完了"'
```

## ログ分析・トラブルシューティング

### エラーログの分析
```ruby
# 特定サービスの重要なエラーを抽出
service_name = ARGV[0] || "nginx"; journalctl -u #{service_name} --since="24 hours ago" --priority=0..3 --no-pager | ruby -e 'errors = {}; STDIN.readlines.each { |line| if match = line.match(/(error|critical|alert|emergency):\s*(.+)/i); error_type = match[1].downcase; message = match[2].strip; errors[message] = (errors[message] || 0) + 1; end }; puts "🔍 #{ARGV[0]} の過去24時間のエラー分析:"; errors.sort_by { |_, count| -count }.first(10).each { |msg, count| puts "  #{count}回: #{msg[0..80]}..." }'
```

### システムブート時の問題分析
```ruby
# ブート時に失敗したサービスを特定
journalctl --boot --priority=0..3 --no-pager | ruby -e 'boot_errors = []; STDIN.readlines.each { |line| if line.match(/Failed to start|Job .+ failed/); boot_errors << line.strip; end }; puts "🚨 ブート時の問題:"; boot_errors.uniq.each { |error| puts "  #{error}" }'
```

### パフォーマンス問題の調査
```ruby
# CPU・メモリ使用量が急増したサービスを特定
journalctl --since="1 hour ago" --no-pager | ruby -e 'performance_issues = {}; STDIN.readlines.each { |line| if match = line.match(/(\w+\.service).*(?:high cpu|memory|performance|slow)/i); service = match[1]; performance_issues[service] = (performance_issues[service] || 0) + 1; end }; puts "⚡ パフォーマンス問題のあるサービス:"; performance_issues.each { |service, count| puts "  #{service}: #{count}件の問題" }'
```

## 🔐 セキュリティ・監査

### 不審なサービス活動の監視
```ruby
# 異常な認証失敗やアクセスを検出
journalctl --since="1 hour ago" --no-pager | ruby -e 'security_events = {}; STDIN.readlines.each { |line| if line.match(/(authentication failure|invalid user|failed login|unauthorized)/i); if match = line.match(/(\w+\.service|\w+\[\d+\])/); service = match[1]; security_events[service] = (security_events[service] || 0) + 1; end; end }; puts "🔒 セキュリティ関連のイベント:"; security_events.each { |service, count| puts "  #{service}: #{count}件の認証関連イベント" }'
```

### サービス権限の監査
```ruby
# rootで実行されているサービスを一覧表示
systemctl list-units --type=service --state=running --no-pager | ruby -e 'services = STDIN.readlines[1..-2].map { |line| line.split[0] }; puts "🔐 root権限で実行中のサービス:"; services.each { |service| user = `systemctl show #{service} --property=User --value`.strip; if user.empty? || user == "root"; exec_main_pid = `systemctl show #{service} --property=ExecMainPID --value`.strip.to_i; if exec_main_pid > 0; process_user = `ps -o user= -p #{exec_main_pid}`.strip; puts "  #{service} (PID: #{exec_main_pid}, User: #{process_user})" if process_user == "root"; end; end }'
```

### ファイアウォール連携の確認
```ruby
# サービスが使用するポートとファイアウォール設定の整合性確認
systemctl list-units --type=service --state=running --no-pager | ruby -e 'services = STDIN.readlines[1..-2].map { |line| line.split[0] }; services.select { |s| s.match(/(nginx|apache|ssh|mysql)/) }.each { |service| puts "🔥 #{service} のポート確認:"; netstat_output = `netstat -tlnp 2>/dev/null | grep #{service}`; if !netstat_output.empty?; netstat_output.lines.each { |line| port = line.split[3].split(":").last; puts "  ポート #{port} でリッスン中" }; else; puts "  アクティブなポートが見つかりません"; end }'
```

## CI/CD・デプロイメント統合

### アプリケーションデプロイ後の検証
```ruby
# デプロイ後のサービス健康確認
app_services = %w[myapp nginx mysql redis]; puts "🚀 デプロイ後検証開始..."; all_healthy = true; app_services.each { |service| status = `systemctl is-active #{service}`.strip; if status == "active"; puts "✅ #{service}: 正常稼働"; sleep 1; recent_errors = `journalctl -u #{service} --since="5 minutes ago" --priority=0..3 --no-pager | wc -l`.strip.to_i; puts recent_errors > 0 ? "⚠️  #{service}: #{recent_errors}件の警告" : "✅ #{service}: エラーなし"; else; puts "❌ #{service}: 停止中"; all_healthy = false; end }; puts all_healthy ? "🎉 全サービス健全、デプロイ成功" : "🚨 問題が検出されました"'
```

### Blue-Greenデプロイメントのサービス切り替え
```ruby
# サービスの段階的切り替え
old_service = "myapp-blue"; new_service = "myapp-green"; puts "🔄 Blue-Green切り替え開始..."; system("sudo systemctl start #{new_service}"); sleep 5; new_status = `systemctl is-active #{new_service}`.strip; if new_status == "active"; puts "✅ #{new_service} 起動成功"; puts "🔄 負荷分散設定更新中..."; system("sudo systemctl reload nginx"); sleep 2; puts "🛑 #{old_service} 停止中..."; system("sudo systemctl stop #{old_service}"); puts "🎉 Blue-Green切り替え完了"; else; puts "❌ #{new_service} 起動失敗、切り替え中止"; end'
```

### ロールバック機能付きデプロイ
```ruby
# 自動ロールバック機能付きサービス更新
service_name = ARGV[0] || "myapp"; backup_time = Time.now.strftime("%Y%m%d_%H%M%S"); puts "💾 #{service_name} の設定をバックアップ中..."; system("sudo cp /etc/systemd/system/#{service_name}.service /etc/systemd/system/#{service_name}.service.backup.#{backup_time}"); puts "🔄 #{service_name} 再起動中..."; system("sudo systemctl daemon-reload && sudo systemctl restart #{service_name}"); sleep 10; status = `systemctl is-active #{service_name}`.strip; error_count = `journalctl -u #{service_name} --since="1 minute ago" --priority=0..3 --no-pager | wc -l`.strip.to_i; if status == "active" && error_count == 0; puts "✅ デプロイ成功"; else; puts "❌ 問題検出、ロールバック実行中..."; system("sudo cp /etc/systemd/system/#{service_name}.service.backup.#{backup_time} /etc/systemd/system/#{service_name}.service"); system("sudo systemctl daemon-reload && sudo systemctl restart #{service_name}"); puts "🔙 ロールバック完了"; end'
```

## 運用ベストプラクティス

### 1. 定期的なシステム健康チェック
```bash
# 毎5分実行でサービス監視
*/5 * * * * systemctl list-units --state=failed --no-pager | ruby -e 'failed = STDIN.readlines[1..-2]; if failed.any?; system("echo \"Failed services: #{failed.map { |l| l.split[0] }.join(\", \")}\" | mail -s \"Service Alert\" admin@example.com"); end'
```

### 2. 週次レポートの自動生成
```bash
# 毎週月曜日午前6時にレポート生成
0 6 * * 1 systemctl list-units --type=service --no-pager | ruby -e 'puts "Weekly Service Report - #{Date.today}"; puts STDIN.read' > /var/log/weekly-service-report.log
```

### 3. システムリソース監視
```ruby
# ディスク・メモリ・CPU使用率の包括的チェック
ruby -e 'puts "📊 システムリソース監視レポート - #{Time.now}"; disk_usage = `df -h / | tail -1`.split[4].to_i; memory_usage = `free | grep Mem | awk \"{printf \"%.0f\", \\$3/\\$2*100}\"`.to_i; cpu_load = `uptime`.match(/load average: ([^,]+)/)[1].to_f; puts "ディスク使用率: #{disk_usage}%"; puts "メモリ使用率: #{memory_usage}%"; puts "CPU負荷: #{cpu_load}"; alerts = []; alerts << "ディスク使用率が高い (#{disk_usage}%)" if disk_usage > 80; alerts << "メモリ使用率が高い (#{memory_usage}%)" if memory_usage > 80; alerts << "CPU負荷が高い (#{cpu_load})" if cpu_load > 2.0; if alerts.any?; puts "🚨 アラート:"; alerts.each { |alert| puts "  #{alert}" }; else; puts "✅ 全システムリソースが正常範囲内"; end'
```

## ⚠️ 注意事項

1. **sudo権限が必要なコマンドは適切な権限で実行してください**
2. **本番環境でのサービス再起動は事前に影響を確認してください**
3. **重要なサービスの設定変更前は必ずバックアップを取ってください**
4. **ログ分析時は機密情報の漏洩に注意してください**
5. **自動化スクリプトは十分にテストしてから運用してください**

---

**これらのワンライナーでLinuxシステムサービスの運用効率を大幅に向上させることができます。**