# frozen_string_literal: true

require "terminal-table"
require "ruby-progressbar"
require "colorize"
require_relative "validator"
require_relative "map_spider"
module Interface
  class UI
    def self.display_banner
      version ||= File.read(File.join(__dir__, "../.app_version")).strip
      puts %q{
 __  __              _____       _     _
|  \/  |            / ____|     (_)   | |
| \  / | __ _ _ __ | (___  _ __  _  __| | ___ _ __
| |\/| |/ _` | '_ \ \___ \| '_ \| |/ _` |/ _ \ '__|
| |  | | (_| | |_) |____) | |_) | | (_| |  __/ |
|_|  |_|\__,_| .__/|_____/| .__/|_|\__,_|\___|_|
             | |          | |へ(⚈益⚈)へ
             |_|          |_|
      }.colorize(:green)
      puts "                      #{version}\n\n".colorize(:green)
    end

    def self.coordinates
      all_coordinates = []

      loop do
        puts "Enter coordinates (format: latitude,longitude) or 'done' to finish:"
        input = gets.chomp
        break if input.downcase == "done"
        next unless Validator.validate_coordinates(input)

        lat, lng = input.split(",").map(&:strip)
        all_coordinates << { lat: lat.to_f, lng: lng.to_f }
        puts "✓ Coordinates added".colorize(:green)
      end

      all_coordinates
    end

    def self.radius
      loop do
        puts "\nEnter search radius in meters (50-50000):"
        radius = gets.chomp.to_i
        if Validator.validate_radius(radius)
          puts "✓ Radius added".colorize(:green)
          return radius
        end
      end
    end

    def self.max_requests
      puts "\nPay attention if you have enough requests left in your API key!".colorize(:yellow)
      puts "Enter maximum number of API requests(default: #{MapSpider::DEFAULT_MAX_REQUESTS}):"

      request_number = gets.chomp.to_i.nonzero?

      if request_number
        Validator.validate_requests_number(request_number)
        puts "✓ Maximum number of requests added".colorize(:green)
      end

      request_number
    end

    def self.place_type
      puts "\nEnter place type (e.g. restaurant, cafe) or press Enter to search for all types:"
      type = gets.chomp

      return nil if type.empty?

      puts "✓ Place type added".colorize(:green)

      type
    end

    def self.create_progress_bar(total_percentage)
      puts

      ProgressBar.create(
        title: "Progress",
        total: total_percentage,
        length: 80,
        format: "%t |%B| %p%% | Speed: %R/sec",
        progress_mark: "█",
        remainder_mark: "░",
        starting_at: 0,
        format_with_color: true,
        autostart: true,
        autofinish: true,
        output: $stdout
      )
    end

    def self.display_parameters(coordinates, radius, max_requests, place_type)
      table = Terminal::Table.new do |t|
        t.title = "Search parameters"
        t.rows = [
          ["Number of points", coordinates.size],
          ["Search radius", "#{radius} meters"],
          ["Max requests", max_requests],
          ["Place type", place_type || "All types"]
        ]
        t.style = { width: 50, padding_left: 3, border_x: "=", border_i: "+" }
      end

      puts "\n#{table}\n\n\n"
    end

    def self.display_completion_message(total_places, filename, spent_requests)
      puts "\n\n✓ Total unique places found: #{total_places}".colorize(:green)
      puts "✓ Spent requests: #{spent_requests}".colorize(:green)
      puts "✓ Results saved to #{filename}".colorize(:green)
    end

    def self.display_error(message)
      puts "\n✗ #{message}".colorize(:red)
    end

    def self.ask_to_show_map
      puts "\nDo you want to see the found places on the map? (y/n):"
      gets.chomp.downcase == "y"
    end

    def self.display_map_generated(filename)
      puts "\n✓ Map generated in file #{filename}".colorize(:green)
      puts "  Open this file in browser to view the map".colorize(:green)

      # Попытка автоматически открыть карту в браузере
      case RbConfig::CONFIG["host_os"]
      when /darwin/
        system("open #{filename}")
      when /linux|bsd/
        system("xdg-open #{filename}")
      when /mswin|mingw|cygwin/
        system("start #{filename}")
      end
    end

    def self.display_stop_scan_message
      puts "\nMaximum number of requests reached. Scan stopped".colorize(:yellow)
    end

    def self.display_radius_stats(stats)
      return if stats.empty?

      stats.each do |radius, count|
        puts "✓ Radius: #{radius}m, Places found: #{count}".colorize(:green)
      end
    end

    def self.update_status_line(radius, coordinates, requests, index) # rubocop:disable Metrics/AbcSize
      print "\e[s" # Save cursor position
      print "\e[2A" # Move up 2 lines
      print "\r\033[K" # Clear line and move to start
      status = "Rad: ".colorize(:cyan) + "#{radius.round(2)}m".colorize(:yellow) +
               " | Req: ".colorize(:cyan) + requests.to_s.colorize(:yellow) +
               " | Point: ".colorize(:cyan) + (index + 1).to_s.colorize(:yellow) +
               " | Loc: ".colorize(:cyan) + "(#{coordinates[:lat].round(6)}, #{coordinates[:lng].round(6)})".colorize(:yellow)
      print status
      print "\e[u" # Restore cursor position
    end
  end
end
