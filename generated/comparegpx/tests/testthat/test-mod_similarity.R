test_that("mod_similarity_ui returns a shiny tag list", {
  ui <- mod_similarity_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_similarity_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_similarity_server computes and renders similarity outputs", {
  track_storage <- shiny::reactiveValues(
    track1 = data.frame(lat = c(48.856, 48.860), lon = c(2.352, 2.355)),
    track2 = data.frame(lat = c(48.857, 48.861), lon = c(2.353, 2.356))
  )

  testServer(
    mod_similarity_server,
    args = list(track_storage = track_storage),
    {
      session$flushReact()
      expect_true(nchar(output$pct) > 0)
      expect_true(nchar(output$mean_dist) > 0)
      expect_true(nchar(output$hausdorff) > 0)
    }
  )
})

test_that("mod_similarity_server shows 100% for identical tracks", {
  identical_track <- data.frame(
    lat = c(48.856, 48.860),
    lon = c(2.352, 2.355)
  )
  track_storage <- shiny::reactiveValues(
    track1 = identical_track,
    track2 = identical_track
  )

  testServer(
    mod_similarity_server,
    args = list(track_storage = track_storage),
    {
      session$flushReact()
      expect_equal(output$pct, "100%")
    }
  )
})
