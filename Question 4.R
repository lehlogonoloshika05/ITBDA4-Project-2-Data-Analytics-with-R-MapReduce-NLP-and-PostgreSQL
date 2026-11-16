library(rvest)   
library(httr)    
library(xml2)    

page_links <- c("https://news.ycombinator.com/news?p=1",
                "https://news.ycombinator.com/news?p=2")    

cat("Files will be saved in:", getwd(), "\n")


# ==============================================================
# 4.1  EXTRACT: SCRAPE THE POSTS AND BUILD A DATA FRAME
# ==============================================================


all_posts <- data.frame()

for (page_link in page_links) {
  
  response <- GET(page_link, user_agent("EduvosStudentProject/2 ITBDA ASSIGNMENT"))
  stop_for_status(response)
  page <- read_html(response)
  
  post_rows <- html_elements(page, "tr.athing")      
  
  for (post_row in post_rows) {
    
    details_row <- xml_find_first(post_row, "following-sibling::tr[1]")
    
    title_link   <- html_element(post_row, "span.titleline > a")
    author_link  <- html_element(details_row, xpath = ".//a[contains(@href, 'user?id=')]")
    all_links    <- html_elements(details_row, "a")
    comments_raw <- NA
    if (length(all_links) > 0) comments_raw <- html_text(all_links[length(all_links)])
    
    new_post <- data.frame(
      post_id      = html_attr(post_row, "id"),
      title_raw    = html_text(title_link),
      link         = html_attr(title_link, "href"),
      points_raw   = html_text(html_element(details_row, "span.score")),
      author       = html_text(author_link),
      age_raw      = html_text(html_element(details_row, "span.age a")),
      comments_raw = comments_raw,
      stringsAsFactors = FALSE
    )
    all_posts <- rbind(all_posts, new_post)
  }
  
  if (page_link != page_links[length(page_links)]) Sys.sleep(30)   
}

cat("Posts scraped:", nrow(all_posts), "\n")
if (nrow(all_posts) < 20) stop("Fewer than 20 posts found - the page layout may have changed")



all_posts$post_type <- "Other"
all_posts$post_type[grepl("^Show HN", all_posts$title_raw)]          <- "Show HN"
all_posts$post_type[grepl("^Ask HN", all_posts$title_raw)]           <- "Ask HN"
all_posts$post_type[grepl("^(Tell|Launch) HN", all_posts$title_raw)] <- "Tell/Launch HN"

all_posts$domain <- sub("^https?://(www\\.)?([^/]+).*", "\\2", all_posts$link)
all_posts$domain[!grepl("^https?://", all_posts$link)] <- NA

get_number <- function(text, word) {
  found  <- grepl(paste0("^[0-9]+.?", word), text)
  number <- suppressWarnings(as.numeric(sub(paste0("^([0-9]+).?", word, ".*"), "\\1", text)))
  number[!found] <- NA
  return(number)
}
all_posts$points     <- get_number(all_posts$points_raw, "point")
all_posts$comments   <- get_number(all_posts$comments_raw, "comment")
all_posts$age_number <- get_number(all_posts$age_raw, "")

all_posts$title_words <- lengths(strsplit(trimws(all_posts$title_raw), "\\s+"))

all_posts$title_has_number <- grepl("[0-9]", all_posts$title_raw)

all_posts$scraped_at <- format(Sys.time(), "%Y-%m-%d %H:%M")

write.csv(all_posts, "raw_hn_posts.csv", row.names = FALSE)

cat("\nMissing values in the raw data:\n")
print(colSums(is.na(all_posts[, c("title_raw", "link", "points_raw", "author",
                                  "comments_raw", "age_raw", "domain")])))
cat("\nDuplicate post ids:", sum(duplicated(all_posts$post_id)), "\n")
cat("\nForms of the comments text:\n")
print(table(gsub("[0-9]+", "N", all_posts$comments_raw)))
cat("\nForms of the age text:\n")
print(table(gsub("[0-9]+", "N", all_posts$age_raw)))
print(head(all_posts[, c("title_raw", "points_raw", "author", "comments_raw", "age_raw", "domain")], 6))


# ==============================================================
# 4.2  TRANSFORM: CLEAN AND IMPUTE, THEN SAVE AS A CSV
# ==============================================================
clean_posts <- all_posts
cat("\n--- Cleaning log ---\n")

# Step 1: remove duplicate posts
cat("Duplicates removed:", sum(duplicated(clean_posts$post_id)), "\n")
clean_posts <- clean_posts[!duplicated(clean_posts$post_id), ]

# Step 2: remove posts with no title
cat("Posts without a title removed:", sum(is.na(clean_posts$title_raw)), "\n")
clean_posts <- clean_posts[!is.na(clean_posts$title_raw), ]

