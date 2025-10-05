<div align="center">

# 🔧 Day 7: JSON/YAML データ変換

[![難易度](https://img.shields.io/badge/難易度-初級-yellow?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-25分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: API設定ファイルやKubernetesマニフェストなど、異なる形式のデータを変換する必要がある。

**問題**: JSON ↔ YAML変換、データ抽出・フィルタリングを手動で行うのは時間がかかる。

**解決**: Rubyワンライナーで瞬時にデータ変換・操作！

## 課題

JSON/YAMLファイルの読み込み、変換、データ抽出をワンライナーで実現してください。

### 期待する処理例
```bash
# JSON → YAML変換
users.json → users.yaml

# 特定条件でフィルタリング
age >= 30 のユーザーのみ抽出

# ネストしたデータの展開
user.profile.skills → フラットな配列
```

## 学習ポイント

| メソッド/ライブラリ | 用途 | 重要度 |
|-------------------|------|--------|
| `JSON.parse/generate` | JSON操作 | ⭐⭐⭐⭐⭐ |
| `YAML.load/dump` | YAML操作 | ⭐⭐⭐⭐ |
| `select/reject` | データフィルタリング | ⭐⭐⭐⭐⭐ |
| `map/flat_map` | データ変換 | ⭐⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
JSON → YAML変換から始めましょう：

```ruby
# ヒント: この構造を完成させてください
require 'json'; require 'yaml'
puts YAML.dump(JSON.parse(File.read("sample_data/users.json")))
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `JSON.parse` でJSONを読み込み
- `YAML.dump` でYAML形式に変換
- `File.read` でファイル内容を取得

</details>

### 応用レベル

<details>
<summary><strong>1. 条件フィルタリング</strong> - 特定条件のデータのみ抽出</summary>

```ruby
# 30歳以上のユーザーのみ抽出してYAML出力
require 'json'; require 'yaml'
users = JSON.parse(File.read("sample_data/users.json"))
filtered = users.select { |user| user["age"] >= 30 }
puts YAML.dump(filtered)
```

</details>

<details>
<summary><strong>2. データ変換</strong> - 必要なフィールドのみ抽出</summary>

```ruby
# name と email のみの簡略版を作成
users.map { |u| { name: u["name"], email: u["email"] } }
```

</details>

<details>
<summary><strong>3. ネストデータの展開</strong> - 複雑な構造をフラット化</summary>

```ruby
# ユーザーのスキルをフラットな配列に
users.flat_map { |u| u.dig("profile", "skills") }.compact.uniq
```

</details>

### 実務レベル

<details>
<summary><strong>設定ファイル管理システム</strong></summary>

複数の設定ファイルをマージし、環境別に出力するシステムを1行で実装。

</details>

## 実際の業務での使用例

- 🔧 **API設定ファイル変換** - 開発/本番環境の設定管理
- ☸️ **Kubernetesマニフェスト操作** - YAML設定の動的生成
- 📋 **ログデータ変換** - JSON形式ログの分析用変換
- 🔄 **CI/CD設定管理** - 環境別設定ファイルの自動生成

## 🎓 次のステップ

- ✅ 基本レベルクリア → [Day 8: CSV高度操作](../day8_csv_advanced/problem.md)
- 🔗 関連する実用例 → [実世界での使用例](../../../resources/real_world_examples.md#データ処理分析)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>