library(tidyverse)
library(here)
library(sf)
library(spmodel)

# get pa conductivity data
pacond_all <- read_csv(here("inst", "extdata", "nla_obs.csv")) %>%
  mutate(PSTL_CODE = str_sub(UNIQUE_ID, 5, 6)) %>%
  filter(PSTL_CODE == "PA") %>%
  mutate(LOG_COND = log(COND_RESULT)) %>%
  select(COMID, STATE = PSTL_CODE, LOG_COND, AREA_HA,
         YEAR = DSGN_CYCLE, Tmean8110Cat:YCOORD) %>%
  st_as_sf(coords = c("XCOORD", "YCOORD"), crs = 5070)

# remove lakecat predictors
pacond <- pacond_all %>%
  select(COMID:YEAR)

# get pa condutivity prediction data

# remove lakecat predictors
