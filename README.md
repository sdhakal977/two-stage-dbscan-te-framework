# GPS Data Processing: Two-Step DBSCAN-TE with Post-Processing


## Overview

This repository implements a robust pipeline for identifying stopping and moving points in GPS trajectories using a two-step DBSCAN-TE approach with custom post-processing. The method extends the original DBSCAN-TE algorithm with additional filtering steps for enhanced precision.


## Key Features

- **Two-step DBSCAN clustering** with temporal and entropy constraints

- **Custom post-processing** including directional gradient analysis, proximity filtering, and segment length filtering

- **Modular architecture** for maintainability and extensibility

- **Complete visualization** with interactive Leaflet maps


## Algorithm References

1. Gong, L., Yamamoto, T., & Morikawa, T. (2018). "Identification of activity stop locations in GPS trajectories by DBSCAN-TE method combined with support vector machines." *Transportation Research Procedia*, 32, 146-154.

2. Wang, K., Pang, L., & Li, X. (2022). "Identification of Stopping Points in GPS Trajectories by Two-Step Clustering Based on DPCC with Temporal and Entropy Constraints." *Sensors*, 23(7), 3749.


## Repository Structure

gps-dbscan-te/

├── archive/
├── data/
│ ├── raw/                     # Raw GPS data files (not included)
│ └── processed/               # Processed outputs
├── data_schema/               # Input data specifications
├── docs/                      # Documentation and paper summaries
├── R/                         # Core R functions
│ ├── 01_utilities.R
│ ├── 02_dbscan_utils.R
│ ├── 03_split_cluster.R
│ ├── 04_fun_dir.R
│ ├── 05_fun_entropy.R
│ ├── 06_process_points.R         
│ └── post_processing/         # Post-processing modules
│   ├── 01_utilities.R
│   ├── 01_gradient_filter.R
│   ├── 02_close_clusters.R
│   ├── 03_long_segments.R
│   └── 04_post_processing_main.R
├── scripts/                   # Execution scripts
│ ├── 2stage_dbscan_te.R
│ └── run_processing.R
├── visuals/                   # Visualization outputs
├── .gitignore
└── README.md


## Data Requirements

Input GPS data must be an sf object with:
- Point geometry
- timestamp column (POSIXct format)


## Output
- points_stops: Refined stopping points (sf object)
- points_move: Moving points (sf object)


## Citation

If you use this code in your research, please cite:
Dhakal, S. (2024). Two-Step DBSCAN-TE with Post-Processing for GPS Trajectory Analysis.



## Example Usage

## Run the processing pipeline:

```r

source("scripts/2stage_dbscan_te.R")

```

- Load your sf GPS data
gps_data <- ... 

- Parameters for Step 1
eps1 <- 50
minPts1 <- 4
time_threshold1 <- 5
entropy_threshold1 <- 0.8

- Parameters for Step 2
eps2 <- 5
minPts2 <- 4
time_threshold2 <- 5
entropy_threshold2 <- 0.9

- Process the GPS data

```r
results <- twostage_dbscan_te(gps_data, eps1, minPts1, time_threshold1, entropy_threshold1,
                            eps2, minPts2, time_threshold2, entropy_threshold2,
                            gradient_threshold = 2, distance_criteria = 25, max_segment_length = 50)


#Extract stopping points and moving points
points_stops <- results$points_stops
points_move <- results$points_move

```


## Visualization

The `visualize_clusters_leaflet()` function creates interactive maps of your GPS clusters:


```r
# Basic usage (WGS84 coordinate system)
map <- visualize_clusters_leaflet(result$points_stops, result$points_move)

# With custom coordinate system (e.g., UTM zone 33N)
map <- visualize_clusters_leaflet(result$points_stops, result$points_move, 
                                  target_crs = 32633)

# With different map tiles
map <- visualize_clusters_leaflet(result$points_stops, result$points_move,
                                  map_tiles = "CartoDB.Positron")

# Display the map
map

```
