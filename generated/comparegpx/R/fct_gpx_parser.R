#' Parse a GPX file into a data frame
#'
#' @param file_path Path to the GPX file.
#'
#' @return A data frame with columns `lat` (numeric) and `lon` (numeric),
#'   one row per track point.
#'
#' @noRd
#'
#' @importFrom xml2 read_xml xml_find_all xml_attr
parse_gpx <- function(file_path) {
  doc <- xml2::read_xml(file_path)

  # Try with GPX 1.1 namespace first
  ns11 <- c(gpx = "http://www.topografix.com/GPX/1/1")
  trkpts <- xml2::xml_find_all(doc, ".//gpx:trkpt", ns11)

  # Fall back to GPX 1.0 namespace
  if (length(trkpts) == 0L) {
    ns10 <- c(gpx = "http://www.topografix.com/GPX/1/0")
    trkpts <- xml2::xml_find_all(doc, ".//gpx:trkpt", ns10)
  }
  # Fall back to no namespace
  if (length(trkpts) == 0L) {
    trkpts <- xml2::xml_find_all(doc, ".//trkpt")
  }

  if (length(trkpts) == 0L) {
    stop("No track points found in GPX file.", call. = FALSE)
  }

  lat <- as.numeric(xml2::xml_attr(trkpts, "lat"))
  lon <- as.numeric(xml2::xml_attr(trkpts, "lon"))

  data.frame(lat = lat, lon = lon)
}
