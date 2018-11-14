filter_index <- function(.data, ...) {
  formulas <- list2(...)
  n <- length(formulas)

  if (n == 0) return(.data)

  lgl <- lhs <- rhs <- vector("list", n)
  index <- eval_tidy(index(.data), data = .data)
  for (i in seq_len(n)) {
    f <- formulas[[i]]
    if (is_atomic(f)) {
      f <- new_formula(f, f)
    }
    env <- get_env(f)
    lhs[[i]] <- start(index, eval_bare(is_dot_null(f_lhs(f)), env = env))
    rhs[[i]] <- end(index, eval_bare(is_dot_null(f_rhs(f)), env = env))
    lgl[[i]] <- eval_bare(index >= lhs[[i]] & index < rhs[[i]])
  }

  lgl <- purrr::reduce(lgl, `|`)
  filter(.data, lgl)
}

#' @importFrom stats start end
#' @importFrom lubridate tz<-
start.numeric <- function(x, y = NULL, ...) {
  if (is_null(y)) {
    min(x)
  } else {
    as.numeric(y)
  }
}

end.numeric <- function(x, y = NULL, ...) {
  if (is_null(y)) {
    max(x) + 1
  } else {
    as.numeric(y) + 1
  }
}

start.Date <- function(x, y = NULL, ...) {
  if (is_null(y)) {
    min(x)
  } else {
    abort_not_chr(y, class = "Date")
    anytime::assertDate(y)
    tz <- lubridate::tz(x)
    y <- anytime::anydate(y)
    tz(y) <- tz
    y
  }
}

end.Date <- function(x, y = NULL, ...) {
  if (is_null(y)) {
    max(x) + lubridate::period(1, "day")
  } else {
    abort_not_chr(y, class = "Date")
    anytime::assertDate(y)
    
    lgl_yrmth <- nchar(y) < 8 & nchar(y) > 4
    lgl_yr <- nchar(y) < 5
    tz <- lubridate::tz(x)
    y <- anytime::anydate(y)
    tz(y) <- tz
    if (any(lgl_yrmth)) {
      y[lgl_yrmth] <- lubridate::rollback(
        y[lgl_yrmth] + lubridate::period(1, "month"), 
        roll_to_first = TRUE
      )
    }
    if (any(lgl_yr)) {
      y[lgl_yr] <- y[lgl_yr] + lubridate::period(1, "year")
    }
    lgl_date <- !(lgl_yrmth | lgl_yr)
    y[lgl_date] <- y[lgl_date] + lubridate::period(1, "day")
    y
  }
}

start.POSIXct <- function(x, y = NULL, ...) {
  if (is_null(y)) {
    min(x)
  } else {
    abort_not_chr(y, class = "POSIXct")
    anytime::assertTime(y)
    tz <- lubridate::tz(x)
    y <- anytime::anytime(y)
    tz(y) <- tz
    y
  }
}

end.POSIXct <- function(x, y = NULL, ...) {
  if (is_null(y)) {
    max(x) + lubridate::period(1, "second")
  } else {
    abort_not_chr(y, class = "POSIXct")
    anytime::assertTime(y)
    
    lgl_yrmth <- nchar(y) < 8 & nchar(y) > 4
    lgl_yr <- nchar(y) < 5
    tz <- lubridate::tz(x)
    y <- anytime::anytime(y)
    tz(y) <- tz
    if (any(lgl_yrmth)) {
      y[lgl_yrmth] <- lubridate::rollback(
        y[lgl_yrmth] + lubridate::period(1, "month"), 
        roll_to_first = TRUE
      )
    }
    if (any(lgl_yr)) {
      y[lgl_yr] <- y[lgl_yr] + lubridate::period(1, "year")
    }
    lgl_date <- !(lgl_yrmth | lgl_yr)
    y[lgl_date] <- y[lgl_date] + lubridate::period(1, "second")
    y
  }
}

start.yearweek <- function(x, y = NULL, ...) {
  x <- as_date(x)
  NextMethod()
}

end.yearweek <- function(x, y = NULL, ...) {
  x <- as_date(x)
  NextMethod()
}

start.yearmonth <- start.yearweek

end.yearmonth <- end.yearweek

start.yearquarter <- start.yearweek

end.yearquarter <- end.yearweek

is_dot_null <- function(x) { # x is a sym
  if (is_null(x)) {
    NULL
  } else if (x == sym(".")) {
    NULL
  } else {
    x
  }
}

abort_not_chr <- function(x, class) {
  if (!is_character(x)) {
    abort(sprintf("Must be character(s) for %s, not %s.", class, typeof(x)))
  }
}