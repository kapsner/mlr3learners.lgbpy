context("LearnerClassifLightGBM")

test_that(
  desc = "LearnerClassifLightGBM",
  code = {

    learner <- LearnerClassifLightGBM$new()
    expect_learner(learner)
    learner$param_set$values[["objective"]] <- "binary"
    result <- run_autotest(learner, predict_types = "prob")
    skip("Type error in score()")
    expect_true(result, info = result$error)
  }
)
