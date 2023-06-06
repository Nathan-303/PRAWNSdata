library(tidyverse)
library(terra)
library(devtools)
library(usethis)
library(roxygen2)
library(here)
library(sf)
#Write the shapefile to data
LSOA_shapefile <- read_sf(here::here("data-raw","2011_LSOA_shapefile_20m_generalised"))
usethis::use_data(LSOA_shapefile, overwrite = TRUE,compress = "xz")

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
  mutate(Area_Type="Unitary Authority",Area=Local.Authority.District.name..2019.) %>%
 inner_join(demo_linked_reference,by="LSOA11CD")
refined_chunk <- bind_rows(unitary_chunk,county_chunk) %>% tibble() %>%
  dplyr::select(-c(Income.Score..rate.,Income.Rank..where.1.is.most.deprived.,Employment.Score..rate.,
                   Employment.Rank..where.1.is.most.deprived.,Education..Skills.and.Training.Score,
                   Education..Skills.and.Training.Rank..where.1.is.most.deprived.,Health.Deprivation.and.Disability.Score,
                   Health.Deprivation.and.Disability.Rank..where.1.is.most.deprived.,Crime.Score,
                   Crime.Rank..where.1.is.most.deprived.,Barriers.to.Housing.and.Services.Score,Barriers.to.Housing.and.Services.Rank..where.1.is.most.deprived.,
                   Living.Environment.Score,Living.Environment.Rank..where.1.is.most.deprived.,Income.Deprivation.Affecting.Children.Index..IDACI..Score..rate.,
                   Income.Deprivation.Affecting.Children.Index..IDACI..Rank..where.1.is.most.deprived.,Income.Deprivation.Affecting.Older.People..IDAOPI..Score..rate.,Income.Deprivation.Affecting.Older.People..IDAOPI..Rank..where.1.is.most.deprived.,Children.and.Young.People.Sub.domain.Score,Children.and.Young.People.Sub.domain.Rank..where.1.is.most.deprived.,Adult.Skills.Sub.domain.Score,Adult.Skills.Sub.domain.Rank..where.1.is.most.deprived.,Geographical.Barriers.Sub.domain.Score,Geographical.Barriers.Sub.domain.Rank..where.1.is.most.deprived.,Wider.Barriers.Sub.domain.Score,Wider.Barriers.Sub.domain.Rank..where.1.is.most.deprived.,Indoors.Sub.domain.Score,Indoors.Sub.domain.Rank..where.1.is.most.deprived.,Outdoors.Sub.domain.Score,Outdoors.Sub.domain.Rank..where.1.is.most.deprived.,LSOA11NM.x,LSOA11NM.y
  ))
rm(unitary_list)
rm(unitary_chunk)
rm(county_chunk)

usethis::use_data(refined_chunk, overwrite = TRUE,compress="xz")

pollutant_key <- read.csv(here::here("data-raw","Pollutant_lookup.csv"))
usethis::use_data(pollutant_key, overwrite = TRUE,compress="xz")
