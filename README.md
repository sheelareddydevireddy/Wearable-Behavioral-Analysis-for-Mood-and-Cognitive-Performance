# Sustained Bad Mood, Behavior, and Cognitive Performance

TL;DR: Processed 2M+ minute-level wearable records and analyzed matched data from 90 participants to test whether sustained bad mood was associated with lower cognition through changes in movement and sleep. Mood did not predict behavior, so the proposed pathway was not supported. An exploratory within-person sleep association emerged (approximately −0.10 SD per additional recorded hour), but may reflect limitations in calendar-date sleep alignment.

Tools: Python, pandas, statsmodels (mixed-effects and clustered OLS)

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

| Behavioral outcome | Mood coefficient (β) | 95% CI | p-value | Observations | Participants |
|---|---:|---:|---:|---:|---:|
| Total steps | -258.034 | [-749.951, 233.883] | .304 | 770 | 74 |
| Sedentary minutes | 2.069 | [-15.578, 19.716] | .818 | 735 | 70 |
| Maximum sedentary-bout length | -2.227 | [-12.635, 8.181] | .675 | 735 | 70 |
| MVPA steps | -0.749 | [-3.247, 1.749] | .557 | 770 | 74 |
| Sedentary-to-upright transitions | -0.210 | [-2.160, 1.739] | .833 | 770 | 74 |
| Sleep minutes | -4.134 | [-17.868, 9.599] | .555 | 735 | 70 |


### Step 2: Prior behavior predicting cognition

Separate participant random-intercept models tested whether previous available behavior predicted current cognitive performance while controlling for prior cognition.

Examples:

```text
current cognition ~ prior available steps + prior cognition
current cognition ~ prior available sedentary minutes + prior cognition
current cognition ~ prior available sleep minutes + prior cognition
```

Several mixed models estimated the participant random-intercept variance at or near zero. Clustered OLS models were therefore used as robustness checks to account for repeated observations within participants when estimating standard errors.

Relevant clustered OLS results:

| Prior behavior | Coefficient (β) | 95% CI | p-value | Observations | Participants |
|---|---:|---:|---:|---:|---:|
| Sedentary minutes | 0.0003 | [-0.000016, 0.001] | .063 | 1,017 | 84 |
| Maximum sedentary-bout length | -0.0004 | [-0.001, 0.000] | .130 | 1,017 | 84 |
| Sleep minutes | -0.0007 | [-0.001, -0.000] | .006 | 1,017 | 84 |

The sleep result was counterintuitive and should be treated as exploratory. Sleep was aggregated by calendar date and may not represent the sleep period immediately preceding cognition. Irregular observation gaps may also affect temporal alignment.

Each additional hour of prior recorded sleep was associated with approximately 0.04 standard deviations lower cognition (−0.0007 × 60 = −0.042), after controlling for prior cognition.

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

This suggests that the exploratory sleep association may reflect within-person variation in sleep rather than between-person differences.

In practical terms, one additional hour of sleep relative to a participant’s usual amount was associated with approximately 0.10 standard deviations lower cognition (−0.0016 × 60 = −0.096).

## Conclusion and limitations

- Sustained bad mood did not significantly predict movement, sedentary behavior, or sleep.
- Most prior behavioral measures were not significantly associated with later cognition after controlling for prior cognition.
- Prior sleep showed a small negative association with cognition, but this counterintuitive finding remains exploratory.
- Formal mediation was not supported because mood did not predict the proposed behavioral mediators.
- Limitations include irregular observations, nonconsecutive lags, uncertain nonwear classification, calendar-day sleep aggregation, and a reduced matched sample.
- Advanced signal processing was not used because the data contained processed minute-level summaries rather than raw accelerometer signals.
