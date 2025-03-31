# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/map_generator"
require_relative "../../lib/logger"

RSpec.describe MapGenerator do
  let(:test_csv_path) { "spec/fixtures/test_places.csv" }
  let(:output_dir) { "results/html" }
  let(:log_dir) { "logs" }

  before do
    FileUtils.mkdir_p("logs")
    FileUtils.mkdir_p("spec/fixtures")
    allow(MapSpiderLogger).to receive_messages(log_info: nil, log_error: nil)
  end

  after do
    FileUtils.rm_rf("spec/fixtures")
    FileUtils.rm_rf(output_dir)
    FileUtils.rm_rf("logs")
  end

  describe ".generate" do
    context "with valid places" do
      before do
        CSV.open(test_csv_path, "w") do |csv|
          csv << %w[Name Coordinates Address]
          csv << ["Test Place 1", "40.7128,-74.0060", "123 Test St"]
          csv << ["Test Place 2", "51.5074,-0.1278", "456 Sample Rd"]
        end
      end

      it "generates an HTML file with the correct content" do
        filename = described_class.generate(test_csv_path)

        expect(File.exist?(filename)).to be true
        content = File.read(filename)

        expect(content).to include("<!DOCTYPE html>")
        expect(content).to include('<div id="map"></div>')
        expect(content).to include("leaflet.js")

        expect(content).to include("Test Place 1")
        expect(content).to include("40.7128,-74.0060")
        expect(content).to include("123 Test St")
      end

      it "creates output directory if it does not exist" do
        FileUtils.rm_rf(output_dir)
        described_class.generate(test_csv_path)
        expect(Dir.exist?(output_dir)).to be true
      end

      it "generates file with correct naming pattern" do
        filename = described_class.generate(test_csv_path)
        expect(filename).to match(%r{results/html/places_\d{8}_\d{6}\.html})
      end
    end

    context "with invalid coordinates" do
      before do
        CSV.open(test_csv_path, "w") do |csv|
          csv << %w[Name Coordinates Address]
          csv << ["Valid Place", "40.7128,-74.0060", "123 Test St"]
          csv << ["Invalid Place", "invalid", "456 Bad St"]
          csv << ["Empty Place", "", "789 Null St"]
        end
      end

      it "filters out invalid coordinates" do
        filename = described_class.generate(test_csv_path)
        content = File.read(filename)

        expect(content).to include("40.7128,-74.0060")
        expect(content).not_to include("invalid")
        expect(content).not_to include("Empty Place")
      end
    end

    context "with missing values" do
      before do
        CSV.open(test_csv_path, "w") do |csv|
          csv << %w[Name Coordinates Address]
          csv << [nil, "40.7128,-74.0060", nil]
        end
      end

      it "uses default values for missing fields" do
        filename = described_class.generate(test_csv_path)
        content = File.read(filename)

        expect(content).to include("Unknown Place")
        expect(content).to include("No address")
        expect(content).to include("40.7128,-74.0060")
      end
    end

    context "with non-existent file" do
      it "raises ENOENT error" do
        expect do
          described_class.generate("nonexistent.csv")
        end.to raise_error(Errno::ENOENT)
      end
    end

    context "with malformed CSV" do
      before do
        File.write(test_csv_path, "malformed,csv\ndata")
      end

      it "generates empty map without raising error" do
        filename = described_class.generate(test_csv_path)
        content = File.read(filename)
        expect(content).to include("const markers = []")
      end
    end
  end
end
