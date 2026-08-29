library(magrittr)

source("R/get-latest-version-from-summary-sheet.R")

download_dictionary <- function(osf_token, osf_folder) {
  osfr::osf_auth(osf_token)
  repo_files <- osfr::osf_retrieve_node(osf_repo_link) %>%
    osfr::osf_ls_files()
  folder_name <- tidyr::if_else(
    osf_folder == "dev", developer_version_folder, current_version_folder
  )
  dictionary_folder <- repo_files[repo_files$name == folder_name, ]
  dictionary_file <- osfr::osf_ls_files(
    dictionary_folder,
    type = "file", pattern = "ODM_dev-dictionary"
  )
  download_info <- osfr::osf_download(
    requested_dictionary,
    path = dictionary_set_path,
    conflicts = "overwrite"
  )
  return(parse_dictionary(download_info[1, "local_path"]))
}
