test_that("mod_gpx_reader_ui returns a shiny tag list", {
  ui <- mod_gpx_reader_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_gpx_reader_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_gpx_reader_server initialises track_storage with default tracks", {
  skip_on_cran()
  skip_if(
    !nzchar(system.file("app/www/track1.gpx", package = "comparegpx")),
    "Sample GPX files not installed"
  )

  track_storage <- shiny::reactiveValues(track1 = NULL, track2 = NULL)

  testServer(
    mod_gpx_reader_server,
    args = list(track_storage = track_storage),
    {
      expect_s3_class(track_storage$track1, "data.frame")
      expect_s3_class(track_storage$track2, "data.frame")
      expect_named(track_storage$track1, c("lat", "lon"))
      expect_named(track_storage$track2, c("lat", "lon"))
    }
  )
})

test_that("mod_gpx_reader_server applies reverse when checkbox is toggled", {
  skip_on_cran()
  skip_if(
    !nzchar(system.file("app/www/track1.gpx", package = "comparegpx")),
    "Sample GPX files not installed"
  )

  track_storage <- shiny::reactiveValues(track1 = NULL, track2 = NULL)

  testServer(
    mod_gpx_reader_server,
    args = list(track_storage = track_storage),
    {
      # Prime the input (ignoreInit = TRUE on the server observer means the
      # first NULL->value transition is skipped; prime with FALSE first)
      session$setInputs(reverse1 = FALSE)
      original_second_lat <- track_storage$track1$lat[2]

      session$setInputs(reverse1 = TRUE)
      reversed_second_lat <- track_storage$track1$lat[2]

      expect_false(isTRUE(all.equal(original_second_lat, reversed_second_lat)))
    }
  )
})
