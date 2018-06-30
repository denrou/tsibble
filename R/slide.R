# nocov start
replace_fn_names <- function(fn, replace = list()){
  rec_fn <- function(cl) {
    if (!is_call(cl)) {
      return(cl)
    }
    if (any(repl_fn <- names(replace) %in% call_name(cl))) {
      cl[[1]] <- replace[[repl_fn]]
    }
    as.call(append(cl[[1]], purrr::map(as.list(cl[-1]), rec_fn)))
  }
  body(fn) <- rec_fn(body(fn))
  fn
}
# nocov end

#' Sliding window calculation
#'
#' Rolling window with overlapping observations:
#' * `slide()` always returns a list.
#' * `slide_lgl()`, `slide_int()`, `slide_dbl()`, `slide_chr()` return vectors
#' of the corresponding type.
#' * `slide_dfr()` `slide_dfc()` return data frames using row-binding & column-binding.
#'
#' @param .x An atomic vector. Instead [lslide] takes list & data.frame.
#' @inheritParams purrr::map
#' @param .size An integer for window size.
#' @param .fill A single value or data frame to replace `NA`.
#'
#' @rdname slide
#' @export
#' @seealso
#' * [slide2], [pslide], [lslide]
#' * [tile] for tiling window without overlapping observations
#' * [stretch] for expanding more observations
#' @details The `slide()` function attempts to tackle more general problems using
#' the purrr-like syntax. For some specialist functions like `mean` and `sum`,
#' you may like to check out for
#' [RcppRoll](https://CRAN.R-project.org/package=RcppRoll) for faster performance.
#'
#' @examples
#' # sliding through a vector ----
#' x <- 1:10
#' slide_dbl(x, mean, .size = 3)
#' slide_dbl(x, mean, .size = 3, .fill = 0)
#' slide_lgl(x, ~ mean(.) > 1, .size = 3)
#' @export
slide <- function(.x, .f, ..., .size = 1, .fill = NA) {
  only_atomic(.x)
  lst_x <- slider(.x, .size = .size)
  result <- purrr::map(lst_x, .f, ...)
  if (is.na(.fill)) {
    .fill <- rep_len(.fill, length(result[[1]]))
  }
  c(replicate(n = .size - 1, .fill, simplify = FALSE), result)
}

#' @rdname slide
#' @export
slide_dbl <- function(.x, .f, ..., .size = 1, .fill = NA) {
  only_atomic(.x)
  lst_x <- slider(.x, .size = .size)
  c(rep_len(.fill, .size - 1), purrr::map_dbl(lst_x, .f, ...))
}

#' @evalRd paste0('\\alias{slide_', c("lgl", "chr", "int"), '}')
#' @name slide
#' @rdname slide
#' @exportPattern ^slide_
for(type in c("lgl", "chr", "int")){
  assign(
    paste0("slide_", type),
    replace_fn_names(slide_dbl, list(map_dbl = sym(paste0("map_", type))))
  )
}

#' @rdname slide
#' @export
slide_dfr <- function(.x, .f, ..., .size = 1, .fill = NA, .id = NULL) {
  only_atomic(.x)
  out <- slide(.x, .f = .f, ..., .size = .size, .fill = .fill)
  out_named <- purrr::map(out, set_names, names(out[[.size]]))
  dplyr::bind_rows(!!! out_named, .id = .id)
}

#' @rdname slide
#' @export
slide_dfc <- function(.x, .f, ..., .size = 1, .fill = NA) {
  only_atomic(.x)
  out <- slide(.x, .f = .f, ..., .size = .size, .fill = .fill)
  out_named <- purrr::map(out, set_names, names(out[[.size]]))
  dplyr::bind_cols(!!! out_named)
}

