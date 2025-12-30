# split_cluster.R
# Function to split clusters based on temporal sequence constraint

library(dplyr)
library(sf)

split_cluster <- function(points_stops, time_threshold) {
  delta_t <- time_threshold * 60  # Convert the time threshold to seconds
  points_stops <- points_stops %>%
    group_by(cluster) %>%
    arrange(timestamp) %>%
    mutate(
      time_diff = as.numeric(difftime(timestamp, lag(timestamp), units = "secs")),
      sub_cluster_track = paste(cluster, cumsum(is.na(time_diff) | time_diff > delta_t) + 1, sep = "_")
    ) %>%
    group_by(sub_cluster_track) %>%
    mutate(sub_cluster_size = n()) %>%
    ungroup()
  points_stops <- st_as_sf(as.data.frame(points_stops))
  class(points_stops) <- c("sf", "data.frame")
  return(points_stops)
}

