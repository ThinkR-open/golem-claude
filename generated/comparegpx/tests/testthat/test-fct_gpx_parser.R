test_that("parse_gpx returns a data frame with lat and lon columns", {
  gpx_file <- withr::local_tempfile(fileext = ".gpx")
  writeLines(
    c(
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">',
      "  <trk><trkseg>",
      '    <trkpt lat="48.8566" lon="2.3522"></trkpt>',
      '    <trkpt lat="48.8580" lon="2.3530"></trkpt>',
      "  </trkseg></trk>",
      "</gpx>"
    ),
    gpx_file
  )

  result <- parse_gpx(gpx_file)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("lat", "lon"))
  expect_equal(nrow(result), 2L)
  expect_equal(result$lat[1], 48.8566)
  expect_equal(result$lon[1], 2.3522)
})

test_that("parse_gpx works without a namespace declaration", {
  gpx_file <- withr::local_tempfile(fileext = ".gpx")
  writeLines(
    c(
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<gpx version="1.1">',
      "  <trk><trkseg>",
      '    <trkpt lat="48.8566" lon="2.3522"></trkpt>',
      "  </trkseg></trk>",
      "</gpx>"
    ),
    gpx_file
  )

  result <- parse_gpx(gpx_file)
  expect_equal(nrow(result), 1L)
})

test_that("parse_gpx errors when no track points are found", {
  gpx_file <- withr::local_tempfile(fileext = ".gpx")
  writeLines(
    c(
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">',
      "  <trk><trkseg></trkseg></trk>",
      "</gpx>"
    ),
    gpx_file
  )

  expect_error(parse_gpx(gpx_file), "No track points found")
})

test_that("parse_gpx parses the bundled sample GPX files", {
  skip_on_cran()
  track1_path <- system.file("app/www/track1.gpx", package = "comparegpx")
  track2_path <- system.file("app/www/track2.gpx", package = "comparegpx")

  skip_if(
    !nzchar(track1_path) || !nzchar(track2_path),
    "Sample GPX files not installed"
  )

  t1 <- parse_gpx(track1_path)
  t2 <- parse_gpx(track2_path)

  expect_gt(nrow(t1), 0L)
  expect_gt(nrow(t2), 0L)
})
