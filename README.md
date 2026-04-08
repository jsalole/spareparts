
<!-- README.md is generated from README.Rmd. Please edit that file -->

# spareparts

<!-- badges: start -->

<!-- badges: end -->

**spareparts** is a depot for one-off functions analyzing data through
pipelines that will be updated through time. Currently existing
pipelines are outlind below:

- Analysis of thermal endurance challenges to measure V02 max
  (`TEdriftR()`)
- Analysis of metabolic rate from the feild metabolic system
  (`VO2FMS()`)

## Getting Started

You can install the development version of **spareparts** from
[GitHub](https://github.com/jsalole/spareparts) with `pak()`.

``` r
# install.packages("pak")
pak::pak("jsalole/spareparts")
```

``` r
library("spareparts")
```

This will get the package into your R session.

## Examples

## Authours

- **Jack Salole** - [jsalole](https://github.com/jsalole)

## Acknowledgments

This collection of functions has been generated for and with the support
of colleagues listed below.

- **K. Garvey**: TEdriftR
- **P. Ouyang**: TEdriftR
- **F. O’Dacre**: TEdriftR
- **A. Eaton**: `VO2FMS`, and datasets (expedata, markers)
