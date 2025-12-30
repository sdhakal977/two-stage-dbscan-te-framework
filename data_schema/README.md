# Data Schema & Requirements

This project processes high-dimensional GPS trajectory data. Although the original datasets are proprietary, 
the algorithm is designed to work with any GPS log following this schema.

## Input Requirements
The input data must be an `sf` (Simple Features) object in R with the following attributes:

| Column | Type | Description |
| :--- | :--- | :--- |
| `geometry` | POINT | Spatial coordinates (XY) |
| `timestamp` | POSIXct | Date and time of the recorded point |

## Spatial Reference System (CRS)
The algorithm performs distance-based clustering (Euclidean). Therefore, data must be projected into a **Projected Coordinate System** 
(e.g., SWEREF99 TM, EPSG:3006 or 3010) rather than a Geographic Coordinate System (WGS84). 

## Processing Pipeline
The function `twostage_dbscan_te()` assumes the data has undergone initial cleaning to remove signal jumps and 
is ordered chronologically by user/device ID.

## Data Quality Requirements
1. **Temporal Consistency**: Timestamps must be in chronological order
2. **No Duplicates**: Each point should have unique coordinates/timestamp
3. **Valid Geometry**: All points must have valid coordinate values
4. **Complete Records**: No missing values in mandatory columns