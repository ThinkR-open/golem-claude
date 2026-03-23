test_that("mod_gpx_upload_ui returns a shiny tag list", {
  ui <- mod_gpx_upload_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_gpx_upload_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_gpx_upload_server loads example GPX into gpx_storage", {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")
  skip_if(nchar(example_path) == 0, "Example GPX file not found")

  gpx_storage <- shiny::reactiveValues(data = NULL)

  shiny::testServer(
    mod_gpx_upload_server,
    args = list(gpx_storage = gpx_storage),
    {
      session$setInputs(source = "example", load = 1)
      expect_s3_class(gpx_storage$data, "sf")
      expect_gt(nrow(gpx_storage$data), 0)
    }
  )
})

test_that("mod_gpx_upload_server loads uploaded GPX file into gpx_storage", {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")
  skip_if(nchar(example_path) == 0, "Example GPX file not found")

  gpx_storage <- shiny::reactiveValues(data = NULL)

  shiny::testServer(
    mod_gpx_upload_server,
    args = list(gpx_storage = gpx_storage),
    {
      session$setInputs(
        source = "upload",
        gpx_file = list(datapath = example_path, name = "example.gpx"),
        load = 1
      )
      expect_s3_class(gpx_storage$data, "sf")
      expect_gt(nrow(gpx_storage$data), 0)
    }
  )
})
