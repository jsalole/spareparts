#' Calculate Respirometry Metrics
#'
#' @param data Exported expedata file
#' @param markers Dataframe of timepoints and labels
#'
#' @return A named list containing:
#' \describe{
#'   \item{data}{The full joined dataset with VO2, VCO2, and rolling means.}
#'   \item{VO2_min_candidates}{Top 10 rows with lowest 30s VO2.}
#'   \item{VO2_max_candidates}{Top 10 rows with highest 30s VO2.}
#'   \item{VCO2_min_candidates}{Top 10 rows with lowest 30s VCO2.}
#'   \item{VCO2_max_candidates}{Top 10 rows with highest 30s VCO2.}
#' }
#' @export
#'
#' @import dplyr
#' @import tidyr
#' @import purrr
#' @import slider
VO2FMS <- function(data, markers) {
  data$Time <- hms::as_hms(data$Time)
  data$time_since_start <- as.numeric(
    data$Time - data$Time[1],
    units = "secs"
  )
  data$O2 <- data$O2 / 100
  data$CO2 <- data$CO2 / 100

  # --- Load and prepare markers ---
  markers <- markers[, 1:3]

  # --- Join markers to main data ---
  data <- dplyr::left_join(data, markers, by = c("time_since_start" = "second"))

  data <- data %>%
    tidyr::fill(c(marker, number), .direction = "down") %>%
    dplyr::filter(marker != "end")

  # --- Compute baseline group means (marker == "B") ---
  group_means <- data %>%
    dplyr::filter(marker == "B") %>%
    dplyr::group_by(number) %>%
    dplyr::summarize(
      mean_O2 = mean(O2, na.rm = TRUE),
      mean_time = mean(time_since_start, na.rm = TRUE)
    ) %>%
    dplyr::arrange(number)

  # --- Compute linear slopes between consecutive baselines ---
  slopes <- group_means %>%
    dplyr::mutate(
      next_O2 = dplyr::lead(mean_O2),
      next_time = dplyr::lead(mean_time),
      m = (next_O2 - mean_O2) / (next_time - mean_time),
      b = mean_O2 - m * mean_time,
      start_time = round(mean_time),
      end_time = round(dplyr::lead(mean_time))
    )

  # --- Interpolate baseline O2 across each interval ---
  interpolated <- slopes %>%
    dplyr::filter(!is.na(end_time)) %>%
    dplyr::mutate(
      x = purrr::map2(
        ceiling(start_time),
        floor(end_time),
        ~ seq(.x, .y, by = 1)
      ),
      y = purrr::pmap(list(x, m, b), function(x_seq, m_val, b_val) {
        x_seq * m_val + b_val
      })
    ) %>%
    dplyr::select(number, x, y) %>%
    tidyr::unnest(c(x, y)) %>%
    dplyr::rename(time_since_start = x, O2_interp = y)

  # --- Join interpolated baseline back to main data ---
  data_joined <- data %>%
    dplyr::left_join(
      interpolated %>% dplyr::select(time_since_start, O2_interp),
      by = "time_since_start"
    )

  # --- VO2 and VCO2 calculations ---
  data_joined <- data_joined %>%
    dplyr::mutate(
      VO2 = FR * ((O2_interp - O2) - O2 * (CO2 - 0)) / (1 - O2),
      VCO2 = FR * ((CO2 - 0) - CO2 * (O2_interp - O2)) / (1 - CO2)
    )

  # --- 30s rolling means ---
  data_joined <- data_joined %>%
    dplyr::arrange(time_since_start) %>%
    dplyr::mutate(
      VO2_30s = slider::slide_index_dbl(
        VO2,
        time_since_start,
        mean,
        .before = 15,
        .after = 15,
        na.rm = TRUE
      ),
      VCO2_30s = slider::slide_index_dbl(
        VCO2,
        time_since_start,
        mean,
        .before = 15,
        .after = 15,
        na.rm = TRUE
      )
    )

  # --- 300s rolling means ---
  data_joined <- data_joined %>%
    dplyr::mutate(
      VO2_300s = slider::slide_index_dbl(
        VO2,
        time_since_start,
        mean,
        .before = 150,
        .after = 150,
        na.rm = TRUE
      ),
      VCO2_300s = slider::slide_index_dbl(
        VCO2,
        time_since_start,
        mean,
        .before = 150,
        .after = 150,
        na.rm = TRUE
      )
    )

  # --- Top/bottom 10 candidates ---
  VO2_min <- data_joined %>%
    dplyr::slice_min(VO2_30s, n = 10) %>%
    dplyr::select(VO2_30s, time_since_start)

  VO2_max <- data_joined %>%
    dplyr::slice_max(VO2_30s, n = 10) %>%
    dplyr::select(VO2_30s, time_since_start)

  VCO2_min <- data_joined %>%
    dplyr::slice_min(VCO2_30s, n = 10) %>%
    dplyr::select(VCO2_30s, time_since_start)

  VCO2_max <- data_joined %>%
    dplyr::slice_max(VCO2_30s, n = 10) %>%
    dplyr::select(VCO2_30s, time_since_start)

  # --- Return ---
  return(
    list(
      data = data_joined,
      VO2_min_candidates = VO2_min,
      VO2_max_candidates = VO2_max,
      VCO2_min_candidates = VCO2_min,
      VCO2_max_candidates = VCO2_max
    )
  )
}
