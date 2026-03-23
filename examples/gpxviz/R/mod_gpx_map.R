#' gpx_map UI Function
#'
#' @description Module that displays a ggplot2 map of a loaded GPX track.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList plotOutput
mod_gpx_map_ui <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("track_plot"), height = "500px")
  )
}

#' gpx_map Server Function
#'
#' @param id Module id.
#' @param gpx_storage A `reactiveValues` object with a `data` element
#'   containing an `sf` track object as returned by [read_gpx()].
#'
#' @noRd
#'
#' @importFrom shiny moduleServer renderPlot req
mod_gpx_map_server <- function(id, gpx_storage) {
  moduleServer(id, function(input, output, session) {
    output$track_plot <- renderPlot({
      req(!is.null(gpx_storage$data))
      plot_gpx(gpx_storage$data)
    })
  })
}

## To be copied in the UI
# mod_gpx_map_ui("gpx_map")

## To be copied in the server
# mod_gpx_map_server("gpx_map", gpx_storage)
