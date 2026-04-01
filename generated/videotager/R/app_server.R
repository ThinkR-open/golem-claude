#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @importFrom shiny observeEvent reactiveValues req
#' @importFrom bslib nav_select
#' @importFrom DBI dbDisconnect
#' @noRd
app_server <- function(input, output, session) {
  # Open DB connection and initialise schema
  con <- db_connect()
  db_init(con)

  # Ensure connection is closed when the session ends
  session$onSessionEnded(function() {
    tryCatch(DBI::dbDisconnect(con), error = function(e) NULL)
  })

  # Shared state passed to all modules
  app_state <- reactiveValues(
    db_con      = con,
    folder_path = NULL,
    folder_id   = NULL,
    refresh     = 0L
  )

  # When a folder is selected, navigate to the Search tab
  observeEvent(app_state$folder_path, {
    req(app_state$folder_path)
    bslib::nav_select("main_navbar", "tab_search", session = session)
  })

  mod_folder_select_server("folder_select", app_state)
  mod_search_server("search", app_state)
  mod_tag_server("tag", app_state)
  mod_db_io_server("db_io", app_state)
}
