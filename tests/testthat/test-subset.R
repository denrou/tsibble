context("a tsibble for base subset")

idx_day <- seq.Date(ymd("2017-02-01"), ymd("2017-02-05"), by = 1)
dat_x <- tibble(
  date = rep(idx_day, 2),
  group = rep(letters[1:2], each = 5),
  value = rnorm(10)
)

tsbl <- as_tsibble(dat_x, key = id(group), index = date)

test_that("if it's an atomic vector", {
  expect_is(tsbl$date, "Date")
  expect_is(tsbl[["date"]], "Date")
  expect_is(tsbl$group, "character")
  expect_is(tsbl[["group"]], "character")
  expect_is(tsbl$value, "numeric")
  expect_is(tsbl[["value"]], "numeric")
})

test_that("if it's a tibble", {
  expect_is(pedestrian[2], "tbl_df")
  expect_is(tsbl[, "date"], "tbl_df")
  expect_is(tsbl[, "date"], "tbl_df")
  expect_is(tsbl[1, "group"], "tbl_df")
  expect_is(tsbl[1, c("group", "date")], "tbl_ts")
  expect_is(tsbl[, 1], "tbl_df")
  expect_is(tsbl[, 2], "tbl_df")
  expect_is(tsbl[, 3], "tbl_df")
  expect_is(tsbl[, 2:3], "tbl_df")
  expect_is(tsbl[, c(1, 3)], "tbl_df")
  tsbl_tmp <- tsbl %>% filter(group == "a")
  expect_is(tsbl_tmp[, "date"], "tbl_ts")
  expect_is(tsbl_tmp["date"], "tbl_ts")
})

tsbl1 <- tsibble(date = as.Date("2010-01-01") + 0:10)
test_that("if it's a vector", {
  expect_equal(tsbl1[, 1, drop = TRUE], tsbl1$date)
  tsbl2 <- tsbl1[1, ]
  expect_equal(tsbl2[, 1, drop = TRUE], as.Date("2010-01-01"))
})

test_that("if it's a tsibble", {
  expect_identical(tsbl[1:11, ], as_tibble(tsbl)[1:11, ])
  expect_equal(tsbl[], tsbl)
  expect_is(tsbl[, c(1, 2)], "tbl_ts")
  expect_warning(tsbl[c("group", "date"), drop = TRUE], "`drop` is ignored.")
  expect_identical(tsbl[FALSE, ], tsbl[0, ])
  expect_identical(tsbl[TRUE, ], tsbl)
  tsbl2 <- tsbl[1, ]
  expect_is(tsbl2, "tbl_ts")
  expect_true(is_regular(tsbl2))
})

dat_x <- tibble::tribble(
  ~ date, ~ group1, ~ group2, ~ value,
  ymd("2017-10-01"), "a", "x", 1,
  ymd("2017-10-02"), "a", "x", 1,
  ymd("2017-10-01"), "a", "y", 3,
  ymd("2017-10-02"), "a", "y", 3,
  ymd("2017-10-01"), "b", "x", 2,
  ymd("2017-10-02"), "b", "y", 2
)

tsbl <- as_tsibble(dat_x, key = id(group1, group2), index = date)

test_that("subset 2 variables in a tsibble", {
  expect_is(tsbl[, c(1, 2, 4)], "tbl_df")
  expect_is(tsbl[, c(1, 3, 4)], "tbl_df")
  expect_is(tsbl[, 2:4], "tbl_df")
})

# test_that("`[<-.tbl_ts", {
#   expect_error(tsbl[] <- 0, "Oops!")
#   expect_error(tsbl[1] <- 0, "Can't retain")
#   expect_error(tsbl[1:7, 2] <- 0, "not exceed")
#   expect_is({tsbl[4] <- 0; tsbl}, "tbl_ts")
#   expect_is({tsbl["value"] <- 0; tsbl}, "tbl_ts")
#   expect_is({tsbl["value2"] <- 0; tsbl}, "tbl_ts")
#   expect_equal({tsbl["value2"] <- 0; NCOL(tsbl)}, 5)
#   expect_equal({tsbl[6] <- 0; NCOL(tsbl)}, 5 + 1)
#   expect_equal({tsbl[, 7] <- 0; NCOL(tsbl)}, 5 + 2)
#   expect_equal({tsbl[6] <- 0; names(tsbl)[6]}, "6")
#   expect_error(tsbl[1:5, 2] <- 0, "Can't retain")
#   expect_is({tsbl[4, 2] <- "c"; tsbl}, "tbl_ts")
#   expect_identical({tsbl[2, "value"] <- 1; tsbl[, 1:3]}, tsbl[, 1:3])
# })
#
# test_that("`$<-.tbl_ts", {
#   expect_error(tsbl$date <- 0, "Can't retain")
#   expect_is({tsbl$value <- 0; tsbl}, "tbl_ts")
#   expect_is({tsbl$value2 <- 0; tsbl}, "tbl_ts")
#   expect_equal({tsbl$value2 <- 0; NCOL(tsbl)}, 5)
# })
