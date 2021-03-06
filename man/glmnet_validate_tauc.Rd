% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/3_2_validate_utils.R
\name{glmnet_validate_tauc}
\alias{glmnet_validate_tauc}
\title{Compute validation measures for glmnet objects}
\usage{
glmnet_validate_tauc(
  x_tr,
  x_te,
  y_tr,
  y_te,
  alpha,
  lambda,
  pen.factor,
  tauc.type,
  tauc.time
)
}
\value{
time-dependent AUC (tAUC) value
}
\description{
Compute validation measures for glmnet objects
}
\keyword{internal}
