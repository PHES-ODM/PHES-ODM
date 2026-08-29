source("R/odm-dictionary-file.R")
source("R/files.R")
source("R/logging.R")
source("R/sets-sheet.R")
source("R/parts-sheet.R")

#' Create release files
#'
#' Creates release files given the user OSF link and auth token.
#'
#' @param osf_repo_link The link to the OSF repo.
#' @param osf_token The OSF token used to authenticate the user.
#'
#' @export
create_release_branch <- function(osf_repo_link, osf_token, github_token) {
  setup_logging()

  errors <- c()
  warnings <- c()

  download_dictionary_result <- download_dictionary(osf_token, "dev")
  warnings <- c(warnings, download_dictionary_result$warnings)

  parse_files_sheet_result <- parse_files_sheet(
    download_dictionary_result$dictionary
  )
  errors <- c(errors, parse_files_sheet_result$errors)
  warnings <- c(warnings, parse_files_sheet_result$warnings)
  if (length(errors) == 0) {
    parsed_github_files <- .get_github_files(
      parse_files_sheet_result$parsed_files
    )
    create_files(
      parsed_github_files,
      file.path(getwd(), "..")
    )
    # Download previous release dictionary
    previous_dictionary_download_results <- download_dictionary(
      osf_token, "current"
    )
    files_to_remove_result <-
      parse_files_sheet(parse_previous_dictionary_result$dictionary)
    remove_files(
      .get_github_files(files_to_remove_result$parsed_files),
      parse_previous_dictionary_result$dictionary
    )

    # Set git config
    system('git config user.name "PBL-Bot"')
    system('git config user.email "projectbiglife@toh.ca"')
    system(glue::glue("git config user.password {github_token}"))

    release_branch_name <- glue::glue(
      "release-{parse_dictionary_result$dictionary_version}"
    )

    system(glue::glue("git checkout -b {release_branch_name}"))

    commit_and_push_files(dictionary_version, release_branch_name)

    print("Operation Successful")
  } else {
    print(glue::glue(
      "{length(errors) errors found during the build process. They can be seen
      in the log file located at {log_file_path}. Aborting operation."
    ))
  }

  if (length(warnings) > 0) {
    print(glue::glue(
      "{length(warnings) warnings found during the build process. They can be
      seen in the log file located at {log_file_path}."
    ))
  }
}

#' Remove Files
#'
#' Helper function to remove files based on output from validate_and_parse_files_sheet.
#'
#' @param files_to_remove List output from validate_and_parse_files_sheet
#' @param dictionary openxlsx environment object storing the dictionary
remove_files <- function(files_to_remove, dictionary) {
  # Loop over files to remove based on fileID
  for (fileID in names(files_to_remove)) {
    current_file_info <- files_to_remove[[fileID]]
    # Skip OSF files
    if (!"github" %in% current_file_info$destination) {
      next()
    }

    # Create full file path
    file_extension <- switch(current_file_info$file_type,
      "excel" = ".xlsx",
      "csv" = ".csv"
    )
    file_path <- file.path(
      "..",
      current_file_info$github_location,
      paste0(current_file_info$file_name, file_extension)
    )
    # Check if file exists
    if (file.exists(file_path)) {
      file.remove(file_path)
    }
  }
}

#' Commit files
#'
#' Utility function to add, commit, and push all changes
#'
#' @param repo git2r object for repo reference
#' @param dictionary_version version of the dictionary being deployed
commit_and_push_files <- function(dictionary_version, branch_name) {
  # Add all files
  system("git add --all")
  # Create commit
  system(glue::glue('git commit -m "[BOT] release-{dictionary_version}"'))
  # Push updated branch
  system(glue::glue("git push origin {branch_name}"))
}

.get_github_files <- function(parsed_files) {
  github_files <- list()
  for (file_id in names(parse_files_sheet_result$parsed_files)) {
    if (parse_files_sheet_result$parsed_files[[file_id]] == "github") {
      github_files[[file_id]] <- parse_files_sheet_result$parsed_files[[file_id]]
    }
  }
  return(github_files)
}
