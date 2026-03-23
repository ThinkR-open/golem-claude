#' Plot a GPX track
#'
#' @description Creates a ggplot2 visualization of a GPX track, connecting
#'   the track points into a path and marking the start (green) and end (red).
#'
#' @param track_data An `sf` object with POINT geometries, as returned by
#'   [read_gpx()].
#'
#' @return A `ggplot` object.
#'
#' @noRd
#'
#' @importFrom ggplot2 ggplot geom_sf theme_minimal labs
#' @importFrom sf st_cast st_combine
plot_gpx <- function(track_data) {
  track_line <- sf::st_cast(sf::st_combine(track_data), "LINESTRING")
  start_pt <- track_data[1, ]
  end_pt <- track_data[nrow(track_data), ]

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = track_line, color = "steelblue", linewidth = 1) +
    ggplot2::geom_sf(data = start_pt, color = "green3", size = 3) +
    ggplot2::geom_sf(data = end_pt, color = "red", size = 3) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::labs(
      title = "GPX Track",
      subtitle = "Green = start, Red = end",
      caption = paste(nrow(track_data), "track points"),
      x = "Longitude",
      y = "Latitude"
    )
}
