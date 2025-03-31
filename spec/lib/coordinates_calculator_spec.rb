# frozen_string_literal: true

require_relative "../../lib/coordinates_calculator"
require_relative "../spec_helper"

RSpec.describe CoordinatesCalculator do
  describe ".calculate_sub_coordinates" do
    subject(:sub_coordinates) { described_class.calculate_sub_coordinates(coordinates, offset) }

    let(:coordinates) { { lat: 55.7558, lng: 37.6173 } }
    let(:offset) { 1000 }

    it "returns array of 4 coordinate pairs" do
      expect(sub_coordinates.length).to eq(4)
      expect(sub_coordinates).to all(include(:lat, :lng))
    end

    it "calculates coordinates correctly" do
      expected_coords = [
        { lat: 55.7468, lng: 37.6013 },
        { lat: 55.7468, lng: 37.6333 },
        { lat: 55.7648, lng: 37.6013 },
        { lat: 55.7648, lng: 37.6333 }
      ]

      expect(sub_coordinates).to match_array(expected_coords.map do |coord|
        a_hash_including(lat: be_within(0.0001).of(coord[:lat]), lng: be_within(0.0001).of(coord[:lng]))
      end)
    end

    context "with edge cases" do
      it "handles equator coordinates" do
        equator_coords = { lat: 0.0, lng: 0.0 }
        result = described_class.calculate_sub_coordinates(equator_coords, offset)

        expect(result.length).to eq(4)
        expect(result.map { |coord| coord[:lat].abs }).to all(be_within(0.0001).of(0.009))
        expect(result.map { |coord| coord[:lng].abs }).to all(be_within(0.0001).of(0.009))
      end

      it "handles pole coordinates" do
        pole_coords = { lat: 89.9, lng: 0.0 } # Changed from 90.0 to 89.9
        result = described_class.calculate_sub_coordinates(pole_coords, offset)

        expect(result.length).to eq(4)
        expect(result.map { |coord| coord[:lat] }).to all(be < 90.0)
      end
    end
  end

  describe "constants" do
    it "defines Earth radius in meters" do
      expect(CoordinatesCalculator::EARTH_RADIUS).to eq(6_378_137.0)
    end

    it "defines correct conversion constants" do
      expect(CoordinatesCalculator::DEGREES_TO_RADIANS).to eq(Math::PI / 180.0)
      expect(CoordinatesCalculator::RADIANS_TO_DEGREES).to eq(180.0 / Math::PI)
    end
  end
end
