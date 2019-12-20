#' @title Classification LightGBM Learner
#'
#' @aliases mlr_learners_classif.lgbpy
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
        id = "classif.lgbpy",
        packages = "lightgbm.py",
        feature_types = c("numeric", "factor", "ordered"),
        predict_types = "prob",
        param_set = private$lgb_learner$param_set,
        properties = c("twoclass",
                       "multiclass",
                       "missings",
                       "importance")
      )
    },

    train_internal = function(task) {

      data <- task$data()

      n <- nlevels(factor(data[, get(task$target_names)]))

      if (is.null(private$lgb_learner$param_set$values[["objective"]])) {
        # if not provided, set default objective depending on the
        # number of levels
        message("No objective provided...")
        if (n > 2) {
          private$lgb_learner$param_set$values <- c(
            self$param_set$values,
            list("objective" = "multiclass")
          )
          message("Setting objective to 'multiclass'")
        } else if (n == 2) {
          private$lgb_learner$param_set$values <- c(
            self$param_set$values,
            list("objective" = "binary")
          )
          message("Setting objective to 'binary'")
        } else {
          stop(paste0("Please provide a target with a least ",
                      "2 levels for classification tasks"))
        }

      } else {
        stopifnot(
          private$lgb_learner$param_set$values[["objective"]] %in%
            c("binary", "multiclass", "multiclassova", "lambdarank")
        )
      }

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
        revalue = TRUE,
        reshape = TRUE # this has only effect for binary classifications
        # multiclass classifications will always return reshaped data
      )

      PredictionClassif$new(
        task = task,
        prob = p$probabilities
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
