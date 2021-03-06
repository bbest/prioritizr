#' @include internal.R ConservationProblem-proto.R
NULL

#' Feature representation
#'
#' Calculate how well features are represented in a solution.
#'
#' @param x \code{\link{ConservationProblem-class}} object.
#'
#' @param solution \code{numeric}, \code{matrix}, \code{data.frame},
#'   \code{\link[raster]{Raster-class}}, or \code{\link[sp]{Spatial-class}}
#'   object. See the Details section for more information.
#'
#' @details Note that all arguments to \code{solution} must correspond
#'   to the planning unit data in the argument to \code{x} in terms
#'   of data representation, dimensionality, and spatial attributes (if
#'   applicable). This means that if the planning unit data in \code{x}
#'   is a \code{numeric} vector then the argument to \code{solution} must be a
#'   \code{numeric} vector with the same number of elements, if the planning
#'   unit data in \code{x} is a \code{\link[raster]{RasterLayer-class}} then the
#'   argument to \code{solution} must also be a
#'   \code{\link[raster]{RasterLayer-class}} with the same number of rows and
#'   columns and the same resolution, extent, and coordinate reference system,
#'   if the planning unit data in \code{x} is a \code{\link[sp]{Spatial-class}}
#'   object then the argument to \code{solution} must also be a
#'   \code{\link[sp]{Spatial-class}} object and have the same number of spatial
#'   features (e.g. polygons) and have the same coordinate reference system,
#'   if the planning units in \code{x} are a \code{data.frame} then the
#'   argument to \code{solution} must also be a \code{data.frame} with each
#'   column correspond to a different zone and each row correspond to
#'   a different planning unit, and values correspond to the allocations
#'   (e.g. values of zero or one).
#'
#'   Valid solutions should not have non-zero allocations for planning
#'   units in zones that have \code{NA} cost values in the argument to
#'   \code{x}. In other words, planning units that have \code{NA} cost values
#'   in \code{x} should always have a value of zero in the argument to
#'   \code{solution}. If an argument is supplied to \code{solution} where
#'   this is not the case, then an error will be thrown. Additionally,
#'   note that when calculating the proportion of each feature represented
#'   in the solution, the denominator is calculated using all planning
#'   units---\strong{including any planning units with \code{NA} cost values in
#'   the argument to \code{x}}.
#'
#' @return \code{\link[tibble]{tibble}} containing the amount
#'   (\code{"absolute_held"}) and proportion (\code{"relative_held"})
#'   of the distribution of each feature held in the solution. Here, each
#'   row contains data that pertain to a specific feature in a specific
#'   management zone (if multiple zones are present). This object
#'   contains the following columns:
#'
#'   \describe{
#'
#'   \item{feature}{\code{character} name of the feature.}
#'
#'   \item{zone}{\code{character} name of the zone (not included when the
#'     argument to \code{x} contains only one management zone).}
#'
#'   \item{absolute_held}{\code{numeric} total amount of each feature secured in
#'     the solution. If the problem contains multiple zones, then this
#'     column shows how well each feature is represented in a each
#'     zone.}
#'
#'   \item{relative_held}{\code{numeric} proportion of the feature's
#'     distribution held in the solution. If the problem contains
#'     multiple zones, then this column shows how well each feature is
#'     represented in each zone.}
#'
#'   }
#'
#' @name feature_representation
#'
#' @aliases feature_representation,ConservationProblem,numeric-method feature_representation,ConservationProblem,matrix-method feature_representation,ConservationProblem,data.frame-method feature_representation,ConservationProblem,Spatial-method feature_representation,ConservationProblem,Raster-method
#'
#' @seealso \code{\link{problem}}, \code{\link{feature_abundances}}.
#'
#' @examples
#' # set seed for reproducibility
#' set.seed(500)
#'
#' # load data
#' data(sim_pu_raster, sim_pu_polygons, sim_features, sim_pu_zones_stack,
#'      sim_pu_zones_polygons, sim_features_zones)
#'
#'
#' # create a simple conservation planning data set so we can see exactly
#' # how feature representation is calculated
#' pu <- data.frame(id = seq_len(10), cost = c(0.2, NA, runif(8)),
#'                  spp1 = runif(10), spp2 = c(rpois(9, 4), NA))
#'
#' # create problem
#' p1 <- problem(pu, c("spp1", "spp2"), cost_column = "cost")
#'
#' # create a solution
#' s1 <- data.frame(solution = rep(c(1, 0), 5))
#'
#' # calculate feature representation
#' r1 <- feature_representation(p1, s1)
#'
#' # print feature representation
#' print(r1)
#'
#' # verify that feature representation calculations are correct
#' all.equal(r1$absolute_held, c(sum(pu$spp1 * s1[[1]]),
#'                               sum(pu$spp2 * s1[[1]], na.rm = TRUE)))
#' all.equal(r1$relative_held, c(sum(pu$spp1 * s1[[1]]) / sum(pu$spp1),
#'                               sum(pu$spp2 * s1[[1]], na.rm = TRUE) /
#'                               sum(pu$spp2, na.rm = TRUE)))
#'
#' # build minimal conservation problem with raster data
#' p2 <- problem(sim_pu_raster, sim_features) %>%
#'       add_min_set_objective() %>%
#'       add_relative_targets(0.1) %>%
#'       add_binary_decisions()
#' \donttest{
#' # solve the problem
#' s2 <- solve(p2)
#'
#' # print solution
#' print(s2)
#'
#' # calculate feature representation in the solution
#' r2 <- feature_representation(p2, s2)
#' print(r2)
#'
#' # plot solution
#' plot(s2, main = "solution", axes = FALSE, box = FALSE)
#' }
#' # build minimal conservation problem with spatial polygon data
#' p3 <- problem(sim_pu_polygons, sim_features, cost_column = "cost") %>%
#'       add_min_set_objective() %>%
#'       add_relative_targets(0.1) %>%
#'       add_binary_decisions()
#' \donttest{
#' # solve the problem
#' s3 <- solve(p3)
#'
#' # print first six rows of the attribute table
#' print(head(s3))
#'
#' # calculate feature representation in the solution
#' r3 <- feature_representation(p3, s3[, "solution_1"])
#' print(r3)
#'
#' # plot solution
#' spplot(s3, zcol = "solution_1", main = "solution", axes = FALSE, box = FALSE)
#' }
#' # build multi-zone conservation problem with raster data
#' p4 <- problem(sim_pu_zones_stack, sim_features_zones) %>%
#'       add_min_set_objective() %>%
#'       add_relative_targets(matrix(runif(15, 0.1, 0.2), nrow = 5,
#'                                   ncol = 3)) %>%
#'       add_binary_decisions()
#' \donttest{
#' # solve the problem
#' s4 <- solve(p4)
#'
#' # print solution
#' print(s4)
#'
#' # calculate feature representation in the solution
#' r4 <- feature_representation(p4, s4)
#' print(r4)
#'
#' # plot solution
#' plot(category_layer(s4), main = "solution", axes = FALSE, box = FALSE)
#' }
#' # build multi-zone conservation problem with spatial polygon data
#' p5 <- problem(sim_pu_zones_polygons, sim_features_zones,
#'               cost_column = c("cost_1", "cost_2", "cost_3")) %>%
#'       add_min_set_objective() %>%
#'       add_relative_targets(matrix(runif(15, 0.1, 0.2), nrow = 5,
#'                                   ncol = 3)) %>%
#'       add_binary_decisions()
#' \donttest{
#' # solve the problem
#' s5 <- solve(p5)
#'
#' # print first six rows of the attribute table
#' print(head(s5))
#'
#' # calculate feature representation in the solution
#' r5 <- feature_representation(p5, s5[, c("solution_1_zone_1",
#'                                         "solution_1_zone_2",
#'                                         "solution_1_zone_3")])
#' print(r5)
#'
#' # create new column representing the zone id that each planning unit
#' # was allocated to in the solution
#' s5$solution <- category_vector(s5@data[, c("solution_1_zone_1",
#'                                            "solution_1_zone_2",
#'                                            "solution_1_zone_3")])
#' s5$solution <- factor(s5$solution)
#'
#' # plot solution
#' spplot(s5, zcol = "solution", main = "solution", axes = FALSE, box = FALSE)
#' }
NULL