#' Sliding window calculation over multiple inputs simultaneously
#'
#' @param .x,.y An atomic vector.
#' @inheritParams slide
#'
#' @rdname slide2
#' @export
#' @seealso
#' * [slide]
#' * [tile2] for tiling window without overlapping observations
#' * [stretch2] for expanding more observations
#'
#' @export
#' @examples
#' x <- 1:10
#' y <- 10:1
#' z <- x * 2
#' slide2_dbl(x, y, cor, .size = 3)
#' slide2(x, y, cor, .size = 3)
#' pslide_dbl(list(x, y, z), sum, .size = 3)
#' @rdname slide2
#' @export
slide2 <- function(.x, .y, .f, ..., .size = 1, .fill = NA) {
  only_atomic(.x)
  only_atomic(.y)
  lst <- slider(.x, .y, .size = .size)
  result <- purrr::map2(lst[[1]], lst[[2]], .f, ...)
  if (is.na(.fill)) {
    .fill <- rep_len(.fill, length(result[[1]]))
  }
  c(replicate(n = .size - 1, .fill, simplify = FALSE), result)
}

#' @rdname slide2
#' @export
slide2_dbl <- function(.x, .y, .f, ..., .size = 1, .fill = NA) {
  only_atomic(.x)
  only_atomic(.y)
  lst <- slider(.x, .y, .size = .size)
  c(rep_len(.fill, .size - 1), purrr::map2_dbl(lst[[1]], lst[[2]], .f, ...))
}

#' @evalRd paste0('\\alias{slide2_', c("lgl", "chr", "int"), '}')
#' @name slide2
#' @rdname slide2
#' @exportPattern ^slide2_
for(type in c("lgl", "chr", "int")){
  assign(
    paste0("slide2_", type),
    replace_fn_names(slide2_dbl, list(map2_dbl = sym(paste0("map2_", type))))
  )
}

#' @rdname slide2
#' @export
slide2_dfr <- function(.x, .y, .f, ..., .size = 1, .fill = NA, .id = NULL) {
  only_atomic(.x)
  only_atomic(.y)
  out <- slide2(.x, .y, .f = .f, ..., .size = .size, .fill = .fill)
  out_named <- purrr::map(out, set_names, names(out[[.size]]))
  dplyr::bind_rows(!!! out_named, .id = .id)
}

#' @rdname slide2
#' @export
slide2_dfc <- function(.x, .y, .f, ..., .size = 1, .fill = NA) {
  only_atomic(.x)
  only_atomic(.y)
  out <- slide2(.x, .y, .f = .f, ..., .size = .size, .fill = .fill)
  out_named <- purrr::map(out, set_names, names(out[[.size]]))
  dplyr::bind_cols(!!! out_named)
}

#' @rdname slide2
#' @inheritParams purrr::pmap
#' @export
pslide <- function(.l, .f, ..., .size = 1, .fill = NA) {
  lst <- slider(.l, .size = .size)
  result <- purrr::pmap(lst, .f, ...)
  if (is.na(.fill)) {
    .fill <- rep_len(.fill, length(result[[1]]))
  }
  c(replicate(n = .size - 1, .fill, simplify = FALSE), result)
}

#' @rdname slide2
#' @export
pslide_dbl <- function(.l, .f, ..., .size = 1, .fill = NA) {
  lst <- slider(.l, .size = .size)
  c(rep_len(.fill, .size - 1), purrr::pmap_dbl(lst, .f, ...))
}

#' @evalRd paste0('\\alias{pslide_', c("lgl", "chr", "int"), '}')
#' @name pslide
#' @rdname slide2
#' @exportPattern ^pslide_
for(type in c("lgl", "chr", "int")){
  assign(
    paste0("pslide_", type),
    replace_fn_names(pslide_dbl, list(pmap_dbl = sym(paste0("pmap_", type))))
  )
}

#' @rdname slide2
#' @export
pslide_dfr <- function(.l, .f, ..., .size = 1, .fill = NA, .id = NULL) {
  out <- pslide(.l, .f = .f, ..., .size = .size, .fill = .fill)
  out_named <- purrr::map(out, set_names, names(out[[.size]]))
  dplyr::bind_rows(!!! out_named, .id = .id)
}

#' @rdname slide2
#' @export
pslide_dfc <- function(.l, .f, ..., .size = 1, .fill = NA) {
  out <- pslide(.l, .f = .f, ..., .size = .size, .fill = .fill)
  out_named <- purrr::map(out, set_names, names(out[[.size]]))
  dplyr::bind_cols(!!! out_named)
}

