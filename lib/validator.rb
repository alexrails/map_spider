# frozen_string_literal: true

require 'colorize'

class Validator
  class << self
    def validate_coordinates(coordinates)
      unless coordinates.match?(/^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$/)
        puts "✗ Invalid coordinates format. Try again.".colorize(:red)
        return false
      end
      true
    end

    def validate_radius(radius)
      unless radius.to_i.between?(50, 50000)
        puts "✗ Radius must be between 50 and 50000 meters. Try again.".colorize(:red)
        return false
      end
      true
    end

    def validate_requests_number(requests_number)
      puts "✗ Requests number must be a positive number. Try again.".colorize(:red) unless requests_number.positive?
    end
  end
end
