#' Nomograms for high-dimensional Cox models
#'
#' Nomograms for high-dimensional Cox models
#'
#' @param object Fitted model object.
#' @param model.type Fitted model type. Could be one of \code{"lasso"},
#' \code{"alasso"}, \code{"flasso"}, \code{"enet"}, \code{"aenet"},
#' \code{"mcp"}, \code{"mnet"}, \code{"scad"}, or \code{"snet"}.
#' @param x Matrix of training data used for fitting the model.
#' @param time Survival time.
#' Must be of the same length with the number of rows as \code{x}.
#' @param event Status indicator, normally 0 = alive, 1 = dead.
#' Must be of the same length with the number of rows as \code{x}.
#' @param pred.at Time point at which to plot nomogram prediction axis.
#' @param fun.at Function values to label on axis.
#' @param funlabel Label for \code{fun} axis.
#'
#' @note We will try to use the value of the automatically selected
#' "optimal" penalty parameter (e.g. lambda, alpha) in the model object.
#' The selected variables under the penalty parameter will be
#' used to build the nomogram and make predictions.
#'
#' @export as_nomogram
#'
#' @importFrom stats coef as.formula
#'
#' @examples
#' library("hdnom")
#' library("survival")
#'
#' # Load imputed SMART data
#' data(smart)
#' x <- as.matrix(smart[, -c(1, 2)])
#' time <- smart$TEVENT
#' event <- smart$EVENT
#' y <- Surv(time, event)
#'
#' # Fit penalized Cox model with lasso penalty
#' fit <- fit_lasso(x, y, nfolds = 5, rule = "lambda.1se", seed = 11)
#'
#' nom <- as_nomogram(
#'   fit$lasso_model,
#'   model.type = "lasso",
#'   x, time, event, pred.at = 365 * 2,
#'   funlabel = "2-Year Overall Survival Probability"
#' )
#'
#' print(nom)
#' plot(nom)
as_nomogram <- function(
  object,
  model.type =
    c(
      "lasso", "alasso", "flasso", "enet", "aenet",
      "mcp", "mnet", "scad", "snet"
    ),
  x, time, event,
  pred.at = NULL, fun.at = NULL, funlabel = NULL) {

  # input parameter sanity check
  model.type <- match.arg(model.type)

  if (nrow(x) != length(time) || nrow(x) != length(event)) {
    stop("Number of x rows and length of time/event did not match")
  }

  if (is.null(pred.at)) stop("Missing argument pred.at")

  # convert hdcox models to nomogram object
  nomogram_object <- convert_model(object, x)

  # compute survival curves
  if (model.type %in% c("lasso", "alasso", "enet", "aenet")) {
    if (!all(c("coxnet", "glmnet") %in% class(object))) {
      stop('object class must be "glmnet" and "coxnet"')
    }

    if (length(object$"lambda") != 1L) {
      stop("There should be one and only one lambda in the model object")
    }

    idx_ones <- which(event == 1L)
    survtime_ones <- time[idx_ones]
    names(survtime_ones) <- idx_ones
    survtime_ones <- sort(survtime_ones)
    survtime_at <- survtime_ones[which(survtime_ones > pred.at)[1L] - 1L]
    survtime_at_idx <- names(survtime_at)

    survcurve <- glmnet_survcurve(
      object = object, time = time, event = event,
      x = x, survtime = survtime_ones
    )
  }

  if (model.type %in% c("mcp", "mnet", "scad", "snet")) {
    if (!all(c("ncvsurv", "ncvreg") %in% class(object))) {
      stop('object class must be "ncvreg" and "ncvsurv"')
    }

    idx_ones <- which(event == 1L)
    survtime_ones <- time[idx_ones]
    names(survtime_ones) <- idx_ones
    survtime_ones <- sort(survtime_ones)
    survtime_at <- survtime_ones[which(survtime_ones > pred.at)[1L] - 1L]
    survtime_at_idx <- names(survtime_at)

    survcurve <- ncvreg_survcurve(
      object = object, time = time, event = event,
      x = x, survtime = survtime_ones
    )
  }

  if (model.type %in% c("flasso")) {
    if (!("penfit" %in% class(object))) {
      stop('object class must be "penfit"')
    }

    idx_ones <- which(event == 1L)
    survtime_ones <- time[idx_ones]
    names(survtime_ones) <- idx_ones
    survtime_ones <- sort(survtime_ones)
    survtime_at <- survtime_ones[which(survtime_ones > pred.at)[1L] - 1L]
    survtime_at_idx <- names(survtime_at)

    survcurve <- penalized_survcurve(
      object = object, time = time, event = event,
      x = x, survtime = survtime_ones
    )
  }

  # compute baseline harzard
  baseline <- exp(
    log(survcurve$p[1L, which(colnames(survcurve$p) == survtime_at_idx)]) /
      exp(survcurve$lp[1L])
  )
  bhfun <- function(z) baseline^exp(z)

  # set prediction time points
  if (is.null(fun.at)) {
    fun.at <- c(0.05, 0.2, 0.4, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99)
  }

  if (is.null(funlabel)) {
    funlabel <- paste("Overall Survival Probability at Time", pred.at)
  }

  nom <- list(
    "nomogram" = nomogram_object,
    "survcurve" = survcurve,
    "bhfun" = bhfun,
    "pred.at" = pred.at,
    "fun.at" = fun.at,
    "funlabel" = funlabel
  )

  class(nom) <- "hdnom.nomogram"

  nom
}