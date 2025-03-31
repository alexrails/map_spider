# frozen_string_literal: true

require_relative "../../lib/map_spider"
require_relative "../spec_helper"

RSpec.describe MapSpider do
  let(:api_key) { "fake_api_key" }
  let(:mock_client) { instance_double(GooglePlacesClient) }
  let(:map_spider) { described_class.new }

  before do
    allow(GooglePlacesClient).to receive(:new).and_return(mock_client)
    allow(ENV).to receive(:[]).with("GOOGLE_MAPS_API_KEY").and_return(api_key)

    allow(Interface::UI).to receive(:display_banner)
    allow(Interface::UI).to receive(:display_parameters)
    allow(Interface::UI).to receive(:update_status_line)
    allow(Interface::UI).to receive(:display_completion_message)

    progress_bar_double = instance_double(ProgressBar::Base, progress: 0)
    allow(progress_bar_double).to receive(:progress=)
    allow(Interface::UI).to receive_messages(
      coordinates: [{ lat: 40.7128, lng: -74.0060 }],
      radius: 100,
      max_requests: 10,
      place_type: "restaurant",
      ask_to_show_map: false,
      create_progress_bar: progress_bar_double
    )

    mock_logger = double("logger", info: nil) # rubocop:disable RSpec/VerifiedDoubles
    allow(MapSpiderLogger).to receive(:logger).and_return(mock_logger)
    allow(CsvGenerator).to receive(:generate).and_return("output.csv")
  end

  describe "#initialize" do
    it "creates a new GooglePlacesClient with the API key" do
      allow(GooglePlacesClient).to receive(:new).and_return(mock_client)
      described_class.new
      expect(GooglePlacesClient).to have_received(:new).with("AIzaSyC2EZJvFdir2b5VNpmM0uM5dd6b-97h6_c")
    end

    it "initializes empty places array" do
      expect(map_spider.instance_variable_get(:@all_places)).to eq([])
    end
  end

  describe "#start" do
    let(:mock_places) { [{ id: "1", name: "Place 1" }, { id: "2", name: "Place 2" }] }

    before do
      allow(mock_client).to receive_messages(places_nearby: mock_places, requests_counter: 1)
    end

    it "displays the banner" do
      allow(Interface::UI).to receive(:display_banner)
      map_spider.start
      expect(Interface::UI).to have_received(:display_banner)
    end

    it "gathers user input" do
      allow(Interface::UI).to receive_messages(
        coordinates: [{ lat: 40.7128, lng: -74.0060 }],
        radius: 100,
        max_requests: 10,
        place_type: "restaurant"
      )
      map_spider.start
      expect(Interface::UI).to have_received(:coordinates)
      expect(Interface::UI).to have_received(:radius)
      expect(Interface::UI).to have_received(:max_requests)
      expect(Interface::UI).to have_received(:place_type)
    end

    it "makes API call to fetch places" do
      allow(mock_client).to receive(:places_nearby).with(
        { lat: 40.7128, lng: -74.0060 }, 100, "restaurant"
      ).and_return(mock_places)
      map_spider.start
      expect(mock_client).to have_received(:places_nearby).with(
        { lat: 40.7128, lng: -74.0060 }, 100, "restaurant"
      )
    end

    it "saves results to CSV" do
      allow(CsvGenerator).to receive(:generate).and_return("output.csv")
      map_spider.start
      expect(CsvGenerator).to have_received(:generate).with(mock_places)
    end

    it "displays completion message" do
      allow(Interface::UI).to receive(:display_completion_message)
      map_spider.start
      expect(Interface::UI).to have_received(:display_completion_message).with(2, "output.csv", 1)
    end

    context "when max places per request is reached" do
      let(:mock_places) { Array.new(MapSpider::MAX_PLACES_PER_REQUEST) { |i| { id: i.to_s, name: "Place #{i}" } } }

      it "splits the area into sub-coordinates" do
        allow(CoordinatesCalculator).to receive(:calculate_sub_coordinates).and_return([
                                                                                         { lat: 40.71, lng: -74.01 },
                                                                                         { lat: 40.71, lng: -74.00 },
                                                                                         { lat: 40.72, lng: -74.01 },
                                                                                         { lat: 40.72, lng: -74.00 }
                                                                                       ])

        allow(mock_client).to receive(:places_nearby).and_return(mock_places, [], [], [], [])
        map_spider.start
        expect(CoordinatesCalculator).to have_received(:calculate_sub_coordinates)
      end
    end
  end

  describe "private methods" do
    describe "#remove_duplicates" do
      it "removes duplicates based on id" do
        places = [
          { id: "1", name: "Place 1" },
          { id: "1", name: "Place 1 Duplicate" },
          { id: "2", name: "Place 2" }
        ]

        map_spider.instance_variable_set(:@all_places, places)
        map_spider.send(:remove_duplicates)

        expect(map_spider.instance_variable_get(:@all_places).size).to eq(2)
        expect(map_spider.instance_variable_get(:@all_places).map { |p| p[:id] }).to eq(%w[1 2])
      end
    end

    describe "#area_size" do
      it "calculates area size correctly" do
        expect(map_spider.send(:area_size, 10)).to eq(400)
      end
    end

    describe "#scanned_percentage" do
      before do
        progress_bar_double = instance_double(ProgressBar::Base, progress: 0)
        allow(progress_bar_double).to receive(:progress=)
        allow(map_spider).to receive(:progressbar).and_return(progress_bar_double)
      end

      it "calculates percentage correctly" do
        map_spider.instance_variable_set(:@scanned_area, 2000.0)
        map_spider.instance_variable_set(:@total_area, 4000.0)

        expect(map_spider.send(:scanned_percentage)).to eq(50)
      end

      it "returns 100 if percentage is almost 100" do
        map_spider.instance_variable_set(:@scanned_area, 3996.0)
        map_spider.instance_variable_set(:@total_area, 4000.0)

        expect(map_spider.send(:scanned_percentage)).to eq(100)
      end
    end
  end
end
