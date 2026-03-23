test_that("read_gpx returns an sf object with track points", {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")
  skip_if(nchar(example_path) == 0, "Example GPX file not found")

  result <- read_gpx(example_path)

  expect_s3_class(result, "sf")
  expect_gt(nrow(result), 0)
  expect_true("geometry" %in% names(result))
})

test_that("read_gpx includes elevation and time columns", {
  example_path <- system.file("extdata", "example.gpx", package = "gpxviz")
  skip_if(nchar(example_path) == 0, "Example GPX file not found")

  result <- read_gpx(example_path)

  expect_true("ele" %in% names(result))
  expect_true("time" %in% names(result))
})

test_that("read_gpx errors on invalid file", {
  tmp <- withr::local_tempfile(fileext = ".gpx")
  writeLines("not valid gpx", tmp)

  expect_error(read_gpx(tmp))
})
