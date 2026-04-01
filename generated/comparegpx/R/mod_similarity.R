#' similarity UI Function
#'
#' @description Module displaying the similarity percentage between two GPX
#'   tracks together with supporting distance metrics.
#'
#' @param id Internal parameter for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList textOutput
mod_similarity_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      bslib::value_box(
        title = "Similarity",
        value = textOutput(ns("pct")),
        showcase = bsicons::bs_icon("bullseye"),
        theme = "primary",
        full_screen = FALSE
      ),
      bslib::value_box(
        title = "Mean distance",
        value = textOutput(ns("mean_dist")),
        showcase = bsicons::bs_icon("rulers"),
        theme = "secondary",
        full_screen = FALSE
      ),
      bslib::value_box(
        title = "Hausdorff distance",
        value = textOutput(ns("hausdorff")),
        showcase = bsicons::bs_icon("arrow-left-right"),
        theme = "light",
        full_screen = FALSE
      )
    )
  )
}

#' similarity Server Functions
#'
#' @param id Internal parameter for {shiny}.
#' @param track_storage A [shiny::reactiveValues()] object with fields
#'   `track1` and `track2` (data frames with `lat`/`lon` columns).
#'
#' @noRd
#'
#' @importFrom shiny moduleServer reactiveValues observeEvent renderText req
mod_similarity_server <- function(id, track_storage) {
  moduleServer(id, function(input, output, session) {
    local_rv <- reactiveValues(result = NULL)

    observeEvent(
      list(track_storage$track1, track_storage$track2),
      {
        req(!is.null(track_storage$track1), !is.null(track_storage$track2))
        local_rv$result <- calculate_similarity(
          track_storage$track1,
          track_storage$track2
        )
      }
    )

    output$pct <- renderText({
      req(!is.null(local_rv$result))
      paste0(round(local_rv$result$percentage, 1), "%")
    })

    output$mean_dist <- renderText({
      req(!is.null(local_rv$result))
      paste0(round(local_rv$result$mean_dist, 0), " m")
    })

    output$hausdorff <- renderText({
      req(!is.null(local_rv$result))
      paste0(round(local_rv$result$hausdorff_dist, 0), " m")
    })
  })
}
