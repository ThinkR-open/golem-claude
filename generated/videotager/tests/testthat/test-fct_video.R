test_that("video_extensions returns a non-empty character vector", {
  exts <- video_extensions()
  expect_type(exts, "character")
  expect_true(length(exts) > 0L)
  expect_true("mp4" %in% exts)
  expect_true("mkv" %in% exts)
})

test_that("list_videos returns only video files", {
  tmp_dir <- withr::local_tempdir()

  # Create dummy files
  file.create(file.path(tmp_dir, "movie.mp4"))
  file.create(file.path(tmp_dir, "clip.mkv"))
  file.create(file.path(tmp_dir, "notes.txt"))
  file.create(file.path(tmp_dir, "image.jpg"))

  result <- list_videos(tmp_dir)

  basenames <- basename(result)
  expect_true("movie.mp4" %in% basenames)
  expect_true("clip.mkv" %in% basenames)
  expect_false("notes.txt" %in% basenames)
  expect_false("image.jpg" %in% basenames)
})

test_that("list_videos returns character(0) for empty folder", {
  tmp_dir <- withr::local_tempdir()
  result <- list_videos(tmp_dir)
  expect_equal(length(result), 0L)
})

test_that("list_videos handles non-existent folder gracefully", {
  result <- list_videos("/nonexistent/path/xyz")
  expect_type(result, "character")
  expect_equal(length(result), 0L)
})

test_that("format_bytes formats sizes correctly", {
  expect_equal(format_bytes(500L), "500 B")
  expect_equal(format_bytes(1024L), "1 KB")
  expect_equal(format_bytes(1024L * 1024L), "1 MB")
  expect_equal(format_bytes(1024L^3L), "1 GB")
})

test_that("format_bytes handles NA and NULL", {
  expect_equal(format_bytes(NA), "--")
  expect_equal(format_bytes(NULL), "--")
})

test_that("video_mime_type returns correct types", {
  expect_equal(video_mime_type("file.mp4"), "video/mp4")
  expect_equal(video_mime_type("file.webm"), "video/webm")
  expect_equal(video_mime_type("file.ogv"), "video/ogg")
  expect_equal(video_mime_type("FILE.MP4"), "video/mp4")
  # Unknown extension falls back to mp4
  expect_equal(video_mime_type("file.xyz"), "video/mp4")
})
