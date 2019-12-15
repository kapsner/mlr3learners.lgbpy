#' @title Classification LightGBM Learner
#'
#' @aliases mlr_learners_classif.lightgbm
#' @format [R6::R6Class] inheriting from [mlr3::LearnerClassif].
#'
#' @import data.table
#' @import paradox
#' @import reticulate
#' @importFrom mlr3 mlr_learners LearnerClassif
#'
#' @export
LearnerClassifLightGBM <- R6::R6Class(
  "LearnerClassifLightGBM",
  inherit = LearnerClassif,

  private = list(
    lgb_learner = NULL
  ),

  public = list(

    lgb_params = NULL,

    id_col = NULL,

    validation_split = 1,
    split_seed = NULL,

    num_boost_round = 5000,
    early_stopping_rounds = 100,

    initialize = function() {

      private$lgb_learner <- lightgbm.py::LightgbmTrain$new()
      self$lgb_params <- private$lgb_learner$param_set

      super$initialize(
        # see the mlr3book for a description:
        # https://mlr3book.mlr-org.com/extending-mlr3.html
        id = "classif.lightgbm",
        packages = "lightgbm.py",
        feature_types = c("numeric", "factor", "ordered"),
        predict_types = "prob",
        param_set = self$lgb_params,
        properties = c("twoclass",
                       "multiclass",
                       "missings",
                       "importance")
      )
    },

    train_internal = function(task) {

      stopifnot(
        self$param_set$values[["objective"]] %in%
              c("binary", "multiclass", "multiclassova", "lambdarank")
      )

      data <- task$data()

      private$lgb_learner$init_data(
        dataset = data,
        target_col = task$target_names,
        id_col = self$id_col
      )

      private$lgb_learner$data_preprocessing(
        validation_split = self$validation_split,
        split_seed = self$split_seed
      )

      if (is.null(self$param_set$values[["num_threads"]])) {
        private$lgb_learner$param_set$values <- c(
          self$param_set$values,
          list("num_threads" = 1L)
        )
      } else {
        self$param_set$values[["num_threads"]] <- 1L
      }

      mlr3misc::invoke(
        .f = private$lgb_learner$train,
        num_boost_round = self$num_boost_round,
        early_stopping_rounds = self$early_stopping_rounds
      ) # use the mlr3misc::invoke function (it's similar to do.call())
    },

    predict_internal = function(task) {
      newdata <- task$data(cols = task$feature_names) # get newdata

      p <- mlr3misc::invoke(
        .f = private$lgb_learner$predict,
        newdata = newdata,
        revalue = TRUE,
        reshape = TRUE # this has only effect for binary classifications
        # multiclass classifications will always return reshaped data
      )

      PredictionClassif$new(task = task, prob = p$probabilities)

    },

    # Add method for importance, if learner supports that.
    # It must return a sorted (decreasing) numerical, named vector.
    importance = function() {
      if (is.null(private$lgb_learner$model)) {
        stop("No model stored")
      }
      return(private$lgb_learner$importance())
    }
  )
)
