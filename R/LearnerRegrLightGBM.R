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

    id_col = NULL,

    validation_split = NULL,
    split_seed = NULL,

    num_boost_round = NULL,
    early_stopping_rounds = NULL,

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
    importance = function() {
      if (is.null(private$lgb_learner$model)) {
        stop("No model stored")
      }
      return(private$lgb_learner$importance())
    }
  )
)
