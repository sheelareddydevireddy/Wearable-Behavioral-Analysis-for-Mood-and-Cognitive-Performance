
library(tidyverse)
library(lme4)
library(slider)

acc <- read_csv("/Users/sheelareddy/Downloads/acc data update version/acc_data.csv")
sleep <- read_csv("/Users/sheelareddy/Downloads/acc data update version/sleep_data.csv")
healthy <- read_csv("/Users/sheelareddy/Downloads/acc data update version/healthy aging EMA study dataset.csv")

glimpse(acc)
glimpse(sleep)
glimpse(healthy) #what we will be using mostly - cognitive games


n_distinct(acc$id) #92
n_distinct(sleep$id) #94
n_distinct(healthy$id) #102 
sum(is.na(healthy$mindsharp_z))

summary(acc) #ignore dchan1,2,3 
summary(sleep)
summary(healthy)

id_counts <- healthy %>%
  count(id, sort = TRUE, name = "number_of_entries")

View(id_counts)

table(healthy$mood_crash_strict) #98/1251
table(healthy$mood_crash_moderate) #170/1251

healthy$day_in_study
healthy$mindsharp

healthy %>%
  filter(id == 101) %>%
  ggplot(aes(x = day_in_study, y = mindsharp)) +
  geom_line() +
  geom_point()


#Target: A participant will trigger a crash if their overall negative state spikes
healthy <- healthy %>%
  group_by(id) %>% #ensures individual data calculations 
  mutate(
    
    anxious_z    = as.numeric(scale(anxious)),
    stressed_z   = as.numeric(scale(stressed)),
    tired_z      = as.numeric(scale(tired)),
    depressed_z  = as.numeric(scale(depressed)),
    
    
    mood_composite_z = (anxious_z + stressed_z + tired_z + depressed_z)/ 4,
    mindsharp_z = as.numeric(scale(mindsharp)),
    gonogo_z = as.numeric(scale(go_nogo.dprime)),
    mood_above_norm = ifelse(mood_composite_z > 0, "above", "below"),
    
  ) %>%
  ungroup() 

table(healthy$mood_crash_strict) #98/1251
table(healthy$mood_crash_moderate) #170/1251


ggplot(healthy, aes(x = mood_composite_z, y = mindsharp)) + 
  geom_point(alpha = 0.3) +
  geom_smooth(method = "loess")
#as mood composite increases mind sharp is decreasing!

ggplot(healthy, aes(x = mood_above_norm, y = mindsharp_z)) +
  geom_boxplot()
#if mood composite is higher their mind sharp is lower!



#------
healthy <- healthy %>%
  group_by(id) %>%
  arrange(id, day_in_study) %>%
  mutate(
    #same day
    mood_same = mood_composite_z,
    
    #single day lag
    mood_lag1 = lag(mood_composite_z, 1),
    
    #3 day rolling average lag
    mood_roll3 = slide_dbl(mood_composite_z, mean, na.rm = TRUE,
                           .before = 3, .after = -1)
  ) %>%
  ungroup()

healthy_model <- healthy %>%
  filter(!is.na(mood_same), !is.na(mood_lag1), !is.na(mood_roll3), !is.na(mindsharp_z))

#model 1: same day
m1 <- lmer(mindsharp_z ~ mood_same + (1 | id), data = healthy_model, REML = FALSE)

#model 2: single lag
m2 <- lmer(mindsharp_z ~ mood_lag1 + (1 | id), data = healthy_model, REML = FALSE)

#model 3: rolling window
m3 <- lmer(mindsharp_z ~ mood_roll3 + (1 | id), data = healthy_model, REML = FALSE)

# compare all three
anova(m1, m2, m3)

summary(m1)
summary(m2)
summary(m3)

#Yesterday’s bad mood has some relationship with today’s mental sharpness, but it is not very strong.


