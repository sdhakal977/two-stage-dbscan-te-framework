# 01_utilities.R
# Utility functions for data validation and formatting

#' Validate GPS Data Structure
#' 
#' @param df A data frame containing GPS data
#' @return TRUE if validation passes, stops with error message otherwise

library(dplyr)
library(lubridate)

validate_gps_data <- function(df) {
  required <- c("id", "timestamp", "latitude", "longitude")
  
  missing <- setdiff(required, names(df))
  
  if (length(missing) > 0) {
    stop(
      "GPS data validation failed.\n",
      "Your data must contain the following columns with these exact names:\n",
      paste(" -", required, collapse = "\n"),
      "\n\nMissing column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  
  TRUE
}

#' Convert Timestamp Column to POSIXct Format
#' 
#' Simple conversion using ymd_hms(). Assumes timestamps are in "YYYY-MM-DD HH:MM:SS" format.
#' 
#' @param gps_data A data frame containing GPS data
#' @return The GPS data with timestamp converted to POSIXct format
convert_timestamp <- function(gps_data) {
  # Check if timestamp column exists
  if (!"timestamp" %in% names(gps_data)) {
    stop("GPS data does not contain a 'timestamp' column", call. = FALSE)
  }
  
  # Convert the timestamp column to POSIXct format if it is not already
  if (!inherits(gps_data$timestamp, "POSIXct")) {
    gps_data <- gps_data %>%
      mutate(timestamp = ymd_hms(timestamp))
  }
  
  return(gps_data)
}


#' Validate and Prepare GPS Data
#' 
#' Combined utility function that validates GPS data structure and converts timestamps
#' 
#' @param gps_data A data frame containing GPS data
#' @return The GPS data with validated structure and converted timestamps
#' 
validate_and_prepare_gps_data <- function(gps_data) {
  # Validate data structure
  validate_gps_data(gps_data)
  
  # Convert timestamp (simple ymd_hms conversion)
  gps_data <- convert_timestamp(gps_data)
  
  return(gps_data)
}