# frozen_string_literal: true

require "csv"
require "json"
require "fileutils"
require_relative "logger"

class MapGenerator
  HTML_TEMPLATE = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>MapSpider Results</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <style>
            #map { height: 95vh; width: 100%%; }
            body { margin: 0; padding: 0; }
            .map-controls {#{' '}
                padding: 10px;
                background: white;
                box-shadow: 0 0 10px rgba(0,0,0,0.1);
            }
        </style>
    </head>
    <body>
        <div class="map-controls">
            <select id="mapStyle" onchange="changeMapStyle()">
                <option value="osm">OpenStreetMap</option>
                <option value="carto">Carto Light</option>
                <option value="terrain">Terrain</option>
            </select>
        </div>
        <div id="map"></div>
        <script>
            const map = L.map('map');
            let currentLayer;
    #{'        '}
            const layers = {
                osm: L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '© OpenStreetMap contributors'
                }),
                carto: L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {
                    attribution: '© CARTO'
                }),
                terrain: L.tileLayer('https://{s}.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png', {
                    attribution: '© Thunderforest'
                })
            };

            function changeMapStyle() {
                const style = document.getElementById('mapStyle').value;
                if (currentLayer) {
                    map.removeLayer(currentLayer);
                }
                currentLayer = layers[style];
                map.addLayer(currentLayer);
            }

            currentLayer = layers.osm;
            currentLayer.addTo(map);

            const markers = %s;
            const bounds = L.latLngBounds();
    #{'        '}
            markers.forEach(marker => {
                const [lat, lng] = marker.location.split(',').map(Number);
                bounds.extend([lat, lng]);
                L.marker([lat, lng])
                 .bindPopup('<b>' + marker.name + '</b><br>' + marker.address)
                 .addTo(map);
            });
    #{'        '}
            map.fitBounds(bounds);
        </script>
    </body>
    </html>
  HTML

  def self.generate(csv_file)
    FileUtils.mkdir_p("results/html")
    filename = "results/html/places_#{Time.now.strftime('%Y%m%d_%H%M%S')}.html"

    valid_places = process_places(csv_file)
    html_content = format(HTML_TEMPLATE, valid_places.to_json)

    File.write(filename, html_content)
    MapSpiderLogger.log_info("Generated HTML map #{filename} with #{valid_places.size} places")
    filename
  end

  def self.process_places(csv_file)
    places = CSV.read(csv_file, headers: true).filter_map do |row|
      next unless row["Coordinates"]

      {
        name: row["Name"] || "Unknown Place",
        location: row["Coordinates"],
        address: row["Address"] || "No address"
      }
    end

    places.select { |place| place[:location]&.include?(",") }
  end
end