healthy <- healthy %>%
  group_by(id) %>%
  arrange(id, day_in_study) %>%
  mutate(
    #same day
    mood_same = mood_composite_z,
    
    #single day lag
    mood_lag1 = lag(mood_composite_z, 1),
    
    #3 day rolling average lag
    mood_roll3 = slide_dbl(mood_composite_z, mean, na.rm = TRUE,
                           .before = 3, .after = -1)
  ) %>%
  ungroup()

healthy_model <- healthy %>%
  filter(!is.na(mood_same), !is.na(mood_lag1), !is.na(mood_roll3), !is.na(mindsharp_z))

#model 1: same day
m1 <- lmer(gonogo_z ~ mood_same + (1 | id), data = healthy_model, REML = FALSE)

#model 2: single lag
m2 <- lmer(gonogo_z ~ mood_lag1 + (1 | id), data = healthy_model, REML = FALSE)

#model 3: rolling window
m3 <- lmer(gonogo_z ~ mood_roll3 + (1 | id), data = healthy_model, REML = FALSE)

# compare all three
anova(m1, m2, m3)

summary(m1)
summary(m2)
summary(m3)

#Yesterday’s bad mood has some relationship with today’s mental sharpness, but it is not very strong.

#find: predictors

#Initial: Spearman correlation

target <- healthy$mindsharp_z
predictors <- c(
    # mood / emotion / subjective state
    "thoughtsemotions",
    "physical",
    "present",
    "control",
    "feel",
    "feelenergy",
    "anxious",
    "energetic",
    "stressed",
    "joyful",
    "tired",
    "calm",
    "depressed",
    "lonely",
    "pain",
    "mood_composite_z",
    "anxious_z",
    "stressed_z",
    "tired_z",
    "depressed_z",
    
    # sleep
    "d_sleep",
    "sleep_quality_day_mean",
    
    # activity / movement
    "d_sed",
    "d_lig",
    "d_mod",
    "d_vig",
    "d_step_mvpa",
    "d_valid",
    "day_stepcount",
    "day_stepcount2",
    "day_stepcount2_within_person",
    "d_sed_within_person",
    "d_lig_within_person",
    "d_mod_within_person",
    
    # context / timing
    "typicalday",
    "where_indoors",
    "where_athome",
    "date_weekend",
    "time_of_day",
    "total_prompts_day",
    "study_prompt_number",
    "day_prompt_number",
    
    # demographics / person-level
    "sex",
    "eth",
    "race",
    "marriage",
    "livealone",
    "edu",
    "prevexp",
    "bmi",
    "age",
    
    # cognitive task variables
    "symbol_search.median.rt.accurate_trials",
    "symbol_search.n.accurate.trials",
    "dot_memory.median.rt.perfect_trials",
    "dot_memory.median.error.distance.overall",
    "dot_memory.sum.error.distance.overall",
    "dot_memory.count.perfect.dots",
    "dot_memory.count.perfect.trials",
    "go_nogo.median.rt.hit_trials",
    "go_nogo.n.hit",
    "go_nogo.dprime",
    "go_nogo.beta",
    "go_nogo.c",
    
    # scaled/within-person cognitive versions
    "symbol_search.median.rt.accurate_trials2",
    "dot_memory.median.rt.perfect_trials2",
    "symbol_search.median.rt.accurate_trials2_within_person",
    "dot_memory.median.rt.perfect_trials2_within_person",
    "go_nogo.dprime_within_person"
  )
results <- list()

for (i in predictors) {
  x_val <- healthy[[i]]
  y_val <- target
  
  complete_pairs <- !is.na(x_val) & !is.na(y_val)
  x_clean <- x_val[complete_pairs]
  y_clean <- y_val[complete_pairs]
  
  test_result <- cor.test(x_clean, y_clean,
                          method = "spearman",
                          exact = FALSE)

results[[i]] <- c(rho = test_result$estimate, p_value = test_result$p.value)

}


