test_that("mod_db_io_ui produces a shiny tag list", {
  ui <- mod_db_io_ui("test")
  golem::expect_shinytaglist(ui)
})

test_that("mod_db_io_ui contains export and import controls", {
  ui <- mod_db_io_ui("test")
  html <- as.character(ui)
  expect_true(grepl("test-export_db_btn", html))
  expect_true(grepl("test-import_db_file", html))
  expect_true(grepl("test-import_db_btn", html))
})

test_that("db_connect and db_init round-trip: connect, init, disconnect", {
  db_path <- withr::local_tempfile(fileext = ".db")
  con <- db_connect(db_path)
  db_init(con)
  expect_true(DBI::dbIsValid(con))
  DBI::dbDisconnect(con)
  expect_false(DBI::dbIsValid(con))
})

test_that("copying a valid DB file preserves all data", {
  db_path1 <- withr::local_tempfile(fileext = ".db")
  db_path2 <- withr::local_tempfile(fileext = ".db")

  con1 <- db_connect(db_path1)
  db_init(con1)

  db_upsert_folder(con1, "/some/folder")
  db_ensure_tag(con1, "test_tag")
  DBI::dbDisconnect(con1)

  file.copy(db_path1, db_path2, overwrite = TRUE)

  con2 <- db_connect(db_path2)
  on.exit(DBI::dbDisconnect(con2), add = TRUE)

  folders <- db_get_folders(con2)
  tags    <- db_get_all_tags(con2)

  expect_equal(nrow(folders), 1L)
  expect_equal(folders$path, "/some/folder")
  expect_equal(nrow(tags), 1L)
  expect_equal(tags$name, "test_tag")
})
