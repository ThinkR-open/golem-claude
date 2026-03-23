#' gpx_upload UI Function
#'
#' @description Module for selecting and loading a GPX file. The user can
#'   either upload their own GPX file or use the bundled example track.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList radioButtons conditionalPanel fileInput
#'   actionButton
mod_gpx_upload_ui <- function(id) {
  ns <- NS(id)
  tagList(
    radioButtons(
      ns("source"),
      label = "Data source",
      choices = c(
        "Use example track" = "example",
        "Upload GPX file" = "upload"
      ),
      selected = "example"
    ),
    conditionalPanel(
      condition = "input.source === 'upload'",
      ns = ns,
      fileInput(
        ns("gpx_file"),
        label = "Select GPX file",
        accept = ".gpx",
        buttonLabel = "Browse...",
        placeholder = "No file selected"
      )
    ),
    actionButton(
      ns("load"),
      label = "Load GPX",
      class = "btn-primary btn-block"
    )
  )
}

#' gpx_upload Server Function
#'
#' @param id Module id.
#' @param gpx_storage A `reactiveValues` object with a `data` element that
#'   will receive the loaded `sf` track data.
#'
#' @noRd
#'
#' @importFrom shiny moduleServer observeEvent req showNotification
#'   removeNotification
mod_gpx_upload_server <- function(id, gpx_storage) {
  moduleServer(id, function(input, output, session) {
    observeEvent(
      input$load,
      {
        path <- if (input$source == "example") {
          system.file("extdata", "example.gpx", package = "gpxviz")
        } else {
          req(input$gpx_file)
          input$gpx_file$datapath
        }

        notify_id <- showNotification("Loading GPX\u2026", duration = NULL)
        on.exit(removeNotification(notify_id), add = TRUE)

        gpx_storage$data <- read_gpx(path)
      }
    )
  })
}

## To be copied in the UI
# mod_gpx_upload_ui("gpx_upload")

## To be copied in the server
# mod_gpx_upload_server("gpx_upload", gpx_storage)
