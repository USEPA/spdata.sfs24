library(finsyncR)
library(tidyverse)
library(sf)
library(tigris)
library(StreamCatTools)
library(nhdplusTools)
library(spmodel)
library(data.table)
library(prism)

############################################
#### Argia Data
############################################
macros <- getInvertData(dataType = "occur",
                        taxonLevel = "Genus",
                        agency = "EPA",
                        lifestage = FALSE,
                        rarefy = TRUE,
                        rarefyCount = 300,
                        sharedTaxa = FALSE,
                        seed = 1,
                        boatableStreams = T)

# Flexible code so we could model another taxon
genus <- 'Argia'

taxon = macros %>%
  dplyr::select(SampleID,
                ProjectLabel,
                CollectionDate,
                Latitude_dd,
                Longitude_dd,
                all_of(genus))  %>%
  #filter(ProjectLabel != 'WSA') %>%
  mutate(CollectionDate = date(CollectionDate),
         presence =
           as.factor(pull(., genus)))  %>%
  st_as_sf(coords = c('Longitude_dd', 'Latitude_dd'), crs = 4269)  %>%
  st_transform(crs = 5070)

states <- tigris::states(cb = TRUE, progress_bar = FALSE)  %>%
  filter(!STUSPS %in% c('HI', 'PR', 'AK', 'MP', 'GU', 'AS', 'VI'))  %>%
  st_transform(crs = 5070)



# Filter to study region (states)
region <- states %>%
  filter(STUSPS %in% c('VT', 'NH', 'ME', 'NY', 'RI',
                       'MA', 'CT', 'NJ', 'PA', 'DE'))

# Use region as spatial filter (sf::st_filter()) for taxon of interest
taxon_rg <- taxon %>%
  st_filter(region) %>%
  filter(ProjectLabel %in% c('NRSA1314', 'NRSA1819')) %>%
  mutate(year = year(ymd(CollectionDate))) %>%
  select(SampleID:CollectionDate, presence:year)

taxon_rg %>%
  pull(presence) %>%
  table()

comids <- sc_get_comid(taxon_rg)

#comids <- read_rds('./data/nrsa_comids.rds')
comid_vect <-
  comids %>%
  str_split(',') %>%
  unlist() %>%
  as.integer()

taxon_rg <-
  taxon_rg %>%
  mutate(COMID = comid_vect)

sc <-
  sc_get_data(comid = comids,
              aoi = 'watershed',
              metric = 'bfi, precip8110, wetindex, elev',
              showAreaSqKm = TRUE)


wetlands <-
  sc_get_data(comid = comids,
              aoi = 'watershed',
              metric = 'pctwdwet2013,pcthbwet2013,pctwdwet2019,pcthbwet2019',
              showAreaSqKm = FALSE) %>%

  # Sum wetland types to create single wetlands metric
  mutate(PCTWETLAND2013WS = PCTHBWET2013WS + PCTWDWET2013WS,
         PCTWETLAND2019WS = PCTHBWET2019WS + PCTWDWET2019WS) %>%

  # Reduce columns
  select(COMID, PCTWETLAND2013WS, PCTWETLAND2019WS) %>%

  # Create long table w/ column name w/out year
  pivot_longer(!COMID, names_to = 'tmpcol', values_to = 'PCTWETLANDXXXXWS') %>%

  # Create new column of year by removing "PCTWETLAND" and "WS" from names
  mutate(year = as.integer(str_replace_all(tmpcol, 'PCTWETLAND|WS', '')))

# But some samples have 2014 and 2018 as sample years? How can we trick the data into joining?
# We can match 2019 data to 2018 observations by subtracting a year and appending it to the data

# Create tmp table with 1 added or subtracted to year of record
tmp_wetlands <- wetlands %>%
  mutate(year = ifelse(year == 2013, year + 1, year - 1))

# rbind() wetlands and tmp_wetlands so we have records to join to 2014 and 2018
wetlands <- wetlands %>%
  rbind(tmp_wetlands) %>%
  select(-tmpcol)

riparian_imp <-
  sc_get_data(comid = comids,
              aoi = 'riparian_watershed',
              metric = 'pctimp2013, pctimp2019',
              showAreaSqKm = FALSE) %>%
  select(-WSAREASQKMRP100) %>%
  pivot_longer(!COMID, names_to = 'tmpcol', values_to = 'PCTIMPXXXXWSRP100') %>%
  mutate(year = as.integer(
    str_replace_all(tmpcol, 'PCTIMP|WSRP100', '')))

