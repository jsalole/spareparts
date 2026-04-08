#' Get thermal endurance metrics from FMS output
#'
#' @description
#' This function calculates respirometry metrics from a single-analyzer setup, that accounts for drift over time. This works by taking incurrent measurements throughout the trialling period to create a 'drift slope' throughout the run, which corrects excurrent measures. These corrected measures are then used to calculate rolling VO2 max measures.
#'
#' @param data A dataframe with 4+ columns. Four of the columns must have the names: O2 = oxygen levels, CO2 = CO2 levels, FR = the flow rate, Time = current time in hh:mm:ss.
#' @param markers A dataframe with 2 columns, second and marker. Second is the time since the start of the trial, in seconds. Marker is "B" for baseline (incurrent) or "S" for sample (Excurrent)
#'
#' @returns A list of the original data, and dataframes of 10 candidates for important values.
#'
#' @export
#'
#' @details
#' The `data$Cmt Text` variable **must** have the following levels.
#'  "Baseline.Incur.Start", "Baseline.Excur.Start", "Last.Incur.Start", "Last.Excur.Start". These are baseline measurements taken with no speciemen in the chamber.
#'  "Incur.X.Start" are measurements taken from the incurrent (before speciement chamber). X is a placeholder for numbers 1:5, indicating the sections during trial.
#'  "Excur.X.Start" are measurments taken from the excurrent (afte speciemen chamber). X is a placeholder for numbers 1:5, indicating the sections during trial.
#'
#'
#' @import dplyr lubridate purrr slider tidyr hms
#'
VO2FMS = function(data, markers) {
  # correct percents and flow rate
  data$O2 = data$O2 / 100
  data$CO2 = data$CO2 / 100

  # Need to confirm flow rate is correct units

  # correct time
  data$Time = as_hms(data$Time)
  data$Time_since_start =
    data = data %>%
      dplyr::mutate(
        is_end = grepl("end", Cmt.Text, ignore.case = TRUE)
      ) %>% # if cmt.text contains end, returns TRUE for $is_end column
      dplyr::filter(!is_end) %>% # keeps rows if $is_end column is false
      dplyr::select(-is_end) # we chuck out this helper row

  O2_group_means = data %>%
    group_by(Cmt.Text) %>%
    arrange(Time, .by_group = TRUE) %>%
    summarise(
      mean_value = mean(O2Corrected, na.rm = TRUE),
      middle_time_seconds = as.numeric(first(Time), "seconds") +
        (as.numeric(last(Time), "seconds") -
          as.numeric(first(Time), "seconds")) /
          2,
      middle_time = seconds_to_period(middle_time_seconds)
    ) %>%
    ungroup()

  incur_correction_factor <- O2_group_means %>%
    filter(
      Cmt.Text %in%
        c(
          "Baseline.Excur.Start",
          "Baseline.Incur.Start",
          "Last.Excur.Start",
          "Last.Incur.Start"
        )
    ) %>% # select only the baseline and last section group
    dplyr::select(Cmt.Text, mean_value) %>% # select coulumns needed
    tidyr::pivot_wider(
      names_from = Cmt.Text,
      values_from = mean_value
    ) %>% # pivot table
    mutate(
      correction_factor = ((`Baseline.Incur.Start` - `Baseline.Excur.Start`) +
        (`Last.Incur.Start` - `Last.Excur.Start`)) /
        2
    ) %>% # back ticks allow us to refer to values by name
    pull(correction_factor) # returns as a numeric value

  incur_correction_factor

  O2_group_means <- O2_group_means %>%
    mutate(
      corrected_mean_value = if_else(
        grepl("Incur", Cmt.Text, ignore.case = TRUE), # condition
        mean_value - incur_correction_factor, # value if TRUE
        mean_value # value if FALSE
      )
    )

  # incur and excur values directly comparable

  incur_slopes <- O2_group_means %>%
    filter(grepl("Incur", Cmt.Text, ignore.case = TRUE))

  group_order <- c(
    "Baseline.Incur.Start",
    "Incur.1.Start",
    "Incur.2.Start",
    "Incur.3.Start",
    "Incur.4.Start",
    "Last.Incur.Start"
  )

  incur_slopes <- incur_slopes %>%
    mutate(
      Cmt.Text = factor(Cmt.Text, levels = group_order, ordered = TRUE)
    ) %>%
    mutate(
      next_mean = lead(mean_value),
      next_seconds = lead(middle_time_seconds),
      m = (next_mean - mean_value) / (next_seconds - middle_time_seconds), # slope
      b = mean_value - m * middle_time_seconds # intercept
    )

  incur_slopes = incur_slopes %>%
    mutate(
      start_time = round(middle_time_seconds),
      end_time = round(lead(middle_time_seconds))
    )

  interpolated_points <- incur_slopes %>%
    filter(!is.na(end_time)) %>% # remove last row
    mutate(
      x = map2(
        ceiling(start_time),
        floor(end_time),
        ~ seq(.x, .y, by = 1)
      ),
      # use pmap to access m and b per row
      y = pmap(list(x, m, b), function(x_seq, m_val, b_val) {
        x_seq * m_val + b_val
      })
    ) %>%
    select(Cmt.Text.start = Cmt.Text, x, y) %>%
    tidyr::unnest(c(x, y))

  interpolated_points <- interpolated_points %>%
    rename(
      Time = x,
      O2_incur = y
    ) %>%
    mutate(
      Time = seconds_to_period(Time)
    )

  data_joined <- data %>%
    left_join(
      interpolated_points %>% select(Time, O2_incur),
      by = "Time"
    ) %>%
    filter(!grepl("Incur", Cmt.Text, ignore.case = TRUE))

  data_joined

  data_joined$VO2_max = data_joined$Flow.Rate *
    ((data_joined$O2_incur - data_joined$O2Corrected) -
      data_joined$O2Corrected * (data_joined$CO2Corrected - 0)) /
    (1 - data_joined$O2Corrected)

  data_joined$VCO2_max = data_joined$Flow.Rate *
    ((data_joined$CO2Corrected - 0) -
      data_joined$CO2Corrected *
        (data_joined$O2_incur - data_joined$O2Corrected)) /
    (1 - data_joined$CO2Corrected)

  data_joined$seconds = as.numeric(data_joined$Time)

  data_joined <- data_joined %>%
    arrange(seconds) %>%
    mutate(
      VO2_max_30s = slide_index_dbl(
        .x = VO2_max,
        .i = seconds,
        .f = mean,
        .before = 15,
        .after = 15,
        na.rm = TRUE
      ),
      VCO2_max_30s = slide_index_dbl(
        .x = VCO2_max,
        .i = seconds,
        .f = mean,
        .before = 15,
        .after = 15,
        na.rm = TRUE
      )
    )

  data_joined <- data_joined %>%
    arrange(seconds) %>%
    mutate(
      VO2_max_300s = slide_index_dbl(
        .x = VO2_max,
        .i = seconds,
        .f = mean,
        .before = 150,
        .after = 150,
        na.rm = TRUE
      ),
      VCO2_max_300s = slide_index_dbl(
        .x = VCO2_max,
        .i = seconds,
        .f = mean,
        .before = 150,
        .after = 150,
        na.rm = TRUE
      )
    )

  lowest_10_VO2max <- data_joined %>%
    slice_min(VO2_max_30s, n = 10) %>%
    dplyr::select(VO2_max_30s, Time)
  highest_10_VO2max <- data_joined %>%
    slice_max(VO2_max_30s, n = 10) %>%
    dplyr::select(VO2_max_30s, Time)

  lowest_10_VCO2max <- data_joined %>%
    slice_min(VCO2_max_30s, n = 10) %>%
    dplyr::select(VCO2_max_30s, Time)

  highest_10_VCO2max <- data_joined %>%
    slice_max(VCO2_max_30s, n = 10) %>%
    dplyr::select(VCO2_max_30s, Time)

  return(list(
    data = data_joined,
    VO2min_candidates = lowest_10_VO2max,
    VO2max_candidates = highest_10_VO2max,
    VCO2min_candidates = lowest_10_VCO2max,
    VCO2max_candidates = highest_10_VCO2max
  ))
}
