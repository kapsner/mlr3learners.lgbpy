# mlr3learners.lgbpy (!!!under development!!!)

<!-- badges: start -->
[![pipeline status](https://gitlab.com/kapsner/mlr3learners-lgbpy/badges/master/pipeline.svg)](https://gitlab.com/kapsner/mlr3learners-lgbpy/commits/master)
[![coverage report](https://gitlab.com/kapsner/mlr3learners-lgbpy/badges/master/coverage.svg)](https://gitlab.com/kapsner/mlr3learners-lgbpy/commits/master)
<!-- badges: end -->
 
[mlr3learners.lgbpy](https://github.com/kapsner/mlr3learners.lgbpy) brings the [LightGBM gradient booster](https://lightgbm.readthedocs.io) to the [mlr3](https://github.com/mlr-org/mlr3) framework by using the [lightgbm.py](https://github.com/kapsner/lightgbm.py) R implementation. 

# Features 

* integrated native cross-validation (CV) step before the actual model training to find the optimal `num_boost_round` for the given training data and parameter set  
* GPU support  

# Installation

Install the [mlr3learners.lgbpy](https://github.com/kapsner/mlr3learners.lgbpy) R package:

```r
install.packages("devtools")
devtools::install_github("kapsner/mlr3learners.lgbpy")
```

In order to use the `mlr3learners.lgbpy` R package, please make sure, the [reticulate](https://github.com/rstudio/reticulate) R package is configured properly on your system (reticulate version >= 1.14) and is pointing to a python environment. If not, you can e.g. install `miniconda`:

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

For further information and examples, please view the `mlr3learners.lgbpy` [package vignettes](vignettes/), the [mlr3book](https://mlr3book.mlr-org.com/index.html) and the vignettes of the `lightgbm.py` R package.  

# GPU acceleration

The `mlr3learners.lgbpy` can also be used with lightgbm's GPU compiled version.

To install the lightgbm python package with GPU support, execute the following commands ([lightgbm manual](https://github.com/microsoft/LightGBM/blob/master/python-package/README.md)):

```bash
pip install lightgbm --install-option=--gpu
```

In order to use the GPU acceleration, the parameter `device_type = "gpu"` (default: "cpu") needs to be set. According to the [LightGBM parameter manual](https://lightgbm.readthedocs.io/en/latest/Parameters.html), 'it is recommended to use the smaller `max_bin` (e.g. 63) to get the better speed up'. 

```r
learner$param_set$values <- list(
  "objective" = "multiclass",
  "learning_rate" = 0.01,
  "seed" = 17L,
  "device_type" = "gpu",
  "max_bin" = 63L
)
```

All other steps are similar to the workflow without GPU support. 

The GPU support has been tested in a [Docker container](https://github.com/kapsner/docker_images/blob/master/Rdatascience/rdsc_gpu/Dockerfile) running on a Linux 19.10 host, Intel i7, 16 GB RAM, an NVIDIA(R) RTX 2060, CUDA(R) 10.2 and [nvidia-docker](https://github.com/NVIDIA/nvidia-docker). 

# More Infos:

- RStudio's reticulate R package: https://rstudio.github.io/reticulate/
- Microsoft's LightGBM: https://lightgbm.readthedocs.io/en/latest/
- lightgbm.py R package: https://github.com/kapsner/lightgbm.py
