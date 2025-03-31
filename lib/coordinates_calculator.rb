# frozen_string_literal: true

class CoordinatesCalculator
  EARTH_RADIUS = 6_378_137.0 # Радиус Земли в метрах
  DEGREES_TO_RADIANS = Math::PI / 180.0
  RADIANS_TO_DEGREES = 180.0 / Math::PI

  class << self
    def calculate_sub_coordinates(coordinates, offset)
      lat = coordinates[:lat]
      lng = coordinates[:lng]

      lat_rad = degrees_to_radians(lat)
      delta_lat = calculate_delta_lat(offset)
      delta_lng = calculate_delta_lng(offset, lat_rad)

      generate_coordinates(lat, lng, delta_lat, delta_lng)
    end

    private

    def degrees_to_radians(degrees)
      degrees * DEGREES_TO_RADIANS
    end

    def calculate_delta_lat(offset)
      (offset / EARTH_RADIUS) * RADIANS_TO_DEGREES
    end

    def calculate_delta_lng(offset, lat_rad)
      (offset / (EARTH_RADIUS * Math.cos(lat_rad))) * RADIANS_TO_DEGREES
    end

    def generate_coordinates(lat, lng, delta_lat, delta_lng)
      [-1, 1].product([-1, 1]).map do |sign1, sign2|
        {
          lat: lat + (sign1 * delta_lat),
          lng: lng + (sign2 * delta_lng)
        }
      end
    end
  end
end
