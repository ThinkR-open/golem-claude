test_that("db_connect creates a valid connection", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  expect_s4_class(con, "SQLiteConnection")
})

test_that("db_init creates all expected tables", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  db_init(con)

  tables <- DBI::dbListTables(con)
  expect_true("folders" %in% tables)
  expect_true("videos" %in% tables)
  expect_true("tags" %in% tables)
  expect_true("video_tags" %in% tables)
})

test_that("db_init is idempotent", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  expect_no_error(db_init(con))
  expect_no_error(db_init(con))
})

test_that("db_upsert_folder creates folder and updates last_accessed", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  id1 <- db_upsert_folder(con, "/tmp/test_folder")
  expect_type(id1, "integer")

  # Second upsert of same path returns same id
  id2 <- db_upsert_folder(con, "/tmp/test_folder")
  expect_equal(id1, id2)
})

test_that("db_get_folders returns data frame with expected columns", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  db_upsert_folder(con, "/tmp/folder_a")
  db_upsert_folder(con, "/tmp/folder_b")

  result <- db_get_folders(con)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("id", "path", "last_accessed") %in% names(result)))
  expect_equal(nrow(result), 2L)
})

test_that("db_upsert_video stores and returns a video id", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/folder")
  vid_id <- db_upsert_video(
    con, folder_id, "test.mp4", "/tmp/folder/test.mp4",
    1024L, "2024-01-01 00:00:00"
  )
  expect_type(vid_id, "integer")
  expect_true(vid_id > 0L)
})

test_that("db_ensure_tag creates tag and is case-insensitive", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  id1 <- db_ensure_tag(con, "Holiday")
  id2 <- db_ensure_tag(con, "holiday")  # same tag
  expect_equal(id1, id2)

  all_tags <- db_get_all_tags(con)
  expect_equal(nrow(all_tags), 1L)
})

test_that("db_add_video_tag and db_get_video_tags work correctly", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/folder")
  vid_id <- db_upsert_video(
    con, folder_id, "clip.mp4", "/tmp/folder/clip.mp4",
    2048L, "2024-06-01 10:00:00"
  )
  tag_id <- db_ensure_tag(con, "nature")
  db_add_video_tag(con, vid_id, tag_id)

  tags <- db_get_video_tags(con, vid_id)
  expect_equal(nrow(tags), 1L)
  expect_equal(tags$name, "nature")
})

test_that("db_add_video_tag is idempotent", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/folder")
  vid_id <- db_upsert_video(
    con, folder_id, "clip.mp4", "/tmp/folder/clip.mp4",
    2048L, "2024-06-01 10:00:00"
  )
  tag_id <- db_ensure_tag(con, "sport")

  expect_no_error(db_add_video_tag(con, vid_id, tag_id))
  expect_no_error(db_add_video_tag(con, vid_id, tag_id))

  tags <- db_get_video_tags(con, vid_id)
  expect_equal(nrow(tags), 1L)
})

test_that("db_remove_video_tag removes the tag", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/folder")
  vid_id <- db_upsert_video(
    con, folder_id, "clip.mp4", "/tmp/folder/clip.mp4",
    1024L, "2024-01-01"
  )
  tag_id <- db_ensure_tag(con, "music")
  db_add_video_tag(con, vid_id, tag_id)
  db_remove_video_tag(con, vid_id, tag_id)

  tags <- db_get_video_tags(con, vid_id)
  expect_equal(nrow(tags), 0L)
})

test_that("db_search_videos filters by tag (AND logic)", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/folder")
  vid1 <- db_upsert_video(con, folder_id, "a.mp4", "/tmp/folder/a.mp4", 100L, "2024-01-01")
  vid2 <- db_upsert_video(con, folder_id, "b.mp4", "/tmp/folder/b.mp4", 200L, "2024-01-02")

  t1 <- db_ensure_tag(con, "alpha")
  t2 <- db_ensure_tag(con, "beta")

  db_add_video_tag(con, vid1, t1)
  db_add_video_tag(con, vid1, t2)
  db_add_video_tag(con, vid2, t1)

  # Both tags -> only vid1
  result <- db_search_videos(con, folder_id, tag_ids = c(t1, t2))
  expect_equal(nrow(result), 1L)
  expect_equal(result$filename, "a.mp4")

  # One tag -> both videos
  result2 <- db_search_videos(con, folder_id, tag_ids = c(t1))
  expect_equal(nrow(result2), 2L)
})

test_that("db_search_videos filters by text", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/folder")
  db_upsert_video(con, folder_id, "vacation2023.mp4", "/tmp/folder/vacation2023.mp4", 100L, "2024-01-01")
  db_upsert_video(con, folder_id, "birthday.mp4", "/tmp/folder/birthday.mp4", 200L, "2024-01-02")

  result <- db_search_videos(con, folder_id, text = "vacation")
  expect_equal(nrow(result), 1L)
  expect_equal(result$filename, "vacation2023.mp4")
})

test_that("db_search_videos respects order_by and order_dir", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/folder")
  db_upsert_video(con, folder_id, "b.mp4", "/tmp/folder/b.mp4", 300L, "2024-03-01")
  db_upsert_video(con, folder_id, "a.mp4", "/tmp/folder/a.mp4", 100L, "2024-01-01")
  db_upsert_video(con, folder_id, "c.mp4", "/tmp/folder/c.mp4", 200L, "2024-02-01")

  asc <- db_search_videos(con, folder_id, order_by = "filename", order_dir = "ASC")
  expect_equal(asc$filename, c("a.mp4", "b.mp4", "c.mp4"))

  desc <- db_search_videos(con, folder_id, order_by = "size_bytes", order_dir = "DESC")
  expect_equal(desc$filename, c("b.mp4", "c.mp4", "a.mp4"))
})
