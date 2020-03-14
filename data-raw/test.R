# debug tests

learner <- LearnerClassifLightGBM$new()
expect_learner(learner)
learner$autodetect_categorical <- FALSE
learner$early_stopping_rounds <- 5
learner$num_boost_round <- 10

learner
N = 30L
exclude = NULL
predict_types = learner$predict_types

learner = learner$clone(deep = TRUE)
id = learner$id
tasks = generate_tasks(learner, N = N)

predict_type = "prob"

tasks <- tasks[names(tasks)[grepl("sanity", names(tasks))]]


for (task in tasks) {
  learner$id = sprintf("%s:%s", id, predict_type)
  learner$predict_type = predict_type

  run = run_experiment(task, learner)
  if (!run$ok) {
    return(run)
  }
}
