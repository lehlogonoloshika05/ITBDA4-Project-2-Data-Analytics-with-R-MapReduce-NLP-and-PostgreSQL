# ==============================================================
# 1.4  CONFIGURATION
# ==============================================================

input_folder <- "input"

if (!dir.exists(input_folder) && .Platform$OS.type == "windows") {
  input_folder <- choose.dir(caption = "Select the folder with doc1.txt ... doc7.txt")
}
if (is.na(input_folder) || !dir.exists(input_folder)) {
  stop("Cannot find the document folder. R is working in: ", getwd())
}

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  keyword <- rstudioapi::showPrompt("Keyword search", "Enter the keyword:", "africa")
} else {
  keyword <- readline("Enter the keyword: ")
}
if (is.null(keyword) || keyword == "") keyword <- "africa"   
keyword <- tolower(keyword)                                 

output_file <- "output_results.csv"


# ==============================================================
# 1.2  MAPPER
# ==============================================================
map_function <- function(file_path) {
  document_name <- basename(file_path)
  lines <- readLines(file_path, warn = FALSE, encoding = "UTF-8")
  
  hits <- data.frame(document = character(), row = numeric(), column = numeric())
  
  for (row in seq_along(lines)) {                     
    line <- tolower(lines[row])                       
    found <- gregexpr(keyword, line, fixed = TRUE)[[1]] 
    if (found[1] != -1) {                              
      for (column in found) {
        new_hit <- data.frame(document = document_name, row = row, column = column)
        hits <- rbind(hits, new_hit)
      }
    }
  }
  return(hits)
}


# ==============================================================
# 1.3  REDUCER
# ==============================================================
reduce_function <- function(hits) {
  hits <- hits[order(hits$row, hits$column), ]        
  positions <- paste0("(", hits$row, ",", hits$column, ")", collapse = " ")
  data.frame(document = hits$document[1], count = nrow(hits), positions = positions)
}


# ==============================================================
# 1.5  RUN
# ==============================================================
files <- list.files(input_folder, pattern = "\\.txt$", full.names = TRUE)
if (length(files) == 0) stop("No .txt files found in ", input_folder)

# Step 1 - MAP
all_hits <- do.call(rbind, lapply(files, map_function))
if (nrow(all_hits) == 0) stop("The keyword '", keyword, "' was not found")

# Step 2 - SHUFFLE
hits_by_document <- split(all_hits, all_hits$document)

# Step 3 - REDUCE
result <- do.call(rbind, lapply(hits_by_document, reduce_function))
rownames(result) <- NULL


# ==============================================================
# 1.6  RESULT
# ==============================================================
cat("\nKeyword:", keyword, "\n\n")
print(result, right = FALSE)
write.csv(result, output_file, row.names = FALSE)
cat("\nResults saved to", output_file, "\n")