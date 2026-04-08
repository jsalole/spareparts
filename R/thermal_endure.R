#' Data collected from a respirometry experiment with 1 analyzer.
#'
#' A dataframe of respirometry experiment metrics.
#'
#' @format ## `thermal_endure`
#' A data frame with 12288 rows and 7 columns:
#' \describe{
#'   \item{O2Corrected}{Oxygen level}
#'   \item{CO2Corrected}{Carbon dioxide level}
#'   \item{Flow Rate}{Flow rate of air through the analyzer}
#'   \item{Time}{Time in hh:mm:ss}
#'   \item{Cmt.Text}{See \code{\link{TEdriftR}} for information}
#'   \item{number}{Numeric order of events; indicates the order of baseline and sample periods for slope calculations}
#' }
"thermal_endure"