#' @name feature_representation
#'
#' @rdname feature_representation
#'
#' @exportMethod feature_representation
#'
methods::setGeneric("feature_representation",
  function(x, solution) {
  standardGeneric("feature_representation")
})

#' @name feature_representation
#' @usage \S4method{feature_representation}{ConservationProblem,numeric}(x, solution)
#' @rdname feature_representation
methods::setMethod("feature_representation",
  methods::signature("ConservationProblem", "numeric"),
  function(x, solution) {
    # assert valid arguments
    assertthat::assert_that(
      is.numeric(solution),
      is.numeric(x$data$cost), is.matrix(x$data$cost),
      number_of_total_units(x) == length(solution),
      number_of_zones(x) == 1,
      min(solution, na.rm = TRUE) >= 0,
      max(solution, na.rm = TRUE) <= 1)
    # subset planning units with finite cost values
    pos <- x$planning_unit_indices()
    if (any(solution[setdiff(seq_along(solution), pos)] > 0))
     stop("planning units with NA cost data have non-zero allocations in the ",
          "argument to solution")
    solution <- solution[pos]
    # calculate amount of each feature in each planning unit
    total <- x$feature_abundances_in_total_units()
    held <- rowSums(x$data$rij_matrix[[1]] *
                    matrix(solution, ncol = length(solution),
                           nrow = nrow(x$data$rij_matrix[[1]]),
                           byrow = TRUE))
    tibble::tibble(feature = x$feature_names(),
                   absolute_held = c(held),
                   relative_held = c(held / total))
})

