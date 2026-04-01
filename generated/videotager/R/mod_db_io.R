#' db_io UI Function
#'
#' @description Module for exporting and importing the SQLite database file.
#'
#' @param id Module id.
#'
#' @noRd
#' @importFrom shiny NS tagList downloadButton fileInput
#' @importFrom bslib card card_header card_body layout_columns
mod_db_io_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_columns(
      col_widths = c(6, 6),
      # Export card
      bslib::card(
        bslib::card_header(
          shiny::tags$span(
            shiny::icon("download"), " Export Database",
            class = "fw-semibold"
          )
        ),
        bslib::card_body(
          shiny::p(
            "Download your current database file to back it up or transfer it
             to another computer.",
            class = "text-muted"
          ),
          shiny::downloadButton(
            ns("export_db_btn"),
            "Download Database",
            icon = shiny::icon("floppy-disk"),
            class = "btn btn-primary w-100"
          )
        )
      ),
      # Import card
      bslib::card(
        bslib::card_header(
          shiny::tags$span(
            shiny::icon("upload"), " Import Database",
            class = "fw-semibold"
          )
        ),
        bslib::card_body(
          shiny::p(
            shiny::tags$strong("Warning:"),
            " Importing a database will replace the current one. All existing
             tags and folder history will be overwritten.",
            class = "text-warning"
          ),
          shiny::fileInput(
            ns("import_db_file"),
            label = "Choose a .db file",
            accept = c(".db", ".sqlite", ".sqlite3"),
            width = "100%"
          ),
          shiny::actionButton(
            ns("import_db_btn"),
            "Import Database",
            icon = shiny::icon("file-import"),
            class = "btn btn-warning w-100"
          ),
          shiny::uiOutput(ns("import_status"))
        )
      )
    )
  )
}

#' db_io Server Functions
#'
#' @param id Module id.
#' @param app_state A `reactiveValues()` with fields `db_con`, `folder_path`,
#'   `folder_id`, and `refresh`.
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent renderUI downloadHandler req tags
#' @importFrom DBI dbDisconnect
mod_db_io_server <- function(id, app_state) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$export_db_btn <- shiny::downloadHandler(
      filename = function() {
        paste0("videotager_backup_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".db")
      },
      content = function(file) {
        db_path <- db_default_path()
        file.copy(db_path, file)
      }
    )

    output$import_status <- shiny::renderUI(NULL)

    observeEvent(input$import_db_btn, {
      req(input$import_db_file)
      uploaded <- input$import_db_file$datapath

      # Validate that it is a valid SQLite file by trying to connect
      valid <- tryCatch({
        test_con <- DBI::dbConnect(RSQLite::SQLite(), uploaded)
        DBI::dbDisconnect(test_con)
        TRUE
      }, error = function(e) FALSE)

      if (!valid) {
        output$import_status <- shiny::renderUI({
          shiny::tags$div(
            class = "alert alert-danger mt-2",
            shiny::icon("circle-xmark"), " The uploaded file is not a valid SQLite database."
          )
        })
        return(invisible(NULL))
      }

      # Close current connection, replace the file, reconnect
      tryCatch({
        DBI::dbDisconnect(app_state$db_con)
        db_path <- db_default_path()
        file.copy(uploaded, db_path, overwrite = TRUE)
        new_con <- db_connect(db_path)
        db_init(new_con)
        app_state$db_con    <- new_con
        app_state$folder_path <- NULL
        app_state$folder_id   <- NULL
        app_state$refresh     <- app_state$refresh + 1L

        output$import_status <- shiny::renderUI({
          shiny::tags$div(
            class = "alert alert-success mt-2",
            shiny::icon("circle-check"),
            " Database imported successfully. Please re-select your folder."
          )
        })
      }, error = function(e) {
        output$import_status <- shiny::renderUI({
          shiny::tags$div(
            class = "alert alert-danger mt-2",
            shiny::icon("circle-xmark"),
            paste(" Import failed:", conditionMessage(e))
          )
        })
      })
    })
  })
}
