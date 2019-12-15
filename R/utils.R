.onLoad <- function(libname, pkgname) {
  # nocov start
  # get mlr_learners dictionary from the mlr3 namespace
  x <- utils::getFromNamespace("mlr_learners", ns = "mlr3")

  # add the learner to the dictionary
  x$add("classif.lightgbm", LearnerClassifLightGBM)
  x$add("regr.lightgbm", LearnerRegrLightGBM)
} # nocov end
