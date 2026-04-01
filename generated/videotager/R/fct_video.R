#' Supported video file extensions
#'
#' @return Character vector of lowercase file extensions (without leading dot).
#' @noRd
video_extensions <- function() {
  c("mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg", "ts", "3gp", "ogv")
}

#' List all video files in a folder (non-recursive)
#'
#' @param folder_path Absolute path to the folder.
#' @return Character vector of absolute paths to video files.
#' @importFrom fs dir_ls path_ext
#' @noRd
list_videos <- function(folder_path) {
  exts <- video_extensions()
  all_files <- tryCatch(
    fs::dir_ls(folder_path, type = "file", recurse = FALSE),
    error = function(e) character(0)
  )
  as.character(all_files[tolower(fs::path_ext(all_files)) %in% exts])
}

#' Format a byte count as a human-readable string
#'
#' @param bytes Integer number of bytes.
#' @return Character string such as `"12.5 MB"`.
#' @noRd
format_bytes <- function(bytes) {
  if (is.na(bytes) || is.null(bytes) || length(bytes) == 0L) return("--")
  units <- c("B", "KB", "MB", "GB", "TB")
  size <- as.numeric(bytes)
  i <- 1L
  while (size >= 1024 && i < length(units)) {
    size <- size / 1024
    i <- i + 1L
  }
  paste(round(size, 1L), units[i])
}

#' Get the MIME type for a video file based on its extension
#'
#' @param path Path to the video file.
#' @return A MIME type string.
#' @importFrom fs path_ext
#' @noRd
video_mime_type <- function(path) {
  ext <- tolower(fs::path_ext(path))
  switch(ext,
    "mp4"  = "video/mp4",
    "webm" = "video/webm",
    "ogv"  = "video/ogg",
    "mkv"  = "video/x-matroska",
    "avi"  = "video/x-msvideo",
    "mov"  = "video/quicktime",
    "wmv"  = "video/x-ms-wmv",
    "flv"  = "video/x-flv",
    "m4v"  = "video/x-m4v",
    "video/mp4"
  )
}

#' Open the enclosing folder for a file in the system file manager
#'
#' On macOS uses `open -R`, on Windows uses `explorer /select,`, on Linux
#' opens the parent directory with `xdg-open`.
#'
#' @param file_path Absolute path to the file.
#' @return Invisibly `NULL`.
#' @noRd
open_in_finder <- function(file_path) {
  sysname <- Sys.info()[["sysname"]]
  if (sysname == "Darwin") {
    system2("open", args = c("-R", shQuote(file_path)), wait = FALSE)
  } else if (sysname == "Windows") {
    shell(paste0("explorer /select,", shQuote(file_path)), wait = FALSE)
  } else {
    system2("xdg-open", args = shQuote(dirname(file_path)), wait = FALSE)
  }
  invisible(NULL)
}

#' Register a video folder as a Shiny static resource
#'
#' After calling this, videos in `folder_path` are accessible at
#' `/videos/<filename>` within the Shiny app.
#'
#' @param folder_path Absolute path to the folder.
#' @importFrom shiny addResourcePath
#' @noRd
register_video_resource <- function(folder_path) {
  shiny::addResourcePath("videos", folder_path)
  invisible(NULL)
}
