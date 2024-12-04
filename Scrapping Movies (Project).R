# Getting the full, 1000 movie dataset into R-studio:
moviedata <- readr::read_csv("~/Downloads/ISA 401/Data/highestgrossingfilms.csv")

summary(moviedata)

# Condensing the dataset to only the top 100 movies:
top_100 <- moviedata |> 
  dplyr::slice_head(n = 100)

# Getting rid of columns I do not need for later analysis:
top_100 <- top_100 |>
  dplyr::select(-"Position", -"Const", -"Modified", -"Original Title", -"URL", -"Title Type", -"Num Votes", -"Created")

# Editing the name of "Lifetime Gross" column and removing the character text from each record 
# of this column 
top_100 <- top_100 |>
  dplyr::rename("Worldwide Lifetime Gross (in $)" = "Description")

top_100 <- top_100 |>
  dplyr::mutate(
    `Worldwide Lifetime Gross (in $)` = stringr::str_remove(
      `Worldwide Lifetime Gross (in $)`, 
      "Worldwide Lifetime Gross: \\$"
    )
  )

# Checking the structure of each field in my dataset:
str(top_100)

# Converting character fields to numeric fields and changing the 'Year' field to a chr:
top_100 <- top_100 |>
  dplyr::mutate(
    `Worldwide Lifetime Gross (in $)` = stringr::str_remove_all(`Worldwide Lifetime Gross (in $)`, "[^0-9.-]"),
    `Worldwide Lifetime Gross (in $)` = as.numeric(`Worldwide Lifetime Gross (in $)`)
  )

top_100 <- top_100 |>
  dplyr::mutate(
    `Year` = as.character(`Year`)
  )

str(top_100)

# Saving the cleaned dataset as a CSV file
readr::write_csv(top_100, "top_100.csv")

# Adding actors category to R:
movie_actors <- readr::read_csv("Downloads/movie_actors.csv")

# Adding the actors column to my larger dataset (the column titles already match)
top_100 <- top_100 |>
  dplyr::mutate(Actors = movie_actors$Actors)

# Scrapping website for data on movie budgets
"https://www.the-numbers.com/movie/budgets/all" |> 
  rvest::read_html_live() -> budget_webpage

budget_webpage |> 
  rvest::html_elements("b a") |> 
  rvest::html_text2() -> titles100

budget_webpage |> 
  rvest::html_elements("#page_filling_chart > center > table > tbody > tr > td:nth-child(4)") |> 
  rvest::html_text2() -> budget100

"https://www.the-numbers.com/movie/budgets/all/101" |> 
  rvest::read_html_live() -> budget_webpage2

budget_webpage2 |> 
  rvest::html_elements("b a") |> 
  rvest::html_text2() -> titles200

budget_webpage2 |> 
  rvest::html_elements("#page_filling_chart > center > table > tbody > tr > td:nth-child(4)") |> 
  rvest::html_text2() -> budget200

"https://www.the-numbers.com/movie/budgets/all/201" |> 
  rvest::read_html_live() -> budget_webpage3

budget_webpage3 |> 
  rvest::html_elements("b a") |> 
  rvest::html_text2() -> titles300

budget_webpage3 |> 
  rvest::html_elements("#page_filling_chart > center > table > tbody > tr > td:nth-child(4)") |> 
  rvest::html_text2() -> budget300

# Creating a table with this information:
scraped_titles_budget <- c(titles100, titles200, titles300)
scraped_budgets <- c(budget100, budget200, budget300)

#Removing unwanted rows from this table:
indices_to_remove <- c(101, 102, 203, 204, 305, 306)
modified_titles <- scraped_titles_budget[-indices_to_remove]


# Creating a table for the top 300 movies in terms of budget:
budget_table <- data.frame(
  Title = modified_titles,
  Budget = scraped_budgets
)

# Code to match the titles from the "top_100" table and "budget_table"; if there is a match, 
# then the "Budget" is added to a record in "top_100". 

top_100 <- top_100 |>
  dplyr::left_join(budget_table, by = "Title") |>
  dplyr::select(everything(), Budget)

# Cleaning the "Budget" column:
top_100 <- top_100 |>
  dplyr::mutate(
    `Budget` = stringr::str_remove(
      `Budget`, 
      "\\$"
    )
  )

# Loading in award data for each movie:
oscars_awards_with_totals <- readr::read_csv("Downloads/oscars_awards_with_totals.csv")

# Adding this data to the larger dataset:
top_100 <- dplyr::left_join(
  top_100,
  oscars_awards_with_totals,
  relationship = "many-to-many",
  by = "Title" 
) |> 
  dplyr::select(Title, oscars_awards_with_totals$Oscars_Won, oscars_awards_with_totals$Total_Nominations)

# Removing unwanted columns 
top_100 <- top_100 |>
  dplyr::select(-Oscars_Nominated, -Total_Wins)

# Saving the cleaned dataset as a CSV file
readr::write_csv(top_100, "top_100.csv")

# Creating table to show any missing variables in our combined dataset:
na_count <- top_100 |>
  dplyr::summarize(across(everything(), ~ sum(is.na(.)), .names = "na_count_{col}"))

print(na_count)

# Identifying rows with NAs and what column:
na_rows <- top_100 |>
  dplyr::mutate(row_number = dplyr::row_number()) |>
  dplyr::mutate(across(everything(), as.character)) |>
  tidyr::pivot_longer(cols = -row_number, names_to = "variable", values_to = "value") |>
  dplyr::filter(is.na(value)) |>
  dplyr::select(row_number, variable)

print(na_rows)
