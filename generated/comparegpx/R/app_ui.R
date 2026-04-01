#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    bslib::page_sidebar(
      title = "GPX Track Comparator",
      theme = bslib::bs_theme(
        bootswatch = "flatly",
        base_font = bslib::font_google("Inter")
      ),
      sidebar = bslib::sidebar(
        title = "Tracks",
        width = 260,
        mod_gpx_reader_ui("gpx_reader")
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          bslib::card_title("Map Comparison")
        ),
        mod_map_display_ui("map_display")
      ),
      bslib::card(
        bslib::card_header(
          bslib::card_title("Similarity Analysis")
        ),
        mod_similarity_ui("similarity")
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "comparegpx"
    )
  )
}
