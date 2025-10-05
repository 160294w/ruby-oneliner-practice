<div align="center">

# Day 9: 正規表現マスター

[![難易度](https://img.shields.io/badge/難易度-中級-orange?style=flat-square)](#)
[![実用度](https://img.shields.io/badge/実用度-⭐⭐⭐⭐-yellow?style=flat-square)](#)
[![所要時間](https://img.shields.io/badge/所要時間-35分-blue?style=flat-square)](#)

</div>

---

## 実用場面

**シチュエーション**: ログファイル、設定ファイル、ユーザー入力データから特定のパターンを抽出・検証する必要がある。

**問題**: メールアドレス、URL、電話番号、IPアドレスなどの抽出や妥当性チェックを手作業で行うのは非効率かつエラーが起きやすい。

**解決**: Rubyの強力な正規表現機能で瞬時にパターンマッチング・データ抽出！

## 課題

テキストデータから正規表現を使って情報抽出、データクレンジング、パターン検証をワンライナーで実現してください。

### 期待する処理例
```bash
# メールアドレスの抽出
contact.txt → 全てのメールアドレスをリスト化

# URLの抽出と分類
document.txt → http/https URLを抽出、ドメイン別に集計

# ログパターンのマッチング
app.log → エラーログのみ抽出、エラータイプ別に集計

# データクレンジング
users.txt → 電話番号を統一フォーマットに変換
```

## 学習ポイント

| メソッド/パターン | 用途 | 重要度 |
|-----------------|------|--------|
| `scan/match` | パターン抽出 | ⭐⭐⭐⭐⭐ |
| `gsub/sub` | パターン置換 | ⭐⭐⭐⭐⭐ |
| `=~/!~` | パターンマッチング | ⭐⭐⭐⭐ |
| 名前付きキャプチャ `(?<name>)` | 構造化抽出 | ⭐⭐⭐⭐ |

## レベル別チャレンジ

### 基本レベル
メールアドレスの抽出から始めましょう：

```ruby
# ヒント: この構造を完成させてください
text = File.read("sample_data/contacts.txt")
emails = text.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)
puts emails.uniq
```

<details>
<summary>💡 基本レベルのヒント</summary>

- `scan` メソッドでマッチする全パターンを配列で取得
- メールアドレスパターン: `ユーザー名@ドメイン名.TLD`
- `uniq` で重複を除去

</details>

### 応用レベル

<details>
<summary><strong>1. URL抽出とドメイン分析</strong></summary>

```ruby
# URLを抽出してドメイン別に集計
text = File.read("sample_data/document.txt")
urls = text.scan(%r{https?://[^\s<>"]+})
domains = urls.map { |url| url[%r{https?://([^/]+)}, 1] }
             .group_by(&:itself)
             .transform_values(&:size)
puts domains
```

**学習ポイント**: URLパターン、ドメイン抽出、集計処理

</details>

<details>
<summary><strong>2. 電話番号の統一フォーマット</strong></summary>

```ruby
# 様々な形式の電話番号を統一フォーマットに変換
text = File.read("sample_data/contacts.txt")
normalized = text.gsub(/(\d{3})[-.\s]?(\d{4})[-.\s]?(\d{4})/, '\1-\2-\3')
puts normalized
```

**学習ポイント**: キャプチャグループ、置換パターン

</details>

<details>
<summary><strong>3. ログパターン解析</strong></summary>

```ruby
# エラーログのみ抽出してエラータイプ別に集計
logs = File.readlines("sample_data/app.log")
errors = logs.select { |line| line =~ /ERROR|FATAL/ }
error_types = errors.map { |line| line[/\[(.*?)\]/, 1] }
                   .compact
                   .group_by(&:itself)
                   .transform_values(&:size)
puts error_types
```

**学習ポイント**: 条件抽出、パターン分類

</details>

<details>
<summary><strong>4. IPアドレスの抽出と検証</strong></summary>

```ruby
# IPv4アドレスを抽出して有効性チェック
text = File.read("sample_data/network.log")
ips = text.scan(/\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/)
valid_ips = ips.select do |ip|
  ip.split('.').all? { |octet| (0..255).include?(octet.to_i) }
end
puts valid_ips.uniq
```

**学習ポイント**: 複雑なパターン、妥当性検証

</details>

### 実務レベル

<details>
<summary><strong>包括的データ抽出システム</strong></summary>

複数のテキストファイルから、メール、URL、電話番号、IPアドレスを一括抽出し、
JSONフォーマットで出力するシステムを実装。重複除去とドメイン別分類も実施。

```ruby
require 'json'

data = {
  emails: [],
  urls: {},
  phones: [],
  ips: []
}

Dir.glob("sample_data/*.txt").each do |file|
  text = File.read(file)

  # メールアドレス抽出
  data[:emails] += text.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)

  # URL抽出とドメイン別集計
  urls = text.scan(%r{https?://[^\s<>"]+})
  urls.each do |url|
    domain = url[%r{https?://([^/]+)}, 1]
    data[:urls][domain] ||= 0
    data[:urls][domain] += 1
  end

  # 電話番号抽出（統一フォーマット）
  phones = text.scan(/(\d{3})[-.\s]?(\d{4})[-.\s]?(\d{4})/)
  data[:phones] += phones.map { |parts| parts.join('-') }

  # IPアドレス抽出
  data[:ips] += text.scan(/\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/)
end

# 重複除去
data[:emails].uniq!
data[:phones].uniq!
data[:ips].uniq!

puts JSON.pretty_generate(data)
```

</details>

## 実際の業務での使用例

- 📧 **メールアドレス収集** - 問い合わせフォームや資料からの自動抽出
- 🔗 **リンクチェック** - ドキュメント内の全URLを抽出して検証
- 📞 **顧客データクレンジング** - 電話番号フォーマットの統一
- 🔍 **ログ監視** - エラーパターンの自動検出とアラート
- 🌐 **IPアドレス管理** - アクセスログからの不正アクセス検出

## 🎓 次のステップ

- ✅ 基本レベルクリア → [Day 10: ログ分析](../../week4_text_processing/day10_log_analysis/problem.md)
- 🔗 関連する実用例 → [実世界での使用例](../../../resources/real_world_examples.md#データ処理分析)

---

<div align="center">

[🏠 メインページに戻る](../../../README.md) | [💡 ヒントを見る](hints.md) | [✅ 解答例を確認](solution.rb)

</div>
