#!/usr/bin/env ruby
# Rubyワンライナー練習用テストランナー

require 'fileutils'
require 'pathname'

class OnelimerTestRunner
  def initialize
    @project_root = File.expand_path('..', __dir__)
    @results = {}
  end

  def run_all_tests
    puts "🚀 Rubyワンライナー練習 - テストランナー"
    puts "=" * 50

    find_all_solutions.each do |solution_file|
      puts "\n📁 テスト実行: #{relative_path(solution_file)}"
      run_solution_test(solution_file)
    end

    print_summary
  end

  def run_specific_test(day)
    solution_file = find_solution_by_day(day)
    if solution_file
      puts "🎯 Day #{day} テスト実行"
      run_solution_test(solution_file)
    else
      puts "❌ Day #{day} の解答ファイルが見つかりません"
    end
  end

  private

  def find_all_solutions
    Dir.glob("#{@project_root}/**/solution.rb").sort
  end

  def find_solution_by_day(day)
    Dir.glob("#{@project_root}/**/day#{day}_*/solution.rb").first
  end

  def run_solution_test(solution_file)
    solution_dir = File.dirname(solution_file)

    begin
      # 解答ディレクトリに移動して実行
      Dir.chdir(solution_dir) do
        # Ruby構文チェック
        syntax_check = `ruby -c solution.rb 2>&1`
        unless $?.success?
          @results[solution_file] = { status: :syntax_error, message: syntax_check }
          puts "❌ 構文エラー: #{syntax_check}"
          return
        end

        # 実際に実行してみる
        output = `ruby solution.rb 2>&1`
        if $?.success?
          @results[solution_file] = { status: :success, output: output }
          puts "✅ 実行成功"

          # 出力の一部を表示（長すぎる場合は省略）
          display_output = output.lines.first(5).join
          display_output += "...(省略)" if output.lines.size > 5
          puts "📄 出力プレビュー:"
          puts display_output.each_line.map { |line| "   #{line}" }.join
        else
          @results[solution_file] = { status: :runtime_error, message: output }
          puts "❌ 実行エラー: #{output}"
        end
      end
    rescue => e
      @results[solution_file] = { status: :error, message: e.message }
      puts "❌ テストエラー: #{e.message}"
    end
  end

  def print_summary
    puts "\n" + "=" * 50
    puts "📊 テスト結果サマリー"
    puts "=" * 50

    success_count = @results.values.count { |r| r[:status] == :success }
    total_count = @results.size

    puts "✅ 成功: #{success_count}/#{total_count}"
    puts "❌ 失敗: #{total_count - success_count}/#{total_count}"

    if total_count > 0
      success_rate = (success_count * 100.0 / total_count).round(1)
      puts "📈 成功率: #{success_rate}%"
    end

    # 失敗したテストの詳細
    failed_tests = @results.select { |_, result| result[:status] != :success }
    if failed_tests.any?
      puts "\n🔍 失敗したテスト:"
      failed_tests.each do |file, result|
        puts "  - #{relative_path(file)}: #{result[:status]}"
      end
    end
  end

  def relative_path(file)
    Pathname.new(file).relative_path_from(Pathname.new(@project_root)).to_s
  end
end

# コマンドライン実行
if __FILE__ == $0
  runner = OnelimerTestRunner.new

  if ARGV.empty?
    runner.run_all_tests
  elsif ARGV[0] =~ /^\d+$/
    runner.run_specific_test(ARGV[0])
  else
    puts "使用方法:"
    puts "  ruby test_runner.rb          # 全テスト実行"
    puts "  ruby test_runner.rb 1        # Day 1のみ実行"
    puts "  ruby test_runner.rb 2        # Day 2のみ実行"
  end
end