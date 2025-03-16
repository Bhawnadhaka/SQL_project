# 🍽️ Swiggy Data Cleaning and Transformation SQL Queries

## 🎯 Overview
This README showcases a complete SQL workflow to clean and transform a Swiggy dataset, ensuring data consistency, accuracy, and readiness for analysis. The dataset includes restaurant details like hotel names, ratings, delivery times, food types, locations, and offers.

---

## 🛠️ Setup: Database and Table Creation

### 🏗️ 1. Create and Select the Database
```sql
CREATE DATABASE swiggydata;
USE swiggydata;
```

### 🗂️ 2. Define the Table Schema
```sql
DROP TABLE IF EXISTS swiggy_table;
CREATE TABLE swiggy_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_name VARCHAR(255),
    rating VARCHAR(255),
    time_minutes VARCHAR(255),
    food_type VARCHAR(255),
    location VARCHAR(255),
    offer_above VARCHAR(255),
    offer_percentage VARCHAR(255)
);
```

### 🔒 3. Ensure File Load Permissions
```sql
SHOW VARIABLES LIKE 'secure_file_priv';
SHOW VARIABLES LIKE 'local_infile';
```

### 📥 4. Load Data from CSV
```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/swiggy_cleaned.csv'
INTO TABLE swiggy_table
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(hotel_name, rating, time_minutes, food_type, location, offer_above, offer_percentage);
```

---

## 🔍 Data Exploration

### 🔎 1. View Raw Data
```sql
SELECT * FROM swiggy_table;
```

### 📊 2. Identify Missing Values
```sql
SELECT
    SUM(CASE WHEN hotel_name='' THEN 1 ELSE 0 END) AS hotel_name_missing,
    SUM(CASE WHEN rating='' THEN 1 ELSE 0 END) AS rating_missing,
    SUM(CASE WHEN time_minutes='' THEN 1 ELSE 0 END) AS time_minutes_missing,
    SUM(CASE WHEN food_type='' THEN 1 ELSE 0 END) AS food_type_missing,
    SUM(CASE WHEN location='' THEN 1 ELSE 0 END) AS location_missing,
    SUM(CASE WHEN offer_above='' THEN 1 ELSE 0 END) AS offer_above_missing,
    SUM(CASE WHEN offer_percentage='' THEN 1 ELSE 0 END) AS offer_percentage_missing
FROM swiggy_table;
```

### 🛠️ 3. Extract Column Names
```sql
SELECT column_name FROM information_schema.columns WHERE table_name = 'swiggy_table';
```

---

## 🧼 Data Cleaning

### 🕒 1️⃣ Fix `time_minutes` Column

- **Isolate Rows with Time Data in Rating Column:**
```sql
CREATE TABLE clean AS SELECT * FROM swiggy_table WHERE rating LIKE '%mins%';
```

- **Extract Time Value:**
```sql
DELIMITER $$
CREATE FUNCTION f_name(a VARCHAR(100)) RETURNS VARCHAR(100) DETERMINISTIC
BEGIN
    DECLARE l INT;
    DECLARE s VARCHAR(100);
    SET l = LOCATE(' ', a);
    SET s = IF(l > 0, LEFT(a, l - 1), a);
    RETURN s;
END $$
DELIMITER ;
```

- **Clean and Update Time Data:**
```sql
UPDATE swiggy_table AS s
INNER JOIN clean AS c ON s.hotel_name = c.hotel_name
SET s.time_minutes = f_name(c.rating);
```

---

### ⭐ 2️⃣ Clean `rating` Column

- **Replace Invalid Ratings with Location Averages:**
```sql
UPDATE swiggy_table AS t
JOIN (
    SELECT location, ROUND(AVG(rating), 2) AS avg_rating
    FROM swiggy_table
    WHERE rating NOT LIKE '%mins%'
    GROUP BY location
) AS avg_table ON t.location = avg_table.location
SET t.rating = avg_table.avg_rating
WHERE t.rating LIKE '%mins%';
```

---

### 📍 3️⃣ Standardize `location` Names

- **Fix Spelling and Ensure Consistency:**
```sql
UPDATE swiggy_table SET location = 'Kandivali East' WHERE location LIKE '%East%';
UPDATE swiggy_table SET location = 'Kandivali West' WHERE location LIKE '%West%';
UPDATE swiggy_table SET location = 'Kandivali Wast' WHERE location LIKE '%W%';
```

---

### 🎁 4️⃣ Clean `offer_percentage` Column

- **Set Missing Offers to 0:**
```sql
UPDATE swiggy_table SET offer_percentage = 0 WHERE offer_above = 'not_available';
```

---

### 🍔 5️⃣ Normalize `food_type` Column

- **Extract Unique Food Types:**
```sql
SELECT DISTINCT food FROM (
    SELECT *, SUBSTRING_INDEX(SUBSTRING_INDEX(food_type, ',', numbers.n), ',', -1) AS food
    FROM swiggy_table
    JOIN (
        SELECT 1 + a.N + b.N * 10 AS n
        FROM (
            SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
        ) AS a CROSS JOIN (
            SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
        ) AS b
    ) AS numbers
    ON CHAR_LENGTH(food_type) - CHAR_LENGTH(REPLACE(food_type, ',', '')) >= numbers.n - 1
) a;
```

---

## ✅ Final Check

- **Review the Cleaned Dataset:**
```sql
SELECT * FROM swiggy_table;
```

---

## 🎉 Conclusion
Your Swiggy dataset is now **spotless, normalized, and analysis-ready** — perfect for insights or machine learning projects. Happy querying! 🚀✨

