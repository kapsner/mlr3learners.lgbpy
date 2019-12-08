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

      ps = lgbparams()

      super$initialize(
        # see the mlr3book for a description:
        # https://mlr3book.mlr-org.com/extending-mlr3.html
        id = "classif.lightgbm",
        packages = "reticulate",
        feature_types = c("numeric", "factor", "ordered"),
        predict_types = "prob",
        param_set = ps,
        properties = c("twoclass",
                       "multiclass",
                       "missings",
                       "importance")
      )
    },

    label_names = NULL,

    feature_names = NULL,

    valids = NULL,

    train_internal = function(task) {

      # https://rstudio.github.io/reticulate/articles/package.html
      stopifnot(reticulate::py_available(),
                reticulate::py_module_available("lightgbm"))
      lightgbm <- reticulate::import("lightgbm")

      pars = self$param_set$get_values(tags = "train")

      # Get formula, data, classwt, cutoff for the LightGBM
      data = task$data() # the data is available
      levs = levels(data[[task$target_names]])
      n = as.integer(length(levs))

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
      # convert Missings to NaN, otherwise they wil be transformed
      # wrong to python/ an error occurs
      for (i in colnames(x_train)) {
        x_train[which(is.na(x_train[, i])), i] <- NaN
      }
      self$feature_names = colnames(x_train)

      x_label <- data[, get(task$target_names)]
      self$label_names <- unique(x_label)

      if (is.null(self$valids)) {
        x_valid <- x_train
        x_label_valid <- x_label
      } else {
        x_valid <- as.matrix(self$valids[, task$feature_names, with = FALSE])
        for (i in colnames(x_valid)) {
          x_valid[which(is.na(x_valid[, i])), i] <- NaN
        }
        x_label_valid <- self$valids[, get(task$target_names)]
      }

      # make sure, integers are integers (e.g. in grid search)
      # for (parameter in c("num_iterations", "num_leaves", "seed",
      #                     "max_depth", "max_depth", "min_data_in_leaf",
      #                     "bagging_freq", "bagging_seed",
      #                     "feature_fraction_seed", "feature_fraction_seed",
      #                     "max_drop", "drop_seed",
      #                     "min_data_per_group", "max_cat_threshold",
      #                     "max_cat_to_onehot", "top_k", "max_bin",
      #                     "min_data_in_bin", "bin_construct_sample_cnt",
      #                     "data_random_seed", "snapshot_freq",
      #                     "max_position", "metric_freq",
      #                     "multi_error_top_k")) {
      #   if (!is.integer(parameter)) {
      #     pars[[parameter]] <- as.integer(pars[[parameter]])
      #   }
      # }

      mlr3misc::invoke(
        .f = lightgbm$train,
        train_set = lightgbm$Dataset(
          data = x_train,
          label = x_label
        ),
        params = pars,
        verbose_eval = 50L,
        valid_sets = lightgbm$Dataset(
          data = x_valid,
          label = x_label_valid
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
        "Feature" = self$feature_names,
        #"Feature" = self$model$feature_name(),
        "Value" = as.numeric(
          as.character(self$model$feature_importance())
        )
      )[order(get("Value"), decreasing = T)]

      if (nrow(imp) > 20) {
        imp <- imp[1:20, ]
      }

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
