test_that("mod_folder_select_ui produces a shiny tag list with expected inputs", {
  ui <- mod_folder_select_ui("test")
  golem::expect_shinytaglist(ui)
  html <- as.character(ui)
  expect_true(grepl("test-folder_btn", html))
  expect_true(grepl("test-recent_path", html))
  expect_true(grepl("test-open_recent_btn", html))
})

test_that("mod_folder_select_ui id is correctly namespaced", {
  fmls <- formals(mod_folder_select_ui)
  expect_true("id" %in% names(fmls))
})

test_that(".open_folder updates app_state fields", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  db_init(con)

  tmp_dir <- withr::local_tempdir()
  file.create(file.path(tmp_dir, "movie.mp4"))

  app_state <- shiny::reactiveValues(
    db_con      = con,
    folder_path = NULL,
    folder_id   = NULL,
    refresh     = 0L
  )

  shiny::isolate({
    .open_folder(tmp_dir, app_state)
    expect_equal(app_state$folder_path, tmp_dir)
    expect_type(app_state$folder_id, "integer")
    expect_equal(app_state$refresh, 1L)
  })
})