#' Rolling window on a list
#'
#' @inheritParams purrr::lmap
#' @inheritParams slide
#' @rdname lslide
#' @export
lslide <- function(.x, .f, ..., .size = 1, .fill = NA) {
  only_list(.x)
  lst <- slider(.x, .size = .size)
  lslide_constructor(lst, .f, ..., .size = .size, .fill = .fill)
}

#' @rdname lslide
#' @export
lslide_if <- function(.x, .p, .f, ..., .size = 1, .fill = NA) {
  only_list(.x)
  sel <- probe(.x, .p)
  out <- list_along(.x)
  lst <- slider(.x[sel], .size = .size)
  out[sel] <- lslide_constructor(lst, .f, ..., .size = .size, .fill = .fill)
  out[!sel] <- .x[!sel]
  set_names(out, names(.x))
}

#' @rdname lslide
#' @export
lslide_at <- function(.x, .at, .f, ..., .size = 1, .fill = NA) {
  only_list(.x)
  sel <- inv_which(.x, .at)
  out <- list_along(.x)
  lst <- slider(.x[sel], .size = .size)
  out[sel] <- lslide_constructor(lst, .f, ..., .size = .size, .fill = .fill)
  out[!sel] <- .x[!sel]
  set_names(out, names(.x))
}

lslide_constructor <- function(x, .f, ..., .size = 1, .fill = NA) {
  purrr::modify_depth(x, 2, .f, ...) %>% 
    purrr::map(~ c(rep(.fill, .size - 1), .)) %>% 
    purrr::map(unlist, recursive = FALSE, use.names = FALSE)
}

#' Splits the input to a list according to the rolling window .size.
#'
#' @param ... Objects to be splitted.
#' @inheritParams slide
#' @rdname slider
#' @export
#' @examples
#' x <- 1:10
#' slider(x, .size = 3)
#' y <- 10:1
#' slider(x, y, .size = 3)
slider <- function(..., .size = 1) {
  lst <- list2(...)
  x <- flatten(lst)
  if (purrr::vec_depth(lst) == 2 && has_length(x, 1)) {
    return(slider_base(x[[1]], .size = .size))
  } else {
    return(purrr::map(x, ~ slider_base(., .size = .size)))
  }
}

slider_base <- function(x, .size = 1) {
  bad_window_function(x, .size)
  len_x <- NROW(x)
  lst_idx <- seq_len(len_x - .size + 1)
  if (is_atomic(x)) {
    return(purrr::map(lst_idx, ~ x[(.):(. + .size - 1)]))
  }
  purrr::map(lst_idx, ~ x[(.):(. + .size - 1), , drop = FALSE])
}

bad_window_function <- function(.x, .size) {
  if (is_bare_list(.x)) {
    abort("`.x` must not be a list of lists.")
  }
  if (!is_bare_numeric(.size, n = 1) || .size < 1) {
    abort("`.size` must be a positive integer.")
  }
}

incr <- function(init, size) {
  init
  function() {
    init <<- init + size
    init
  }
}

only_atomic <- function(x) {
  if (!is_bare_atomic(x)) {
    abort("Only accepts atomic vector, not a list or data.frame.")
  }
}

only_list <- function(x) {
  if (!is_list(x)) {
    abort("Only accepts a list or data.frame.")
  }
}

# from purrr
probe <- function(.x, .p, ...) {
  if (is_logical(.p)) {
    stopifnot(length(.p) == length(.x))
    .p
  } else {
    map_lgl(.x, .p, ...)
  }
}

inv_which <- function(x, sel) {
  if (is.character(sel)) {
    names <- names(x)
    if (is.null(names)) {
      stop("character indexing requires a named object", call. = FALSE)
    }
    names %in% sel
  } else if (is.numeric(sel)) {
    if (any(sel < 0)) {
      !seq_along(x) %in% abs(sel)
    } else {
      seq_along(x) %in% sel
    }

  } else {
    stop("unrecognised index type", call. = FALSE)
  }
}