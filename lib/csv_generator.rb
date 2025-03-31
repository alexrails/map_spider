# frozen_string_literal: true

require "csv"
require "fileutils"

class CsvGenerator
  HEADERS = [
    "ID",
    "Name",
    "Address",
    "Rating",
    "Type",
    "Coordinates",
    "Business status",
    "User ratings total",
    "Primary type",
    "Google Maps URL",
    "Plus code"
  ].freeze

  def self.generate(places)
    FileUtils.mkdir_p("results/csv")
    filename = generate_filename
    write_to_csv(filename, places)
    filename
  end

  def self.generate_filename
    "results/csv/places_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"
  end

  def self.write_to_csv(filename, places)
    CSV.open(filename, "wb") do |csv|
      csv << HEADERS
      places.each do |place|
        csv << build_row(place)
      end
    end
  end

  def self.build_row(place)
    [
      place[:id],
      place[:displayName][:text],
      place[:formattedAddress],
      place[:rating],
      place[:types]&.join(";"),
      "#{place[:location][:latitude]},#{place[:location][:longitude]}",
      place[:businessStatus],
      place[:userRatingsTotal],
      place[:primaryType],
      place[:googleMapsUri],
      place[:plusCode]
    ]
  end
end
