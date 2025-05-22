library(tidyverse)
library(readxl)
library(usmap)
library(sf)
library(rnaturalearth)
library(leaflet)
library(ggiraph)

# Sources
#
# New York Times: Where Federal Dollars Flow to Universities
# https://www.nytimes.com/interactive/2025/04/30/us/university-funding-research.html
#
# Higher Education Research and Development (HERD) Survey2023
# https://ncses.nsf.gov/surveys/higher-education-research-development/2023#data
#
# Institution rankings, by federally financed R&D expenditures
# https://ncses.nsf.gov/surveys/higher-education-research-development/2023#


# Input file: highered-geo-type-nsf25314-tab024.csv
# File curated with ChatGPT to get geospatial coordinates of institutions
# adjust limits to avoid institutions outside U.S. States
edu = read_csv("highered-geo-type-nsf25314-tab024.csv") |> 
  filter(Longitude < 0, 
         Latitude > 19) |> 
  mutate(Color = case_when(
    Type == "Public" ~ "#cc823799",
    Type == "Private" ~ "#8c677399"
  ))


# Option 1) using map from "usmap" which inlcudes Alaska and Hawaii
# Important: Convert spatial data (e.g. lon, lat) to "usmap" projection
edu2 = usmap_transform(
  data = edu, 
  input_names = c("Longitude", "Latitude"))

ggplot() +
  geom_sf(data = us_map(), #fill = "#f7f6f0"
          fill = "#f8f8f8") +
  geom_sf(data = edu2, 
          color = "white",
          shape = 21,
          fill = edu2$Color) +
  theme_void()


# Option 2) another less ideal option is to use a map from "rnaturalearth"
us_states = ne_states(country = "United States of America", returnclass = "sf")

gg = ggplot() +
  geom_sf(data = us_states) +
  coord_sf(xlim = c(-130, -65), ylim = c(25, 50)) +
  geom_point_interactive(
    data = edu, 
    aes(x = Lon, y = Lat, tooltip = University), 
    color = "tomato", alpha = 0.5) +
  theme_void()

girafe(ggobj = gg)



# Option 3) leaflet map
edu |> 
  leaflet() |> 
  addTiles() |> 
  addCircles(lat = ~Lat,
             lng = ~Lon,
             label = ~University)



# =============================================================================
# Import data from file nsf25314-tab024.xlsx
# =============================================================================

dat24_raw = read_excel(
  path = "nsf25314-tab024.xlsx", 
  sheet = 1, 
  col_names = FALSE,
  range = "A6:AC406") # read-in till New York Institute of Technology 

# select
dat24 = dat24_raw |> 
  select(1, 2, 29)

colnames(dat24) = c("Name", "Rank", "Exp2023")

# expenditure amount in millions of dollars
dat24 = dat24 |> 
  mutate(Amount = Exp2023 / 1000)

# Merge with points-polygon data
edu3 = edu2 |> 
  inner_join(dat24, by = c("Institution" = "Name"))

# Map
ggplot() +
  geom_sf(data = us_map(), fill = "#f8f8f8", color = "#d8d8d8") +
  geom_sf(data = edu3, aes(size = Amount), 
          color = "#FFFFFF55", 
          fill = edu3$Color, 
          shape = 21) +
  #scale_size_area(breaks = c(500, 1000, 2000, 3000)) +
  scale_size_continuous(breaks = c(500, 1000, 2000, 3000)) +
  theme_void() #+
  #theme(legend.position = "bottom")


