
-- --------------------------------------------------------------
-- PART A: create the table 
-- --------------------------------------------------------------
DROP TABLE IF EXISTS hn_posts;

CREATE TABLE hn_posts (
    post_id          BIGINT PRIMARY KEY,
    title            TEXT NOT NULL,
    post_type        TEXT,
    domain           TEXT,
    author           TEXT,
    points           NUMERIC(10,1),
    comments         INTEGER,
    age_hours        NUMERIC(8,2),
    title_words      INTEGER,
    title_has_number BOOLEAN,
    points_per_hour  NUMERIC(10,2),
    is_job           BOOLEAN,
    scraped_at       TIMESTAMP
);


-- --------------------------------------------------------------
-- PART B: load the data 
--   1. In the Query Tool click the folder icon (Open File)
--   2. Choose insert_hn_posts.sql 
--   3. Press F5.
-- --------------------------------------------------------------


-- --------------------------------------------------------------
-- PART C: check the data
-- --------------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM hn_posts;

SELECT * FROM hn_posts LIMIT 5;

-- Were the authors scraped? (many 'unknown' = something went wrong)
SELECT author, COUNT(*) AS posts
FROM hn_posts
GROUP BY author
ORDER BY posts DESC
LIMIT 5;


-- ==============================================================
-- PART D, INVESTIGATION 1: does a number in the title matter
-- ==============================================================
SELECT
    title_has_number,
    COUNT(*)                                                 AS posts,
    ROUND(AVG(points), 1)                                    AS avg_points,
    ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY points) AS NUMERIC), 1) AS median_points,
    ROUND(AVG(comments), 1)                                  AS avg_comments,
    ROUND(AVG(points_per_hour), 1)                           AS avg_points_per_hour
FROM hn_posts
WHERE is_job = FALSE
GROUP BY title_has_number
ORDER BY title_has_number DESC;


-- ==============================================================
-- PART D, INVESTIGATION 2: does the length of the title matter?
-- ==============================================================
SELECT
    CASE
        WHEN title_words <= 5  THEN '1. Short (1-5 words)'
        WHEN title_words <= 10 THEN '2. Medium (6-10 words)'
        ELSE                        '3. Long (11+ words)'
    END                                  AS title_length,
    COUNT(*)                             AS posts,
    ROUND(AVG(points), 1)                AS avg_points,
    ROUND(AVG(comments), 1)              AS avg_comments,
    ROUND(AVG(points_per_hour), 1)       AS avg_points_per_hour
FROM hn_posts
WHERE is_job = FALSE
GROUP BY title_length
ORDER BY title_length;

-- One number for the link between title length and points
SELECT ROUND(CAST(CORR(title_words, points) AS NUMERIC), 2) AS correlation_title_words_points
FROM hn_posts
WHERE is_job = FALSE;
