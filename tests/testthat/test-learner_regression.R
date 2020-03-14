context("Test Regression")

test_that(
  desc = "Learner Regression",
  code = {

    task <- mlr3::tsk("boston_housing")

    set.seed(17)
    split <- list(
      train_index = sample(seq_len(task$nrow), size = 0.7 * task$nrow)
    )
    split$test_index <- setdiff(seq_len(task$nrow), split$train_index)

    learner <- mlr3::lrn("regr.lgbpy")
    learner$early_stopping_rounds <- 3
    learner$num_boost_round <- 10

    learner$param_set$values <- list(
      "learning_rate" = 0.1,
      "seed" = 17L,
      "metric" = "rmse"
    )

    learner$train(task, row_ids = split$train_index)

    expect_equal(learner$model$current_iteration(), 10L)
    expect_known_hash(learner$lgb_learner$train_label, "23f5a981e9")

    predictions <- learner$predict(task, row_ids = split$test_index)

    expect_known_hash(predictions$response, "b630ef15f5")
    importance <- learner$importance()

    expect_equal(importance[["cmedv"]], 99.99153482234328294)
  }
)
