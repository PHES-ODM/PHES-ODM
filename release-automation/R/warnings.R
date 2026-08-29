library(glue)

source("R/files.R")

version_number_mismatch_id <- "W1"
version_number_mismatch_msg <- function(summary_sheet_version, file_name_version) {
  return(glue::glue(
    "Warning {version_number_mismatch_id}: The latest version defined in the ",
    "summary sheet is not equal to the version found in the file name.",
    "The summary sheet version is {summary_sheet_version} while the file ",
    "sheet version is {file_name_version}."
  ))
}

invalid_file_type_id <- "W2"
invalid_file_type_msg <- function(invalid_file_type, file_id) {
  return(glue::glue(
    "Warning {invalid_file_type_id}: Invalid file type found in row with ",
    "file ID {file_id}. Allowed file types are ",
    "{.fmt_categories(files$file_type$categories)} whereas we ",
    "found the file type {invalid_file_type}. Ignoring file."
  ))
}

invalid_destination_id <- "W3"
invalid_destination_msg <- function(invalid_destinations, file_id) {
  return(glue::glue(
    "Warning {invalid_destination_id_id}: Invalid destinations value found in ",
    "row with file ID {file_id}. Allowed values in the destinations column ",
    "are {.fmt_categories(files$destinations$categories)} whereas we found a
    destination ", "{invalid_destinations}. Ignoring file."
  ))
}

.fmt_file_type_categories <- function() {
  return(paste(files_sheet_metadata$file_type$categories, collapse = ", "))
}

.fmt_categories <- function(categories) {
  return(paste(files_sheet_metadata$file_type$categories, collapse = ", "))
}
