# Sustained Bad Mood, Behavior, and Cognitive Performance

## Research question

**Does sustained bad mood predict lower cognitive performance?**

The original analysis tested whether bad mood and cognitive performance were directly associated. But since mood may affect cognition indirectly through daily behavior, the analysis was expanded to examine the following pathway:

> Sustained bad mood → behavioral change → later cognitive performance

The behavioral measures came from minute-level accelerometer and sleep data. The health dataset contained mood and cognitive-performance measures.

## Analysis overview

The analysis followed these main steps:

1. Inspect and clean the accelerometer data.
2. Convert minute-level observations into daily behavioral features.
3. Identify incomplete days, probable nonwear, and unusual participant records.
4. Examine feature distributions and correlations.
5. Create temporal variables separately in the health and accelerometer datasets.
6. Merge both datasets by participant ID and calendar date.
7. Test whether sustained bad mood predicts later behavior.
8. Test whether prior behavior predicts later cognition.
9. Run clustered OLS for robustness checks and an exploratory within-/between-person model.

## Data privacy

The raw health and accelerometer data are private and are not included in this repository. The notebook contains analysis code only.

## Accelerometer feature extraction

Minute-level accelerometer data were converted into daily participant-level measures of movement, activity intensity, sedentary behavior, transitions, and sleep.

The main features included total steps, MVPA steps, sedentary-to-upright transitions, sedentary minutes, maximum sedentary-bout length, and sleep minutes. Records were ordered by participant and timestamp. Sedentary bouts were defined using consecutive awake minutes classified as sedentary, with timestamp gaps beginning a new bout.

## Data-quality rules

Several checks were performed before modeling:

- A complete day required at least 1,152 observations, equal to 80% of a 1,440-minute day.
- Days with more than 1,440 observations were treated as daylight-saving fallback days and excluded from the final valid-day range.
- Sleep-derived measures were set to missing when fewer than 80% of the recorded minutes had a valid sleep value.
- A temporary probable-nonwear rule flagged days with zero steps, zero stepping time, zero sleep, zero sedentary-to-upright transitions, no activity-score variation, sufficient recorded minutes, and a mean activity score at or below 80.
- Probable-nonwear participant-days were excluded.
- One participant was excluded because most or all recorded days showed a constant probable-nonwear pattern.

This probable-nonwear definition was an operational rule based on observed patterns and was not validated against a device-specific nonwear standard.

## Exploratory feature review

Histograms were used to examine skewness, large spikes, and potentially invalid values. A Spearman correlation matrix was used because several behavioral variables were highly skewed and contained many zeros.

The final behavioral feature set was:

- Total steps
- MVPA steps
- Sedentary-to-upright transitions
- Sedentary minutes
- Maximum sedentary-bout length
- Sleep minutes

These features represent overall movement, movement intensity, activity fragmentation, total sedentary behavior, prolonged sedentary behavior, and sleep.

## Temporal variables

Temporal variables were created before merging so that all available observations in each source dataset contributed to its own history.

### Health variables

- `prior_3day_bad_mood`: mean bad mood across the previous three available health observations.
- `prior_cognition`: cognitive performance from the previous available health observation.
- `days_since_prior_health`: calendar gap since the previous available health observation.

### Accelerometer variables

Previous available accelerometer values were created for steps, MVPA steps, transitions, sedentary minutes, maximum sedentary-bout length, and sleep minutes. The calendar gap from the prior accelerometer observation was also retained.

“Previous available” does not always mean the immediately preceding calendar day. Missing observation days can create longer gaps, so results describe temporal ordering based on available measurements.

## Merging

The health and accelerometer datasets were inner-joined by `id` and `date`. The merge produced:

- 1,487 health rows before merging
- 1,317 accelerometer participant-days before merging
- 1,184 matched participant-days
- 90 matched participants
- 771 rows with a sustained-mood measure based on the previous three available health observations

The final sample differed slightly across models because each model required different nonmissing predictors and outcomes.

