#' tag UI Function
#'
#' @description Module for tagging videos: add new tags, add existing tags,
#'   remove tags from a selected video.
#'
#' @param id Module id.
#'
#' @noRd
#' @importFrom shiny NS tagList
#' @importFrom bslib layout_columns card card_header card_body
#' @importFrom DT dataTableOutput
mod_tag_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_columns(
      col_widths = c(6, 6),
      # Left: video list
      bslib::card(
        full_screen = FALSE,
        bslib::card_header(
          shiny::tags$span(
            shiny::icon("film"), " Select a Video",
            class = "fw-semibold"
          )
        ),
        bslib::card_body(
          class = "p-0",
          DT::dataTableOutput(ns("video_list_table"), width = "100%")
        )
      ),
      # Right: tag management
      bslib::card(
        full_screen = FALSE,
        bslib::card_header(
          shiny::tags$span(
            shiny::icon("tags"), " Manage Tags",
            class = "fw-semibold"
          )
        ),
        bslib::card_body(
          shiny::div(
            id = ns("no_selection_msg"),
            shiny::p(
              shiny::icon("arrow-left"), " Select a video from the list to manage its tags.",
              class = "text-muted"
            )
          ),
          shiny::div(
            id = ns("tag_panel"),
            style = "display:none;",
            # Selected video info
            shiny::tags$div(
              class = "alert alert-info py-2 mb-3",
              shiny::tags$strong("Selected: "),
              shiny::textOutput(ns("selected_video_name"), inline = TRUE)
            ),
            # Current tags
            shiny::tags$h6("Current Tags", class = "fw-semibold text-muted"),
            shiny::selectInput(
              ns("current_tags_select"),
              label = NULL,
              choices = character(0),
              multiple = TRUE,
              size = 4,
              selectize = FALSE,
              width = "100%"
            ),
            shiny::actionButton(
              ns("remove_tags_btn"),
              "Remove Selected",
              icon = shiny::icon("trash"),
              class = "btn btn-danger btn-sm w-100 mb-3"
            ),
            shiny::tags$hr(),
            # Add new tags
            shiny::tags$h6("Add New Tags", class = "fw-semibold text-muted"),
            shiny::p(
              shiny::tags$small("Separate multiple tags with commas."),
              class = "text-muted mb-1"
            ),
            shiny::div(
              class = "input-group mb-3",
              shiny::textInput(
                ns("new_tags_text"),
                label = NULL,
                placeholder = "e.g. holiday, 2024, family",
                width = "100%"
              ),
              shiny::actionButton(
                ns("add_new_tags_btn"),
                "Add",
                icon = shiny::icon("plus"),
                class = "btn btn-success"
              )
            ),
            shiny::tags$hr(),
            # Add existing tag
            shiny::tags$h6("Add Existing Tag", class = "fw-semibold text-muted"),
            shiny::div(
              class = "input-group",
              shiny::selectInput(
                ns("existing_tag_select"),
                label = NULL,
                choices = character(0),
                width = "100%"
              ),
              shiny::actionButton(
                ns("add_existing_tag_btn"),
                "Add",
                icon = shiny::icon("plus"),
                class = "btn btn-outline-primary"
              )
            )
          )
        )
      )
    )
  )
}

