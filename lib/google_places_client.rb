# frozen_string_literal: true

require 'httparty'
require 'retryable'
require 'json'
require 'uri'
require_relative 'map_spider'
require_relative 'logger'

class GooglePlacesClient
  attr_reader :requests_counter

  BASE_URL = "https://places.googleapis.com/v1/places"
  FIELDS = [
    "places.id",
    "places.displayName",
    "places.formattedAddress",
    "places.types",
    "places.location",
    "places.businessStatus",
    "places.primaryType",
    "places.googleMapsUri",
    "places.plusCode"
  ].join(',')

  RETRYABLE_ERRORS = [Net::OpenTimeout, HTTParty::Error, Resolv::ResolvError].freeze
  RETRY_OPTIONS = {
    tries: 3,
    sleep: 1,
    on: RETRYABLE_ERRORS
  }.freeze

  def initialize(api_key)
    @api_key = api_key
    @requests_counter = 0
  end

  def places_nearby(coordinates, radius, type)
    response = make_request(":searchNearby", build_body(coordinates, radius, type))

    response[:places] || []
  rescue => e
    Interface::UI.display_error("API Error in coordinates: #{coordinates[:lat]}, #{coordinates[:lng]} - #{e.message}")
    logger.error("API Error during coordinates: (#{coordinates[:lat]}, #{coordinates[:lng]}) - #{e.message}")
    []
  end

  private

  def build_body(coordinates, radius, type)
    body = {
      maxResultCount: MapSpider::MAX_PLACES_PER_REQUEST,
      locationRestriction: {
        circle: {
          center: {
            latitude: coordinates[:lat],
            longitude: coordinates[:lng]
          },
          radius: radius.to_f
        }
      }
    }
    body[:includedTypes] = [type] if type
    body[:rankPreference] = "DISTANCE" if radius <= MapSpider::MINIMAL_RADIUS
    body
  end

  def make_request(path, body)
    Retryable.retryable(RETRY_OPTIONS) do
      response = HTTParty.post(
        "#{BASE_URL}#{path}",
        body: body.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Goog-Api-Key' => @api_key,
          'X-Goog-FieldMask' => FIELDS
        }
      )
      @requests_counter += 1
      handle_response(response)
    end
  end

  def handle_response(response)
    case response.code
    when 200
      JSON.parse(response.body, symbolize_names: true)
    when 429
      raise "API quota exceeded"
    when 400
      raise "Invalid request: #{response['error']['message']}"
    when 401, 403
      raise "Authentication error: #{response['error']['message']}"
    else
      raise "API error: #{response['error']['message']}"
    end
  end

  def logger
    MapSpiderLogger.logger
  end
end
