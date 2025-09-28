# ヘルパーユーティリティ
module Helper
  def self.format_date(date)
    date.strftime("%Y年%m月%d日")
  end

  def self.validate_email(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end

  def self.sanitize_input(input)
    input.strip.gsub(/[<>&"']/, '')
  end
end