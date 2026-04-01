#' Get the default path for the SQLite database
#'
#' @return A character string with the path to the SQLite database file.
#' @importFrom fs path_home path dir_create
#' @noRd
db_default_path <- function() {
  dir <- fs::path_home(".videotager")
  fs::dir_create(dir)
  as.character(fs::path(dir, "videotager.db"))
}

#' Connect to the SQLite database
#'
#' @param path Path to the SQLite database file.
#' @return A DBI connection object.
#' @importFrom DBI dbConnect
#' @importFrom RSQLite SQLite
#' @noRd
db_connect <- function(path = db_default_path()) {
  DBI::dbConnect(RSQLite::SQLite(), path)
}

#' Initialise the database schema
#'
#' Creates all tables if they do not already exist.
#'
#' @param con A DBI connection.
#' @importFrom DBI dbExecute
#' @noRd
db_init <- function(con) {
  DBI::dbExecute(con, "PRAGMA foreign_keys = ON")
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT UNIQUE NOT NULL,
      last_accessed TEXT DEFAULT (datetime('now'))
    )
  ")
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS videos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      folder_id INTEGER NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
      filename TEXT NOT NULL,
      path TEXT UNIQUE NOT NULL,
      size_bytes INTEGER,
      modified_at TEXT,
      UNIQUE(folder_id, filename)
    )
  ")
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL COLLATE NOCASE
    )
  ")
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS video_tags (
      video_id INTEGER NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
      tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
      PRIMARY KEY (video_id, tag_id)
    )
  ")
  invisible(con)
}

#' Upsert a folder into the database
#'
#' @param con A DBI connection.
#' @param path Absolute path of the folder.
#' @return The folder id (integer).
#' @importFrom DBI dbExecute dbGetQuery
#' @noRd
db_upsert_folder <- function(con, path) {
  DBI::dbExecute(
    con,
    "INSERT INTO folders (path, last_accessed)
     VALUES (?, datetime('now'))
     ON CONFLICT(path) DO UPDATE SET last_accessed = datetime('now')",
    list(path)
  )
  result <- DBI::dbGetQuery(con, "SELECT id FROM folders WHERE path = ?", list(path))
  result$id[[1L]]
}

#' Get all previously used folders
#'
#' @param con A DBI connection.
#' @return A data frame with columns id, path, last_accessed.
#' @importFrom DBI dbGetQuery
#' @noRd
db_get_folders <- function(con) {
  DBI::dbGetQuery(
    con,
    "SELECT id, path, last_accessed FROM folders ORDER BY last_accessed DESC"
  )
}

#' Upsert a video into the database
#'
#' @param con A DBI connection.
#' @param folder_id Integer folder id.
#' @param filename Filename (basename only).
#' @param path Absolute path to the video.
#' @param size_bytes File size in bytes.
#' @param modified_at Modification time as character (ISO 8601).
#' @return The video id (integer).
#' @importFrom DBI dbExecute dbGetQuery
#' @noRd
db_upsert_video <- function(con, folder_id, filename, path, size_bytes, modified_at) {
  DBI::dbExecute(
    con,
    "INSERT INTO videos (folder_id, filename, path, size_bytes, modified_at)
     VALUES (?, ?, ?, ?, ?)
     ON CONFLICT(path) DO UPDATE SET
       size_bytes = excluded.size_bytes,
       modified_at = excluded.modified_at",
    list(folder_id, filename, path, size_bytes, modified_at)
  )
  result <- DBI::dbGetQuery(con, "SELECT id FROM videos WHERE path = ?", list(path))
  result$id[[1L]]
}

#' Sync all videos from a folder into the database
#'
#' Inserts or updates all video files found in the folder.
#'
#' @param con A DBI connection.
#' @param folder_id Integer folder id.
#' @param folder_path Absolute path to the folder.
#' @return Invisibly, the number of videos synced.
#' @importFrom fs file_info path_file
#' @noRd
db_sync_videos <- function(con, folder_id, folder_path) {
  video_paths <- list_videos(folder_path)
  for (vpath in video_paths) {
    info <- fs::file_info(vpath)
    db_upsert_video(
      con,
      folder_id,
      as.character(fs::path_file(vpath)),
      as.character(vpath),
      as.integer(info$size),
      as.character(info$modification_time)
    )
  }
  invisible(length(video_paths))
}

