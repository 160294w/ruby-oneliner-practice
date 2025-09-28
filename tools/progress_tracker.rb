#!/usr/bin/env ruby
# Rubyワンライナー練習進捗管理ツール

require 'json'
require 'time'

class ProgressTracker
  PROGRESS_FILE = File.expand_path('../.progress.json', __dir__)

  def initialize
    @progress = load_progress
  end

  def mark_completed(day, level = :basic)
    day_key = "day#{day}"
    @progress[day_key] ||= {}
    @progress[day_key][level.to_s] = {
      completed: true,
      completed_at: Time.now.iso8601,
      attempts: (@progress[day_key][level.to_s]&.dig('attempts') || 0) + 1
    }
    save_progress
    puts "✅ Day #{day} (#{level}) 完了マークしました！"
  end

  def show_progress
    puts "🎯 Rubyワンライナー練習 進捗状況"
    puts "=" * 50

    total_days = 6  # Phase1の総日数
    completed_basic = 0
    completed_advanced = 0

    (1..total_days).each do |day|
      day_key = "day#{day}"
      day_progress = @progress[day_key] || {}

      basic_done = day_progress.dig('basic', 'completed') || false
      advanced_done = day_progress.dig('advanced', 'completed') || false

      status = if advanced_done
                 "🏆 完全制覇"
               elsif basic_done
                 "✅ 基本完了"
               else
                 "⭕ 未着手"
               end

      puts "Day #{day}: #{status}"

      completed_basic += 1 if basic_done
      completed_advanced += 1 if advanced_done
    end

    puts "\n📊 統計"
    puts "基本レベル完了: #{completed_basic}/#{total_days} (#{(completed_basic * 100.0 / total_days).round(1)}%)"
    puts "応用レベル完了: #{completed_advanced}/#{total_days} (#{(completed_advanced * 100.0 / total_days).round(1)}%)"

    show_achievements(completed_basic, completed_advanced, total_days)
  end

  def show_day_detail(day)
    day_key = "day#{day}"
    day_progress = @progress[day_key]

    if day_progress.nil? || day_progress.empty?
      puts "Day #{day}: まだ着手していません"
      return
    end

    puts "📅 Day #{day} 詳細進捗"
    puts "-" * 30

    [:basic, :advanced, :expert].each do |level|
      level_data = day_progress[level.to_s]
      if level_data && level_data['completed']
        completed_at = Time.parse(level_data['completed_at'])
        attempts = level_data['attempts']
        puts "#{level_name(level)}: ✅ 完了 (#{completed_at.strftime('%Y-%m-%d %H:%M')})"
        puts "  試行回数: #{attempts}回"
      else
        puts "#{level_name(level)}: ⭕ 未完了"
      end
    end
  end

  def reset_progress
    @progress = {}
    save_progress
    puts "🔄 進捗をリセットしました"
  end

  def export_progress
    puts "📤 進捗データ:"
    puts JSON.pretty_generate(@progress)
  end

  private

  def load_progress
    return {} unless File.exist?(PROGRESS_FILE)
    JSON.parse(File.read(PROGRESS_FILE))
  rescue JSON::ParserError
    {}
  end

  def save_progress
    File.write(PROGRESS_FILE, JSON.pretty_generate(@progress))
  end

  def level_name(level)
    case level
    when :basic then "基本レベル"
    when :advanced then "応用レベル"
    when :expert then "実務レベル"
    end
  end

  def show_achievements(basic, advanced, total)
    puts "\n🏅 達成状況"

    achievements = []
    achievements << "🥉 初心者 (基本1つ完了)" if basic >= 1
    achievements << "🥈 中級者 (基本3つ完了)" if basic >= 3
    achievements << "🥇 上級者 (基本全完了)" if basic == total
    achievements << "💎 マスター (応用3つ完了)" if advanced >= 3
    achievements << "👑 グランドマスター (応用全完了)" if advanced == total

    if achievements.any?
      puts achievements.join(", ")
    else
      puts "まだ実績がありません。頑張りましょう！"
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  tracker = ProgressTracker.new

  case ARGV[0]
  when 'complete'
    day = ARGV[1]&.to_i
    level = ARGV[2]&.to_sym || :basic
    if day && day > 0
      tracker.mark_completed(day, level)
    else
      puts "使用方法: ruby progress_tracker.rb complete <day> [basic|advanced|expert]"
    end
  when 'show'
    if ARGV[1]
      tracker.show_day_detail(ARGV[1].to_i)
    else
      tracker.show_progress
    end
  when 'reset'
    tracker.reset_progress
  when 'export'
    tracker.export_progress
  else
    puts "使用方法:"
    puts "  ruby progress_tracker.rb show              # 全体進捗表示"
    puts "  ruby progress_tracker.rb show 1            # Day 1詳細表示"
    puts "  ruby progress_tracker.rb complete 1 basic  # Day 1基本レベル完了"
    puts "  ruby progress_tracker.rb complete 2 advanced # Day 2応用レベル完了"
    puts "  ruby progress_tracker.rb reset             # 進捗リセット"
    puts "  ruby progress_tracker.rb export            # 進捗データ出力"
  end
end