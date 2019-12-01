data("iris")
dataset <- data.table::as.data.table(iris)
dataset[, ("Species") := factor(as.numeric(get("Species")) - 1L)]

task <- TaskClassif$new(
  id = "iris",
  target = "Species",
  backend = dataset
)

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


lightgbm <- reticulate::import("lightgbm")
pars = ps$get_values(tags = "train")

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
  if (is.null(pars[["metric"]])) {
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

mymodel <- lightgbm$train(
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
)

newdata <- task$data(cols = task$feature_names)

p = mlr3misc::invoke(.f = mymodel$predict,
           data = newdata,
           is_reshape = T)
colnames(p) <- as.character(unique(x_label))

PredictionClassif$new(task = task, prob = p)


imp <- data.table::data.table(
  "Feature" = mymodel$feature_name(),
  "Value" = as.numeric(as.character(mymodel$feature_importance()))
)[order(get("Value"), decreasing = T)]

imp

ggplot2::ggplot(data = NULL,
                ggplot2::aes(x = reorder(imp$Feature, imp$Value),
                             y = imp$Value,
                             fill = imp$Value)) +
  ggplot2::geom_col() +
  ggplot2::coord_flip() +
  ggplot2::scale_fill_gradientn(colours = grDevices::rainbow(n = nrow(imp))) +
  ggplot2::labs(title = "LightGBM Feature Importance") +
  ggplot2::ylab("Feature") +
  ggplot2::xlab("Importance") +
  ggplot2::theme(legend.position = "none")

imp
