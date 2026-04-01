#' search UI Function
#'
#' @description Search and browse videos by tags and free text.
#'
#' @param id Module id.
#'
#' @noRd
#' @importFrom shiny NS tagList textInput selectInput radioButtons actionButton
#' @importFrom bslib layout_sidebar sidebar card card_body card_header
#' @importFrom DT dataTableOutput
mod_search_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      fillable = TRUE,
      sidebar = bslib::sidebar(
        width = 300,
        open = TRUE,
        shiny::tags$h6(
          shiny::icon("magnifying-glass"), " Search",
          class = "fw-semibold text-muted"
        ),
        shiny::textInput(
          ns("search_text"),
          label = "Free text",
          placeholder = "Search by name or tag\u2026",
          width = "100%"
        ),
        shiny::selectInput(
          ns("filter_tags"),
          label = "Filter by tags",
          choices = NULL,
          multiple = TRUE,
          width = "100%"
        ),
        shiny::actionButton(
          ns("search_btn"),
          "Search",
          icon = shiny::icon("magnifying-glass"),
          class = "btn btn-primary w-100 mb-2"
        ),
        shiny::actionButton(
          ns("reset_btn"),
          "Reset",
          icon = shiny::icon("rotate"),
          class = "btn btn-outline-secondary w-100"
        ),
        shiny::tags$hr(),
        shiny::tags$h6(
          shiny::icon("arrow-up-wide-short"), " Sort",
          class = "fw-semibold text-muted"
        ),
        shiny::selectInput(
          ns("order_by"),
          label = "Sort by",
          choices = c(
            "Name"     = "filename",
            "Size"     = "size_bytes",
            "Modified" = "modified_at"
          ),
          selected = "filename",
          width = "100%"
        ),
        shiny::radioButtons(
          ns("order_dir"),
          label = NULL,
          choices = c("Ascending" = "ASC", "Descending" = "DESC"),
          inline = TRUE
        )
      ),
      # Main content
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          class = "d-flex justify-content-between align-items-center",
          shiny::tags$span(
            shiny::icon("film"), " Videos",
            class = "fw-semibold"
          ),
          shiny::textOutput(ns("result_count"), inline = TRUE) |>
            shiny::tagAppendAttributes(class = "text-muted small")
        ),
        bslib::card_body(
          class = "p-0",
          DT::dataTableOutput(ns("videos_table"), width = "100%")
        )
      ),
      bslib::card(
        id = ns("preview_card"),
        full_screen = TRUE,
        bslib::card_header(
          class = "d-flex justify-content-between align-items-center",
          shiny::tags$span(
            shiny::icon("play"), " Preview",
            class = "fw-semibold"
          ),
          shiny::actionButton(
            ns("open_finder_btn"),
            "Show in Finder",
            icon = shiny::icon("folder-open"),
            class = "btn btn-sm btn-outline-secondary",
            disabled = "disabled"
          )
        ),
        bslib::card_body(
          shiny::uiOutput(ns("video_preview"))
        )
      )
    )
  )
}