# Step 3: clean the title text
clean_posts$title <- gsub("[ \t\n]", " ", clean_posts$title_raw)
clean_posts$title <- trimws(gsub("\\s+", " ", clean_posts$title))

# Step 4: comments.
is_discuss <- grepl("^discuss", clean_posts$comments_raw)
cat("'discuss' set to 0 comments:", sum(is_discuss), "\n")
clean_posts$comments[is_discuss] <- 0
cat("Missing comments set to 0:", sum(is.na(clean_posts$comments)), "\n")
clean_posts$comments[is.na(clean_posts$comments)] <- 0

# Step 5: age text into hours
clean_posts$age_hours <- NA
is_minute <- grepl("minute", clean_posts$age_raw)
is_hour   <- grepl("hour",   clean_posts$age_raw)
is_day    <- grepl("day",    clean_posts$age_raw)
clean_posts$age_hours[is_minute] <- clean_posts$age_number[is_minute] / 60
clean_posts$age_hours[is_hour]   <- clean_posts$age_number[is_hour]
clean_posts$age_hours[is_day]    <- clean_posts$age_number[is_day] * 24
clean_posts$age_hours <- round(clean_posts$age_hours, 2)

clean_posts$is_job <- is.na(clean_posts$points_raw)
cat("Job adverts found:", sum(clean_posts$is_job), "\n")

for (type in unique(clean_posts$post_type)) {
  rows_of_type <- clean_posts$post_type == type
  middle_value <- median(clean_posts$points[rows_of_type & !clean_posts$is_job], na.rm = TRUE)
  fill_rows    <- rows_of_type & is.na(clean_posts$points) & !clean_posts$is_job
  clean_posts$points[fill_rows] <- middle_value
  if (sum(fill_rows) > 0) cat("Points filled with the median for", type, ":", sum(fill_rows), "\n")
}
clean_posts$points[clean_posts$is_job] <- 0   

#   missing age into  median age
cat("Missing ages filled with the median:", sum(is.na(clean_posts$age_hours)), "\n")
clean_posts$age_hours[is.na(clean_posts$age_hours)] <- median(clean_posts$age_hours, na.rm = TRUE)

cat("Missing websites filled:", sum(is.na(clean_posts$domain)), "\n")
clean_posts$domain[is.na(clean_posts$domain)] <- "news.ycombinator.com"

cat("Missing authors filled:", sum(is.na(clean_posts$author)), "\n")
if (sum(is.na(clean_posts$author)) > 0.5 * nrow(clean_posts)) {
  cat("WARNING: most authors are missing - the author scrape may have failed\n")
}
clean_posts$author[is.na(clean_posts$author)] <- "unknown"

clean_posts$points_per_hour <- round(clean_posts$points / pmax(clean_posts$age_hours, 0.25), 2)

clean_posts <- clean_posts[, c("post_id", "title", "post_type", "domain", "author",
                               "points", "comments", "age_hours", "title_words",
                               "title_has_number", "points_per_hour", "is_job", "scraped_at")]
write.csv(clean_posts, "clean_hn_posts.csv", row.names = FALSE)

cat("\n===== CLEANED DATA =====\n")
cat("Rows:", nrow(clean_posts), "  Columns:", ncol(clean_posts), "\n")
cat("Missing values left:", sum(is.na(clean_posts)), "\n")
print(summary(clean_posts[, c("points", "comments", "age_hours", "title_words", "points_per_hour")]))
print(table(clean_posts$post_type))
cat("Most frequent authors:\n")
print(head(sort(table(clean_posts$author), decreasing = TRUE), 5))
print(head(clean_posts, 6))


# ==============================================================
# 4.3  PREPARE FOR POSTGRESQL
# ==============================================================


text_value <- function(x) paste0("'", gsub("'", "''", x), "'")   

insert_lines <- paste0(
  "INSERT INTO hn_posts VALUES (",
  clean_posts$post_id, ", ",
  text_value(clean_posts$title), ", ",
  text_value(clean_posts$post_type), ", ",
  text_value(clean_posts$domain), ", ",
  text_value(clean_posts$author), ", ",
  clean_posts$points, ", ",
  clean_posts$comments, ", ",
  clean_posts$age_hours, ", ",
  clean_posts$title_words, ", ",
  clean_posts$title_has_number, ", ",
  clean_posts$points_per_hour, ", ",
  clean_posts$is_job, ", ",
  text_value(clean_posts$scraped_at),
  ");")

sql_file <- file("insert_hn_posts.sql", open = "w", encoding = "UTF-8")
writeLines(c("TRUNCATE hn_posts;", insert_lines), sql_file)
close(sql_file)

cat("\nSaved in", getwd(), ":\n")
cat(" - raw_hn_posts.csv\n - clean_hn_posts.csv\n -", length(insert_lines), "INSERT lines in insert_hn_posts.sql\n")