#' tag Server Functions
#'
#' @param id Module id.
#' @param app_state A `reactiveValues()` with fields `db_con`, `folder_id`,
#'   and `refresh`.
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent reactiveValues renderText
#'   updateSelectInput req
#' @importFrom DT renderDataTable datatable
mod_tag_server <- function(id, app_state) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    local_rv <- reactiveValues(
      videos     = data.frame(),
      video_id   = NULL,
      video_name = NULL
    )

    # Refresh video list when folder or refresh changes
    observeEvent(app_state$refresh, {
      req(app_state$folder_id)
      local_rv$videos <- db_search_videos(
        con       = app_state$db_con,
        folder_id = app_state$folder_id
      )
      .refresh_all_tags(session, app_state, local_rv)
    }, ignoreNULL = TRUE, ignoreInit = FALSE)

    output$video_list_table <- DT::renderDataTable({
      df <- local_rv$videos
      if (nrow(df) == 0L) {
        return(DT::datatable(
          data.frame(Message = "No videos in this folder"),
          options = list(dom = "t"),
          rownames = FALSE
        ))
      }
      display_df <- data.frame(
        Filename = df$filename,
        Tags     = df$tags,
        stringsAsFactors = FALSE
      )
      DT::datatable(
        display_df,
        selection = "single",
        rownames  = FALSE,
        options   = list(
          dom        = "ftp",
          pageLength = 20,
          scrollX    = TRUE
        ),
        class = "table table-hover table-sm"
      )
    })

    # Video selected
    observeEvent(input$video_list_table_rows_selected, {
      idx <- input$video_list_table_rows_selected
      if (is.null(idx) || length(idx) == 0L) {
        local_rv$video_id   <- NULL
        local_rv$video_name <- NULL
        shinyjs::hide("tag_panel")
        shinyjs::show("no_selection_msg")
      } else {
        local_rv$video_id   <- local_rv$videos$id[idx]
        local_rv$video_name <- local_rv$videos$filename[idx]
        shinyjs::show("tag_panel")
        shinyjs::hide("no_selection_msg")
        .refresh_video_tags(session, app_state, local_rv)
      }
    })

    output$selected_video_name <- shiny::renderText({
      local_rv$video_name %||% ""
    })

    # Add new tags (comma-separated)
    observeEvent(input$add_new_tags_btn, {
      req(local_rv$video_id, input$new_tags_text, nchar(trimws(input$new_tags_text)) > 0L)
      raw_tags <- strsplit(input$new_tags_text, ",", fixed = TRUE)[[1L]]
      new_names <- trimws(raw_tags)
      new_names <- new_names[nchar(new_names) > 0L]
      con <- app_state$db_con
      for (nm in new_names) {
        tag_id <- db_ensure_tag(con, nm)
        db_add_video_tag(con, local_rv$video_id, tag_id)
      }
      shiny::updateTextInput(session, "new_tags_text", value = "")
      .refresh_after_tag_change(app_state, local_rv, session)
    })

    # Add an existing tag
    observeEvent(input$add_existing_tag_btn, {
      req(local_rv$video_id, input$existing_tag_select, nchar(input$existing_tag_select) > 0L)
      tag_id <- as.integer(input$existing_tag_select)
      db_add_video_tag(app_state$db_con, local_rv$video_id, tag_id)
      .refresh_after_tag_change(app_state, local_rv, session)
    })

    # Remove selected tags from the video
    observeEvent(input$remove_tags_btn, {
      req(local_rv$video_id, length(input$current_tags_select) > 0L)
      con <- app_state$db_con
      for (tag_id_str in input$current_tags_select) {
        db_remove_video_tag(con, local_rv$video_id, as.integer(tag_id_str))
      }
      .refresh_after_tag_change(app_state, local_rv, session)
    })
  })
}

#' Refresh current-video tags and all-tags selects after a change
#'
#' @noRd
.refresh_after_tag_change <- function(app_state, local_rv, session) {
  .refresh_video_tags(session, app_state, local_rv)
  .refresh_all_tags(session, app_state, local_rv)
  # Re-sync video list to show updated tags column
  local_rv$videos <- db_search_videos(
    con       = app_state$db_con,
    folder_id = app_state$folder_id
  )
}

#' Update the current-video tags selectInput
#'
#' @noRd
.refresh_video_tags <- function(session, app_state, local_rv) {
  req <- !is.null(local_rv$video_id)
  if (!req) return(invisible(NULL))
  tags_df <- db_get_video_tags(app_state$db_con, local_rv$video_id)
  if (nrow(tags_df) > 0L) {
    choices <- stats::setNames(as.character(tags_df$id), tags_df$name)
  } else {
    choices <- character(0)
  }
  shiny::updateSelectInput(session, "current_tags_select", choices = choices, selected = character(0))
  invisible(NULL)
}

#' Update the all-tags selectInput for adding existing tags
#'
#' @noRd
.refresh_all_tags <- function(session, app_state, local_rv) {
  all_tags <- db_get_all_tags(app_state$db_con)
  if (nrow(all_tags) > 0L) {
    choices <- stats::setNames(as.character(all_tags$id), all_tags$name)
  } else {
    choices <- character(0)
  }
  shiny::updateSelectInput(session, "existing_tag_select", choices = choices)
  invisible(NULL)
}

#' NULL-coalescing operator
#'
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x
