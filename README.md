
<!-- README.md is generated from README.Rmd. Please edit that file -->

# spareparts

<!-- badges: start -->

<!-- badges: end -->

**spareparts** is a depot for one-off functions analyzing data through
pipelines that will be updated through time. Currently existing
pipelines are outlind below:

- Analysis of thermal endurance challenges to measure V02 max
  `TEdriftR()`
- Analysis of metabolic rate from the feild metabolic system `VO2FMS()`

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

``` r
head(thermal_endure)
#>   O2Corrected CO2Corrected      VO2 Flow.Rate Chamber.Temp             Cmt.Text
#> 1    12.13318  0.001619542 133.0402  1.504719     30.09618 Baseline.Incur.Start
#> 2    12.13130  0.001006923 133.0684  1.504696     30.09484 Baseline.Incur.Start
#> 3    12.13270  0.000738460 133.0392  1.504603     30.09424 Baseline.Incur.Start
#> 4    12.13009  0.000830430 133.0971  1.504785     30.09683 Baseline.Incur.Start
#> 5    12.13565  0.001280686 133.0043  1.504703     30.09757 Baseline.Incur.Start
#> 6    12.13483  0.001531938 133.0091  1.504631     30.09854 Baseline.Incur.Start
#>       Time
#> 1 14:35:16
#> 2 14:35:17
#> 3 14:35:18
#> 4 14:35:19
#> 5 14:35:20
#> 6 14:35:21
data_01 <- TEdriftR(thermal_endure)
head(data_01$VO2max_candidates)
#>   VO2_max_30s        Time
#> 1    4.119587 17H 33M 33S
#> 2    4.119356 17H 33M 34S
#> 3    4.115779 17H 33M 32S
#> 4    4.113239 17H 33M 35S
#> 5    4.111867 17H 33M 31S
#> 6    4.106033 17H 33M 36S
```

``` r
head(expedata)
#>       Time       O2       CO2       FR      MFS Thermo_1 Thermo_2 Thermo_4
#> 1 13:47:55 20.80165 0.2023332 407.1323 1994.353 15.32836    -1000 12.38532
#> 2 13:47:56 20.80083 0.2021157 401.2784 1993.029 15.33106    -1000 12.38647
#> 3 13:47:57 20.79909 0.2027999 405.1239 1992.942 15.33373    -1000 12.37551
#> 4 13:47:58 20.79734 0.2026778 399.9376 1994.871 15.32911    -1000 12.35847
#> 5 13:47:59 20.79541 0.2020427 388.6046 1993.865 15.32505    -1000 12.35481
#> 6 13:48:00 20.79369 0.2013691 409.0300 1995.199 15.32683    -1000 12.36785
#>   Marker
#> 1     -1
#> 2     -1
#> 3     b1
#> 4     -1
#> 5     -1
#> 6     -1
head(markers)
#>   second marker number                                                       X
#> 1   1821      B      1                                                        
#> 2   1990    end     NA                                            B = baseline
#> 3   2025      S      1                                              S = sample
#> 4   3294    end     NA markers placed at the beginning and end of each segment
#> 5   3408      B      2                                                        
#> 6   3759    end     NA
data_02 <- VO2FMS(expedata, markers)
head(data_02$VO2_max_candidates)
#>     VO2_30s time_since_start
#> 1 0.5485580             4381
#> 2 0.5484209             4379
#> 3 0.5478672             4377
#> 4 0.5478410             4378
#> 5 0.5477671             4380
#> 6 0.5477284             4383
```

## Authours

- **Jack Salole** - [jsalole](https://github.com/jsalole)

## Acknowledgments

This collection of functions and example datasets has been generated
with the support of colleagues listed below.

- **K. Garvey:** `TEdriftR`, and datasets (thermal_endure)
- **P. Ouyang:** `TEdriftR`
- **F. O’Dacre:** `TEdriftR`
- **A. Eaton:** `VO2FMS`, and datasets (expedata, markers)
