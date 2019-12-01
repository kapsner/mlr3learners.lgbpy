#' @import data.table
#' @import paradox
#' @import mlr3misc
#' @importFrom R6 R6Class
#' @importFrom mlr3 mlr_learners LearnerClassif LearnerRegr
"_PACKAGE"

.onLoad = function(libname, pkgname) {
  # nocov start
  # get mlr_learners dictionary from the mlr3 namespace
  x = utils::getFromNamespace("mlr_learners", ns = "mlr3")

  # add the learner to the dictionary
  x$add("classif.lightgbm", LearnerClassifLightGBM)

  # use superassignment to update global reference to lightgbm
  reticulate::py_config()
  if (isFALSE(reticulate::py_module_available("lightgbm"))) {
    reticulate::py_install("lightgbm", method = "auto", conda = "auto")
  }
  lightgbm <<- reticulate::import("lightgbm", delay_load = TRUE)
} # nocov end
