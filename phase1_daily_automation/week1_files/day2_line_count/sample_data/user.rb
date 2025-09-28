# ユーザーモデルクラス
class User
  attr_accessor :name, :email, :created_at

  def initialize(name, email)
    @name = name
    @email = email
    @created_at = Time.now
  end

  def self.all
    [
      new("田中太郎", "tanaka@example.com"),
      new("佐藤花子", "sato@example.com"),
      new("鈴木一郎", "suzuki@example.com")
    ]
  end

  def to_s
    "#{@name} (#{@email})"
  end

  def valid?
    !@name.empty? && @email.include?("@")
  end

  def age_in_days
    (Time.now - @created_at) / (24 * 60 * 60)
  end

  def display_info
    puts "名前: #{@name}"
    puts "メール: #{@email}"
    puts "登録日: #{@created_at.strftime('%Y-%m-%d')}"
    puts "経過日数: #{age_in_days.round}日"
  end

  def update_email(new_email)
    return false unless new_email.include?("@")
    @email = new_email
    true
  end

  def send_notification(message)
    puts "#{@email} に通知: #{message}"
  end
end