tmp_imp <- riparian_imp %>%
  mutate(year = ifelse(year == 2013, year + 1, year - 1))

riparian_imp <- riparian_imp %>%
  rbind(tmp_imp) %>%
  select(-tmpcol)

# Get these years of PRISM
years <- c(2013, 2014, 2018, 2019)

# Set the PRISM directory (creates directory in not present)
prism_set_dl_dir("inst/extdata/prism_data", create = TRUE)

# Download monthly PRISM rasters (tmean)
get_prism_monthlys('tmean',
                   years = years,
                   mon = 7:8,
                   keepZip = FALSE)

# Create stack of downloaded PRISM rasters
tmn <- pd_stack((prism_archive_subset("tmean","monthly",
                                      years = years,
                                      mon = 7:8)))

# Extract tmean at sample points and massage data
tmn <- terra::extract(tmn,
                      # Transform taxon_rg to CRS of PRISM on the fly
                      taxon_rg %>%
                        st_transform(crs = st_crs(tmn))) %>%

  # Add COMIDs to extracted values
  data.frame(COMID = comid_vect, .) %>%

  # Remove front and back text from PRISM year/month in names
  rename_with( ~ stringr::str_replace_all(., 'PRISM_tmean_stable_4kmM3_|_bil', '')) %>%

  # Pivot to long table and calle column TMEANPRISMXXXXPT, XXXX indicates year
  pivot_longer(!COMID, names_to = 'year_month',
               values_to = 'TMEANPRISMXXXXPT') %>%

  # Create new column of year
  mutate(year = year(ym(year_month))) %>%

  # Average July and August temperatures
  summarise(TMEANPRISMXXXXPT = mean(TMEANPRISMXXXXPT, na.rm = TRUE),
            .by = c(COMID, year))


model_data <-
  taxon_rg %>%
  left_join(sc, join_by(COMID)) %>%
  left_join(wetlands, join_by(COMID, year)) %>%
  left_join(riparian_imp, join_by(COMID, year)) %>%
  left_join(tmn, join_by(COMID, year)) %>%
  drop_na()

cor(model_data %>%
      st_drop_geometry() %>%
      select(WSAREASQKM:TMEANPRISMXXXXPT))

# for prediction

state <- region %>%
  filter(STUSPS == "NJ") %>%
  st_transform(crs = 4326)

# Use get_nhdplus to access the individual stream sub-catchments
pourpoints <-
  nhdplusTools::get_nhdplus(AOI = state,
                            realization = 'outlet') |>
  filter(flowdir == "With Digitized")

sc_prd <- sc_get_data(state = 'NJ',
                      aoi = 'watershed,riparian_watershed',
                      metric = 'bfi,precip8110,wetindex,elev,pctwdwet2019,pcthbwet2019,pctimp2019') |>
  mutate(PCTWETLANDXXXXWS = PCTWDWET2019WS + PCTHBWET2019WS) |>
  rename(PCTIMPXXXXWSRP100 = PCTIMP2019WSRP100) |>
  select(COMID, WSAREASQKM, ELEVWS, WETINDEXWS, BFIWS,
         PRECIP8110WS, PCTWETLANDXXXXWS, PCTIMPXXXXWSRP100)

tmn_prd <-
  pd_stack((prism_archive_subset("tmean","monthly",
                                 years = 2019,
                                 mon = 7:8)))
tmn_prd <-
  terra::extract(tmn_prd,
                 pourpoints %>%
                   st_transform(crs = st_crs(tmn_prd))) |>
  as.tibble() |>
  mutate(COMID = pourpoints$comid,
         TMEANPRISMXXXXPT = (PRISM_tmean_stable_4kmM3_201907_bil + PRISM_tmean_stable_4kmM3_201908_bil)/2) |>
  select(COMID, TMEANPRISMXXXXPT)

prediction <- sc_prd |>
  left_join(tmn_prd, join_by(COMID)) |>
  left_join(pourpoints, join_by(COMID == comid)) |>
  st_as_sf() |>
  st_transform(crs = 5070) |>
  select(COMID, WSAREASQKM, ELEVWS, WETINDEXWS,
         BFIWS, PRECIP8110WS, PCTWETLANDXXXXWS,
         PCTIMPXXXXWSRP100, TMEANPRISMXXXXPT) |>
  na.omit()


# rename things
argia_model_data <- model_data
argia_pred_data <- prediction
argia_pred_data_small <- argia_pred_data %>%
  slice(seq_len(100))
