# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/csv_generator"

RSpec.describe CsvGenerator do
  describe ".generate" do
    let(:places) do
      [
        {
          id: "place123",
          displayName: { text: "Coffee Shop" },
          formattedAddress: "123 Main St",
          rating: 4.5,
          types: %w[cafe restaurant],
          location: { latitude: 37.7749, longitude: -122.4194 },
          businessStatus: "OPERATIONAL",
          userRatingsTotal: 100,
          primaryType: "cafe",
          googleMapsUri: "https://maps.google.com/?id=place123",
          plusCode: "ABCDEF"
        },
        {
          id: "place456",
          displayName: { text: "Pizza Place" },
          formattedAddress: "456 Oak St",
          rating: 4.0,
          types: %w[restaurant food],
          location: { latitude: 37.7848, longitude: -122.4294 },
          businessStatus: "OPERATIONAL",
          userRatingsTotal: 80,
          primaryType: "restaurant",
          googleMapsUri: "https://maps.google.com/?id=place456",
          plusCode: "GHIJKL"
        }
      ]
    end

    before do
      allow(FileUtils).to receive(:mkdir_p)

      fixed_time = Time.new(2023, 1, 1, 12, 0, 0)
      allow(Time).to receive(:now).and_return(fixed_time)
    end

    it "creates a CSV file with the correct filename" do
      csv_double = instance_double(CSV)
      allow(CSV).to receive(:open).and_yield(csv_double)
      allow(csv_double).to receive(:<<)

      expected_filename = "results/csv/places_20230101_120000.csv"
      expect(described_class.generate(places)).to eq(expected_filename)
    end

    it "writes headers and place data to the CSV file" do
      csv_data = StringIO.new
      allow(CSV).to receive(:open).and_yield(CSV.new(csv_data))

      described_class.generate(places)

      csv_lines = csv_data.string.split("\n")
      expect(csv_lines[0].split(",").map(&:strip)).to eq(CsvGenerator::HEADERS)

      expect(csv_lines[1]).to include("place123")
      expect(csv_lines[1]).to include("Coffee Shop")
      expect(csv_lines[1]).to include("123 Main St")
      expect(csv_lines[1]).to include("4.5")
      expect(csv_lines[1]).to include("cafe;restaurant")
      expect(csv_lines[1]).to include("37.7749,-122.4194")

      expect(csv_lines[2]).to include("place456")
      expect(csv_lines[2]).to include("Pizza Place")
      expect(csv_lines[2]).to include("456 Oak St")
    end

    it "handles places with nil values" do
      place_with_nils = [
        {
          id: "place789",
          displayName: { text: "Bakery" },
          formattedAddress: "789 Pine St",
          rating: nil,
          types: nil,
          location: { latitude: 37.7947, longitude: -122.4394 },
          businessStatus: nil,
          userRatingsTotal: nil,
          primaryType: "bakery",
          googleMapsUri: "https://maps.google.com/?id=place789",
          plusCode: nil
        }
      ]

      csv_data = StringIO.new
      allow(CSV).to receive(:open).and_yield(CSV.new(csv_data))

      described_class.generate(place_with_nils)

      csv_lines = csv_data.string.split("\n")
      place_line = csv_lines[1]

      expect(place_line).to include("place789")
      expect(place_line).to include("Bakery")
      expect(place_line).to include("37.7947,-122.4394")
      expect(place_line).to include("bakery")
    end
  end
end
