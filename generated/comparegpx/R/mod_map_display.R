#' map_display UI Function
#'
#' @description Module rendering a Leaflet map with both GPX tracks.
#'   Includes colour pickers for each track.
#'
#' @param id Internal parameter for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
#' @importFrom leaflet leafletOutput
#' @importFrom colourpicker colourInput
mod_map_display_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_columns(
      col_widths = c(6, 6),
      colourpicker::colourInput(
        ns("color1"),
        label = "Track 1 colour",
        value = "#E74C3C",
        showColour = "background"
      ),
      colourpicker::colourInput(
        ns("color2"),
        label = "Track 2 colour",
        value = "#2980B9",
        showColour = "background"
      )
    ),
    leaflet::leafletOutput(ns("map"), height = "430px")
  )
}

#' map_display Server Functions
#'
#' @param id Internal parameter for {shiny}.
#' @param track_storage A [shiny::reactiveValues()] object with fields
#'   `track1` and `track2` (data frames with `lat`/`lon` columns).
#'
#' @noRd
#'
#' @importFrom shiny moduleServer observeEvent req
#' @importFrom leaflet renderLeaflet leaflet addProviderTiles providers
#'   providerTileOptions leafletProxy clearShapes addPolylines fitBounds
#'   addLayersControl layersControlOptions
mod_map_display_server <- function(id, track_storage) {
  moduleServer(id, function(input, output, session) {
    # Base map — tracks added via proxy to avoid full re-renders
    output$map <- leaflet::renderLeaflet({
      leaflet::leaflet() |>
        leaflet::addProviderTiles(
          leaflet::providers$CartoDB.Positron,
          options = leaflet::providerTileOptions(noWrap = TRUE)
        ) |>
        leaflet::addLayersControl(
          overlayGroups = c("Track 1", "Track 2"),
          options = leaflet::layersControlOptions(collapsed = FALSE)
        )
    })

    # Fit bounds when track data changes
    observeEvent(
      list(track_storage$track1, track_storage$track2),
      {
        req(!is.null(track_storage$track1), !is.null(track_storage$track2))
        t1 <- track_storage$track1
        t2 <- track_storage$track2
        all_lat <- c(t1$lat, t2$lat)
        all_lon <- c(t1$lon, t2$lon)

        leaflet::leafletProxy("map", session = session) |>
          leaflet::fitBounds(
            lng1 = min(all_lon),
            lat1 = min(all_lat),
            lng2 = max(all_lon),
            lat2 = max(all_lat)
          )
      }
    )

    # Redraw polylines when tracks or colours change
    observeEvent(
      list(
        track_storage$track1,
        track_storage$track2,
        input$color1,
        input$color2
      ),
      {
        req(
          !is.null(track_storage$track1),
          !is.null(track_storage$track2),
          !is.null(input$color1),
          !is.null(input$color2)
        )
        t1 <- track_storage$track1
        t2 <- track_storage$track2

        leaflet::leafletProxy("map", session = session) |>
          leaflet::clearShapes() |>
          leaflet::addPolylines(
            data = t1,
            lng = ~lon,
            lat = ~lat,
            color = input$color1,
            weight = 4,
            opacity = 0.85,
            group = "Track 1",
            label = "Track 1"
          ) |>
          leaflet::addPolylines(
            data = t2,
            lng = ~lon,
            lat = ~lat,
            color = input$color2,
            weight = 4,
            opacity = 0.85,
            group = "Track 2",
            label = "Track 2"
          )
      }
    )
  })
}
