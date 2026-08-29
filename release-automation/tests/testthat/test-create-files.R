test_that("Creating a CSV file", {
  odm_dictionary_df <- list(
    "summary" = data.frame(
      version = c("1.0.0")
    ),
    "files" = data.frame(
      fileID = c("partsSheet"),
      label = c(""),
      name = c("ODM_parts_{version}"),
      fileType = c("csv"),
      partID = c("parts"),
      addHeaders = c("version;{version}"),
      destinations = c("github"),
      osfLocation = c("N/A"),
      githubLocation = c("dictionary-tables/")
    ),
    parts = data.frame(
      partID = c("parts")
    ),
    sets = data.frame(setID = c("sets"))
  )
  odm_dictionary <- create_odm_dictionary(odm_dictionary_df)
  parse_result <- parse_files_sheet(odm_dictionary)

  file_creation_path <- "../assets/files"
  withr::defer({
    unlink(file_creation_path, recursive = TRUE)
  })

  create_files(parse_result$parsed_files, odm_dictionary, file_creation_path)

  csv_file_path <- file.path(
    file_creation_path,
    "/dictionary-tables/ODM_parts_1.0.0.csv"
  )
  expect_equal(
    file.exists(csv_file_path),
    TRUE
  )
  expect_equal(
    read.csv(csv_file_path),
    data.frame(
      version = c("partID", "parts"),
      X1.0.0 = c(NA, NA)
    )
  )
})

test_that("Creating an Excel file", {
  odm_dictionary_df <- list(
    "summary" = data.frame(
      version = c("1.0.0")
    ),
    "files" = data.frame(
      fileID = c("dictionary"),
      label = c(""),
      name = c("ODM_parts_{version}"),
      fileType = c("excel"),
      partID = c("dictionarySheets"),
      addHeaders = c("version;{version}"),
      destinations = c("github"),
      osfLocation = c("N/A"),
      githubLocation = c("dictionary-tables/")
    ),
    parts = data.frame(
      partID = c("parts", "sets", "dictionarySheets")
    ),
    sets = data.frame(
      setID = c("dictionarySheets", "dictionarySheets"),
      partID = c("parts", "sets")
    )
  )
  odm_dictionary <- create_odm_dictionary(odm_dictionary_df)
  parse_result <- parse_files_sheet(odm_dictionary)

  file_creation_path <- "../assets/files"
  withr::defer({
    unlink(file_creation_path, recursive = TRUE)
  })

  create_files(parse_result$parsed_files, odm_dictionary, file_creation_path)

  excel_file_path <- file.path(
    file_creation_path,
    "/dictionary-tables/ODM_parts_1.0.0.xlsx"
  )
  expect_equal(
    file.exists(excel_file_path),
    TRUE
  )
  created_excel <- openxlsx::loadWorkbook(
    file.path(excel_file_path)
  )
  expect_equal(
    openxlsx::readWorkbook(created_excel, "parts"),
    data.frame(
      version = c("partID", "parts", "sets", "dictionarySheets"),
      "1.0.0" = c("", "", "", ""),
      check.names = FALSE
    )
  )
  expect_equal(
    openxlsx::readWorkbook(created_excel, "sets"),
    data.frame(
      version = c("setID", "dictionarySheets", "dictionarySheets"),
      "1.0.0" = c("partID", "parts", "sets"),
      check.names = FALSE
    )
  )
})
