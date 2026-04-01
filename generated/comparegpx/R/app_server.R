#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Shared reactive storage passed to all modules
  track_storage <- reactiveValues(
    track1 = NULL,
    track2 = NULL
  )

  mod_gpx_reader_server("gpx_reader", track_storage)
  mod_map_display_server("map_display", track_storage)
  mod_similarity_server("similarity", track_storage)
}
