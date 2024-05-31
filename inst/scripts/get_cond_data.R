library(tidyverse)
library(sf)
library(spmodel)
library(StreamCatTools)

############################################
#### Conductivity Data
############################################

states <- tigris::states(cb = TRUE, progress_bar = FALSE)  %>%
  filter(!STUSPS %in% c('HI', 'PR', 'AK', 'MP', 'GU', 'AS', 'VI'))  %>%
  st_transform(crs = 5070)

# Read in lakes, select/massage columns, convert to spatial object
lake_cond <- read_csv('inst/extdata/nla_obs.csv') %>%
  select(COMID, COND_RESULT,
         AREA_HA, DSGN_CYCLE,
         XCOORD, YCOORD) %>%
  mutate(DSGN_CYCLE = factor(DSGN_CYCLE)) %>%
  st_as_sf(coords = c('XCOORD', 'YCOORD'),
           crs = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +type=crs") %>%
  st_transform(crs = 5070)

MN <- states %>%
  filter(STUSPS == 'MN')

cond_mn <- lake_cond %>%
  st_filter(MN) %>%
  rename(year = DSGN_CYCLE)

comids <- cond_mn$COMID

mn_lakecat <- lc_get_data(comid = comids,
                          metric = 'Tmean8110, Precip8110,
                          CaO, S') %>%
  select(COMID, TMEAN8110CAT, PRECIP8110WS, CAOWS, SWS)

crop <-
  # Grab LakeCat crop data
  lc_get_data(comid = comids,
              aoi = 'watershed',
              metric = 'pctcrop2006, pctcrop2011, pctcrop2016') %>%
  # Remove watershed area from data
  select(-WSAREASQKM) %>%
  # Pivot table to long to create "year" column
  pivot_longer(!COMID, names_to = 'tmpcol', values_to = 'PCTCROPWS') %>%
  # Remove PCTCROP and WS to make "year" column
  mutate(year = as.integer(
    str_replace_all(tmpcol, 'PCTCROP|WS', ''))) %>%
  # Add 1 to each year to match NLA years
  mutate(year = factor(year + 1)) %>%
  # Remove the tmp column
  select(-tmpcol)

urb <-
  lc_get_data(comid = comids,
              aoi = 'watershed',
              metric = 'pcturbmd2006, pcturbmd2011, pcturbmd2016,
              pcturbhi2006, pcturbhi2011, pcturbhi2016',
              showAreaSqKm = FALSE) %>%

  # Add up medium and high urban areas
  mutate(PCTURB2006WS = PCTURBMD2006WS + PCTURBHI2006WS,
         PCTURB2011WS = PCTURBMD2011WS + PCTURBHI2011WS,
         PCTURB2016WS = PCTURBMD2016WS + PCTURBHI2016WS) %>%
  select(COMID, PCTURB2006WS, PCTURB2011WS, PCTURB2016WS) %>%
  pivot_longer(!COMID, names_to = 'tmpcol', values_to = 'PCTURBWS') %>%
  mutate(year = as.integer(
    str_replace_all(tmpcol, 'PCTURB|WS', ''))) %>%
  mutate(year = factor(year + 1)) %>%
  select(-tmpcol)

model_data <- cond_mn %>%
  left_join(mn_lakecat, join_by(COMID)) %>%
  left_join(crop, join_by(COMID, year)) %>%
  left_join(urb, join_by(COMID, year))

# rename things
cond <- lake_cond
cond_mn <- cond_mn
cond_mn_lc <- model_data

cond_model_data <- model_data
