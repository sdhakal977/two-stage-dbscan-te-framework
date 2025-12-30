# keep_close_clusters.R
# Function for 2nd Post-Processing Step (Keep Close Clusters)

library(dplyr)
library(sf)

keep_close_clusters <- function(points_stops, points_move, distance_criteria) {
  coords <- st_coordinates(points_stops)
  points_stops <- points_stops %>%
    mutate(
      lon = coords[, 1],  # Longitude
      lat = coords[, 2]   # Latitude
    )
  
  crs <- st_crs(points_stops)
  
  start_end_points <- points_stops %>%
    group_by(sub_cluster_track) %>%
    arrange(timestamp) %>%
    summarise(
      start_lon = first(lon),   # Longitude of the first point
      start_lat = first(lat),   # Latitude of the first point
      end_lon = last(lon),      # Longitude of the last point
      end_lat = last(lat)       # Latitude of the last point
    ) %>%
    rowwise() %>%
    mutate(
      start_point = st_sfc(st_point(c(start_lon, start_lat)), crs = crs),
      end_point = st_sfc(st_point(c(end_lon, end_lat)), crs = crs),
      distance = abs(end_lon - start_lon) + abs(end_lat - start_lat)  # Manhattan distance
    ) %>%
    ungroup()
  
  valid_tracks <- start_end_points %>%
    filter(distance <= distance_criteria) %>%
    pull(sub_cluster_track)
  
  non_meeting_tracks <- start_end_points %>%
    filter(distance > distance_criteria) %>%
    pull(sub_cluster_track)
  
  points_stops_filtered <- points_stops %>%
    filter(sub_cluster_track %in% valid_tracks) %>%
    dplyr::select(-lon, -lat)
  
  non_meeting_data <- points_stops %>%
    filter(sub_cluster_track %in% non_meeting_tracks)
  
  points_move_combined <- points_move %>%
    bind_rows(non_meeting_data) %>%
    arrange(timestamp) %>%
    dplyr::select(-lon, -lat)
  
  return(list(points_stops = points_stops_filtered, points_move = points_move_combined))
}