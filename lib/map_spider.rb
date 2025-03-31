# frozen_string_literal: true

require_relative "interface"
require_relative "google_places_client"
require_relative "map_generator"
require "colorize"
require_relative "csv_generator"
require_relative "coordinates_calculator"
require_relative "logger"

class MapSpider
  MINIMAL_RADIUS = 15
  DEFAULT_MAX_REQUESTS = 100
  MAX_PLACES_PER_REQUEST = 20
  VERSION = "0.1.0"
  PERCENTAGE_EPSILON = 1

  def initialize
    @client = GooglePlacesClient.new(ENV.fetch("GOOGLE_MAPS_API_KEY", nil))
    @all_places = []
  end

  def start # rubocop:disable Metrics/AbcSize
    Interface::UI.display_banner
    logger.info("Application started")

    coordinates = Interface::UI.coordinates
    radius = Interface::UI.radius
    @max_requests = Interface::UI.max_requests || DEFAULT_MAX_REQUESTS
    @place_type = Interface::UI.place_type
    @total_area = area_size(radius).to_f

    Interface::UI.display_parameters(coordinates, radius, @max_requests, @place_type)

    coordinates.each_with_index do |coord, _index|
      @scanned_area = 0
      catch_places(coord, radius, radius)
    end

    remove_duplicates
    save_to_csv(@all_places)
    show_map(@filename) if Interface::UI.ask_to_show_map
  end

  private

  def catch_places(coordinates, radius, square_size) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return if @stop_scan
    return stop_scan if requests_counter >= @max_requests

    Interface::UI.update_status_line(radius, coordinates)

    places = @client.places_nearby(coordinates, radius, @place_type)

    logger.info(
      "Scanned point: #{coordinates[:lat]}, #{coordinates[:lng]}, " \
      "Radius: #{radius}, Places found: #{places.count}, " \
      "Requests: #{requests_counter}"
    )

    if places.count >= MAX_PLACES_PER_REQUEST && radius > MINIMAL_RADIUS
      offset = square_size / 2
      new_radius = offset * Math.sqrt(2)
      sub_coordinates = CoordinatesCalculator.calculate_sub_coordinates(coordinates, offset)

      sub_coordinates.each do |sub_coord|
        catch_places(sub_coord, new_radius, offset)
      end
    else
      @all_places.concat(places)
      @scanned_area += area_size(square_size)
      progressbar.progress = scanned_percentage
    end
  end

  def area_size(radius)
    4 * (radius**2)
  end

  def requests_counter
    @client.requests_counter
  end

  def stop_scan
    @stop_scan = true

    Interface::UI.display_stop_scan_message
  end

  def scanned_percentage
    percentage = (@scanned_area / @total_area * 100)

    return 100 if percentage + PERCENTAGE_EPSILON >= 100

    percentage
  end

  def remove_duplicates
    @all_places.uniq! { |place| place[:id] }
  end

  def save_to_csv(places)
    @filename = CsvGenerator.generate(places)
    Interface::UI.display_completion_message(@all_places.count, @filename, requests_counter)
  end

  def show_map(csv_filename)
    map_file = MapGenerator.generate(csv_filename)
    Interface::UI.display_map_generated(map_file)
  end

  def progressbar
    @progressbar ||= Interface::UI.create_progress_bar(100)
  end

  def logger
    MapSpiderLogger.logger
  end
end
