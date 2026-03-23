test_that("mod_gpx_map_ui returns a shiny tag list", {
  ui <- mod_gpx_map_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_gpx_map_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_gpx_map_server renders a plot when data is available", {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")
  skip_if(nchar(example_path) == 0, "Example GPX file not found")

  track_data <- read_gpx(example_path)
  gpx_storage <- shiny::reactiveValues(data = track_data)

  shiny::testServer(
    mod_gpx_map_server,
    args = list(gpx_storage = gpx_storage),
    {
      expect_true(inherits(output$track_plot, "list"))
    }
  )
})

test_that("mod_gpx_map_server silently cancels render when data is NULL", {
  gpx_storage <- shiny::reactiveValues(data = NULL)

  shiny::testServer(
    mod_gpx_map_server,
    args = list(gpx_storage = gpx_storage),
    {
      # req() silently cancels the reactive when data is NULL
      expect_error(output$track_plot, class = "shiny.silent.error")
    }
  )
})
