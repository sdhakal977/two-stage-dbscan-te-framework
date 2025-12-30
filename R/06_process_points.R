# process_points.R
# Function to process points with filtering

library(dplyr)
library(sf)

process_points <- function(points_stops, points_move, minPts, entropy_threshold) {
  filtered_points <- points_stops %>% filter(sub_cluster_size < minPts)
  points_move <- points_move %>% bind_rows(filtered_points) %>% arrange(timestamp)
  points_stops <- points_stops %>%
    filter(sub_cluster_size >= minPts)
  
  points_stops <- st_as_sf(as.data.frame(points_stops))
  class(points_stops) <- c("sf", "data.frame")
  
  # Check if points_stops has at least minPts observations
  if (nrow(points_stops) < minPts) {
    return(list(points_stops = points_stops, points_move = points_move))
  }
  
  points_stops <- points_stops %>%
    group_by(sub_cluster_track) %>%
    group_map(~ {
      .x$dir_rad <- fun_dir(.x)
      .x$entropy <- fun_entropy(.x, .x$dir_rad)
      .x
    }, .keep = TRUE) %>%
    bind_rows() %>%
    ungroup()
  
  points_stops <- st_as_sf(as.data.frame(points_stops))
  class(points_stops) <- c("sf", "data.frame")
  
  filtered_points <- points_stops %>% filter(entropy < entropy_threshold)
  points_move <- points_move %>% bind_rows(filtered_points) %>% arrange(timestamp)
  points_stops <- points_stops %>% filter(entropy >= entropy_threshold)
  
  points_stops <- st_as_sf(as.data.frame(points_stops))
  class(points_stops) <- c("sf", "data.frame")
  
  # Check if points_stops has at least minPts observations after filtering by entropy
  if (nrow(points_stops) < minPts) {
    return(list(points_stops = points_stops, points_move = points_move))
  }
  
  return(list(points_stops = points_stops, points_move = points_move))
}

