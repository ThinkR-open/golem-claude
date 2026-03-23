#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")

  gpx_storage <- reactiveValues(
    data = if (nchar(example_path) > 0) read_gpx(example_path) else NULL
  )

  mod_gpx_upload_server("gpx_upload", gpx_storage = gpx_storage)
  mod_gpx_map_server("gpx_map", gpx_storage = gpx_storage)
}
