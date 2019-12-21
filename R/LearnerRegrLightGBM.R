#' @title Regression LightGBM Learner
#'
#' @aliases mlr_learners_regr.lgbpy
#' @format [R6::R6Class] inheriting from [mlr3::LearnerRegr].
#'
#' @importFrom mlr3 mlr_learners LearnerRegr
#'
#' @export
LearnerRegrLightGBM <- R6::R6Class(
  "LearnerRegrLightGBM",
  inherit = LearnerRegr,

  private = list(
    lgb_learner = NULL
  ),

  public = list(

    #' @field  id_col (optional) A character string. The name of the ID column
    #'   (default: NULL).
    id_col = NULL,

    #' @field validation_split A numeric. Ratio to further split the training
    #'   data for validation (default: 1). The allowed value range is
    #'   0 < validation_split <= 1. This parameter can also be set to
    #'   '1', taking the whole training data for validation during the model
    #'   training.
    validation_split = NULL,

    #' @field split_seed A integer (default: NULL). Please use this argument in
    #'   order to generate reproducible results.
    split_seed = NULL,

    #' @field num_boost_round A integer. The number of boosting iterations
    #'   (default: 100).
    num_boost_round = NULL,


    #' @field early_stopping_rounds A integer. It will stop training if one
    #'   metric of one validation data doesn’t improve in last
    #'   `early_stopping_round` rounds. '0' means disable (default: 0).
    early_stopping_rounds = NULL,

    #' @description The initialize function.
    #'
    initialize = function() {

      private$lgb_learner <- lightgbm.py::LightgbmTrain$new()

      self$validation_split <- 1
      self$num_boost_round <- 5000
      self$early_stopping_rounds <- 100

      super$initialize(
        # see the mlr3book for a description:
        # https://mlr3book.mlr-org.com/extending-mlr3.html
        id = "regr.lgbpy",
        packages = "lightgbm.py",
        feature_types = c("numeric", "factor", "ordered"),
        predict_types = "response",
        param_set = private$lgb_learner$param_set,
        properties = c("missings",
                       "importance")
      )
    },

    #' @description The train_internal function.
    #'
    #' @param task An mlr3 task.
    #'
    train_internal = function(task) {

      if (is.null(private$lgb_learner$param_set$values[["objective"]])) {
        # if not provided, set default objective to "regression"
        # this is needed for the learner's init_data function
        private$lgb_learner$param_set$values <- c(
          self$param_set$values,
          list("objective" = "regression")
        )
        message("No objective provided... Setting objective to 'regression'")
      } else {
        stopifnot(
          !(private$lgb_learner$param_set$values[["objective"]] %in%
              c("binary", "multiclass",
                "multiclassova", "lambdarank"))
        )
      }

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

      # switch of python modules parallelization and use the one of mlr3
      private$lgb_learner$param_set$values <- c(
        self$param_set$values,
        list("num_threads" = 1L)
      )

      mlr3misc::invoke(
        .f = private$lgb_learner$train,
        num_boost_round = self$num_boost_round,
        early_stopping_rounds = self$early_stopping_rounds
      ) # use the mlr3misc::invoke function (it's similar to do.call())
    },

    #' @description The predict_internal function.
    #'
    #' @param task An mlr3 task.
    #'
    predict_internal = function(task) {
      newdata <- task$data(cols = task$feature_names) # get newdata

      p <- mlr3misc::invoke(
        .f = private$lgb_learner$predict,
        newdata = newdata,
        revalue = FALSE
      )

      PredictionRegr$new(
        task = task,
        response = p$response
      )

    },

    # Add method for importance, if learner supports that.
    # It must return a sorted (decreasing) numerical, named vector.
    #' @description The importance function
    #'
    #' @details A named vector with the learner's variable importances.
    #'
    importance = function() {
      if (is.null(self$model)) {
        stop("No model stored")
      }

      imp <- private$lgb_learner$importance()$raw_values
      ret <- sapply(imp$Feature, function(x) {
        return(imp[which(imp$Feature == x), ]$Value)
      }, USE.NAMES = TRUE, simplify = TRUE)

      return(unlist(ret))
    },
    #' @description The importance2 function
    #'
    #' @details Returns a list with the learner's variable importance values
    #'   and an importance plot.
    #'
    importance2 = function() {
      if (is.null(self$model)) {
        stop("No model stored")
      }
      return(private$lgb_learner$importance())
    }
  )
)
