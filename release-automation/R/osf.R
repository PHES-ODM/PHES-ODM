library(tidyr)

osf_repo_link <- "https://osf.io/xevnh/"

developer_version_folder <- "Developer Version"
current_version_folder <- "Current Version"

#' Download dictionary
#'
#' Utility function to download dictionary from OSF
#'
#' @param osf_token string containing the OSF auth token
#' @param osf_repo_link string containing the link to the dictionary to download
#' @param dictionary_set_path string containing the path to be set if one is not provided
#'
#' @return string containing the path to the saved dictionary.
download_dictionary <- function(osf_token, osf_folder) {
  # Download file using passed credentials
  osfr::osf_auth(osf_token)
  repo_files <- osfr::osf_retrieve_node(osf_repo_link) %>%
    osfr::osf_ls_files()
  folder_name <- tidyr::if_else(
    osf_folder == "dev", developer_version_folder, current_version_folder
  )
  dictionary_folder <- repo_files[repo_files$name == folder_name, ]
  dictionary_file <- osfr::osf_ls_files(
    dictionary_folder,
    type = "file", pattern = "ODM_dictionary_"
  )
  download_info <- osfr::osf_download(
    requested_dictionary,
    path = dictionary_set_path,
    conflicts = "overwrite"
  )

  return(download_info[1, "local_path"])
}
