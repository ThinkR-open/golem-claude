#' gpx_reader UI Function
#'
#' @description Module for uploading or using default GPX tracks.
#'   Provides file inputs and reverse-direction toggles for two tracks.
#'
#' @param id Internal parameter for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList fileInput checkboxInput tags hr
mod_gpx_reader_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$h6("Track 1", class = "fw-semibold text-primary mt-2"),
    fileInput(
      ns("file1"),
      label = NULL,
      accept = ".gpx",
      placeholder = "Default: Morning Run",
      buttonLabel = "Browse\u2026"
    ),
    checkboxInput(ns("reverse1"), "Reverse direction", value = FALSE),
    hr(),
    tags$h6("Track 2", class = "fw-semibold text-success mt-2"),
    fileInput(
      ns("file2"),
      label = NULL,
      accept = ".gpx",
      placeholder = "Default: Evening Run",
      buttonLabel = "Browse\u2026"
    ),
    checkboxInput(ns("reverse2"), "Reverse direction", value = FALSE)
  )
}

#' gpx_reader Server Functions
#'
#' @param id Internal parameter for {shiny}.
#' @param track_storage A [shiny::reactiveValues()] object with fields
#'   `track1` and `track2` (data frames with `lat`/`lon` columns).
#'
#' @noRd
#'
#' @importFrom shiny moduleServer reactiveValues observeEvent req
mod_gpx_reader_server <- function(id, track_storage) {
  moduleServer(id, function(input, output, session) {
    local_rv <- reactiveValues(
      raw_track1 = parse_gpx(app_sys("app/www/track1.gpx")),
      raw_track2 = parse_gpx(app_sys("app/www/track2.gpx"))
    )

    # Initialise shared storage with default tracks
    track_storage$track1 <- local_rv$raw_track1
    track_storage$track2 <- local_rv$raw_track2

    # ---- File uploads ---------------------------------------------------

    observeEvent(input$file1, {
      local_rv$raw_track1 <- parse_gpx(input$file1$datapath)
      df <- local_rv$raw_track1
      track_storage$track1 <- if (isTRUE(input$reverse1)) df[nrow(df):1L, ] else df
    })

    observeEvent(input$file2, {
      local_rv$raw_track2 <- parse_gpx(input$file2$datapath)
      df <- local_rv$raw_track2
      track_storage$track2 <- if (isTRUE(input$reverse2)) df[nrow(df):1L, ] else df
    })

    # ---- Reverse toggles ------------------------------------------------

    observeEvent(input$reverse1, {
      req(!is.null(local_rv$raw_track1))
      df <- local_rv$raw_track1
      track_storage$track1 <- if (isTRUE(input$reverse1)) df[nrow(df):1L, ] else df
    }, ignoreInit = TRUE)

    observeEvent(input$reverse2, {
      req(!is.null(local_rv$raw_track2))
      df <- local_rv$raw_track2
      track_storage$track2 <- if (isTRUE(input$reverse2)) df[nrow(df):1L, ] else df
    }, ignoreInit = TRUE)
  })
}
