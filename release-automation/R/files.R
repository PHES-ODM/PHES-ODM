files_sheet_metadata <- list(
  file_name = list(
    name = "name"
  ),
  file_ID = list(
    name = "fileID"
  ),
  file_type = list(
    name = "fileType",
    categories = list(
      excel = "excel",
      csv = "csv"
    )
  ),
  part_ID = list(
    name = "partID"
  ),
  add_headers = list(
    name = "addHeaders"
  ),
  destinations = list(
    name = "destinations",
    categories = list(
      osf = "osf",
      github = "github"
    )
  ),
  osf_locations = list(
    name = "osfLocation"
  ),
  github_location = list(
    name = "githubLocation"
  )
)

create_files <- function(files_to_create, dictionary, write_dir) {
  # Loop over files to extract based on fileID
  for (file_id in names(files_to_create)) {
    current_file_info <- files_to_create[[file_id]]

    # Create a write directory based on destination and saving location
    current_file_dir <- file.path(
      write_dir,
      current_file_info$github_location
    )
    dir.create(current_file_dir,
      showWarnings = FALSE,
      recursive = TRUE
    )

    if (current_file_info$file_type == "excel") {
      # Use parts as names of sheets to extract
      sheets_to_copy <- current_file_info$sheet_names
      excel_file <- openxlsx::copyWorkbook(dictionary)
      all_dictionary_sheets <- names(dictionary)
      for (sheet_name in all_dictionary_sheets) {
        if (!(sheet_name %in% sheets_to_copy)) {
          openxlsx::removeWorksheet(excel_file, sheet_name)
        }
      }

      if (!is.null(current_file_info$add_headers)) {
        for (sheet_to_copy in sheets_to_copy) {
          worksheet <- openxlsx::readWorkbook(excel_file, sheet_to_copy)
          openxlsx::writeData(
            excel_file,
            sheet_to_copy,
            .add_headers(worksheet, current_file_info$add_headers)
          )
        }
      }

      # Save the workbook in the appropriate directory
      openxlsx::saveWorkbook(excel_file,
        file = file.path(
          current_file_dir,
          glue::glue("{current_file_info$file_name}.xlsx")
        ),
        overwrite = TRUE
      )
    } else if (current_file_info$file_type == "csv") {
      sheet_name <- current_file_info$sheet_names[1]
      csv_file <-
        openxlsx::readWorkbook(dictionary, sheet_name)
      if (!is.null(current_file_info$add_headers)) {
        csv_file <- .add_headers(csv_file, current_file_info$add_headers)
      }

      write.csv(csv_file,
        file = file.path(
          current_file_dir,
          glue::glue(
            "{current_file_info$file_name}.csv"
          )
        ),
        row.names = FALSE
      )
    }
  }
}

.add_headers <- function(df, headers) {
  df <-
    rbind(colnames(df), df)
  if (length(colnames(df)) > length(headers)) {
    length_to_append <-
      length(colnames(df)) - length(headers)
    headers <- c(headers, rep("", length_to_append))
  } else if (length(colnames(df)) < length(headers)) {
    length_to_append <-
      length(headers) - length(colnames(df))
    for (col_counter in 1:length_to_append) {
      df <- cbind(df, "")
    }
  }
  colnames(df) <- headers
  return(df)
}
