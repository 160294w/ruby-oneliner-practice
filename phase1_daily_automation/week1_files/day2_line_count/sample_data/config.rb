# 設定管理クラス
class Config
  attr_reader :settings

  def initialize
    @settings = load_default_settings
  end

  def get(key)
    @settings[key]
  end

  def set(key, value)
    @settings[key] = value
  end

  private

  def load_default_settings
    {
      app_name: "Ruby Practice App",
      version: "1.0.0",
      debug: true,
      port: 3000,
      host: "localhost"
    }
  end
end