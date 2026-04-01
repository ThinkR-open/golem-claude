test_that("haversine_point_to_track returns 0 for the same point", {
  dist <- haversine_point_to_track(2.3522, 48.8566, 2.3522, 48.8566)
  expect_equal(dist, 0, tolerance = 1e-9)
})

test_that("haversine_point_to_track returns the minimum distance", {
  dist <- haversine_point_to_track(
    lon1 = 2.3522, lat1 = 48.8566,
    lons2 = c(2.3522, 2.4000),
    lats2 = c(48.8566, 48.9000)
  )
  expect_equal(dist, 0, tolerance = 1e-9)
})

test_that("calculate_similarity returns 100% for identical tracks", {
  track <- data.frame(
    lat = c(48.8566, 48.8580, 48.8600),
    lon = c(2.3522, 2.3530, 2.3545)
  )
  result <- calculate_similarity(track, track)
  expect_equal(result$percentage, 100)
  expect_equal(result$mean_dist, 0, tolerance = 1e-6)
  expect_equal(result$hausdorff_dist, 0, tolerance = 1e-6)
})

test_that("calculate_similarity returns < 100% for different tracks", {
  track1 <- data.frame(lat = c(48.8566, 48.8580), lon = c(2.3522, 2.3530))
  track2 <- data.frame(lat = c(48.8666, 48.8680), lon = c(2.3622, 2.3630))

  result <- calculate_similarity(track1, track2)
  expect_lt(result$percentage, 100)
  expect_gt(result$mean_dist, 0)
})

test_that("calculate_similarity result fields are correctly named", {
  track <- data.frame(lat = c(48.8566), lon = c(2.3522))
  result <- calculate_similarity(track, track)
  expect_named(result, c("mean_dist", "hausdorff_dist", "percentage"))
})

test_that("calculate_similarity percentage is clamped to [0, 100]", {
  track1 <- data.frame(lat = c(0), lon = c(0))
  track2 <- data.frame(lat = c(80), lon = c(0))
  result <- calculate_similarity(track1, track2)
  expect_gte(result$percentage, 0)
  expect_lte(result$percentage, 100)
})
