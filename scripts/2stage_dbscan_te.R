# 2stage_dbscan_te.R
# Main analysis script for two-stage DBSCAN-based GPS data processing

# Load/install pacman first
if (!require("pacman")) install.packages("pacman")

# Load all required packages at once
pacman::p_load(
  dplyr,     # Data manipulation
  dbscan,    # DBSCAN clustering
  sf,        # Spatial data handling
  lubridate, # Date/time manipulation
  here       # Robust path handling
)

# Source modularized functions from R folder
source(here("R", "01_utilities.R"))
source(here("R", "02_dbscan_utils.R"))
source(here("R", "03_split_cluster.R"))
source(here("R", "04_fun_dir.R"))
source(here("R", "05_fun_entropy.R"))
source(here("R", "06_process_points.R"))
source(here("R", "post_processing", "04_post_processing_main.R"))


# Main function
twostage_dbscan_te <- function(gps_data, eps1, minPts1, time_threshold1, entropy_threshold1, 
                               eps2, minPts2, time_threshold2, entropy_threshold2, 
                               gradient_threshold = 2, distance_criteria = 25, divisions = 8,
                               max_segment_length = 25) {
  #' Process GPS Data to Identify Stopping Points and Moving Points in Three Steps
  #'
  #' @param gps_data An `sf` object containing GPS coordinates and timestamps.
  #' @param eps1 Numeric. The maximum distance for DBSCAN in the first step.
  #' @param minPts1 Integer. The minimum number of points for DBSCAN in the first step.
  #' @param time_threshold1 Numeric. The time gap threshold for splitting clusters in the first step.
  #' @param entropy_threshold1 Numeric. The entropy threshold in the first step.
  #' @param eps2 Numeric. The maximum distance for DBSCAN in the second step.
  #' @param minPts2 Integer. The minimum number of points for DBSCAN in the second step.
  #' @param time_threshold2 Numeric. The time gap threshold for splitting clusters in the second step.
  #' @param entropy_threshold2 Numeric. The entropy threshold in the second step.
  #' @param gradient_threshold Numeric. The threshold for identifying straight-line clusters (default is 2).
  #' @param distance_criteria Numeric. The distance threshold (in meters) for filtering clusters in the 2nd post-processing step (default is 25).
  #' @param divisions Integer. The number of bins to divide the direction angles into for entropy calculation (default is 8).
  #' @param max_segment_length Numeric. The maximum allowed segment length for the 3rd post-processing step (default is 50).
  #'
  #' @return A list containing:
  #' \describe{
  #'   \item{points_stops}{The refined stopping points that meet the final criteria.}
  #'   \item{points_move}{The combined moving points including filtered out stopping points.}
  #' }
  
  # Validate and prepare GPS data
  gps_data <- validate_and_prepare_gps_data(gps_data)
  
  # STOPS
  # --- Step 1: Initial Clustering ---
  result <- do_dbscan(gps_data, eps = eps1, minPts = minPts1)
  gps_data <- result$gps_data
  points_stops <- result$points_stops
  points_move <- result$points_move
  
  # --- Step 2: Splitting Clusters Based on Time Threshold ---
  points_stops <- split_cluster(points_stops, time_threshold1)
  
  # --- Step 3: Processing Points (1st Processing Step) ---
  processed <- process_points(points_stops, points_move, minPts = minPts1, entropy_threshold = entropy_threshold1)
  points_stops_step1 <- processed$points_stops
  points_move_step1 <- processed$points_move
  
  # --- Step 4: Second Clustering on Stop Points ---
  result <- do_dbscan(points_stops_step1, eps = eps2, minPts = minPts2)
  points_stops_step2 <- result$points_stops
  points_move_step2 <- points_move_step1 %>% bind_rows(result$points_move) %>% arrange(timestamp)
  
  # --- Step 5: Second Splitting Clusters Based on Time Threshold ---
  points_stops_step2 <- split_cluster(points_stops_step2, time_threshold2)
  
  # --- Step 6: Processing Points (2nd Processing Step) ---
  processed <- process_points(points_stops_step2, points_move_step2, minPts = minPts2, entropy_threshold = entropy_threshold2)
  points_stops_step2 <- processed$points_stops
  points_move_step2 <- processed$points_move
  
  points_stops_step2 <- st_as_sf(as.data.frame(points_stops_step2))
  class(points_stops_step2) <- c("sf", "data.frame")
  
  # Check if points_stops has at least minPts observations after the 2nd processing step
  if (nrow(points_stops_step2) < minPts2) {
    return(list(points_stops = points_stops_step2, points_move = points_move_step2))
  }
  
  # --- Apply All Post-Processing Steps ---
  post_processing_result <- post_processing_main(points_stops_step2, points_move_step2, 
                                                 gradient_threshold, distance_criteria, max_segment_length)
  
  points_stops <- post_processing_result$points_stops
  points_move <- post_processing_result$points_move
  
  points_stops <- st_as_sf(as.data.frame(points_stops))
  class(points_stops) <- c("sf", "data.frame")
  
  # Check if points_stops is empty, set it to NULL if no observations
  if (nrow(points_stops) == 0) {
    points_stops <- NULL
  }
  
  # Add the label 's' for stops in a new column
  points_stops <- points_stops %>%
    mutate(s_m_label = "s")
  
  # Add the label 'm' for move in a new column
  points_move <- points_move %>%
    mutate(s_m_label = "m")
  
  # --- Return Final Points ---
  return(list(points_stops = points_stops, points_move = points_move))
}


