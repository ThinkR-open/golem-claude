#' folder_select UI Function
#'
#' @description Landing page module for selecting a video folder.
#'
#' @param id Module id.
#'
#' @noRd
#' @importFrom shiny NS tagList icon tags actionButton selectInput updateSelectInput
#' @importFrom bslib page_fluid card card_header card_body
mod_folder_select_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::page_fluid(
      class = "min-vh-100 d-flex align-items-center justify-content-center bg-light",
      bslib::card(
        style = "min-width:520px; max-width:600px;",
        class = "shadow-sm",
        bslib::card_header(
          class = "bg-primary text-white text-center py-3",
          shiny::tags$h3(
            shiny::icon("film"), " Video Tagger",
            class = "mb-0 fw-bold"
          )
        ),
        bslib::card_body(
          class = "p-4",
          shiny::tags$p(
            "Select a folder on your computer containing videos to get started.",
            class = "text-center text-muted mb-4"
          ),
          shiny::actionButton(
            ns("folder_btn"),
            label = "Open Folder\u2026",
            icon = shiny::icon("folder-open"),
            class = "btn btn-primary btn-lg w-100"
          ),
          shiny::tags$hr(class = "my-4"),
          shiny::tags$h6(
            shiny::icon("clock-rotate-left"), " Recent Folders",
            class = "text-muted fw-semibold mb-2"
          ),
          shiny::selectInput(
            ns("recent_path"),
            label = NULL,
            choices = c("No recent folders" = ""),
            width = "100%"
          ),
          shiny::actionButton(
            ns("open_recent_btn"),
            label = "Open Selected Folder",
            icon = shiny::icon("folder"),
            class = "btn btn-outline-secondary w-100"
          )
        )
      )
    )
  )
}

#' folder_select Server Function
#'
#' @param id Module id.
#' @param app_state A `reactiveValues()` with fields `db_con`, `folder_path`,
#'   `folder_id`, and `refresh` (integer counter incremented after folder open).
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent updateSelectInput req
#' @importFrom fs path_home
mod_folder_select_server <- function(id, app_state) {
  moduleServer(id, function(input, output, session) {

    # Populate the recent-folders dropdown on init and after each state refresh
    observeEvent(app_state$refresh, {
      folders <- db_get_folders(app_state$db_con)
      if (nrow(folders) > 0L) {
        choices <- stats::setNames(folders$path, folders$path)
        shiny::updateSelectInput(session, "recent_path", choices = choices)
      }
    }, ignoreInit = FALSE, ignoreNULL = FALSE)

    # Open a native folder-picker dialog via tcltk
    observeEvent(input$folder_btn, {
      path <- tryCatch(
        tcltk::tk_choose.dir(
          default = as.character(fs::path_home()),
          caption = "Select a video folder"
        ),
        error = function(e) NULL
      )
      req(!is.null(path), !is.na(path), nchar(path) > 0L)
      .open_folder(path, app_state)
    })

    observeEvent(input$open_recent_btn, {
      req(input$recent_path, nchar(input$recent_path) > 0L)
      .open_folder(input$recent_path, app_state)
    })
  })
}

#' Open a folder: upsert in DB, sync videos, register resource, update state
#'
#' @param path Absolute path to the folder.
#' @param app_state The shared `reactiveValues()`.
#' @noRd
.open_folder <- function(path, app_state) {
  con <- app_state$db_con
  folder_id <- db_upsert_folder(con, path)
  db_sync_videos(con, folder_id, path)
  register_video_resource(path)
  app_state$folder_path <- path
  app_state$folder_id <- folder_id
  app_state$refresh <- app_state$refresh + 1L
}
