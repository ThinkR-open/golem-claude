test_that("mod_search_ui produces a shiny tag list", {
  ui <- mod_search_ui("test")
  golem::expect_shinytaglist(ui)
})

test_that("mod_search_ui contains expected input ids", {
  ui <- mod_search_ui("test")
  html <- as.character(ui)
  expect_true(grepl("test-search_text", html))
  expect_true(grepl("test-filter_tags", html))
  expect_true(grepl("test-order_by", html))
})

test_that(".run_search populates local_rv$videos from the database", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/test_folder_search")
  db_upsert_video(con, folder_id, "a.mp4", "/tmp/test_folder_search/a.mp4", 100L, "2024-01-01")

  app_state <- shiny::reactiveValues(db_con = con, folder_id = folder_id)
  local_rv  <- shiny::reactiveValues(videos = data.frame(), selected_path = NULL)

  fake_input <- list(
    filter_tags = NULL,
    search_text = "",
    order_by    = "filename",
    order_dir   = "ASC"
  )

  shiny::isolate({
    .run_search(fake_input, app_state, local_rv)
    expect_equal(nrow(local_rv$videos), 1L)
    expect_null(local_rv$selected_path)
  })
})

test_that(".run_search with text filter returns matching videos only", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  folder_id <- db_upsert_folder(con, "/tmp/search_folder2")
  db_upsert_video(con, folder_id, "vacation.mp4", "/tmp/search_folder2/vacation.mp4", 100L, "2024-01-01")
  db_upsert_video(con, folder_id, "birthday.mp4", "/tmp/search_folder2/birthday.mp4", 200L, "2024-01-02")

  app_state <- shiny::reactiveValues(db_con = con, folder_id = folder_id)
  local_rv  <- shiny::reactiveValues(videos = data.frame(), selected_path = NULL)

  fake_input <- list(
    filter_tags = NULL,
    search_text = "vacation",
    order_by    = "filename",
    order_dir   = "ASC"
  )

  shiny::isolate({
    .run_search(fake_input, app_state, local_rv)
    expect_equal(nrow(local_rv$videos), 1L)
    expect_equal(local_rv$videos$filename, "vacation.mp4")
  })
})