#' @name feature_representation
#' @usage \S4method{feature_representation}{ConservationProblem,matrix}(x, solution)
#' @rdname feature_representation
methods::setMethod("feature_representation",
  methods::signature("ConservationProblem", "matrix"),
  function(x, solution) {
    # assert valid arguments
    assertthat::assert_that(
      is.matrix(solution), is.numeric(solution),
      is.matrix(x$data$cost), is.numeric(x$data$cost),
      number_of_total_units(x) == nrow(solution),
      number_of_zones(x) == ncol(solution),
      min(solution, na.rm = TRUE) >= 0,
      max(solution, na.rm = TRUE) <= 1)
    # subset planning units with finite cost values
    pos <- x$planning_unit_indices()
    if (any(solution[setdiff(seq_len(nrow(solution)), pos), ,
                     drop = FALSE] > 0))
      stop("planning units with NA cost data have non-zero allocations in the ",
           "argument to solution")
    solution <- solution[pos, , drop = FALSE]
    # calculate amount of each feature in each planning unit
    total <- x$feature_abundances_in_total_units()
    held <- vapply(seq_len(x$number_of_zones()),
                   function(i) rowSums(
                     x$data$rij_matrix[[i]] *
                     matrix(solution[, i], ncol = nrow(solution),
                            nrow = nrow(x$data$rij_matrix[[1]]),
                            byrow = TRUE)),
                     numeric(nrow(x$data$rij_matrix[[1]])))
    out <- tibble::tibble(feature = rep(x$feature_names(), x$number_of_zones()),
                          absolute_held = c(held),
                          relative_held = c(held / total))
    if (x$number_of_zones() > 1) {
      out$zone <- rep(x$zone_names(), each = x$number_of_features())
      out <- out[, c(1, 4, 2, 3), drop = FALSE]
    }
    out
})

#' @name feature_representation
#' @usage \S4method{feature_representation}{ConservationProblem,data.frame}(x, solution)
#' @rdname feature_representation
methods::setMethod("feature_representation",
  methods::signature("ConservationProblem", "data.frame"),
  function(x, solution) {
    # assert valid arguments
    assertthat::assert_that(
      is.data.frame(solution),
      number_of_zones(x) == ncol(solution),
      number_of_total_units(x) == nrow(solution),
      is.data.frame(x$data$cost),
      is.numeric(unlist(solution)),
      min(unlist(solution), na.rm = TRUE) >= 0,
      max(unlist(solution), na.rm = TRUE) <= 1)
    # subset planning units with finite cost values
    pos <- x$planning_unit_indices()
    solution <- as.matrix(solution)
    if (any(solution[setdiff(seq_len(nrow(solution)), pos), ,
                     drop = FALSE] > 0))
      stop("planning units with NA cost data have non-zero allocations in the ",
           "argument to solution")
    solution <- solution[pos, , drop = FALSE]
    # calculate amount of each feature in each planning unit
    total <- x$feature_abundances_in_total_units()
    held <- vapply(seq_len(x$number_of_zones()),
                   function(i) rowSums(
                     x$data$rij_matrix[[i]] *
                     matrix(solution[, i], ncol = nrow(solution),
                            nrow = nrow(x$data$rij_matrix[[1]]),
                            byrow = TRUE)),
                     numeric(nrow(x$data$rij_matrix[[1]])))
    out <- tibble::tibble(feature = rep(x$feature_names(), x$number_of_zones()),
                          absolute_held = c(held),
                          relative_held = c(held / total))
    if (x$number_of_zones() > 1) {
      out$zone <- rep(x$zone_names(), each = x$number_of_features())
      out <- out[, c(1, 4, 2, 3), drop = FALSE]
    }
    out
})

