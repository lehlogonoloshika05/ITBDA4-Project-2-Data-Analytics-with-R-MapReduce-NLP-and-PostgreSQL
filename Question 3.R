
library(rvest)      
library(httr)       
library(tm)         
library(ggplot2)    
library(wordcloud)  

web_link <- "https://en.wikipedia.org/wiki/Large_language_model"  
summary_length <- 5      


# ==============================================================
# 3.1  GET THE TEXT FROM THE WEBSITE
# ==============================================================


Sys.sleep(1)
response <- GET(web_link, user_agent("EduvosStudentProject/2 ITBDA ASSIGNMENT"))
stop_for_status(response)          
page <- read_html(response)


paragraphs <- html_text2(html_elements(page, "#mw-content-text p"))
paragraphs <- paragraphs[nchar(paragraphs) > 50]     

web_data <- data.frame(paragraph_number = 1:length(paragraphs),
                       text = paragraphs,
                       stringsAsFactors = FALSE)

cat("Page title:", html_text2(html_element(page, "h1")), "\n")
cat("Paragraphs collected:", nrow(web_data), "\n")
print(head(web_data, 3))
write.csv(web_data, "web_text_data_frame.csv", row.names = FALSE)


# ==============================================================
# 3.2  CLEAN THE TEXT 
# ==============================================================

# Step 1: join all paragraphs into one text
all_text <- paste(web_data$text, collapse = " ")

# Step 2: remove things that are not useful
all_text <- gsub("\\[[^]]*\\]", "", all_text)    
all_text <- gsub("http\\S+", " ", all_text)     
all_text <- gsub("\\s+", " ", all_text)         

# Step 3: split the text into sentences
all_text <- gsub("\\|", " ", all_text)             
all_text <- gsub("([.?!]) ", "\\1|", all_text)       
sentences <- strsplit(all_text, "|", fixed = TRUE)[[1]]
sentences <- sentences[nchar(sentences) > 80]        

get_clean_words <- function(sentence) {
  sentence <- tolower(sentence)                        
  sentence <- gsub("[^a-z ]", " ", sentence)            
  words <- strsplit(sentence, " ")[[1]]                 
  words <- words[words != ""]                           
  words <- words[!(words %in% stopwords("english"))]    
  words <- words[nchar(words) > 2]                     
  return(words)
}

clean_words <- get_clean_words(all_text)
word_counts <- sort(table(clean_words), decreasing = TRUE)

cat("\nSentences:", length(sentences), "\n")
cat("Words before cleaning:", length(strsplit(all_text, " ")[[1]]), "\n")
cat("Words after cleaning :", length(clean_words), "\n")

top_words <- data.frame(word = names(word_counts)[1:15],
                        count = as.numeric(word_counts[1:15]))
print(top_words)


# ==============================================================
# 3.3  SUMMARISE THE TEXT 
# ==============================================================

frequency_score <- c()
for (sentence in sentences) {
  words <- get_clean_words(sentence)
  total <- sum(word_counts[words], na.rm = TRUE)         
  frequency_score <- c(frequency_score, total / max(length(words), 1))   
}

best_1 <- order(frequency_score, decreasing = TRUE)[1:summary_length]
best_1 <- sort(best_1)                                  

cat("\n===== SUMMARY 1: WORD FREQUENCY =====\n")
for (i in best_1) cat("-", sentences[i], "\n")


number_of_sentences <- length(sentences)

sentence_words <- list()
for (i in 1:number_of_sentences) {
  sentence_words[[i]] <- unique(get_clean_words(sentences[i]))
}

shared_words <- matrix(0, number_of_sentences, number_of_sentences)
for (i in 1:(number_of_sentences - 1)) {
  for (j in (i + 1):number_of_sentences) {
    shared <- length(intersect(sentence_words[[i]], sentence_words[[j]]))
    shared_words[i, j] <- shared
    shared_words[j, i] <- shared
  }
}

similarity_score <- rowSums(shared_words)

best_2 <- order(similarity_score, decreasing = TRUE)[1:summary_length]
best_2 <- sort(best_2)

cat("\n===== SUMMARY 2: SENTENCE SIMILARITY =====\n")
for (i in best_2) cat("-", sentences[i], "\n")

cat("\nSentences chosen by BOTH techniques:", length(intersect(best_1, best_2)), "of", summary_length, "\n")
cat("Original text:", length(strsplit(all_text, " ")[[1]]), "words\n")
cat("Summary 1    :", length(strsplit(paste(sentences[best_1], collapse = " "), " ")[[1]]), "words\n")
cat("Summary 2    :", length(strsplit(paste(sentences[best_2], collapse = " "), " ")[[1]]), "words\n")


# ==============================================================
# 3.4  CHARTS
# ==============================================================

# Figure 1
figure_1 <- ggplot(top_words, aes(x = reorder(word, count), y = count)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Figure 1: Top 15 words on the page",
       x = "Word", y = "Number of times used")
print(figure_1)
ggsave("figure1_top_words.png", figure_1, width = 8, height = 6)

# Figure 2
png("figure2_wordcloud.png", width = 900, height = 700)      
wordcloud(names(word_counts), as.numeric(word_counts), max.words = 60, random.order = FALSE)
title("Figure 2: Word cloud")
dev.off()
wordcloud(names(word_counts), as.numeric(word_counts), max.words = 60, random.order = FALSE)  
title("Figure 2: Word cloud")

# Figure 3
top_10_a <- order(frequency_score, decreasing = TRUE)[1:10]
data_3 <- data.frame(sentence = paste("Sentence", top_10_a), score = frequency_score[top_10_a])
figure_3 <- ggplot(data_3, aes(x = reorder(sentence, score), y = score)) +
  geom_col(fill = "darkorange") +
  coord_flip() +
  labs(title = "Figure 3: Word-frequency score of the top 10 sentences",
       x = "Sentence number", y = "Score (average word count)")
print(figure_3)
ggsave("figure3_frequency_scores.png", figure_3, width = 8, height = 5)

# Figure 4
top_10_b <- order(similarity_score, decreasing = TRUE)[1:10]
data_4 <- data.frame(sentence = paste("Sentence", top_10_b), score = similarity_score[top_10_b])
figure_4 <- ggplot(data_4, aes(x = reorder(sentence, score), y = score)) +
  geom_col(fill = "darkgreen") +
  coord_flip() +
  labs(title = "Figure 4: Similarity score of the top 10 sentences",
       x = "Sentence number", y = "Score (total shared words with other sentences)")
print(figure_4)
ggsave("figure4_similarity_scores.png", figure_4, width = 8, height = 5)
