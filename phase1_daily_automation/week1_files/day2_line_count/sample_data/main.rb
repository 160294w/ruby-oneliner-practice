# メインアプリケーションファイル
class MainApp
  def initialize
    @users = []
    @config = load_config
  end

  def run
    puts "アプリケーション開始"
    load_users
    start_server
  end

  private

  def load_config
    { port: 3000, host: 'localhost' }
  end

  def load_users
    # ユーザーデータの読み込み
    @users = User.all
  end

  def start_server
    puts "サーバー起動: #{@config[:host]}:#{@config[:port]}"
  end
end

MainApp.new.run