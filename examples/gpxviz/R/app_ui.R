#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    fluidPage(
      title = "GPX Visualizer",
      titlePanel("GPX Visualizer"),
      sidebarLayout(
        sidebarPanel(
          width = 3,
          h4("Load GPX"),
          mod_gpx_upload_ui("gpx_upload")
        ),
        mainPanel(
          width = 9,
          mod_gpx_map_ui("gpx_map")
        )
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
      app_title = "GPX Visualizer"
    )
  )
}
