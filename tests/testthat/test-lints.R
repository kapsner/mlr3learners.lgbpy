context("lints")

if (dir.exists("../../00_pkg_src")) {
  prefix <- "../../00_pkg_src/mlr3learners.lightgbm/"
} else if (dir.exists("../../R")) {
  prefix <- "../../"
} else if (dir.exists("./R")) {
  prefix <- "./"
}


test_that(
  desc = "test lints",
  code = {

    # skip on covr
    skip_on_covr()

    lintlist <- list(
      "R" = list(
        "LearnerClassifLightGBM.R" = "snake_case",
        "LearnerRegrLightGBM.R" = "snake_case",
        "utils.R" = "snake_case"
      ),
      "tests/testthat" = list(
        "test-lints.R" = NULL
      )
    )
    for (directory in names(lintlist)) {
      print(directory)
      for (fname in names(lintlist[[directory]])) {
        print(fname)
        #% print(list.files(prefix))

        lintr::expect_lint(
          file = paste0(
            prefix,
            directory,
            "/",
            fname
          ),
          checks = lintlist[[directory]][[fname]]
        )
      }
    }
  }
)