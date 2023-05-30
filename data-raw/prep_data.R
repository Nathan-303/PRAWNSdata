library(tidyverse)
library(terra)
library(devtools)
library(usethis)
library(roxygen2)
library(here)
#Write the shapefile to data
LSOA_shapefile <- vect(here::here("data-raw","2011_LSOA_shapefile_20m_generalised"))
usethis::use_data(LSOA_shapefile, overwrite = TRUE,compress = )

#Read in the rural urban classifications
rural_urban <- read.csv(here::here("data-raw","LSOA_statistics","LSOA_urban_rural.csv")) %>%
  tibble %>%  dplyr::select(-FID)

#read in the information about what city LSOAs are in
city_data <- read.csv(here::here("data-raw","LSOA_statistics","city lookup 2011.csv")) %>%
  tibble()
#Renames a column to avoid a special character that makes things go wrong
colnames(city_data)[1] <- "LSOA11CD"

#Reads the demographic information about the LSOAs, binds them by LSOA code so the FID is incorporated
LSOA_demographics <- read.csv(here::here("data-raw","LSOA_statistics","2019_LSOA_Stats.csv")) %>%
  tibble() %>%
  rename(LSOA11CD=LSOA.code..2011.) %>%
  inner_join(city_data,by="LSOA11CD")%>%
  inner_join(rural_urban,by=c("LSOA11CD"="LSOA11CD"))

#Links the demographic data to the references to the shapefile
demo_linked_reference <- inner_join(city_data,LSOA_demographics,by=c("LSOA11CD"="LSOA11CD","FID"="FID","TCITY15CD"="TCITY15CD",
                                                                     "TCITY15NM"="TCITY15NM"))

#Reads the county lookup data
county_lookup <- read.csv(here::here("data-raw","LSOA_statistics","county lookup 2019.csv"),row.names = 1)

#Makes a chunk for the LSOAs that are in counties, then mutates in a column saying it's a couty not UA
county_chunk <- inner_join(county_lookup,demo_linked_reference,by=c("LAD19NM"="Local.Authority.District.name..2019.")) %>%
  mutate(Area_Type="County") %>%
  rename("Area"=CTY19NM)

unitary_list <- !(LSOA_demographics$Local.Authority.District.name..2019. %in% county_lookup$LAD19NM)

unitary_chunk <- LSOA_demographics[unitary_list,] %>%
  mutate(Area_Type="Unitary Authority",Area=Local.Authority.District.name..2019.)# %>%
#inner_join(demo_linked_reference,by="LSOA11CD")
refined_chunk <- bind_rows(unitary_chunk,county_chunk) %>% tibble()
rm(unitary_list)
rm(unitary_chunk)
rm(county_chunk)

usethis::use_data(refined_chunk, overwrite = TRUE)
