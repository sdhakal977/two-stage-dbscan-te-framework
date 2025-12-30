#' Visualize GPS Clusters on Interactive Leaflet Map


visualize_clusters_leaflet <- function(points_stops, points_move, 
                                       target_crs = 4326,
                                       map_tiles = "OpenStreetMap",
                                       colors = list(
                                         move = "blue",
                                         stop = "red", 
                                         start = "green",
                                         end = "purple"
                                       ),
                                       radii = list(
                                         move = 2,
                                         stop = 2,
                                         marker = 5
                                       )) {
  #' Visualize GPS Clusters on Interactive Leaflet Map
  #'
  #' @description
  #' Creates an interactive leaflet map showing moving points, stopping points,
  #' and start/end markers for each cluster and sub-cluster. This visualization
  #' helps analyze GPS movement patterns and stopping behavior.
  #'
  #' @param points_stops An `sf` object containing stopping points identified by
  #'   the clustering algorithm. Must contain columns: `cluster`, `sub_cluster_track`,
  #'   and `timestamp`. If NULL or empty, stopping points won't be displayed.
  #' @param points_move An `sf` object containing moving points identified by
  #'   the clustering algorithm. Must contain a `timestamp` column.
  #' @param target_crs Coordinate Reference System for the output map. Default is
  #'   4326 (WGS84).
  #' @param map_tiles Base map tile provider. Default is "OpenStreetMap".
  #'   Other options include: "CartoDB.Positron", "Esri.WorldImagery",
  #'   "OpenTopoMap", "Stamen.Toner". See `leaflet::providers` for full list.
  #' @param colors Named list specifying colors for different point types:
  #'   - `move`: Color for moving points (default: "blue")
  #'   - `stop`: Color for stopping points (default: "red")
  #'   - `start`: Color for cluster start markers (default: "green")
  #'   - `end`: Color for cluster end markers (default: "purple")
  #'   Colors can be any valid CSS color name, hex code, or RGB value.
  #' @param radii Named list specifying radii for different point types (in pixels):
  #'   - `move`: Radius for moving points (default: 2)
  #'   - `stop`: Radius for stopping points (default: 2)
  #'   - `marker`: Radius for start/end markers (default: 5)
  #'
  #' @return A `leaflet` map object that can be displayed, saved with
  #'   `htmlwidgets::saveWidget()`, or further customized with leaflet functions.
  #'
  #' @details
  #' The function performs the following steps:
  #' 1. Transforms all points to the specified target CRS
  #' 2. Extracts coordinates from `sf` objects
  #' 3. Identifies start and end points for each sub-cluster
  #' 4. Creates an interactive leaflet map with multiple layer groups
  #' 5. Adds layer controls for toggling different point types
  #'
  #' @note
  #' - Requires the `sf` package for spatial operations
  #' - Requires the `leaflet` package for map creation
  #' - Requires the `dplyr` package for data manipulation
  #' - All input `sf` objects must have a valid CRS defined
  #' - The `timestamp` column is used for point labels
  #'
  #' @examples
  #' \dontrun{
  #' # Basic usage with defaults
  #' result <- twostage_dbscan_te(gps_data, eps1 = 100, minPts1 = 5, ...)
  #' map <- visualize_clusters_leaflet(result$points_stops, result$points_move)
  #' map  # Display the map
  #'
  #' # Custom colors and radii
  #' map <- visualize_clusters_leaflet(
  #'   points_stops = result$points_stops,
  #'   points_move = result$points_move,
  #'   colors = list(
  #'     move = "navy",
  #'     stop = "orange",
  #'     start = "limegreen",
  #'     end = "darkviolet"
  #'   ),
  #'   radii = list(
  #'     move = 3,
  #'     stop = 4,
  #'     marker = 6
  #'   )
  #' )
  #'
  #' # Different coordinate system and map tiles
  #' map <- visualize_clusters_leaflet(
  #'   result$points_stops,
  #'   result$points_move,
  #'   target_crs = 32633,  # UTM zone 33N
  #'   map_tiles = "CartoDB.Positron"
  #' )
  #'
  #' # Save the map to HTML file
  #' htmlwidgets::saveWidget(map, "gps_clusters_map.html")
  #' }
  #'
  #' @importFrom leaflet leaflet addProviderTiles addCircleMarkers addLayersControl
  #'   layersControlOptions
  #' @importFrom dplyr %>% group_by summarise first last ungroup
  #' @importFrom sf st_transform st_coordinates st_crs
  #'
  #' @export
  
  # Load required libraries
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load("dplyr", "sf", "leaflet")
  
  # Transform to target CRS for leaflet
  points_move <- st_transform(points_move, crs = target_crs)
  
  if (!is.null(points_stops) && nrow(points_stops) > 0) {
    points_stops <- st_transform(points_stops, crs = target_crs)
    
    # Extract coordinates for points_stops
    coords_stops <- st_coordinates(points_stops)
    points_stops$lon <- coords_stops[, 1]
    points_stops$lat <- coords_stops[, 2]
    
    # Extract start and stop points of each sub-cluster
    start_stop_points <- points_stops %>%
      group_by(cluster, sub_cluster_track) %>%
      summarise(
        start_lat = first(lat),
        start_lon = first(lon),
        stop_lat = last(lat),
        stop_lon = last(lon)
      ) %>%
      ungroup()
  } else {
    points_stops <- NULL
    start_stop_points <- NULL
  }
  
  # Extract coordinates for points_move
  coords_move <- st_coordinates(points_move)
  points_move$lon <- coords_move[, 1]
  points_move$lat <- coords_move[, 2]
  
  # Create the leaflet map
  map <- leaflet() %>%
    addProviderTiles(map_tiles) %>%
    
    # Add moving points (using custom colors and radii)
    addCircleMarkers(data = points_move,
                     lng = ~lon,
                     lat = ~lat,
                     color = colors$move,
                     radius = radii$move,
                     label = ~as.character(timestamp),
                     group = "Moving Points")
  
  # Conditionally add stopping points (using custom colors and radii)
  if (!is.null(points_stops)) {
    map <- map %>%
      addCircleMarkers(data = points_stops,
                       lng = ~lon,
                       lat = ~lat,
                       color = colors$stop,
                       radius = radii$stop,
                       label = ~as.character(timestamp),
                       group = "Stopping Points")
  }
  
  # Conditionally add start and stop points (using custom colors and radii)
  if (!is.null(start_stop_points)) {
    map <- map %>%
      addCircleMarkers(data = start_stop_points,
                       lng = ~start_lon,
                       lat = ~start_lat,
                       color = colors$start,
                       radius = radii$marker,
                       label = ~paste("Start of Sub-cluster:", sub_cluster_track),
                       group = "Start Points") %>%
      addCircleMarkers(data = start_stop_points,
                       lng = ~stop_lon,
                       lat = ~stop_lat,
                       color = colors$end,
                       radius = radii$marker,
                       label = ~paste("End of Sub-cluster:", sub_cluster_track),
                       group = "Stop Points")
  }
  
  # Add layer control
  overlay_groups <- c("Moving Points")
  
  if (!is.null(points_stops)) {
    overlay_groups <- c(overlay_groups, "Stopping Points")
  }
  
  if (!is.null(start_stop_points)) {
    overlay_groups <- c(overlay_groups, "Start Points", "Stop Points")
  }
  
  map %>%
    addLayersControl(
      overlayGroups = overlay_groups,
      options = layersControlOptions(collapsed = FALSE)
    )
}

