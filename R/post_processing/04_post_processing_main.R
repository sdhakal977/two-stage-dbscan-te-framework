# post_processing_main.R
# Main post-processing module that sources and orchestrates individual post-processing functions

if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, dbscan, sf, lubridate, here)  # Load here

# Source individual post-processing functions
source(here("R", "post_processing", "01_utilities.R"))
source(here("R", "post_processing", "01_gradient_filter.R"))
source(here("R", "post_processing", "02_close_clusters.R"))
source(here("R", "post_processing", "03_long_segments.R"))


# Main post-processing function
post_processing_main <- function(points_stops_step2, points_move_step2, 
                                 gradient_threshold, distance_criteria, max_segment_length) {
  
  # Apply the three post-processing steps in sequence
  
  # --- 1st Post-Processing Step: Calculate Directional Gradient ---
  points_stops_step2 <- points_stops_step2 %>%
    group_by(sub_cluster_track) %>%
    mutate(gradient_var = var(calculate_gradient(dir_rad), na.rm = TRUE)) %>%
    ungroup()
  low_gradient_clusters <- points_stops_step2 %>%
    filter(gradient_var < gradient_threshold) %>%
    pull(sub_cluster_track)
  points_move_step2 <- points_move_step2 %>%
    bind_rows(points_stops_step2 %>%
                filter(sub_cluster_track %in% low_gradient_clusters))
  points_stops_step2 <- points_stops_step2 %>%
    filter(!sub_cluster_track %in% low_gradient_clusters)
  
  points_stops_step2 <- st_as_sf(as.data.frame(points_stops_step2))
  class(points_stops_step2) <- c("sf", "data.frame")
  
  # Check if points_stops has at least minPts observations after the 1st post-processing step
  if (nrow(points_stops_step2) < 2) {
    return(list(points_stops = points_stops_step2, points_move = points_move_step2))
  }
  
  # --- 2nd Post-Processing Step: Keep Close Clusters ---
  result <- keep_close_clusters(points_stops_step2, points_move_step2, distance_criteria = distance_criteria)
  points_stops_step2 <- result$points_stops
  points_move_step2 <- result$points_move
  
  points_stops_step2 <- st_as_sf(as.data.frame(points_stops_step2))
  class(points_stops_step2) <- c("sf", "data.frame")
  
  # Check if points_stops has at least minPts observations after the 2nd post-processing step
  if (nrow(points_stops_step2) < 2) {
    return(list(points_stops = points_stops_step2, points_move = points_move_step2))
  }
  
  # --- 3rd Post-Processing Step: Filter out clusters with long segments ---
  result <- filter_long_segments(points_stops_step2, points_move_step2, max_segment_length = max_segment_length)
  points_stops <- result$points_stops
  points_move <- result$points_move

  return(list(points_stops = points_stops, points_move = points_move))
}