#' @name feature_representation
#' @usage \S4method{feature_representation}{ConservationProblem,Spatial}(x, solution)
#' @rdname feature_representation
methods::setMethod("feature_representation",
  methods::signature("ConservationProblem", "Spatial"),
  function(x, solution) {
    # assert valid arguments
    assertthat::assert_that(
      inherits(solution, c("SpatialPointsDataFrame", "SpatialLinesDataFrame",
                           "SpatialPolygonsDataFrame")),
      number_of_zones(x) == ncol(solution@data),
      number_of_total_units(x) == nrow(solution@data),
      class(x$data$cost)[1] == class(solution)[1],
      is.numeric(unlist(solution@data)),
      min(unlist(solution@data), na.rm = TRUE) >= 0,
      max(unlist(solution@data), na.rm = TRUE) <= 1)
    # subset planning units with finite cost values
    pos <- x$planning_unit_indices()
    solution <- as.matrix(solution@data)
    if (any(solution[setdiff(seq_len(nrow(solution)), pos), ,
                     drop = FALSE] > 0))
      stop("planning units with NA cost data have non-zero allocations in the ",
           "argument to solution")
    solution <- solution[pos, , drop = FALSE]
    # calculate amount of each feature in each planning unit
    total <- x$feature_abundances_in_total_units()
    held <- vapply(seq_len(x$number_of_zones()),
                   function(i) rowSums(
                     x$data$rij_matrix[[i]] *
                     matrix(solution[, i], ncol = nrow(solution),
                            nrow = nrow(x$data$rij_matrix[[1]]),
                            byrow = TRUE)),
                     numeric(nrow(x$data$rij_matrix[[1]])))
    out <- tibble::tibble(feature = rep(x$feature_names(), x$number_of_zones()),
                          absolute_held = c(held),
                          relative_held = c(held / total))
    if (x$number_of_zones() > 1) {
      out$zone <- rep(x$zone_names(), each = x$number_of_features())
      out <- out[, c(1, 4, 2, 3), drop = FALSE]
    }
    out
})

#' @name feature_representation
#' @usage \S4method{feature_representation}{ConservationProblem,Raster}(x, solution)
#' @rdname feature_representation
methods::setMethod("feature_representation",
  methods::signature("ConservationProblem", "Raster"),
  function(x, solution) {
    # assert valid arguments
    assertthat::assert_that(
      inherits(solution, "Raster"),
      number_of_zones(x) == raster::nlayers(solution),
      raster::compareCRS(x$data$cost@crs, solution@crs),
      is_comparable_raster(x$data$cost, solution[[1]]),
      min(raster::cellStats(solution, "min")) >= 0,
      max(raster::cellStats(solution, "max")) <= 1)
    # subset planning units with finite cost values
    pos <- x$planning_unit_indices()
    solution2 <- solution
    solution2[pos] <- 0
    if (any(raster::cellStats(solution2, "max") > 0))
      stop("planning units with NA cost data have non-zero allocations in the ",
           "argument to solution")
    solution <- solution[pos]
    if (!is.matrix(solution))
      solution <- matrix(solution, ncol = 1)
    # calculate amount of each feature in each planning unit
    total <- x$feature_abundances_in_total_units()
    held <- vapply(seq_len(x$number_of_zones()),
                   function(i) rowSums(
                     x$data$rij_matrix[[i]] *
                     matrix(solution[, i], ncol = nrow(solution),
                            nrow = nrow(x$data$rij_matrix[[1]]),
                            byrow = TRUE),
                     na.rm = TRUE),
                     numeric(nrow(x$data$rij_matrix[[1]])))
    out <- tibble::tibble(feature = rep(x$feature_names(), x$number_of_zones()),
                          absolute_held = c(held),
                          relative_held = c(held / total))
    if (x$number_of_zones() > 1) {
      out$zone <- rep(x$zone_names(), each = x$number_of_features())
      out <- out[, c(1, 4, 2, 3), drop = FALSE]
    }
    out
})
