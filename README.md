# mlr3learners.lightgbm (!!!under development!!!)

<!-- badges: start -->
[![pipeline status](https://gitlab.com/kapsner/mlr3learners-lightgbm/badges/master/pipeline.svg)](https://gitlab.com/kapsner/mlr3learners-lightgbm/commits/master)
[![coverage report](https://gitlab.com/kapsner/mlr3learners-lightgbm/badges/master/coverage.svg)](https://gitlab.com/kapsner/mlr3learners-lightgbm/commits/master)
<!-- badges: end -->
 
[mlr3learners.lightgbm](https://github.com/kapsner/mlr3learners.lightgbm) brings the [LightGBM gradient booster](https://lightgbm.readthedocs.io) to the [mlr3](https://github.com/mlr-org/mlr3) framework by using the [lightgbm.py](https://github.com/kapsner/lightgbm.py) R implementation. 

# Installation

Install the [mlr3learners.lightgbm](https://github.com/kapsner/mlr3learners.lightgbm) R package:

```r
install.packages("devtools")
devtools::install_github("kapsner/mlr3learners.lightgbm")
```

In order to use the `mlr3learners.lightgbm` R package, please make sure, the [reticulate](https://github.com/rstudio/reticulate) R package is configured properly on your system (reticulate version >= 1.13.0.9006) and is pointing to a python environment. If not, you can e.g. install `miniconda`:

```r
reticulate::install_miniconda(
  path = reticulate::miniconda_path(),
  update = TRUE,
  force = FALSE
)
reticulate::py_config()
```

Use the function `lightgbm.py::install_py_lightgbm` in order to install the lightgbm python module. This function will first look, if the reticulate package is configured well and if the python module `lightgbm` is aready present. If not, it is automatically installed. 

```r
lightgbm.py::install_py_lightgbm()
```

# Example

```r
library(mlr3)
task = mlr3::tsk("iris")
learner = mlr3::lrn("classif.lightgbm")

learner$split_seed <- 2
learner$validation_split <- 0.7
learner$early_stopping_rounds <- 1000
learner$num_boost_round <- 5000

learner$param_set$values <- list(
  "objective" = "multiclass",
  "learning_rate" = 0.01,
  "seed" = 17L
)

learner$train(task, row_ids = 1:120)
predictions <- learner$predict(task, row_ids = 121:150)
```

For further information and examples, please view the `mlr3learners.lightgbm` package vignettes, the [mlr3book](https://mlr3book.mlr-org.com/index.html) and the vignettes of the `lightgbm.py` R package.  

# More Infos:

- RStudio's reticulate R package: https://rstudio.github.io/reticulate/
- Microsoft's LightGBM: https://lightgbm.readthedocs.io/en/latest/
- lightgbm.py R package: https://github.com/kapsner/lightgbm.py