#' Search videos with optional tag and text filters
#'
#' @param con A DBI connection.
#' @param folder_id Integer folder id.
#' @param text Optional free-text search (matched against filename and tag names).
#' @param tag_ids Optional integer vector of tag ids (AND logic: all must match).
#' @param order_by One of `"filename"`, `"size_bytes"`, or `"modified_at"`.
#' @param order_dir One of `"ASC"` or `"DESC"`.
#' @return A data frame with columns id, filename, path, size_bytes, modified_at, tags.
#' @importFrom DBI dbGetQuery
#' @noRd
db_search_videos <- function(
    con,
    folder_id,
    text = NULL,
    tag_ids = NULL,
    order_by = "filename",
    order_dir = "ASC") {
  valid_order <- c("filename", "size_bytes", "modified_at")
  valid_dir <- c("ASC", "DESC")
  if (!order_by %in% valid_order) order_by <- "filename"
  if (!order_dir %in% valid_dir) order_dir <- "ASC"

  params <- list(folder_id)

  tag_clause <- ""
  if (!is.null(tag_ids) && length(tag_ids) > 0L) {
    placeholders <- paste(rep("?", length(tag_ids)), collapse = ", ")
    tag_clause <- paste0(
      "AND v.id IN (
        SELECT vt2.video_id FROM video_tags vt2
        WHERE vt2.tag_id IN (", placeholders, ")
        GROUP BY vt2.video_id
        HAVING COUNT(DISTINCT vt2.tag_id) >= ", length(tag_ids), "
      )"
    )
    params <- c(params, as.list(tag_ids))
  }

  text_clause <- ""
  if (!is.null(text) && nchar(trimws(text)) > 0L) {
    text_clause <- "
      AND (v.filename LIKE ? OR v.id IN (
        SELECT vt3.video_id FROM video_tags vt3
        JOIN tags t3 ON t3.id = vt3.tag_id
        WHERE t3.name LIKE ?
      ))"
    like_val <- paste0("%", trimws(text), "%")
    params <- c(params, list(like_val, like_val))
  }

  sql <- paste0(
    "SELECT
       v.id,
       v.filename,
       v.path,
       v.size_bytes,
       v.modified_at,
       COALESCE(GROUP_CONCAT(t.name, ', '), '') AS tags
     FROM videos v
     LEFT JOIN video_tags vt ON vt.video_id = v.id
     LEFT JOIN tags t ON t.id = vt.tag_id
     WHERE v.folder_id = ?
     ", tag_clause, text_clause, "
     GROUP BY v.id
     ORDER BY v.", order_by, " ", order_dir
  )

  DBI::dbGetQuery(con, sql, params)
}

#' Get all tags in the database
#'
#' @param con A DBI connection.
#' @return A data frame with columns id and name.
#' @importFrom DBI dbGetQuery
#' @noRd
db_get_all_tags <- function(con) {
  DBI::dbGetQuery(
    con,
    "SELECT id, name FROM tags ORDER BY name COLLATE NOCASE"
  )
}

#' Get tags attached to a specific video
#'
#' @param con A DBI connection.
#' @param video_id Integer video id.
#' @return A data frame with columns id and name.
#' @importFrom DBI dbGetQuery
#' @noRd
db_get_video_tags <- function(con, video_id) {
  DBI::dbGetQuery(
    con,
    "SELECT t.id, t.name
     FROM tags t
     JOIN video_tags vt ON vt.tag_id = t.id
     WHERE vt.video_id = ?
     ORDER BY t.name COLLATE NOCASE",
    list(video_id)
  )
}

#' Ensure a tag exists and return its id
#'
#' Creates the tag if it does not yet exist (case-insensitive match).
#'
#' @param con A DBI connection.
#' @param name Tag name (will be trimmed of whitespace).
#' @return Integer tag id.
#' @importFrom DBI dbExecute dbGetQuery
#' @noRd
db_ensure_tag <- function(con, name) {
  name <- trimws(name)
  DBI::dbExecute(con, "INSERT OR IGNORE INTO tags (name) VALUES (?)", list(name))
  result <- DBI::dbGetQuery(
    con,
    "SELECT id FROM tags WHERE name = ? COLLATE NOCASE",
    list(name)
  )
  result$id[[1L]]
}

#' Add a tag to a video (idempotent)
#'
#' @param con A DBI connection.
#' @param video_id Integer video id.
#' @param tag_id Integer tag id.
#' @importFrom DBI dbExecute
#' @noRd
db_add_video_tag <- function(con, video_id, tag_id) {
  DBI::dbExecute(
    con,
    "INSERT OR IGNORE INTO video_tags (video_id, tag_id) VALUES (?, ?)",
    list(video_id, tag_id)
  )
  invisible(NULL)
}

#' Remove a tag from a video
#'
#' @param con A DBI connection.
#' @param video_id Integer video id.
#' @param tag_id Integer tag id.
#' @importFrom DBI dbExecute
#' @noRd
db_remove_video_tag <- function(con, video_id, tag_id) {
  DBI::dbExecute(
    con,
    "DELETE FROM video_tags WHERE video_id = ? AND tag_id = ?",
    list(video_id, tag_id)
  )
  invisible(NULL)
}
