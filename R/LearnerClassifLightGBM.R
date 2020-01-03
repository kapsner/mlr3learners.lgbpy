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

    # save importance values
    imp = NULL,

    # some pre training checks for this learner
    pre_train_checks = function(task) {
      n <- nlevels(factor(task$data()[, get(task$target_names)]))

      if (is.null(self$param_set$values[["objective"]])) {
        # if not provided, set default objective depending on the
        # number of levels
        message("No objective provided...")
        if (n > 2) {
          self$param_set$values <- mlr3misc::insert_named(
            self$param_set$values,
            list("objective" = "multiclass")
          )
          message("Setting objective to 'multiclass'")
        } else if (n == 2) {
          self$param_set$values <- mlr3misc::insert_named(
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
          self$param_set$values[["objective"]] %in%
            c("binary", "multiclass", "multiclassova", "lambdarank")
        )
      }

      # if user has not specified categorical_feature, look in data for
      # categorical features
      if (is.null(self$categorical_feature) && self$autodetect_categorical) {
        if (any(task$feature_types$type %in%
                c("factor", "ordered", "character"))) {
          cat_feat <- task$feature_types[
            get("type") %in% c("factor", "ordered", "character"), get("id")
            ]
          self$categorical_feature <- cat_feat
        }
      }

      self$lgb_learner$num_boost_round <- self$num_boost_round
      self$lgb_learner$early_stopping_rounds <- self$early_stopping_rounds
      self$lgb_learner$categorical_feature <- self$categorical_feature
      self$lgb_learner$param_set <- self$param_set
    }
  ),

  public = list(

    #' @field  id_col (optional) A character string. The name of the ID column
    #'   (default: NULL).
    id_col = NULL,

    #' @field lgb_learner The lightgbm.py learner instance
    lgb_learner = NULL,

    #' @field num_boost_round Number of training rounds.
    num_boost_round = NULL,

    #' @field early_stopping_rounds A integer. Activates early stopping.
    #'   Requires at least one validation data and one metric. If there's
    #'   more than one, will check all of them except the training data.
    #'   Returns the model with (best_iter + early_stopping_rounds).
    #'   If early stopping occurs, the model will have 'best_iter' field.
    early_stopping_rounds = NULL,

    #' @field categorical_feature A vector of str or int. Type int represents
    #'   index, type str represents feature names.
    categorical_feature = NULL,

    #' @field cv_model The cross validation model.
    cv_model = NULL,

    #' @field autodetect_categorical Automatically detect categorical features.
    autodetect_categorical = NULL,

    # define methods
    #' @description The initialize function.
    #'
    initialize = function() {

      self$lgb_learner <- lightgbm.py::LightGBM$new()

      # set default parameters
      self$num_boost_round <- self$lgb_learner$num_boost_round
      self$early_stopping_rounds <- self$lgb_learner$early_stopping_rounds
      self$categorical_feature <- self$lgb_learner$categorical_feature

      self$autodetect_categorical <- TRUE

      super$initialize(
        # see the mlr3book for a description:
        # https://mlr3book.mlr-org.com/extending-mlr3.html
        id = "classif.lgbpy",
        packages = "lightgbm.py",
        feature_types = c(
          "numeric", "factor",
          "integer", "character"
        ),
        predict_types = "prob",
        param_set = self$lgb_learner$param_set,
        properties = c("twoclass",
                       "multiclass",
                       "missings",
                       "importance")
      )
    },

    #' @description The train_internal function.
    #'
    #' @param task An mlr3 task.
    #'
    train_internal = function(task) {

      private$pre_train_checks(task)

      data <- task$data()

      self$lgb_learner$init_data(
        dataset = data,
        target_col = task$target_names,
        id_col = self$id_col
      )

      mlr3misc::invoke(
        .f = self$lgb_learner$train
      ) # use the mlr3misc::invoke function (it's similar to do.call())
    },

    #' @description The train_cv function
    #'
    #' @param task An mlr3 task
    #' @param row_ids An integer vector with the row IDs for the validation
    #'   data.
    #'
    train_cv = function(task, row_ids) {

      if (is.null(self$model)) {

        task <- mlr3::assert_task(as_task(task))
        mlr3::assert_learnable(task, self)

        row_ids <- mlr3::assert_row_ids(row_ids)

        mlr3::assert_task(task)

        # subset to test set w/o cloning
        row_ids <- assert_row_ids(row_ids)
        prev_use <- task$row_roles$use
        on.exit({
          task$row_roles$use <- prev_use
        }, add = TRUE)
        task$row_roles$use <- row_ids

        private$pre_train_checks(task)

        data <- task$data()

        self$lgb_learner$init_data(
          dataset = data,
          target_col = task$target_names,
          id_col = self$id_col
        )

        self$lgb_learner$train_cv()

        self$cv_model <- self$lgb_learner$cv_model

      } else {

        stop("A final model has already been trained!")
      }
    },

    #' @description The predict_internal function.
    #'
    #' @param task An mlr3 task.
    #'
    predict_internal = function(task) {
      newdata <- task$data(cols = task$feature_names) # get newdata

      p <- mlr3misc::invoke(
        .f = self$lgb_learner$predict,
        newdata = newdata
      )

      if (self$param_set$values[["objective"]] %in%
          c("multiclass", "multiclassova", "lambdarank")) {
        colnames(p) <- as.character(unique(self$lgb_learner$label_names))

        # process target variable
        c_names <- colnames(p)
        c_names <- plyr::revalue(
          x = c_names,
          replace = self$lgb_learner$trans_tar$value_mapping_dtrain
        )
        colnames(p) <- c_names

      } else if (self$param_set$values[["objective"]] == "binary") {

        # reshape binary prob to matrix
        p <- cbind(
          "0" = 1 - p,
          "1" = p
        )

        c_names <- colnames(p)
        c_names <- plyr::revalue(
          x = c_names,
          replace = self$lgb_learner$trans_tar$value_mapping_dtrain
        )
        colnames(p) <- c_names
      }

      PredictionClassif$new(
        task = task,
        prob = p
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

      imp <- self$lgb_learner$importance()$raw_values
      ret <- sapply(imp$Feature, function(x) {
        return(imp[which(imp$Feature == x), ]$Value)
      }, USE.NAMES = TRUE, simplify = TRUE)

      return(unlist(ret))
    }
  )
)
