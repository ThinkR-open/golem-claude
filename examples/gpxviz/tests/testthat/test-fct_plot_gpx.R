test_that("plot_gpx returns a ggplot object", {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")
  skip_if(nchar(example_path) == 0, "Example GPX file not found")

  track_data <- read_gpx(example_path)
  result <- plot_gpx(track_data)

  expect_s3_class(result, "gg")
  expect_s3_class(result, "ggplot")
})

test_that("plot_gpx plot contains expected layers", {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")
  skip_if(nchar(example_path) == 0, "Example GPX file not found")

  track_data <- read_gpx(example_path)
  result <- plot_gpx(track_data)

  # Should have 3 geom_sf layers: line + start point + end point
  layer_classes <- vapply(
    result$layers,
    function(l) class(l$geom)[1],
    character(1)
  )
  expect_equal(sum(layer_classes == "GeomSf"), 3)
})
