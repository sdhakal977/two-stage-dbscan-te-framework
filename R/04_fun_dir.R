# fun_dir.R
# Function to calculate direction (angle) between consecutive points

library(sf) 

fun_dir <- function(gps_data) {
  coords <- st_coordinates(gps_data)
  directions <- numeric(length = nrow(gps_data) - 1)
  for (i in 1:(nrow(gps_data) - 1)) {
    pt1 <- coords[i, ]
    pt2 <- coords[i + 1, ]
    x_diff <- pt2[1] - pt1[1]
    y_diff <- pt2[2] - pt1[2]
    alpha <- atan2(y_diff, x_diff)
    if (alpha < 0) alpha <- alpha + 2 * pi
    directions[i] <- alpha
  }
  directions <- c(directions, NA)
  return(directions)
}

