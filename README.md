<div align="center">

# 🚀 Ruby ワンライナー練習プロジェクト

[![Ruby](https://img.shields.io/badge/Ruby-3.0+-red?style=flat-square&logo=ruby)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Progress](https://img.shields.io/badge/進捗-Week1完成-green?style=flat-square)](phase1_daily_automation/week1_files/)

**実務で使えるRubyワンライナーを体系的に学習するためのカリキュラム**

[📚 学習を始める](#-クイックスタート) | [📖 チートシート](resources/cheatsheet.md) | [🎯 実用例](resources/real_world_examples.md) | [🛠️ ツール使用法](#-便利ツール)

</div>

---

## 📋 目次

- [特徴](#-特徴)
- [クイックスタート](#-クイックスタート)
- [カリキュラム構成](#-カリキュラム構成)
- [学習方法](#-学習方法)
- [便利ツール](#-便利ツール)
- [学習目標](#-学習目標)
- [コントリビューション](#-コントリビューション)

## ✨ 特徴

| 特徴 | 説明 | メリット |
|------|------|----------|
| 🎯 **実用性重視** | 実際の業務で即使える内容 | 学んだその日から活用可能 |
| 📈 **段階的学習** | 基本から応用まで無理なく進める | 挫折しにくい学習設計 |
| 🧪 **自動テスト** | 解答の正誤を即座に確認 | 効率的なフィードバック |
| 📊 **進捗管理** | 学習状況を可視化 | モチベーション維持 |

## 🚀 クイックスタート

3分で始められる学習手順：

```bash
# 1. リポジトリをクローン
git clone https://github.com/your-username/ruby-oneliner-practice.git
cd ruby-oneliner-practice

# 2. Day 1の課題を開始
cd phase1_daily_automation/week1_files/day1_file_sizes
cat problem.md

# 3. 解答を作成・テスト
ruby solution.rb

# 4. 進捗を記録
ruby ../../../tools/progress_tracker.rb complete 1 basic
```

## 📚 カリキュラム構成

### 🌟 Phase 1: 日常業務自動化 (Week 1-2)

<details open>
<summary><strong>📁 Week 1: ファイル・ディレクトリ操作</strong> - 完成済み ✅</summary>

| Day | 課題 | 難易度 | 実用度 | ステータス |
|-----|------|--------|--------|------------|
| 1 | [ファイルサイズ一覧表示](phase1_daily_automation/week1_files/day1_file_sizes/problem.md) | 🟢 基本 | ⭐⭐⭐ | ✅ 完成 |
| 2 | [ファイル行数カウント](phase1_daily_automation/week1_files/day2_line_count/problem.md) | 🟡 初級 | ⭐⭐⭐⭐ | ✅ 完成 |
| 3 | [日付付きバックアップディレクトリ作成](phase1_daily_automation/week1_files/day3_date_backup/problem.md) | 🟡 初級 | ⭐⭐⭐⭐⭐ | ✅ 完成 |

</details>

<details>
<summary><strong>📝 Week 2: テキスト処理基礎</strong> - 開発中 🚧</summary>

| Day | 課題 | 難易度 | 実用度 | ステータス |
|-----|------|--------|--------|------------|
| 4 | CSVから特定列抽出 | 🟡 初級 | ⭐⭐⭐⭐ | 🚧 開発中 |
| 5 | ログファイルからエラー行抽出 | 🟠 中級 | ⭐⭐⭐⭐⭐ | 🚧 開発中 |
| 6 | 複数ファイルの文字列一括置換 | 🟠 中級 | ⭐⭐⭐⭐ | 🚧 開発中 |

</details>

### 🎯 Phase 2: データ変換マスター (Week 3-4)
<details>
<summary><strong>📊 高度なデータ処理技術</strong> - 計画中 📋</summary>

*JSON/YAML操作、正規表現マスター、パフォーマンス最適化*

</details>

### ⚡ Phase 3: システム管理・監視 (Week 5-6)
<details>
<summary><strong>🖥️ 運用・監視自動化</strong> - 計画中 📋</summary>

*ログ解析、システム監視、プロセス管理、パフォーマンス分析*

</details>

## 📖 学習方法

### 💡 各日の学習構成

```
📁 dayX_課題名/
├── 📄 problem.md      # 課題説明 + 実用背景
├── 📁 sample_data/    # 練習用データ
├── 💎 solution.rb     # 解答例（複数レベル）
└── 💡 hints.md        # ステップバイステップガイド
```

### 🎯 推奨学習フロー

1. **📖 課題理解** - `problem.md`で実用場面を理解
2. **🧪 実験** - `sample_data/`で試行錯誤
3. **💭 思考** - 自分なりのアプローチを考案
4. **💡 ヒント活用** - `hints.md`で段階的にサポート
5. **✅ 答え合わせ** - `solution.rb`で複数解法を確認
6. **📊 進捗記録** - ツールで学習状況を管理

### 📱 学習進捗の管理

<details>
<summary><strong>進捗管理コマンド一覧</strong></summary>

```bash
# 全体進捗の確認
ruby tools/progress_tracker.rb show

# 特定の日の詳細確認
ruby tools/progress_tracker.rb show 1

# 完了マーク（レベル別）
ruby tools/progress_tracker.rb complete 1 basic     # 基本レベル
ruby tools/progress_tracker.rb complete 1 advanced  # 応用レベル
ruby tools/progress_tracker.rb complete 1 expert    # 実務レベル

# 進捗リセット
ruby tools/progress_tracker.rb reset
```

</details>

## 🛠️ 便利ツール

学習を効率化する3つのツールが利用できます：

### 🧪 テストランナー
解答の正誤を自動チェック

<details>
<summary><strong>使用方法</strong></summary>

```bash
# 全解答のテスト実行
ruby tools/test_runner.rb

# 特定の日のみテスト
ruby tools/test_runner.rb 1

# 実行例
$ ruby tools/test_runner.rb 1
🎯 Day 1 テスト実行
✅ 実行成功
📄 出力プレビュー:
   sample1.txt: 52 bytes
   sample2.txt: 95 bytes
   sample3.txt: 11 bytes
```

</details>

### 📊 進捗管理ツール
学習状況を可視化・管理

<details>
<summary><strong>使用方法</strong></summary>

```bash
# 進捗表示
ruby tools/progress_tracker.rb show

# 完了マーク
ruby tools/progress_tracker.rb complete 1 basic

# 実行例
$ ruby tools/progress_tracker.rb show
🎯 Rubyワンライナー練習 進捗状況
Day 1: ✅ 基本完了
Day 2: ⭕ 未着手
Day 3: ⭕ 未着手
基本レベル完了: 1/3 (33.3%)
```

</details>

### 🎲 データ生成器
練習用の多様なサンプルデータを生成

<details>
<summary><strong>使用方法</strong></summary>

```bash
# 練習用データ生成
ruby tools/data_generator.rb generate

# 生成データ確認
ruby tools/data_generator.rb list

# データ削除
ruby tools/data_generator.rb clean

# 実行例
$ ruby tools/data_generator.rb generate
🎲 練習用データを生成中...
📄 テキストファイル生成中...
📊 CSVファイル生成中...
✅ データ生成完了: generated_data
```

</details>

## 📖 参考資料

### 🎯 学習サポート
| リソース | 内容 | 使用タイミング |
|----------|------|----------------|
| [📋 チートシート](resources/cheatsheet.md) | よく使うパターン集 | 課題中のリファレンス |
| [🌟 実用例集](resources/real_world_examples.md) | 業務での活用例 | モチベーション向上 |
| [🔧 パフォーマンスガイド](resources/cheatsheet.md#-パフォーマンス最適化) | 最適化テクニック | 上級レベル挑戦時 |

## 📈 学習目標

学習段階ごとの達成目標をチェックリスト形式で管理：

### ✅ Week 1終了時の目標
- [ ] ファイル操作の基本ワンライナーが書ける
- [ ] `Dir.glob`, `File.size`, `File.readlines` を使いこなせる
- [ ] 日時フォーマット（`strftime`）を理解している
- [ ] 基本的なメソッドチェーンができる

### 🎯 Phase 1終了時の目標
- [ ] 日常的なファイル操作を自動化できる
- [ ] 基本的なテキスト処理ができる
- [ ] 実務でワンライナーを活用できる
- [ ] 他の開発者にワンライナーを教えられる

### 🏆 全課程終了時の目標
- [ ] 複雑なデータ変換が1行で書ける
- [ ] システム管理をワンライナーで効率化できる
- [ ] パフォーマンスを意識したコードが書ける
- [ ] チーム開発でワンライナーを提案・レビューできる

## 💡 学習のコツ

> **成功する学習者の共通パターン**

### 🎯 効率的な進め方
1. **🚀 まず動かす** - 完璧を目指さず、まず動くコードを書く
2. **📈 段階的改善** - 基本→応用→最適化の順で進める
3. **⚡ 実務で使う** - 学んだパターンを実際の業務で活用する
4. **👥 他の人と共有** - チームメンバーに便利なワンライナーを教える

### 🔄 継続のためのテクニック
- **毎日15分** - 短時間でも継続することを重視
- **実用から入る** - 自分の業務に直結する課題から開始
- **小さな成功体験** - 1つできたら必ず進捗を記録
- **応用を楽しむ** - 基本ができたら創意工夫で遊んでみる

## 🤝 コントリビューション

このプロジェクトをより良くするためのご協力をお待ちしています！

### 🙋‍♀️ こんな貢献を歓迎します
- 新しい課題のアイデア
- 解答例の改善
- ドキュメントの誤字・改善
- ツールの機能追加

### 📝 Issue・PR作成時のお願い
- 課題の実用性を重視した提案
- 段階的な学習を意識した設計
- コードの可読性とコメント

詳細は [CONTRIBUTING.md](CONTRIBUTING.md) をご確認ください。

## 📄 ライセンス

[MIT License](LICENSE) - 自由に使用・改変・配布可能

---

<div align="center">

**🎉 Happy Ruby One-liner Coding! 🎉**

⭐ 役に立ったらスターをお願いします！ | 🐛 問題を見つけたらIssueへ | 💡 アイデアがあればPRを！

[⬆️ ページトップへ](#-ruby-ワンライナー練習プロジェクト)

</div>