#' @include Solver-proto.R
NULL

#' Add a SYMPHONY solver with \pkg{lpsymphony}
#'
#' Specify that the \emph{SYMPHONY} software should be used to solve a
#' conservation planning problem using the \pkg{lpsymphony} package. This
#' function can also be used to customize the behavior of the solver.
#' It requires the \pkg{lpsymphony} package.
#'
#' @inheritParams add_rsymphony_solver
#'
#' @details \href{https://projects.coin-or.org/SYMPHONY}{\emph{SYMPHONY}} is an
#'   open-source integer programming solver that is part of the Computational
#'   Infrastructure for Operations Research (COIN-OR) project, an initiative
#'   to promote development of open-source tools for operations research (a
#'   field that includes linear programming). The \pkg{lpsymphony} package is
#'   distributed through
#'   \href{https://doi.org/doi:10.18129/B9.bioc.lpsymphony}{Bioconductor}.
#'   This functionality is provided because the \pkg{lpsymphony} package may
#'   be easier to install to install on Windows and Mac OSX systems than the
#'   \pkg{Rsymphony} package.
#'
#' @inherit add_rsymphony_solver seealso return
#'
#' @seealso \code{\link{solvers}}.
#'
#' @examples
#' # load data
#' data(sim_pu_raster, sim_features)
#'
#' # create problem
#' p <- problem(sim_pu_raster, sim_features) %>%
#'   add_min_set_objective() %>%
#'   add_relative_targets(0.1) %>%
#'   add_binary_decisions()
#' \donttest{
#' # if the package is installed then add solver and generate solution
#' # note that this solver is skipped on Linux systems due to the fact
#' # that the lpsymphony package randomly crashes on these systems
#' if (require(lpsymphony) &
#'     isTRUE(Sys.info()[["sysname"]] != "Linux")) {
#'   # specify solver and generate solution
#'   s <- p %>% add_lpsymphony_solver(time_limit = 5) %>%
#'              solve()
#'
#'   # plot solutions
#'   plot(stack(sim_pu_raster, s), main = c("planning units", "solution"))
#' }
#' }
#'
#' @name add_lsymphony_solver
NULL

#' @export
methods::setClass("LpsymphonySolver", contains = "Solver")

#' @rdname add_lsymphony_solver
#' @export
add_lpsymphony_solver <- function(x, gap = 0.1, time_limit = -1,
                                  first_feasible = 0, verbose = TRUE) {
  # assert that arguments are valid
  assertthat::assert_that(inherits(x, "ConservationProblem"),
                          isTRUE(all(is.finite(gap))),
                          assertthat::is.scalar(gap),
                          isTRUE(gap >= 0), isTRUE(all(is.finite(time_limit))),
                          assertthat::is.scalar(time_limit),
                          assertthat::is.count(time_limit) || isTRUE(time_limit
                            == -1),
                          assertthat::is.flag(verbose),
                          assertthat::is.scalar(first_feasible),
                          isTRUE(first_feasible == 1 || isTRUE(first_feasible
                            == 0)),
                          requireNamespace("lpsymphony", quietly = TRUE))
  # throw warning about bug in lpsymphony
  if (utils::packageVersion("lpsymphony") <= as.package_version("1.4.1"))
    warning(paste0("The solution may be incorrect due to a bug in ",
                   "lpsymphony. Please verify that it is correct, ",
                   "or use a different solver to generate solutions."))
  # add solver
  x$add_solver(pproto(
    "LpsymphonySolver",
    Solver,
    name = "Lpsymphony",
    parameters = parameters(
      numeric_parameter("gap", gap, lower_limit = 0),
      integer_parameter("time_limit", time_limit, lower_limit = -1,
                        upper_limit = .Machine$integer.max),
      binary_parameter("first_feasible", first_feasible),
      binary_parameter("verbose", verbose)),
    solve = function(self, x) {
      model <- list(
        obj = x$obj(),
        mat = as.matrix(x$A()),
        dir = x$sense(),
        rhs = x$rhs(),
        types = x$vtype(),
        bounds = list(lower = list(ind = seq_along(x$lb()), val = x$lb()),
                      upper = list(ind = seq_along(x$ub()), val = x$ub())),
        max = isTRUE(x$modelsense() == "max"))
      p <- as.list(self$parameters)
      p$verbosity <- -1
      if (!p$verbose)
        p$verbosity <- -2
      p <- p[names(p) != "verbose"]
      names(p)[which(names(p) == "gap")] <- "gap_limit"
      model$dir <- replace(model$dir, model$dir == "=", "==")
      model$types <- replace(model$types, model$types == "S", "C")
      p$first_feasible <- as.logical(p$first_feasible)
      start_time <- Sys.time()
      s <- do.call(lpsymphony::lpsymphony_solve_LP, append(model, p))
      end_time <- Sys.time()
      if (is.null(s$solution) ||
          names(s$status) %in% c("TM_NO_SOLUTION", "PREP_NO_SOLUTION"))
        return(NULL)
      if (any(s$solution > 1 | s$solution < 0))
        stop("infeasible solution returned, try relaxing solver parameters")
      return(list(x = s$solution, objective = s$objval,
                  status = as.character(s$status),
                  runtime = as.double(end_time - start_time,
                                      format = "seconds")))
    }))
}
