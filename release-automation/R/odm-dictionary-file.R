source("R/warnings.R")
source("R/errors.R")

parts_sheet_name <- "parts"
sets_sheet_name <- "sets"
files_sheet_name <- "files"
summary_sheet_name <- "summary"

parse_dictionary <- function(dictionary_path) {
  warnings <- c()

  # Read in the dictionary workbook
  dictionary <- openxlsx::loadWorkbook(dictionary_path)

  latest_version <- .get_latest_version_from_summary_sheet(
    openxlsx::readWorkbook(dictionary, "summary")
  )
  version_in_dictionary_file_name <- .get_version_from_dictionary_file_name(
    basename(dictionary_path)
  )
  if (latest_version != version_in_dictionary_file_name) {
    warnings <- c(warnings, version_number_mismatch_msg)
  }

  return(list(
    dictionary = dictionary,
    dictionary_version = latest_version,
    warnings = warnings
  ))
}
