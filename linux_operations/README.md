<div align="center">

# 🐧 Linux運用ワンライナー実践ガイド

[![難易度](https://img.shields.io/badge/難易度-🔴%20実務レベル-red?style=flat-square)](#)
[![対象](https://img.shields.io/badge/対象-DevOps%20Engineers-blue?style=flat-square)](#)
[![環境](https://img.shields.io/badge/環境-Linux%20%7C%20macOS-green?style=flat-square)](#)

**Docker、Kubernetes、Terraform、systemctlを駆使したLinux運用自動化**

</div>

---

## 🎯 概要

このセクションでは、実際のLinux運用現場で使われる高度なワンライナー技術を学習します。
DevOpsエンジニアが日常的に使用するツールとRubyを組み合わせた実践的な自動化テクニックを習得できます。

## 📚 カリキュラム構成

### 🐳 Docker Management
**実用度**: ⭐⭐⭐⭐⭐ | **難易度**: 🔴 上級

| 項目 | 内容 | 実用例 |
|------|------|--------|
| **コンテナ監視** | 異常コンテナの自動検出・再起動 | `docker ps \| ruby -e "..."` |
| **リソース分析** | CPU/Memory使用率の分析・アラート | メモリ枯渇の早期発見 |
| **ログ集約** | 複数コンテナからのエラーログ抽出 | 障害の根本原因分析 |
| **メンテナンス** | 未使用イメージ・コンテナの一括削除 | ディスク使用量最適化 |

### ☸️ Kubernetes Operations
**実用度**: ⭐⭐⭐⭐⭐ | **難易度**: 🔴 上級

| 項目 | 内容 | 実用例 |
|------|------|--------|
| **Pod監視** | 異常Pod検出・自動再起動 | `kubectl get pods \| ruby -e "..."` |
| **リソース最適化** | Namespace別リソース使用状況分析 | コスト最適化の判断材料 |
| **設定管理** | ConfigMap/Secretの動的生成 | 環境別設定の自動展開 |
| **トラブルシューティング** | ログ集約・障害分析 | 迅速な障害対応 |

### 🏗️ Terraform Automation
**実用度**: ⭐⭐⭐⭐ | **難易度**: 🟠 中級

| 項目 | 内容 | 実用例 |
|------|------|--------|
| **状態管理** | tfstateファイルの分析・バックアップ | `terraform show \| ruby -e "..."` |
| **リソース監査** | 使用中/未使用リソースの特定 | コスト削減のための分析 |
| **プラン分析** | terraform planの差分解析 | 変更影響の事前評価 |
| **自動適用** | 条件付き自動デプロイメント | CI/CDパイプライン統合 |

### ⚙️ SystemCtl Service Management
**実用度**: ⭐⭐⭐⭐⭐ | **難易度**: 🟡 初級

| 項目 | 内容 | 実用例 |
|------|------|--------|
| **サービス監視** | 異常サービスの検出・再起動 | `systemctl status \| ruby -e "..."` |
| **ログ分析** | journalctlログの解析・フィルタリング | システム障害の原因特定 |
| **自動化** | サービス管理の自動化スクリプト | 定期メンテナンスの自動実行 |
| **パフォーマンス** | システムリソースの監視・最適化 | サーバー性能の維持 |

## 🚀 特徴

### 💡 実務直結の内容
- **現場の課題解決**: 実際のDevOps業務で遭遇する問題への対処法
- **即座に活用可能**: 学んだその日から業務で使える実践的なスキル
- **エラーハンドリング**: 本番環境を考慮した堅牢なスクリプト

### 🔧 高度な技術統合
- **複数ツール連携**: Docker + K8s + Terraform の組み合わせ
- **JSON/YAML操作**: 設定ファイルの動的生成・変更
- **システム監視**: リアルタイムな状態監視とアラート

### 📊 運用効率化
- **自動化**: 手動作業の大幅な削減
- **監視**: 24/7運用のためのモニタリング
- **最適化**: リソース使用量とコストの最適化

## 🎯 学習目標

### ✅ Docker運用マスター
- [ ] コンテナライフサイクルの完全制御
- [ ] リソース監視とアラートシステム構築
- [ ] ログ分析による障害の迅速な特定
- [ ] 自動メンテナンスシステムの構築

### ✅ Kubernetes運用エキスパート
- [ ] クラスター全体の健康状態監視
- [ ] 動的なマニフェスト生成・適用
- [ ] Pod・Serviceの自動管理
- [ ] 効率的なトラブルシューティング

### ✅ Infrastructure as Code実践者
- [ ] Terraformリソースの効率的管理
- [ ] インフラ変更の影響分析
- [ ] 自動化されたデプロイメントフロー
- [ ] コスト最適化のためのリソース監査

### ✅ システム管理のプロフェッショナル
- [ ] systemctl による包括的サービス管理
- [ ] ジャーナルログの高度な分析
- [ ] 自動化されたシステム監視
- [ ] パフォーマンス最適化の実施

## 🔧 前提条件

- Linux/Unix環境での基本操作経験
- Docker、Kubernetes、Terraformの基礎知識
- Ruby基本文法の理解
- JSON/YAML形式データの理解

## 📋 実習環境

各セクションの実習には以下の環境が推奨されます：

- **Docker**: Docker Desktop または Docker Engine
- **Kubernetes**: minikube、Docker Desktop、または実クラスター
- **Terraform**: 最新版のTerraform CLI
- **Linux**: Ubuntu 20.04+ または CentOS 8+ または macOS

---

<div align="center">

**🎉 Linux運用のプロフェッショナルを目指しましょう！**

[🐳 Docker管理](docker_management/) | [☸️ K8s運用](k8s_operations/) | [🏗️ Terraform自動化](terraform_automation/) | [⚙️ SystemCtl管理](systemctl_service/)

[⬆️ メインページに戻る](../README.md)

</div>