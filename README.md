# ITBDA4 Project 2 – Data Analytics with R, MapReduce, NLP and PostgreSQL

Student: Lehlogonolo Shika (EDUV4837982)

This folder holds the code, data, results and report for the four questions of Project 2. Everything is written in R and run in RStudio. Question 4 also uses PostgreSQL (pgAdmin).

## Contents at a glance

| Question | Topic                                                      | Script                                      | Main outputs                                                                                            |
| -------- | ---------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 1        | Keyword search with MapReduce                              | `Question 1.R`                              | `output_results.csv`                                                                                    |
| 2        | Topic modelling (LDA) of news articles                     | `Question 2.R`                              | `top_words_per_topic.csv`, `topics_per_document.csv`, `bar_chart.png`, `word_clouds.png`, `heatmap.png` |
| 3        | WebText API: scrape, clean and summarise a web page        | `Question 3.R`                              | `web_text_data_frame.csv`, `figure1_top_words.png` to `figure4_similarity_scores.png`                   |
| 4        | ETL: scrape, clean, load into PostgreSQL, analyse with SQL | `Question 4.R` and `QUESTION4_POSTGRES.sql` | `raw_hn_posts.csv`, `clean_hn_posts.csv`, `insert_hn_posts.sql`                                         |

The written report with the results and their interpretation is `ITBDA4-14 ASSIGNMENT LEHLOGONOLO SHIKA EDUV4837982.pdf`.

## Main results

- **Q1:** the keyword "africa" occurs 22 times in 4 of the 7 documents (doc1: 3, doc2: 5, doc3: 9, doc5: 5). Doc4, doc6 and doc7 have no matches. The result is in `output_results.csv`.
- **Q2:** LDA with 3 topics: government and coalitions (Topic 1), public-service accountability (Topic 2), and Eskom, police and weather news (Topic 3). Four articles lean to Topic 3, four to Topic 2 and two to Topic 1. The tables are in `top_words_per_topic.csv` and `topics_per_document.csv`, and the charts are `bar_chart.png`, `word_clouds.png` and `heatmap.png`.
- **Q3:** a Wikipedia article on large language models gives 113 paragraphs and 272 sentences (over 80 characters). Two extractive summaries (word frequency and sentence similarity) agree on one of five sentences, the opening definition. Charts are `figure1_top_words.png`, `figure2_wordcloud.png`, `figure3_frequency_scores.png` and `figure4_similarity_scores.png`.
- **Q4:** 60 Hacker News posts were scraped, cleaned and loaded into PostgreSQL. SQL shows that a number in the title and the title length do not reliably predict attention.

## Folder layout

```
ITBDA4-14 ASSIGNMENT LEHLOGONOLO SHIKA EDUV4837982/
│
├── ITBDA4-14 ASSIGNMENT LEHLOGONOLO SHIKA EDUV4837982.pdf   the written report
│
├── Question 1.R          Q1 script
├── Question 2.R          Q2 script
├── Question 3.R          Q3 script
├── Question 4.R          Q4 script (scrape and clean)
├── QUESTION4_POSTGRES.sql   Q4 PostgreSQL script (table, checks, analysis)
│
├── input/                Q1: doc1.txt ... doc7.txt (documents for the keyword search)
├── news.zip              Q2: the 10 South African news articles (zipped)
├── news/sa_news/         Q2: the same articles, unzipped (news_1.txt ... news_10.txt)
│
├── output_results.csv            Q1 result
├── top_words_per_topic.csv       Q2 result
├── topics_per_document.csv       Q2 result
├── bar_chart.png                 Q2 chart
├── word_clouds.png               Q2 chart
├── heatmap.png                   Q2 chart
├── web_text_data_frame.csv       Q3 scraped paragraphs
├── figure1_top_words.png         Q3 chart
├── figure2_wordcloud.png         Q3 chart
├── figure3_frequency_scores.png  Q3 chart
├── figure4_similarity_scores.png Q3 chart
├── raw_hn_posts.csv              Q4 scraped data
├── clean_hn_posts.csv            Q4 cleaned data
└── insert_hn_posts.sql           Q4 INSERT statements for PostgreSQL
```

## How to run

1. Open RStudio and install the packages once:
   ```r
   install.packages(c("tm", "topicmodels", "ggplot2", "wordcloud", "rvest", "httr", "xml2", "rstudioapi"))
   ```
   `rstudioapi` is optional. Q1 uses it for the pop-up box and falls back to the console without it.
2. Open a script from the main folder, set the working directory (Session > Set Working Directory > To Source File Location) and click **Source**. Keep the scripts in the same folder as `input` and `news.zip`, because they use relative paths.
   - **Q1** asks for the keyword (the default is "africa") and reads the documents from the `input` folder. Any keyword can be typed. If `input` is not found on Windows, a window opens so you can pick the folder. The result is written to `output_results.csv`.
   - **Q2** unzips `news.zip` into `news` and reads every `.txt` file inside it. It uses 3 topics and a fixed seed (1234), so the results are repeatable. It saves the two CSV files and the three charts.
   - **Q3** needs an internet connection. It downloads one Wikipedia page (the link is set at the top of the script) and writes 5 sentence summaries with two techniques. It saves `web_text_data_frame.csv` and the four figures.
   - **Q4** needs an internet connection. It waits 30 seconds between its two pages, so it takes about a minute. It saves `raw_hn_posts.csv`, `clean_hn_posts.csv` and `insert_hn_posts.sql` in the working directory.

## Question 4: loading the data into PostgreSQL (pgAdmin)

1. Run `Question 4.R`. It creates `raw_hn_posts.csv`, `clean_hn_posts.csv` and `insert_hn_posts.sql`. Ready-made copies are already in this folder.
2. In pgAdmin open the Query Tool on a database, open `QUESTION4_POSTGRES.sql`, select **Part A** and press F5 to create the table `hn_posts`.
3. Click the folder icon (Open File), choose `insert_hn_posts.sql` and press F5. This empties the table (`TRUNCATE`) and inserts the 60 rows.
4. Run **Part C** (row count, first rows and author check), then run **Investigation 1** (does a number in the title matter) and **Investigation 2** (does the length of the title matter) from **Part D**, each on its own.

## Fair use of web scraping

- Q3 downloads one Wikipedia article, waiting between requests. The text is CC BY-SA and is credited.
- Q4 downloads two Hacker News front pages with a 30 second wait between them, which is the crawl delay in its robots.txt.
- Both scripts identify themselves with a User-Agent (`EduvosStudentProject/2 ITBDA ASSIGNMENT`) and the data is used for study only.

## Source of the data

- Q1 documents: provided with the project brief (`input/doc1.txt` to `doc7.txt`).
- Q2 articles: provided with the project brief (`news.zip`, South African government news).
- Q3: Wikipedia, "Large language model" (CC BY-SA).
- Q4: Hacker News front pages (news.ycombinator.com), scraped on 16 November 2026. A new scrape gives different posts and different numbers.
