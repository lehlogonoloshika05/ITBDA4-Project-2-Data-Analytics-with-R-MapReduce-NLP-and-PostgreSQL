library(tm)           
library(topicmodels)  
library(ggplot2)      
library(wordcloud)    

number_of_topics <- 3     
words_per_topic  <- 10    

unzip("news.zip", exdir = "news")     


# ==============================================================
# 2.1  DATA FRAME AND PREPROCESSING
# ==============================================================

file_paths <- list.files("news", pattern = "\\.txt$", recursive = TRUE, full.names = TRUE)

file_names <- basename(file_paths)
contents <- c()
for (path in file_paths) {
  lines <- readLines(path, warn = FALSE)
  contents <- c(contents, paste(lines, collapse = " "))   
}

news_data <- data.frame(file_name = file_names, content = contents, stringsAsFactors = FALSE)
print(news_data$file_name)

clean_text <- news_data$content
clean_text <- tolower(clean_text)                                
clean_text <- gsub("http\\S+", " ", clean_text)                  
clean_text <- gsub("[^a-z ]", " ", clean_text)                   

extra_words <- c("said", "also", "will", "can", "south", "africa", "african", "africans")
clean_text <- removeWords(clean_text, c(stopwords("english"), extra_words)) 

clean_text <- gsub("\\b[a-z]{1,2}\\b", " ", clean_text)         
clean_text <- gsub("\\s+", " ", clean_text)                      
news_data$clean_content <- trimws(clean_text)

cat("BEFORE:", substr(news_data$content[1], 1, 100), "\n")
cat("AFTER :", substr(news_data$clean_content[1], 1, 100), "\n")

corpus <- VCorpus(VectorSource(news_data$clean_content))
word_matrix <- DocumentTermMatrix(corpus)

if (any(rowSums(as.matrix(word_matrix)) == 0)) stop("A file is empty after cleaning - remove it and run again")


# ==============================================================
# 2.2  LDA TOPIC MODEL
# ==============================================================

lda_model <- LDA(word_matrix, k = number_of_topics, method = "Gibbs", control = list(seed = 1234))

word_probabilities <- posterior(lda_model)$terms

top_words <- data.frame()
for (topic_number in 1:number_of_topics) {
  sorted_words <- sort(word_probabilities[topic_number, ], decreasing = TRUE)
  best_words <- sorted_words[1:words_per_topic]
  one_topic <- data.frame(topic = paste("Topic", topic_number),
                          word = names(best_words),
                          probability = round(as.numeric(best_words), 4))
  top_words <- rbind(top_words, one_topic)
}
print(top_words)

topics_per_document <- round(posterior(lda_model)$topics, 3)
rownames(topics_per_document) <- news_data$file_name
colnames(topics_per_document) <- paste("Topic", 1:number_of_topics)
print(topics_per_document)

write.csv(top_words, "top_words_per_topic.csv", row.names = FALSE)
write.csv(topics_per_document, "topics_per_document.csv")


# ==============================================================
# 2.3  CHARTS
# ==============================================================

bar_chart <- ggplot(top_words, aes(x = word, y = probability, fill = topic)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~ topic, scales = "free_y") +
  labs(title = "Top words per topic", x = "Word", y = "Probability in the topic")
print(bar_chart)
ggsave("bar_chart.png", bar_chart, width = 10, height = 5)

png("word_clouds.png", width = 1200, height = 400)              
par(mfrow = c(1, number_of_topics))
for (topic_number in 1:number_of_topics) {
  words <- top_words[top_words$topic == paste("Topic", topic_number), ]
  wordcloud(words$word, words$probability, scale = c(3, 0.8), min.freq = 0)
  title(paste("Topic", topic_number))
}
dev.off()

par(mfrow = c(1, number_of_topics))                              
for (topic_number in 1:number_of_topics) {
  words <- top_words[top_words$topic == paste("Topic", topic_number), ]
  wordcloud(words$word, words$probability, scale = c(3, 0.8), min.freq = 0)
  title(paste("Topic", topic_number))
}
par(mfrow = c(1, 1))

heatmap_data <- data.frame(file  = rep(rownames(topics_per_document), number_of_topics),
                           topic = rep(colnames(topics_per_document), each = nrow(topics_per_document)),
                           share = as.vector(topics_per_document))
heatmap_chart <- ggplot(heatmap_data, aes(x = topic, y = file, fill = share)) +
  geom_tile() +
  geom_text(aes(label = share)) +
  labs(title = "Topic share per document", x = "Topic", y = "File")
print(heatmap_chart)
ggsave("heatmap.png", heatmap_chart, width = 7, height = 5)