## Statistical analysis

### Step 1: Sustained mood predicting behavior

Separate participant random-intercept models tested whether `prior_3day_bad_mood` predicted each current behavioral measure while controlling for that behavior's previous available value.

Examples:

```text
current steps ~ prior sustained bad mood + prior available steps
current sedentary minutes ~ prior sustained bad mood + prior available sedentary minutes
current sleep minutes ~ prior sustained bad mood + prior available sleep minutes
```

No behavioral outcome showed a significant association with prior sustained bad mood.

### Step 2: Prior behavior predicting cognition

Separate participant random-intercept models tested whether previous available behavior predicted current cognitive performance while controlling for prior cognition.

Examples:

```text
current cognition ~ prior available steps + prior cognition
current cognition ~ prior available sedentary minutes + prior cognition
current cognition ~ prior available sleep minutes + prior cognition
```

Several mixed models estimated the participant random-intercept variance at or near zero. Clustered OLS models were therefore used as robustness checks to account for repeated observations within participants when estimating standard errors.

In the clustered OLS checks:

- Prior sedentary minutes were not significant at the conventional 0.05 level (`p = .063`).
- Prior maximum sedentary-bout length was not significant (`p = .130`).
- Prior sleep minutes had a statistically significant negative association with cognition (`p = .006`).

The sleep result was counterintuitive and should be treated as exploratory. Sleep was aggregated by calendar date and may not represent the sleep period immediately preceding cognition. Irregular observation gaps may also affect temporal alignment.

### Step 3: Exploratory combined pathway

Combined clustered OLS models compared:

```text
current cognition ~ sustained bad mood + prior cognition
```

with:

```text
current cognition ~ sustained bad mood + prior behavior + prior cognition
```

These models assessed adjusted associations and changes in explained variance. They did not constitute a formal mediation analysis because sustained bad mood did not significantly predict the proposed behavioral mediators.

### Step 4: Within- and between-person sensitivity analysis

An exploratory sleep model separated each predictor into:

- A participant mean, representing between-person differences.
- A deviation from that participant mean, representing within-person changes.

Results:

- Within-person sustained bad mood: `p = .362`
- Between-person sustained bad mood: `p = .409`
- Within-person sleep: coefficient approximately `-0.0016`, `p = .001`
- Between-person sleep: `p = .636`
- Prior cognition: `p = .115`
- Model R²: approximately `.021`

This suggests that the exploratory sleep association was driven by occasions when a person recorded more sleep than usual, not by people who generally slept more. The effect still requires cautious interpretation because of how sleep was aligned to calendar dates.

## Main conclusion

The available data did not support the proposed pathway that sustained bad mood changes movement or sleep behavior and thereby lowers cognitive performance.

Specifically:

- Sustained bad mood did not significantly predict the selected behavioral measures.
- Most prior behavioral measures did not robustly predict later cognition after accounting for prior cognition.
- The sleep association survived the clustered OLS robustness check but was negative, small, and difficult to interpret.
- Because the mood-to-behavior path was absent, a formal mediation claim was not justified.

The findings should be reported as null or inconclusive evidence rather than evidence that mood has no effect. The study may have been limited by sparse and irregular observations, available-day rather than strictly consecutive-day lags, uncertain nonwear coding, calendar-day sleep aggregation, a reduced matched sample, and a participant population that included older adults with signs of cognitive impairment.

## Why advanced signal processing was not used

Topological or frequency-domain signal processing was not the appropriate next step for this analysis. The available columns were already device-derived minute-level summaries rather than raw high-frequency three-axis accelerometer signals. 

## Final interpretation

The analysis successfully tested a plausible behavioral pathway instead of forcing a direct mood-cognition explanation. The results did not establish that sustained bad mood erodes cognition through changes in daily movement, sedentary behavior, or sleep. The most defensible conclusion is that no clear behavioral pathway was detected in the available dataset, while the sleep finding remains exploratory and requires better sleep timing and validation.

