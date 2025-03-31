# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/google_places_client"
require "webmock/rspec"
require_relative "../../lib/logger"

RSpec.describe GooglePlacesClient do
  let(:api_key) { "test-api-key" }
  let(:client) { described_class.new(api_key) }
  let(:request_params) do
    {
      coordinates: { lat: 41.7151, lng: 44.8271 },
      radius: 1000.0,
      type: "restaurant",
      base_url: GooglePlacesClient::BASE_URL,
      fields: GooglePlacesClient::FIELDS,
      headers: {
        "Content-Type" => "application/json",
        "X-Goog-Api-Key" => api_key,
        "X-Goog-FieldMask" => GooglePlacesClient::FIELDS
      }
    }
  end
  let(:mock_logger) { double("logger", error: nil) } # rubocop:disable RSpec/VerifiedDoubles

  before do
    WebMock.disable_net_connect!
    allow(MapSpiderLogger).to receive(:logger).and_return(mock_logger)
    allow(Interface::UI).to receive(:display_error)
  end

  describe "#initialize" do
    context "with valid api key" do
      it "initializes successfully" do
        expect(client.requests_counter).to eq(0)
        expect(client.instance_variable_get(:@api_key)).to eq(api_key)
      end
    end
  end

  describe "#places_nearby" do
    context "with successful API response" do
      let(:places) do
        [
          { id: "place1", displayName: { text: "Restaurant A" } },
          { id: "place2", displayName: { text: "Restaurant B" } }
        ]
      end

      before do
        stub_request(:post, "#{request_params[:base_url]}:searchNearby")
          .with(
            headers: request_params[:headers],
            body: hash_including(
              maxResultCount: MapSpider::MAX_PLACES_PER_REQUEST,
              locationRestriction: {
                circle: {
                  center: { latitude: request_params[:coordinates][:lat], longitude: request_params[:coordinates][:lng] },
                  radius: request_params[:radius]
                }
              }
            )
          )
          .to_return(
            status: 200,
            body: { places: places }.to_json
          )
      end

      it "returns places array and increments counter" do
        result = client.places_nearby(request_params[:coordinates], request_params[:radius], request_params[:type])
        expect(result).to eq(places)
        expect(client.requests_counter).to eq(1)
      end

      it "handles empty results" do
        stub_request(:post, "#{request_params[:base_url]}:searchNearby")
          .with(headers: request_params[:headers])
          .to_return(status: 200, body: { places: [] }.to_json)

        expect(client.places_nearby(request_params[:coordinates], request_params[:radius], request_params[:type])).to eq([])
      end

      it "adds type when specified" do
        client.places_nearby(request_params[:coordinates], request_params[:radius], request_params[:type])
        expect(WebMock).to have_requested(:post, "#{request_params[:base_url]}:searchNearby")
          .with(body: hash_including(includedTypes: [request_params[:type]]))
      end

      it "adds rankPreference for small radius" do
        stub_request(:post, "#{request_params[:base_url]}:searchNearby")
          .with(
            headers: request_params[:headers],
            body: hash_including(
              rankPreference: "DISTANCE",
              locationRestriction: {
                circle: {
                  center: { latitude: request_params[:coordinates][:lat], longitude: request_params[:coordinates][:lng] },
                  radius: MapSpider::MINIMAL_RADIUS
                }
              }
            )
          )
          .to_return(status: 200, body: { places: [] }.to_json)

        client.places_nearby(request_params[:coordinates], MapSpider::MINIMAL_RADIUS, request_params[:type])
        expect(WebMock).to have_requested(:post, "#{request_params[:base_url]}:searchNearby")
          .with(body: hash_including(rankPreference: "DISTANCE"))
      end
    end

    context "with network errors" do
      it "retries on network errors" do
        stub_request(:post, "#{request_params[:base_url]}:searchNearby")
          .with(headers: request_params[:headers])
          .to_raise(Net::OpenTimeout.new("Connection timed out"))
          .times(GooglePlacesClient::RETRY_OPTIONS[:tries])

        result = client.places_nearby(request_params[:coordinates], request_params[:radius], request_params[:type])
        expect(result).to eq([])

        error_msg = "API Error during coordinates: " \
                    "(#{request_params[:coordinates][:lat]}, #{request_params[:coordinates][:lng]}) - " \
                    "Connection timed out"
        expect(mock_logger).to have_received(:error).with(error_msg)
      end

      it "succeeds after retry" do
        stub_request(:post, "#{request_params[:base_url]}:searchNearby")
          .with(headers: request_params[:headers])
          .to_raise(Net::OpenTimeout.new("Connection timed out"))
          .then
          .to_return(status: 200, body: { places: [{ id: "place1" }] }.to_json)

        result = client.places_nearby(request_params[:coordinates], request_params[:radius], request_params[:type])
        expect(result).to eq([{ id: "place1" }])
      end
    end

    it "handles invalid JSON response" do
      stub_request(:post, "#{request_params[:base_url]}:searchNearby")
        .with(headers: request_params[:headers])
        .to_return(status: 200, body: "invalid json")

      result = client.places_nearby(request_params[:coordinates], request_params[:radius], request_params[:type])
      expect(result).to eq([])

      error_msg = "API Error during coordinates: " \
                  "(#{request_params[:coordinates][:lat]}, #{request_params[:coordinates][:lng]}) - " \
                  "unexpected character: 'invalid json'"
      expect(mock_logger).to have_received(:error).with(error_msg)
    end
  end
end
