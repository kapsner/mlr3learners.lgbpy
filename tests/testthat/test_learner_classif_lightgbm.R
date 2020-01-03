context("LearnerClassifLightGBM")

test_that(
  desc = "LearnerClassifLightGBM",
  code = {

    learner <- LearnerClassifLightGBM$new()
    expect_learner(learner)
    learner$autodetect_categorical <- FALSE
    learner$early_stopping_rounds <- 5
    learner$num_boost_round <- 10
    result <- run_autotest(learner)
    expect_true(result, info = result$error)
  }
)
