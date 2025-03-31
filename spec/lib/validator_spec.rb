# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/validator"

RSpec.describe Validator do
  describe ".validate_coordinates" do
    it "returns true for valid coordinates" do
      valid_coordinates = [
        "37.7749,-122.4194",
        "-37.7749, 122.4194",
        "0,0",
        "37.7749, -122.4194",
        "-89.999999,-179.999999"
      ]

      valid_coordinates.each do |coords|
        expect(described_class.validate_coordinates(coords)).to be true
      end
    end

    it "returns false for invalid coordinates" do
      allow($stdout).to receive(:puts)

      invalid_coordinates = [
        "invalid",
        "37.7749",
        "37.7749,-",
        "37.7749, abc",
        "37.7749, 122.4194, 0",
        ",122.4194"
      ]

      invalid_coordinates.each do |coords|
        expect(described_class.validate_coordinates(coords)).to be false
      end
    end

    it "outputs error message for invalid coordinates" do
      allow($stdout).to receive(:puts)
      described_class.validate_coordinates("invalid")
      expect($stdout).to have_received(:puts).with(/Invalid coordinates format/)
    end
  end

  describe ".validate_radius" do
    it "returns true for valid radius values" do
      valid_radius = [50, 100, 1000, 50_000, "100", "1000"]

      valid_radius.each do |radius|
        expect(described_class.validate_radius(radius)).to be true
      end
    end

    it "returns false for invalid radius values" do
      allow($stdout).to receive(:puts)

      invalid_radius = [0, 49, 50_001, "0", "49", "50001", "invalid"]

      invalid_radius.each do |radius|
        expect(described_class.validate_radius(radius)).to be false
      end
    end

    it "outputs error message for invalid radius" do
      allow($stdout).to receive(:puts)
      described_class.validate_radius(0)
      expect($stdout).to have_received(:puts).with(/Radius must be between 50 and 50000 meters/)
    end
  end

  describe ".validate_requests_number" do
    it "returns nil and outputs error for non-positive numbers" do
      allow($stdout).to receive(:puts)
      expect(described_class.validate_requests_number(0)).to be_nil
      expect($stdout).to have_received(:puts).with(/Requests number must be a positive number/)
    end

    it "does not output error for positive numbers" do
      allow($stdout).to receive(:puts)
      described_class.validate_requests_number(5)
      expect($stdout).not_to have_received(:puts)
    end
  end
end
