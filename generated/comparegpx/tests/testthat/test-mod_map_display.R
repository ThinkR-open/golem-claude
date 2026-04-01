test_that("mod_map_display_ui returns a shiny tag list", {
  ui <- mod_map_display_ui(id = "test")
  golem::expect_shinytaglist(ui)
  fmls <- formals(mod_map_display_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_map_display_server renders the map output", {
  track_storage <- shiny::reactiveValues(
    track1 = data.frame(lat = c(48.856, 48.860), lon = c(2.352, 2.355)),
    track2 = data.frame(lat = c(48.857, 48.861), lon = c(2.353, 2.356))
  )

  testServer(
    mod_map_display_server,
    args = list(track_storage = track_storage),
    {
      session$setInputs(color1 = "#E74C3C", color2 = "#2980B9")
      expect_true(!is.null(output$map))
    }
  )
})
