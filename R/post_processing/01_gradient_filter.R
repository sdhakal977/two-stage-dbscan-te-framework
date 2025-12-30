# calculate_gradient.R
# Function for 1st Post-Processing Step (Calculate Directional Gradient)

library(dplyr)

calculate_gradient <- function(directions) {
  gradients <- c(NA, diff(directions))  
  return(gradients)
}