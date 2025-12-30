# filter_long_segments.R
# Function for 3rd Post-Processing Step (Filter out clusters with long segments)

library(dplyr)
library(sf)

filter_long_segments <- function(points_stops, points_move, max_segment_length) {
  coords <- st_coordinates(points_stops)
  points_stops <- points_stops %>%
    mutate(
      lon = coords[, 1],  # Longitude
      lat = coords[, 2]   # Latitude
    )
  
  crs <- st_crs(points_stops)
  
  distances <- points_stops %>%
    group_by(sub_cluster_track) %>%
    arrange(timestamp) %>%
    mutate(
      next_lon = lead(lon),
      next_lat = lead(lat),
      segment_distance = abs(next_lon - lon) + abs(next_lat - lat)
    ) %>%
    ungroup()
  
  long_segments_clusters <- distances %>%
    filter(segment_distance > max_segment_length) %>%
    pull(sub_cluster_track) %>%
    unique()
  
  valid_clusters <- points_stops %>%
    filter(!sub_cluster_track %in% long_segments_clusters) %>%
    pull(sub_cluster_track)
  
  points_stops_filtered <- points_stops %>%
    filter(sub_cluster_track %in% valid_clusters) %>%
    dplyr::select(-lon, -lat)
  
  non_meeting_data <- points_stops %>%
    filter(sub_cluster_track %in% long_segments_clusters)
  
  points_move_updated <- points_move %>%
    bind_rows(non_meeting_data) %>%
    arrange(timestamp) %>%
    dplyr::select(-lon, -lat)
  
  return(list(points_stops = points_stops_filtered, points_move = points_move_updated))
}


