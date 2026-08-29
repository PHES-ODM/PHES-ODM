get_latest_version_from_summary_sheet <- function(summary_sheet) {
  return(
    summary_sheet[[1]]
    %>% .[!is.na(.)]
      %>% .[length(.)]
  )
}
