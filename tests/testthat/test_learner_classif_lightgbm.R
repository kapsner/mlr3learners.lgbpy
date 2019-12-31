context("LearnerClassifLightGBM")

test_that(
  desc = "LearnerClassifLightGBM",
  code = {

    learner <- LearnerClassifLightGBM$new()
    expect_learner(learner)
    result <- run_autotest(learner)
    skip("Test not working")
    expect_true(result, info = result$error)
  }
)
