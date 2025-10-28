<div align="center">

# Day 17: Kubernetes管理ワンライナー

[![難易度](https://img.shields.io/badge/難易度-上級-red?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-45分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: Kubernetesクラスターの運用で、Pod監視、リソース管理、トラブルシューティングを効率化したい。

**問題**: kubectlコマンドが複雑、複数Podの状態確認が手動で面倒、YAML設定の動的生成が困難。

**解決**: RubyとKubernetesを組み合わせた運用自動化！

## 課題

Kubernetes環境でのPod監視、リソース管理、設定ファイル操作をワンライナーで自動化してください。

### 期待する処理例
```bash
# Pod健康状態の一括監視
kubectl get pods → 異常Podの特定・再起動

# リソース使用量の分析
各NamespaceのCPU/Memory使用状況

# 動的なマニフェスト生成
環境別ConfigMap/Secretの自動生成
```

## 学習ポイント

| 技術要素 | 用途 | 重要度 |
|----------|------|--------|
| `kubectl get -o json` | K8s情報取得 | ⭐⭐⭐⭐⭐ |
| `YAML.dump/load` | マニフェスト操作 | ⭐⭐⭐⭐⭐ |
| `JSON.parse` | kubectl JSON出力解析 | ⭐⭐⭐⭐ |
| `system/backtick` | kubectlコマンド実行 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
Kubernetes情報の基本取得から始めましょう：

```ruby
# ヒント: この構造を完成させてください
require 'json'
pods = `kubectl get pods -o json`
data = JSON.parse(pods)
data["items"].each { |pod| puts pod["metadata"]["name"] }
```

### 応用レベル

<details>
<summary><strong>1. 異常Pod検出</strong></summary>

```ruby
# Running以外のPodを特定
require 'json'
pods = JSON.parse(`kubectl get pods -o json`)
abnormal = pods["items"].select { |pod| pod["status"]["phase"] != "Running" }
```

</details>

<details>
<summary><strong>2. リソース使用量分析</strong></summary>

```ruby
# Namespace別のPod数とリソース要求
namespaces = `kubectl get namespaces -o name`.lines.map(&:strip)
namespaces.each do |ns|
  pod_count = `kubectl get pods -n #{ns} --no-headers | wc -l`.to_i
  puts "#{ns}: #{pod_count} pods"
end
```

</details>

### 実務レベル

<details>
<summary><strong>運用自動化システム</strong></summary>

クラスター全体の健康監視、自動スケーリング判定、アラート通知を統合したシステムを1行で実装。

</details>

## 実際の業務での使用例

- 🔍 **クラスター監視** - Pod、Node、Serviceの健康状態確認
- 📋 **リソース最適化** - CPU/Memory使用率の分析・最適化
- 🔄 **自動運用** - 異常Pod再起動、スケーリング判定
- 🚨 **障害対応** - ログ集約、トラブルシューティング支援

## 前提条件

このコースを実施するには以下が必要です：

- Kubernetes環境（minikube、Docker Desktop等）
- kubectlコマンドの実行権限
- 基本的なKubernetesの知識

---

<div align="center">

[メインページに戻る](../../../README.md) | [ヒントを見る](hints.md) | [解答例を確認](solution.rb)

</div>