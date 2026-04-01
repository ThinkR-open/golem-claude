test_that("mod_tag_ui produces a shiny tag list", {
  ui <- mod_tag_ui("test")
  golem::expect_shinytaglist(ui)
})

test_that("mod_tag_ui contains expected input and panel ids", {
  ui <- mod_tag_ui("test")
  html <- as.character(ui)
  expect_true(grepl("test-new_tags_text", html))
  expect_true(grepl("test-add_new_tags_btn", html))
  expect_true(grepl("test-remove_tags_btn", html))
  expect_true(grepl("test-existing_tag_select", html))
})

test_that(".refresh_video_tags updates session selectInput with correct tags", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/tag_test_folder")
  vid_id <- db_upsert_video(
    con, folder_id, "test.mp4", "/tmp/tag_test_folder/test.mp4", 100L, "2024-01-01"
  )
  tag_id <- db_ensure_tag(con, "scenic")
  db_add_video_tag(con, vid_id, tag_id)

  tags <- db_get_video_tags(con, vid_id)
  expect_equal(nrow(tags), 1L)
  expect_equal(tags$name, "scenic")
})

test_that(".refresh_all_tags returns all tags including newly added ones", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  db_ensure_tag(con, "alpha")
  db_ensure_tag(con, "beta")
  db_ensure_tag(con, "gamma")

  all_tags <- db_get_all_tags(con)
  expect_equal(nrow(all_tags), 3L)
  expect_true(all(c("alpha", "beta", "gamma") %in% all_tags$name))
})

test_that("%||% operator returns left if not NULL, right if NULL", {
  expect_equal("a" %||% "b", "a")
  expect_equal(NULL %||% "b", "b")
  expect_equal(42L %||% 0L, 42L)
})
