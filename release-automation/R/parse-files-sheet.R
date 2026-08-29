library(magrittr)

source("R/get-latest-version-from-summary-sheet.R")
source("R/errors.R")
source("R/odm-dictionary-file.R")

parse_files_sheet <- function(odm_dictionary) {
  files_sheet <-
    openxlsx::readWorkbook(odm_dictionary, files_sheet_name)
  sets_sheet <-
    openxlsx::readWorkbook(odm_dictionary, sets_sheet_name)
  parts_sheet <-
    openxlsx::readWorkbook(odm_dictionary, parts_sheet_name)

  dictionary_version <- get_latest_version_from_summary_sheet(
    openxlsx::readWorkbook(odm_dictionary, summary_sheet_name)
  )
  files_sheet_formatted <- .format_files_sheet_template_variable_columns(
    files_sheet,
    dictionary_version
  )

  parsed_files <- list()
  # Whether there are any errors in the entire file sheet
  warnings <- c()
  errors <- c()
  for (row_index in seq_len(nrow(files_sheet_formatted))) {
    is_file_valid <- TRUE
    files_sheet_row <- files_sheet_formatted[row_index, ]

    file_type <- files_sheet_row[[files_sheet_metadata$file_type$name]]
    if (!files_sheet_row$fileType %in%
      files_sheet_metadata$file_type$categories) {
      warnings <- c(warnings, invalid_file_type_msg(
        working_row[[files_sheet_metadata$file_type$name]],
        working_row[[files_sheet_metadata$file_ID$name]]
      ))
    }

    destinations <- .parse_array_column(files_sheet_row$destinations)
    for (destination in destinations) {
      if (!destination %in% files_sheet_metadata$destinations$categories) {
        warnings <- c(warnings, invalid_destination_msg(
          destination,
          files_sheet_row[[files_sheet_metadata$file_ID$name]]
        ))
      }
    }

    get_sheet_names_result <- .get_sheet_names_for_part(
      files_sheet_row[[files_sheet_metadata$part_ID$name]],
      odm_dictionary
    )
    if (is.null(get_sheet_names_result$sheet_names)) {
      errors <- c(errors, get_sheet_names_result$errors)
      is_file_valid <- FALSE
    } else if (length(get_sheet_names_result$sheet_names) > 1 &&
      file_type == "csv") {
      errors <- c(
        errors,
        invalid_csv_part_msg(
          files_sheet_row[[files_sheet_metadata$file_ID$name]],
          files_sheet_row[[files_sheet_metadata$part_ID$name]]
        )
      )
      is_file_valid <- FALSE
    }

    if (is_file_valid) {
      parsed_files[[files_sheet_row$fileID]] <- list(
        file_name = files_sheet_row[[files_sheet_metadata$file_name$name]],
        file_type = file_type,
        sheet_names = get_sheet_names_result$sheet_names,
        add_headers = .parse_array_column(files_sheet_row$addHeaders),
        destinations = destinations,
        osf_location = files_sheet_row$osfLocation,
        github_location = files_sheet_row$githubLocation
      )
    }
  }

  return(list(
    parsed_files = parsed_files,
    errors = errors,
    warnings = warnings
  ))
}

.format_files_sheet_template_variable_columns <- function(
    files_sheet,
    version) {
  template_variable_columns <- c(
    files_sheet_metadata$file_name$name,
    files_sheet_metadata$add_headers$name,
    files_sheet_metadata$osf_location$name
  )
  for (template_variable_column in template_variable_columns) {
    files_sheet[[template_variable_column]] <- gsub(
      template_variables$version,
      version,
      files_sheet[[template_variable_column]]
    )
  }
  return(files_sheet)
}

.get_sheet_names_for_part <- function(
    part_id,
    odm_dictionary) {
  sets_sheet <- openxlsx::readWorkbook(
    odm_dictionary,
    sets_sheet_name
  )
  sets <- sets_sheet %>%
    dplyr::filter(setID == part_id)
  if (nrow(sets) > 0) {
    sets_validation <- .validate_set_for_file_creation(part_id, odm_dictionary)
    if (length(sets_validation) > 0) {
      return(list(
        sheet_names = NULL,
        errors = sets_validation
      ))
    }
    return(list(
      sheet_names = sets[[sets_sheet_metadata$part_ID$name]],
      errors = c()
    ))
  }


  part_validation <- .validate_part_for_file_creation(
    part_id,
    odm_dictionary
  )
  if (length(part_validation) > 0) {
    return(list(
      sheet_names = NULL,
      errors = part_validation
    ))
  }
  return(
    list(sheet_names = c(part_id), errors = c())
  )
}

.parse_array_column <- function(column_value) {
  if (column_value == odm_dictionary$dictionary_missing_value) {
    return(NULL)
  }
  return(
    strsplit(column_value, ";")[[1]] %>%
      trimws(.)
  )
}

.validate_set_for_file_creation <- function(
    set_id,
    odm_dictionary) {
  errors <- c()
  sheets_in_set <- openxlsx::readWorkbook(
    odm_dictionary,
    sets_sheet_name
  ) %>%
    dplyr::filter(!!sets_sheet_metadata$set_ID$name == set_id) %>%
    .[[sets_sheet_metadata$part_ID$name]]
  file_id <- openxlsx::readWorkbook(odm_dictionary, files_sheet_name) %>%
    dplyr::filter(!!files_sheet_metadata$part_ID$name == set_id) %>%
    .[[files_sheet_metadata$file_ID$name]]
  all_dictionary_sheets <- names(odm_dictionary)
  for (set_sheet in sheets_in_set) {
    if (!set_sheet %in% all_dictionary_sheets) {
      errors <- c(errors, missing_sheet_msg(
        file_id,
        set_sheet,
        all_dictionary_sheets
      ))
    }
  }
  return(errors)
}

.validate_part_for_file_creation <- function(
    part_id,
    odm_dictionary) {
  errors <- c()
  file_id <- openxlsx::readWorkbook(odm_dictionary, files_sheet_name) %>%
    dplyr::filter(partID == part_id) %>%
    .[[files_sheet_metadata$file_ID$name]]
  dictionary_sheets <- names(odm_dictionary)
  if (!part_id %in% dictionary_sheets) {
    errors <- c(errors, missing_sheet_msg(
      file_id,
      part_id,
      dictionary_sheets
    ))
  }
  return(errors)
}