#' search Server Functions
#'
#' @param id Module id.
#' @param app_state A `reactiveValues()` with fields `db_con`, `folder_id`,
#'   and `refresh`.
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent reactiveValues renderText
#'   updateSelectInput req renderUI tags
#' @importFrom DT renderDataTable datatable
mod_search_server <- function(id, app_state) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    local_rv <- reactiveValues(
      videos = data.frame(),
      selected_path = NULL
    )

    # Refresh tag filter choices and re-run search when folder changes
    observeEvent(app_state$refresh, {
      req(app_state$folder_id)
      tags_df <- db_get_all_tags(app_state$db_con)
      if (nrow(tags_df) > 0L) {
        choices <- stats::setNames(tags_df$id, tags_df$name)
        shiny::updateSelectInput(session, "filter_tags", choices = choices, selected = character(0))
      } else {
        shiny::updateSelectInput(session, "filter_tags", choices = character(0), selected = character(0))
      }
      .run_search(input, app_state, local_rv)
    }, ignoreNULL = TRUE, ignoreInit = FALSE)

    observeEvent(input$search_btn, {
      req(app_state$folder_id)
      .run_search(input, app_state, local_rv)
    })

    observeEvent(input$reset_btn, {
      shiny::updateTextInput(session, "search_text", value = "")
      shiny::updateSelectInput(session, "filter_tags", selected = character(0))
      req(app_state$folder_id)
      .run_search(input, app_state, local_rv)
    })

    observeEvent(input$order_by, {
      req(app_state$folder_id)
      .run_search(input, app_state, local_rv)
    })

    observeEvent(input$order_dir, {
      req(app_state$folder_id)
      .run_search(input, app_state, local_rv)
    })

    output$result_count <- shiny::renderText({
      n <- nrow(local_rv$videos)
      if (n == 0L) "No videos found" else paste(n, "video(s)")
    })

    output$videos_table <- DT::renderDataTable({
      df <- local_rv$videos
      if (nrow(df) == 0L) {
        return(DT::datatable(
          data.frame(Message = "No videos found"),
          options = list(dom = "t"),
          rownames = FALSE
        ))
      }

      display_df <- data.frame(
        Filename = df$filename,
        Size     = vapply(df$size_bytes, format_bytes, character(1L)),
        Modified = df$modified_at,
        Tags     = df$tags,
        stringsAsFactors = FALSE
      )

      DT::datatable(
        display_df,
        selection = "single",
        rownames = FALSE,
        options = list(
          dom = "ftp",
          pageLength = 20,
          scrollX = TRUE,
          columnDefs = list(
            list(targets = 0, width = "40%"),
            list(targets = 1, width = "10%"),
            list(targets = 2, width = "20%"),
            list(targets = 3, width = "30%")
          )
        ),
        class = "table table-hover table-sm"
      )
    })

    # React to row selection in the table
    observeEvent(input$videos_table_rows_selected, {
      idx <- input$videos_table_rows_selected
      if (is.null(idx) || length(idx) == 0L) {
        local_rv$selected_path <- NULL
        shinyjs::disable("open_finder_btn")
      } else {
        path <- local_rv$videos$path[idx]
        local_rv$selected_path <- path
        shinyjs::enable("open_finder_btn")
      }
    })

    output$video_preview <- shiny::renderUI({
      req(local_rv$selected_path)
      path <- local_rv$selected_path
      filename <- basename(path)
      mime <- video_mime_type(path)
      shiny::tagList(
        shiny::tags$p(
          shiny::tags$strong("File: "), filename,
          class = "mb-2 text-muted small"
        ),
        shiny::tags$video(
          controls = NA,
          style = "width:100%; max-height:480px; border-radius:6px; background:#000;",
          shiny::tags$source(
            src = paste0("videos/", utils::URLencode(filename, repeated = TRUE)),
            type = mime
          ),
          "Your browser does not support HTML5 video."
        )
      )
    })

    observeEvent(input$open_finder_btn, {
      req(local_rv$selected_path)
      open_in_finder(local_rv$selected_path)
    })
  })
}

#' Run a video search and store results in local_rv
#'
#' @param input Shiny input object.
#' @param app_state Shared `reactiveValues()`.
#' @param local_rv Module-local `reactiveValues()`.
#' @noRd
.run_search <- function(input, app_state, local_rv) {
  tag_ids <- if (length(input$filter_tags) > 0L) as.integer(input$filter_tags) else NULL
  text <- if (!is.null(input$search_text) && nchar(trimws(input$search_text)) > 0L) {
    input$search_text
  } else {
    NULL
  }
  local_rv$videos <- db_search_videos(
    con       = app_state$db_con,
    folder_id = app_state$folder_id,
    text      = text,
    tag_ids   = tag_ids,
    order_by  = input$order_by,
    order_dir = input$order_dir
  )
  local_rv$selected_path <- NULL
}
