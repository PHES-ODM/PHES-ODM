source("R/files.R")
source("R/logging.R")

#' Update OSF files
#'
#' This function updates files on the Open Science Framework (OSF) using the provided OSF link and token.
#' It downloads the dictionary file, validates the dictionary version and files sheet, and stages the files to be uploaded to OSF.
#'
#' @param osf_repo_link The link to the OSF repo.
#' @param osf_token The OSF token used to authenticate the user.
#' @param dictionary_path The path to the dictionary file. If NULL, the file will be downloaded from OSF.
#' @param past_dictionary_path The path to the past dictionary file. If NULL, the file will be downloaded from OSF.
#'
merge_relase_branch <- function(osf_token) {
  setup_logging()

  # Download file using passed credentials
  dictionary_path <- download_dictionary(osf_token, "dev")

  # Validate dictionary version
  parse_dictionary_result <- parse_dictionary(dictionary_path)

  # Validate files sheet
  parse_files_sheet_result <-
    parse_files_sheet(parse_dictionary_result$dictionary)

  osf_files_to_make <- .get_osf_files(parse_files_sheet_result$parsed_files)

  create_files(osf_files_to_make, dictionary, file.path(getwd(), "../osf"))

  # Download previous release dictionary
  previous_dictionary_path <- download_dictionary(
    osf_token, "current"
  )

  # Validate dictionary version
  parse_previous_dictionary_result <- parse_dictionary(previous_dictionary_path)

  archive_previous_release(osf_token, parse_dictionary_result$dictonary_version)
}

#' Archive previous release
#'
#' This function archives the previous release on OSF. It creates a new archive folder, moves the previous release to the archive folder.
#'
#' @param osf_token The OSF token used to authenticate the user.
#' @param osf_link The OSF link to the main repo.
archive_previous_release <- function(
    osf_token,
    osf_link,
    past_dictionary_version) {
  # Authenticate with OSF, in case a local file is used
  osfr::osf_auth(osf_token)
  # Retrieve information from OSF
  osf_info <- osfr::osf_retrieve_node(osf_link)
  # Get info on current release
  root_info <- osfr::osf_ls_files(osf_info)
  current_release_info <- root_info[root_info$name == "Current Release", ]
  # Get info on archieve folder
  archive_info <- root_info[root_info$name == "Archived releases", ]
  # Make new archive dir
  new_archive <- osfr::osf_mkdir(archive_info, paste0("release_", past_dictionary_version))

  # Move contents of current_release_info into archive
  current_release_info_content <- osfr::osf_ls_files(current_release_info)
  for (release_index in seq(nrow(current_release_info_content))) {
    osfr::osf_mv(current_release_info_content[release_index, ], new_archive)
  }

  # Upload staged files
  osfr::osf_upload(
    current_release_info, "osf-stage/.",
    recurse = TRUE,
    conflicts = "overwrite"
  )
  # Upload dev dictionary
  osfr::osf_upload(
    current_release_info,
    paste0(odm_dictionary$tmp_dictionary_directory, "/."),
    conflicts = "overwrite"
  )
}

.get_osf_files <- function(parsed_files) {
  osf_files <- list()
  for (file_id in names(parse_files_sheet_result$parsed_files)) {
    if (parse_files_sheet_result$parsed_files[[file_id]] == "osf") {
      osf_files[[file_id]] <- parse_files_sheet_result$parsed_files[[file_id]]
    }
  }
  return(osf_files)
}
