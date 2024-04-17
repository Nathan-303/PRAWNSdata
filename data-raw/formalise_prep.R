usethis::use_r("LSOA_shapefile")
usethis::use_r("refined_chunk")
usethis::use_r("pollutant_key")
usethis::use_r("ListSets")
devtools::document()
devtools::install()

library(devtools)
install_github("Nathan-303/PRAWNSdata",upgrade = "never")
