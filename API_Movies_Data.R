library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)

library(readr)




url = "https://imdb-top-100-movies.p.rapidapi.com/"


api_key = "db2601cf5dmsh2d56bd4a1efd9d8p1a2026jsn6ef301ba9e2c"

response = GET(url,
               add_headers(
                 `X-RapidAPI-Key` = api_key,
                 `X-RapidAPI-Host` = "imdb-top-100-movies.p.rapidapi.com"
               ))

data = content(response, "text") |>
  fromJSON(flatten = TRUE)

movies_df = as.data.frame(data)
movies_df = movies_df |>
  select(-c('big_image', 'image', 'thumbnail', 'imdbid', 'imdb_link' ))


print(head(movies_df))
