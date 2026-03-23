#' Read a GPX file
#'
#' @description Reads a GPX file and returns the track points as an `sf` object.
#'
#' @param path Character string. Path to the GPX file.
#'
#' @return An `sf` object with POINT geometries, one row per track point.
#'   Columns include `ele` (elevation), `time`, and `geometry`.
#'
#' @noRd
#'
#' @importFrom sf st_read
read_gpx <- function(path) {
  sf::st_read(path, layer = "track_points", quiet = TRUE)
}
