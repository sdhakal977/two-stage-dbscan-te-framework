# fun_entropy.R
# Function to calculate entropy

fun_entropy <- function(gps_data, directions, divisions = 8) {
  directions <- directions[!is.na(directions)]
  hist_data <- hist(directions, breaks = seq(0, 2 * pi, length.out = divisions + 1), plot = FALSE)$counts
  N <- length(directions)
  prob <- hist_data / sum(hist_data)
  D <- sum(prob > 0)
  if (D == 1) {
    entropy <- 0
  } else {
    entropy <- -sum((hist_data / N) * log(hist_data / N + 1e-10)) / log(D)
    entropy <- rep(entropy, dim(gps_data)[1])
  }
  return(entropy)
}

