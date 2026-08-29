log_file_path <- file.path(getwd(), "log")

#' Sets up logging
setup_logging <- function() {
  file.remove(log_file_path)
  logger::log_appender(logger::appender_file(log_file_path))
}