results_df <- do.call(rbind, results)
print(results_df)

#mindsharp important predictors, 
# mood_composite_z = -0.363
# present          =  0.244
# control          =  0.244
#sleep_quality_day_mean =  0.119
# feelenergy = 0.278
# feel = 0.255

linear_model <- lm(mindsharp_z ~ mood_composite_z + present + control + sleep_quality_day_mean + feelenergy + feel, data = healthy)

summary(linear_model) #17.5% -> not great. 


library(randomForest)

set.seed(42)

healthy_rf <- healthy %>%
  filter(!is.na(mindsharp_z))

data.imputed <- rfImpute(mindsharp_z ~ mood_composite_z + present + control + sleep_quality_day_mean + feelenergy + feel, data = healthy_rf, iter = 6)

rf_model <- randomForest(mindsharp_z ~ mood_composite_z + present + control + sleep_quality_day_mean + feelenergy + feel, data = data.imputed, proximity = TRUE)
rf_model

#can impute x values but we cannot impute y our target - first fix the NA in target then impute

-------------
  
  
target <- healthy$gonogo_z
predictors_gonogo_safe <- c(
  # mood / emotion / subjective state
  "thoughtsemotions",
  "physical",
  "present",
  "control",
  "feel",
  "feelenergy",
  "anxious",
  "energetic",
  "stressed",
  "joyful",
  "tired",
  "calm",
  "depressed",
  "lonely",
  "pain",
  "mood_composite_z",
  "anxious_z",
  "stressed_z",
  "tired_z",
  "depressed_z",
  
  # sleep
  "d_sleep",
  "sleep_quality_day_mean",
  
  # activity
  "d_sed",
  "d_lig",
  "d_mod",
  "d_vig",
  "d_step_mvpa",
  "d_valid",
  "day_stepcount",
  "day_stepcount2",
  "day_stepcount2_within_person",
  "d_sed_within_person",
  "d_lig_within_person",
  "d_mod_within_person",
  
  # context / timing
  "typicalday",
  "where_indoors",
  "where_athome",
  "date_weekend",
  "time_of_day",
  "total_prompts_day",
  "study_prompt_number",
  "day_prompt_number",
  
  # demographics
  "sex",
  "eth",
  "race",
  "marriage",
  "livealone",
  "edu",
  "prevexp",
  "bmi",
  "age",
  
  # other cognitive tasks, not Go/No-Go
  "symbol_search.median.rt.accurate_trials",
  "symbol_search.n.accurate.trials",
  "dot_memory.median.rt.perfect_trials",
  "dot_memory.median.error.distance.overall",
  "dot_memory.sum.error.distance.overall",
  "dot_memory.count.perfect.dots",
  "dot_memory.count.perfect.trials",
  "symbol_search.median.rt.accurate_trials2",
  "dot_memory.median.rt.perfect_trials2",
  "symbol_search.median.rt.accurate_trials2_within_person",
  "dot_memory.median.rt.perfect_trials2_within_person"
)
results <- list()

for (i in predictors_gonogo_safe) {
  x_val <- healthy[[i]]
  y_val <- target
  
  complete_pairs <- !is.na(x_val) & !is.na(y_val)
  x_clean <- x_val[complete_pairs]
  y_clean <- y_val[complete_pairs]
  
  test_result <- cor.test(x_clean, y_clean,
                          method = "spearman",
                          exact = FALSE)

results[[i]] <- c(rho = test_result$estimate, p_value = test_result$p.value)

}


results_df1 <- do.call(rbind, results)
print(results_df1)


#takeaway: a linear model is better than the rf but both have weak signal, not the right research question. 


#FEEDBACK FROM ADVISOR:

#signal processing w
#physioloical signs 
#dimensionality reduction! 


#one value per subject rather than multiple 
#acc data^
#potentially sleep too- too much movement (restless leg syndrome) maybe points to smthg 
#did you choose the right predictor?



