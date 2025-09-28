# ☸️ Kubernetes運用ワンライナー集

Kubernetes運用で実際に使われている効率的なワンライナーを収録しました。

## 🔍 Pod・Service監視

### 異常Pod状態の一括確認
```ruby
# Running以外の全Podを検出してNamespace別に表示
kubectl get pods --all-namespaces -o json | ruby -rjson -e 'data = JSON.parse(STDIN.read); abnormal = data["items"].select { |pod| pod["status"]["phase"] != "Running" }; abnormal.group_by { |pod| pod["metadata"]["namespace"] }.each { |ns, pods| puts "#{ns}: #{pods.map { |p| p["metadata"]["name"] }.join(\", \")}" }'
```

### Pod再起動回数の監視
```ruby
# 再起動回数が多いPodを特定（5回以上）
kubectl get pods --all-namespaces -o json | ruby -rjson -e 'data = JSON.parse(STDIN.read); high_restart = data["items"].select { |pod| pod["status"]["containerStatuses"]&.any? { |c| c["restartCount"] > 5 } }; high_restart.each { |pod| puts "🔄 #{pod["metadata"]["namespace"]}/#{pod["metadata"]["name"]}: #{pod["status"]["containerStatuses"][0]["restartCount"]}回再起動" }'
```

### PendingなPodの原因分析
```ruby
# PendingなPodの詳細情報を抽出
kubectl get pods --all-namespaces --field-selector=status.phase=Pending -o json | ruby -rjson -e 'data = JSON.parse(STDIN.read); data["items"].each { |pod| events = `kubectl describe pod #{pod["metadata"]["name"]} -n #{pod["metadata"]["namespace"]} | grep -A 5 Events`; puts "#{pod["metadata"]["name"]}: #{events.split(\"\n\").last}" }'
```

## 📊 リソース分析

### Namespace別リソース使用状況
```ruby
# CPU・Memory使用量をNamespace別に集計
kubectl top pods --all-namespaces | ruby -e 'lines = STDIN.readlines[1..]; usage = {}; lines.each { |line| ns, name, cpu, mem = line.strip.split; usage[ns] ||= {cpu: 0, mem: 0}; usage[ns][:cpu] += cpu.to_i; usage[ns][:mem] += mem.to_i }; usage.each { |ns, res| puts "#{ns}: CPU #{res[:cpu]}m, Memory #{res[:mem]}Mi" }'
```

### ノード別Pod配置状況
```ruby
# 各ノードのPod配置数とリソース使用率
kubectl get pods --all-namespaces -o wide | ruby -e 'lines = STDIN.readlines[1..]; node_pods = {}; lines.each { |line| parts = line.strip.split; node = parts[6]; node_pods[node] = (node_pods[node] || 0) + 1 }; node_pods.each { |node, count| puts "#{node}: #{count} pods" }'
```

### リソース制限の監査
```ruby
# リソース制限が設定されていないPodを特定
kubectl get pods --all-namespaces -o json | ruby -rjson -e 'data = JSON.parse(STDIN.read); no_limits = data["items"].select { |pod| pod["spec"]["containers"].any? { |c| !c["resources"] || (!c["resources"]["limits"] && !c["resources"]["requests"]) } }; no_limits.each { |pod| puts "⚠️  #{pod["metadata"]["namespace"]}/#{pod["metadata"]["name"]}: リソース制限なし" }'
```

## 🔧 ConfigMap・Secret管理

### 環境別ConfigMapの動的生成
```ruby
# 環境変数に基づくConfigMap作成
ruby -ryaml -e 'env = ARGV[0] || "dev"; config = {"database" => {"host" => env == "prod" ? "prod-db.cluster.local" : "dev-db.cluster.local", "port" => 5432}, "redis" => {"host" => "#{env}-redis.cluster.local"}}; puts YAML.dump({"apiVersion" => "v1", "kind" => "ConfigMap", "metadata" => {"name" => "app-config-#{env}"}, "data" => {"config.yaml" => YAML.dump(config)}})' production
```

### Secret情報の安全な更新
```ruby
# 既存SecretをBase64デコードして内容確認（セキュアな方法）
kubectl get secret my-secret -o json | ruby -rjson -rbase64 -e 'data = JSON.parse(STDIN.read); data["data"].each { |key, value| puts "#{key}: #{Base64.decode64(value)[0..10]}..." }'
```

### ConfigMapの変更監視
```ruby
# ConfigMapの変更を検出してPodを再起動
kubectl get configmap app-config -o json | ruby -rjson -e 'cm = JSON.parse(STDIN.read); current_hash = cm["data"].hash.to_s; stored_hash = File.read("/tmp/cm-hash") rescue ""; if current_hash != stored_hash; system("kubectl rollout restart deployment/my-app"); File.write("/tmp/cm-hash", current_hash); puts "🔄 ConfigMap変更検出、アプリケーション再起動"; end'
```

## 🚀 デプロイメント・スケーリング

### ローリングアップデートの進行状況監視
```ruby
# デプロイメントのローリングアップデート状況を監視
kubectl get deployment my-app -o json | ruby -rjson -e 'dep = JSON.parse(STDIN.read); status = dep["status"]; total = status["replicas"]; ready = status["readyReplicas"] || 0; updated = status["updatedReplicas"] || 0; puts "進行状況: #{ready}/#{total} Ready, #{updated}/#{total} Updated"; puts "✅ 完了" if ready == total && updated == total'
```

### 自動スケーリング判定
```ruby
# CPU使用率に基づく手動HPA判定
kubectl top pods -l app=my-app | ruby -e 'lines = STDIN.readlines[1..]; total_cpu = lines.sum { |line| line.split[1].to_i }; avg_cpu = total_cpu / lines.size; puts "平均CPU: #{avg_cpu}m"; if avg_cpu > 500; system("kubectl scale deployment my-app --replicas=#{lines.size + 2}"); puts "🚀 スケールアウト実行"; elsif avg_cpu < 100 && lines.size > 2; system("kubectl scale deployment my-app --replicas=#{lines.size - 1}"); puts "⬇️ スケールイン実行"; end'
```

### Blue-Greenデプロイメントの管理
```ruby
# Blue-Greenデプロイメント用のService切り替え
ruby -ryaml -e 'new_version = ARGV[0]; service_yaml = `kubectl get service my-app-service -o yaml`; service = YAML.load(service_yaml); service["spec"]["selector"]["version"] = new_version; File.write("/tmp/service.yaml", YAML.dump(service)); system("kubectl apply -f /tmp/service.yaml"); puts "✅ Service切り替え完了: #{new_version}"' v2.0.0
```

## 📋 ログ・トラブルシューティング

### 複数Pod からのログ集約
```ruby
# 特定ラベルの全Podからエラーログを抽出
kubectl get pods -l app=my-app -o name | ruby -e 'STDIN.readlines.each { |pod| pod_name = pod.strip.split("/")[1]; puts "=== #{pod_name} ==="; system("kubectl logs #{pod_name} --since=1h | grep -i error | tail -3") }'
```

### イベント情報の分析
```ruby
# 異常なイベントを時系列で表示
kubectl get events --sort-by=.metadata.creationTimestamp -o json | ruby -rjson -e 'events = JSON.parse(STDIN.read)["items"]; abnormal = events.select { |e| e["type"] == "Warning" || e["reason"].match(/Failed|Error/) }; abnormal.last(10).each { |e| puts "#{e["metadata"]["creationTimestamp"]} #{e["involvedObject"]["name"]}: #{e["message"]}" }'
```

### ネットワークポリシーの検証
```ruby
# NetworkPolicyの適用状況を確認
kubectl get networkpolicy --all-namespaces -o json | ruby -rjson -e 'policies = JSON.parse(STDIN.read)["items"]; policies.each { |policy| ns = policy["metadata"]["namespace"]; name = policy["metadata"]["name"]; selector = policy["spec"]["podSelector"]["matchLabels"] || {}; puts "#{ns}/#{name}: #{selector.empty? ? "全Pod" : selector.map { |k,v| "#{k}=#{v}" }.join(",")}" }'
```

## 🔐 セキュリティ・監査

### RBAC権限の監査
```ruby
# ServiceAccountの権限を一覧表示
kubectl get rolebinding,clusterrolebinding --all-namespaces -o json | ruby -rjson -e 'bindings = JSON.parse(STDIN.read)["items"]; bindings.each { |binding| subjects = binding["subjects"] || []; sa_subjects = subjects.select { |s| s["kind"] == "ServiceAccount" }; sa_subjects.each { |sa| puts "#{sa["namespace"]}/#{sa["name"]}: #{binding["roleRef"]["name"]}" } }'
```

### Pod Security Standardsの確認
```ruby
# 特権コンテナの検出
kubectl get pods --all-namespaces -o json | ruby -rjson -e 'pods = JSON.parse(STDIN.read)["items"]; privileged = pods.select { |pod| pod["spec"]["containers"].any? { |c| c["securityContext"] && c["securityContext"]["privileged"] } }; privileged.each { |pod| puts "🚨 特権コンテナ: #{pod["metadata"]["namespace"]}/#{pod["metadata"]["name"]}" }'
```

### イメージの脆弱性監査
```ruby
# 使用中のイメージ一覧と検証
kubectl get pods --all-namespaces -o json | ruby -rjson -e 'pods = JSON.parse(STDIN.read)["items"]; images = {}; pods.each { |pod| pod["spec"]["containers"].each { |c| image = c["image"]; images[image] = (images[image] || 0) + 1 } }; images.sort_by { |img, count| -count }.each { |img, count| puts "#{img}: #{count}個のPodで使用中" }'
```

## 🔄 CI/CD統合

### GitOpsワークフローの自動化
```ruby
# Git commitハッシュに基づくデプロイメント更新
ruby -e 'commit_hash = `git rev-parse HEAD`.strip[0..7]; image_tag = "my-app:#{commit_hash}"; system("kubectl set image deployment/my-app container=my-repo/#{image_tag}"); system("kubectl rollout status deployment/my-app"); puts "🚀 デプロイ完了: #{image_tag}"'
```

### デプロイメント前の環境検証
```ruby
# デプロイ前の必須サービス稼働確認
required_services = %w[database redis api-gateway]; all_ready = required_services.all? { |svc| status = `kubectl get service #{svc} -o jsonpath='{.spec.clusterIP}' 2>/dev/null`; !status.empty? }; if all_ready; puts "✅ 全必須サービスが稼働中、デプロイ可能"; system("kubectl apply -f deployment.yaml"); else; puts "❌ 必須サービスが不足、デプロイ中止"; exit 1; end
```

### カナリアデプロイメントの重み調整
```ruby
# トラフィック重みを段階的に調整
current_weight = `kubectl get virtualservice my-app -o jsonpath='{.spec.http[0].route[1].weight}'`.to_i; new_weight = [current_weight + 10, 100].min; old_weight = 100 - new_weight; ruby_script = %Q{kubectl patch virtualservice my-app --type='json' -p='[{"op": "replace", "path": "/spec/http/0/route/0/weight", "value": #{old_weight}}, {"op": "replace", "path": "/spec/http/0/route/1/weight", "value": #{new_weight}}]'}; system(ruby_script); puts "🔄 カナリア重み調整: #{new_weight}%"
```

## 💡 運用ベストプラクティス

### 1. クラスター健康チェック
```bash
# 毎分実行でクラスター状態監視
* * * * * kubectl get nodes -o json | ruby -rjson -e 'nodes = JSON.parse(STDIN.read)["items"]; unhealthy = nodes.select { |n| !n["status"]["conditions"].any? { |c| c["type"] == "Ready" && c["status"] == "True" } }; system("echo \"異常ノード: #{unhealthy.map { |n| n["metadata"]["name"] }.join(\", \")}\" | mail -s \"K8s Alert\" admin@example.com") if unhealthy.any?'
```

### 2. リソース使用量レポート
```bash
# 日次でリソース使用量レポート生成
0 6 * * * kubectl top pods --all-namespaces | ruby -e 'puts "#{Date.today} Kubernetes Resource Report"; puts STDIN.read' >> /var/log/k8s-resources.log
```

### 3. 自動バックアップ
```ruby
# ETCD バックアップの自動化（管理者向け）
ruby -e 'backup_file = "/backup/etcd-#{Time.now.strftime(\"%Y%m%d-%H%M%S\")}.db"; system("kubectl -n kube-system exec etcd-master -- etcdctl snapshot save #{backup_file}"); puts "✅ ETCDバックアップ完了: #{backup_file}"'
```

## ⚠️ 注意事項

1. **本番環境での使用前に十分テストしてください**
2. **RBAC権限を適切に設定してください**
3. **Secret情報の取り扱いには十分注意してください**
4. **リソース制限を適切に設定してください**
5. **ネットワークポリシーでセキュリティを確保してください**

---

**これらのワンライナーでKubernetesの運用効率を飛躍的に向上させることができます。**