# MapSpider

MapSpider is a Ruby console application that helps you collect and visualize location data using the Google Places API.

## Features

- Search for places using Google Places API
- Support for multiple coordinates
- Customizable search radius
- Rate limiting and request management
- CSV export of place details
- Interactive map visualization with multiple map styles:
  - OpenStreetMap
  - Carto Light
  - Terrain

## Requirements

- Ruby 3.0+
- Google Places API(New) key

## Installation

1. Clone the repository:
```bash
git clone https://github.com/alexrails/map-spider.git
cd mapspider
```

2. Install dependencies:
```bash
bundle install
```

3. Create `.env` file and add your Google API key:
```bash
GOOGLE_MAPS_API_KEY=your_api_key_here
```

## Usage

Run the application:
```bash
./bin/map_spider
```

The application will prompt you for:
- Coordinates (latitude,longitude)
- Search radius (in meters)
- Maximum number of API requests
- Place type (optional)

### Example Input

```bash
$ ./bin/map_spider

 __  __              _____       _     _           
|  \/  |            / ____|     (_)   | |          
| \  / | __ _ _ __ | (___  _ __  _  __| | ___ _ __ 
| |\/| |/ _` | '_ \ \___ \| '_ \| |/ _` |/ _ \ '__|
| |  | | (_| | |_) |____) | |_) | | (_| |  __/ |   
|_|  |_|\__,_| .__/|_____/| .__/|_|\__,_|\___|_|   
             | |          | |                       
             |_|          |_|                       
                  v0.1.0

Enter coordinates (format: latitude,longitude) or 'done' to finish:
41.6377,41.6137
done

Enter search radius in meters (100-50000):
1000

Enter maximum number of requests:
50

Enter place type (or press Enter for all types):
restaurant

+================================================+
|                Search parameters                |
+========================+=======================+
|   Number of points     |   1                   |
|   Search radius        |   1000 meters         |
|   Max requests         |   50                  |
|   Place type          |   restaurant          |
+========================+=======================+

Status: R: 1000m | Coord: (41.6377, 41.6137)
Progress |████████████████████████████████| 100% | Speed: 7.25/sec

✓ Total unique places found: 42
✓ Spent requests: 3
✓ Results saved to results/csv/places_20240328_151016.csv

Do you want to see the found places on the map? (y/n):
y

✓ Map generated in results/html/places_20240328_151016.html
```

### Example Output Files

#### CSV Output (results/csv/places_20240328_151016.csv):
```csv
name,displayName,formattedAddress,location,types,...
"Batumi Restaurant","Batumi Restaurant","12 Rustaveli Ave","41.6377,41.6137","restaurant,food",...
```

#### Map Output (results/html/places_20240328_151016.html):
Interactive HTML map with:
- Multiple map style options (OpenStreetMap, Carto Light, Terrain)
- Markers for each found place
- Popup information on click
- Automatic zoom to show all locations