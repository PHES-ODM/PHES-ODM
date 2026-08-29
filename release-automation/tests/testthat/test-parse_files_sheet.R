test_that("Correctly parse CSV files", {
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

  expected_parsed_files <- list(
    partsSheet = list(
      file_name = "ODM_parts_1.0.0",
      file_type = "csv",
      sheet_names = c("parts"),
      add_headers = c("version", "1.0.0"),
      destinations = c("github"),
      osf_location = "N/A",
      github_location = "dictionary-tables/"
    )
  )

  expect_equal(parse_result$parsed_files, expected_parsed_files)
  expect_length(parse_result$errors, 0)
  expect_length(parse_result$warnings, 0)
})

test_that("Correctly parse Excel files when partID is a part", {
  odm_dictionary_df <- list(
    "summary" = data.frame(
      version = c("1.0.0")
    ),
    "files" = data.frame(
      fileID = c("partsSheet"),
      label = c(""),
      name = c("ODM_parts_{version}"),
      fileType = c("excel"),
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

  expected_parsed_files <- list(
    partsSheet = list(
      file_name = "ODM_parts_1.0.0",
      file_type = "excel",
      sheet_names = c("parts"),
      add_headers = c("version", "1.0.0"),
      destinations = c("github"),
      osf_location = "N/A",
      github_location = "dictionary-tables/"
    )
  )

  expect_equal(parse_result$parsed_files, expected_parsed_files)
  expect_length(parse_result$errors, 0)
  expect_length(parse_result$warnings, 0)
})

test_that("Correctly parse Excel files when partID is a set", {
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
  expected_parsed_files <- list(
    dictionary = list(
      file_name = "ODM_parts_1.0.0",
      file_type = "excel",
      sheet_names = c("parts", "sets"),
      add_headers = c("version", "1.0.0"),
      destinations = c("github"),
      osf_location = "N/A",
      github_location = "dictionary-tables/"
    )
  )
  expect_equal(parse_result$parsed_files, expected_parsed_files)
  expect_length(parse_result$errors, 0)
  expect_length(parse_result$warnings, 0)
})
