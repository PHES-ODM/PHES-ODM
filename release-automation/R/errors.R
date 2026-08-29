missing_sheet_id <- "E1"
missing_sheet_msg <- function(file_id, sheet_name, dictionary_sheets) {
  return(glue::glue(
    "Error {missing_sheet_id}: No sheet found with name {sheet_name} when
    creating file with ID  ", "{file_id}. The following sheets are in the
    dictionary ", "{paste(dictionary_sheets, collapse = ", ")}."
  ))
}

invalid_csv_part_id <- "E2"
invalid_csv_part_msg <- function(file_id, part_id) {
  return(glue::glue(
    "Error {invalid_csv_part_id}: The {part_id} used for the file with ID
    {file_id} is a set which is only allowed for files with type excel"
  ))
}
