#' Calculate similarity between two GPS tracks
#'
#' @description
#' Computes the mean of the minimum Haversine distances from each point on
#' one track to the nearest point on the other track (symmetric). The result
#' is expressed as a similarity percentage where 100 % means identical tracks
#' and 0 % means tracks are on average 500 m or more apart.
#'
#' @param track1 A data frame with columns `lat` and `lon`.
#' @param track2 A data frame with columns `lat` and `lon`.
#'
#' @return A named list with:
#'   \describe{
#'     \item{mean_dist}{Mean minimum distance in metres (numeric).}
#'     \item{hausdorff_dist}{Hausdorff distance in metres (numeric).}
#'     \item{percentage}{Similarity percentage 0-100 (numeric).}
#'   }
#'
#' @noRd
calculate_similarity <- function(track1, track2) {
  min_dists_1 <- vapply(
    seq_len(nrow(track1)),
    function(i) {
      haversine_point_to_track(
        track1$lon[i], track1$lat[i],
        track2$lon, track2$lat
      )
    },
    numeric(1)
  )

  min_dists_2 <- vapply(
    seq_len(nrow(track2)),
    function(i) {
      haversine_point_to_track(
        track2$lon[i], track2$lat[i],
        track1$lon, track1$lat
      )
    },
    numeric(1)
  )

  mean_dist <- mean(c(min_dists_1, min_dists_2))
  hausdorff_dist <- max(max(min_dists_1), max(min_dists_2))

  # Linear normalisation: 0 m -> 100 %, 500 m -> 0 %
  percentage <- max(0, min(100, 100 * (1 - mean_dist / 500)))

  list(
    mean_dist = mean_dist,
    hausdorff_dist = hausdorff_dist,
    percentage = percentage
  )
}

#' Minimum Haversine distance from one point to a set of points
#'
#' @param lon1 Longitude of the query point (degrees).
#' @param lat1 Latitude of the query point (degrees).
#' @param lons2 Numeric vector of longitudes for the target track.
#' @param lats2 Numeric vector of latitudes for the target track.
#'
#' @return Minimum distance in metres (numeric scalar).
#'
#' @noRd
haversine_point_to_track <- function(lon1, lat1, lons2, lats2) {
  r <- 6371000L
  dlat <- (lats2 - lat1) * pi / 180
  dlon <- (lons2 - lon1) * pi / 180
  a <- sin(dlat / 2)^2 +
    cos(lat1 * pi / 180) * cos(lats2 * pi / 180) * sin(dlon / 2)^2
  min(2 * r * asin(pmin(1, sqrt(a))))
}
