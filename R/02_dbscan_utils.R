# do_dbscan.R
# Function to apply DBSCAN clustering

library(dbscan)
library(dplyr)
library(sf)

do_dbscan <- function(gps_data, eps, minPts) {
  coords <- st_coordinates(gps_data)
  db <- dbscan(coords, eps = eps, minPts = minPts)
  gps_data$cluster <- db$cluster
  points_move <- gps_data %>% filter(cluster == 0)
  points_stops <- gps_data %>% filter(cluster > 0)
  list(gps_data = gps_data, points_stops = points_stops, points_move = points_move)
}

