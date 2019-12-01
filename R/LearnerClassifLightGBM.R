#' @title Classification LightGBM Learner
#'
#' @aliases mlr_learners_classif.lightgbm
#' @format [R6::R6Class] inheriting from [mlr3::LearnerClassif].
#'
#' @import data.table
#' @import paradox
#' @import reticulate
#'
#' @export
LearnerClassifLightGBM = R6::R6Class(
  "LearnerClassifLightGBM",
  inherit = LearnerClassif,
  public = list(
    initialize = function() {

      ps = ParamSet$new( # parameter set using the paradox package
        # https://lightgbm.readthedocs.io/en/latest/Parameters.html#
        # core-parameters
        params = list(
          # Core Parameters
          ParamFct$new(id = "objective",
                       default = "binary",
                       levels = c("binary", "multiclass"),
                       tags = c("train", "predict")),
          ParamFct$new(id = "boosting",
                       default = "gbdt",
                       levels = c("gbdt", "rf", "dart", "goss"),
                       tags = c("train", "predict")),
          ParamInt$new(id = "num_iterations",
                       default = 100L,
                       lower = 0L,
                       tags = "train"),
          ParamDbl$new(id = "learning_rate",
                       default = 0.1,
                       lower = 0.0,
                       tags = "train"),
          ParamInt$new(id = "num_leaves",
                       default = 31L,
                       lower = 1L,
                       upper = 131072L,
                       tags = "train"),
          ParamFct$new(id = "tree_learner",
                       default = "serial",
                       levels = c("serial", "feature", "data", "voting"),
                       tags = c("train", "predict")),
          ParamInt$new(id = "num_threads",
                       default = 0L,
                       lower = 0L,
                       tags = "train"),
          ParamInt$new(id = "seed",
                       default = 17L,
                       lower = 0L,
                       tags = "train"),
          # Learning Control Parameters
          ParamInt$new(id = "max_depth",
                       default = -1L,
                       lower = -1L,
                       tags = "train"),
          ParamInt$new(id = "min_data_in_leaf",
                       default = 20L,
                       lower = 0L,
                       tags = "train"),
          ParamDbl$new(id = "min_sum_hessian_in_leaf",
                       default = 1e-3,
                       lower = 0,
                       tags = "train"),
          ParamDbl$new(id = "bagging_fraction",
                       default = 1.0,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamDbl$new(id = "pos_bagging_fraction",
                       default = 1.0,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamDbl$new(id = "neg_bagging_fraction",
                       default = 1.0,
                       lower = 0,
                       upper = 1.0,
                       tags = "train"),
          ParamInt$new(id = "bagging_freq",
                       default = 0L,
                       lower = 0L,
                       tags = "train"),
          ParamInt$new(id = "bagging_seed",
                       default = 3L,
                       lower = 0L,
                       tags = "train"),
          ParamDbl$new(id = "feature_fraction",
                       default = 1.0,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamDbl$new(id = "feature_fraction_bynode",
                       default = 1.0,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamInt$new(id = "feature_fraction_seed",
                       default = 2L,
                       lower = 0L,
                       tags = "train"),
          ParamInt$new(id = "early_stopping_round",
                       default = 0L,
                       lower = 0L,
                       tags = "train"),
          ParamLgl$new(id = "first_metric_only",
                       default = FALSE,
                       tags = "train"),
          ParamDbl$new(id = "max_delta_step",
                       default = 0.0,
                       lower = 0.0,
                       tags = "train"),
          ParamDbl$new(id = "lambda_l1",
                       default = 0.0,
                       lower = 0.0,
                       tags = "train"),
          ParamDbl$new(id = "lambda_l2",
                       default = 0.0,
                       lower = 0.0,
                       tags = "train"),
          ParamDbl$new(id = "min_gain_to_split",
                       default = 0.0,
                       lower = 0.0,
                       tags = "train"),
          ParamDbl$new(id = "drop_rate",
                       default = 0.1,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamInt$new(id = "max_drop",
                       default = 50L,
                       lower = 0L,
                       tags = "train"),
          ParamDbl$new(id = "skip_drop",
                       default = 0.5,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamLgl$new(id = "xgboost_dart_mode",
                       default = FALSE,
                       tags = "train"),
          ParamLgl$new(id = "uniform_drop",
                       default = FALSE,
                       tags = "train"),
          ParamInt$new(id = "drop_seed",
                       default = 4L,
                       lower = 0L,
                       tags = "train"),
          ParamDbl$new(id = "top_rate",
                       default = 0.2,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamDbl$new(id = "other_rate",
                       default = 0.1,
                       lower = 0.0,
                       upper = 1.0,
                       tags = "train"),
          ParamInt$new(id = "min_data_per_group",
                       default = 100L,
                       lower = 0L,
                       tags = "train"),
          ParamInt$new(id = "max_cat_threshold",
                       default = 32L,
                       lower = 0L,
                       tags = "train"),
          ParamDbl$new(id = "cat_l2",
                       default = 10.0,
                       lower = 0.0,
                       tags = "train"),
          ParamDbl$new(id = "cat_smooth",
                       default = 10.0,
                       lower = 0.0,
                       tags = "train"),
          ParamInt$new(id = "max_cat_to_onehot",
                       default = 4L,
                       lower = 0L,
                       tags = "train"),
          ParamInt$new(id = "top_k",
                       default = 20L,
                       lower = 0L,
                       tags = "train"),

          # IO Parameters
          ParamInt$new(id = "max_bin",
                       default = 255L,
                       lower = 1L,
                       tags = "train"),
          ParamInt$new(id = "min_data_in_bin",
                       default = 3L,
                       lower = 1L,
                       tags = "train"),

          # Objective Parameters
          ParamInt$new(id = "num_class",
                       default = 1L,
                       lower = 1L,
                       tags = "train"),
          ParamLgl$new(id = "is_unbalance",
                       default = FALSE,
                       tags = "train"),
          ParamDbl$new(id = "scale_pos_weight",
                       default = 1.0,
                       lower = 0.0,
                       tags = "train"),
          ParamLgl$new(id = "boost_from_average",
                       default = FALSE,
                       tags = "train"),

          # Metric Parameters
          ParamFct$new(id = "metric",
                       default = "",
                       levels = c("", "None",
                                  "binary_logloss", "binary_error",
                                  "multi_logloss", "auc", "multi_error"),
                       tags = "train")
        )
      )

      super$initialize(
        # see the mlr3book for a description:
        # https://mlr3book.mlr-org.com/extending-mlr3.html
        id = "classif.lightgbm",
        packages = "reticulate",
        feature_types = c("numeric", "factor", "ordered"),
        predict_types = c("response", "prob"),
        param_set = ps,
        properties = c("twoclass",
                       "multiclass",
                       "missings",
                       "importance")
      )
    },

    label_names = NULL,

    train_internal = function(task) {

      # https://rstudio.github.io/reticulate/articles/package.html
      stopifnot(reticulate::py_available(),
                reticulate::py_module_available("lightgbm"))
      lightgbm <- reticulate::import("lightgbm")

      pars = self$param_set$get_values(tags = "train")

      # Get formula, data, classwt, cutoff for the LightGBM
      data = task$data() #the data is avail
      levs = levels(data[[task$target_names]])
      n = length(levs)

      # lightgbm needs numeric values
      if (is.factor(data[[task$target_names]])) {
        data[, (task$target_names) := as.numeric(
          as.character(get(task$target_names))
        )]
      }
      # numeric values need to start at 0
      stopifnot(
        min(data[[task$target_names]]) == 0,
        n > 1
      )

      if (n > 2) {
        pars[["objective"]] <- "multiclass"
        pars[["num_class"]] <- n
        if (is.null(pars[["metric"]]))  {
          pars[["metric"]] <- c("multi_logloss", "multi_error")
        }
      } else {
        pars[["objective"]] <- "binary"
        if (is.null(pars[["metric"]]))  {
          pars[["metric"]] <- c("auc", "binary_error")
        }
      }

      x_train <- as.matrix(data[, task$feature_names, with = FALSE])
      x_label <- data[, get(task$target_names)]
      self$label_names <- unique(x_label)


      mlr3misc::invoke(
        .f = lightgbm$train,
        train_set = lightgbm$Dataset(
          data = x_train,
          label = x_label
        ),
        params = pars,
        early_stopping_rounds = 1000L,
        verbose_eval = 50L,
        valid_sets = lightgbm$Dataset(
          data = x_train,
          label = x_label
        )
      ) # use the mlr3misc::invoke function (it's similar to do.call())
    },

    predict_internal = function(task) {
      newdata = task$data(cols = task$feature_names) # get newdata
      p = mlr3misc::invoke(
        .f = self$model$predict,
        data = newdata,
        is_reshape = T
      )
      colnames(p) <- as.character(unique(self$label_names))

      PredictionClassif$new(task = task, prob = p)

    },

    # Add method for importance, if learner supports that.
    # It must return a sorted (decreasing) numerical, named vector.
    importance = function() {
      if (is.null(self$model)) {
        stopf("No model stored")
      }

      # importance dataframe
      imp <- data.table::data.table(
        "Feature" = self$model$feature_name(),
        "Value" = as.numeric(
          as.character(self$model$feature_importance())
        )
      )[order(get("Value"), decreasing = T)]

      # importance plot
      imp_plot <- ggplot2::ggplot(
        data = NULL,
        ggplot2::aes(x = reorder(imp$Feature, imp$Value),
                     y = imp$Value,
                     fill = imp$Value)
      ) +
        ggplot2::geom_col() +
        ggplot2::coord_flip() +
        viridis::scale_fill_viridis() +
        ggplot2::labs(title = "LightGBM Feature Importance") +
        ggplot2::ylab("Feature") +
        ggplot2::xlab("Importance") +
        ggplot2::theme(legend.position = "none")


      return(
        list("raw_values" = imp,
             "plot" = imp_plot)
      )
    }
  )
)
