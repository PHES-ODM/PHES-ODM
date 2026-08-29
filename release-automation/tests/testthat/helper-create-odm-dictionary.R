create_odm_dictionary <- function(dictionary_df) {
  odm_dictionary <- openxlsx::createWorkbook("ODM-dictionary")
  for (sheet_name in names(dictionary_df)) {
    openxlsx::addWorksheet(odm_dictionary, sheet_name)
    openxlsx::writeData(
      odm_dictionary,
      sheet_name,
      dictionary_df[[sheet_name]]
    )
  }
  return(odm_dictionary)
}
