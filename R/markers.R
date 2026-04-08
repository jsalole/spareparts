#' Timepoints in FMS data collection
#'
#' A dataframe of timestamps for labelling incurrent and excurrent sections of respirometry data. Importantly, use "end" to exclude noise in the data.
#'
#'
#' @format ## `markers`
#' A data frame with 11 rows and 4 columns:
#' \describe{
#'   \item{second}{Seconds from the beginning of the run}
#'   \item{marker}{Label of what the timepoint is; should be B (baseline), S (sample), or end (end of these sample periods, or to exclude noisy sections).}
#'   \item{number}{Numeric order of events; indicates the order of baseline and sample periods for slope calculations}
#'   ...
#' }
"markers"
