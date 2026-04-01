#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @importFrom shiny tagList tags icon
#' @importFrom bslib page_navbar nav_panel bs_theme
#' @noRd
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    bslib::page_navbar(
      id    = "main_navbar",
      title = shiny::tags$span(
        shiny::icon("film"), " Video Tagger"
      ),
      theme = bslib::bs_theme(
        version    = 5,
        bootswatch = "flatly",
        primary    = "#2c7be5"
      ),
      # Folder selection tab (always the entry point)
      bslib::nav_panel(
        title = "Folder",
        value = "tab_folder",
        icon  = shiny::icon("folder"),
        mod_folder_select_ui("folder_select")
      ),
      bslib::nav_panel(
        title = "Search",
        value = "tab_search",
        icon  = shiny::icon("magnifying-glass"),
        mod_search_ui("search")
      ),
      bslib::nav_panel(
        title = "Tag",
        value = "tab_tag",
        icon  = shiny::icon("tag"),
        mod_tag_ui("tag")
      ),
      bslib::nav_panel(
        title = "Database",
        value = "tab_db",
        icon  = shiny::icon("database"),
        mod_db_io_ui("db_io")
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @importFrom shiny tags
#' @importFrom golem add_resource_path favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path      = app_sys("app/www"),
      app_title = "Video Tagger"
    ),
    shinyjs::useShinyjs()
  )
}
