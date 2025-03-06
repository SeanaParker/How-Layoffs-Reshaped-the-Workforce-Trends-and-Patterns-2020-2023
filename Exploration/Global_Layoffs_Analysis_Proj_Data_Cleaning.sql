# Global Layoffs Analysis Project (Data Cleaning)
-- https://www.kaggle.com/datasets/swaptr/layoffs-2022
    
-- Cleaning includes:
-- 1. Removing duplicates
-- 2. Standardizing fields
-- 3. Handling null or blank values
-- 4. Dropping unnecessary columns

-- Create a staging table to keep the raw data intact
CREATE TABLE layoffs_staging LIKE layoffs;  -- Copies the structure of the original table
SELECT * FROM layoffs_staging;  -- Quick check to confirm structure

-- Copy data from layoffs table to staging table
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- Identify duplicate records by assigning a row number
WITH duplicates AS (
    SELECT *, 
        ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
        `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicates WHERE row_num > 1;

-- To remove duplicates, create another staging table with an extra row_num column
CREATE TABLE layoffs_staging2 (
  `company` varchar(29),
  `location` varchar(16),
  `industry` varchar(15),
  `total_laid_off` varchar(5),
  `percentage_laid_off` varchar(6),
  `date` varchar(10),
  `stage` varchar(14),
  `country` varchar(20),
  `funds_raised_millions` varchar(6),
  `row_num` INT
);

-- Insert records with row numbers added for easy duplicate identification
INSERT INTO layoffs_staging2
SELECT *, 
    ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
    stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Double-check duplicate records
SELECT * FROM layoffs_staging2 WHERE row_num > 1;

-- Remove extra duplicate rows, keeping only one per set
DELETE FROM layoffs_staging2 WHERE row_num > 1;

-- Trim spaces in company names to keep formatting consistent
UPDATE layoffs_staging2 SET company = TRIM(company);

-- Fix inconsistencies in industry names (e.g., different versions of 'Crypto')
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

-- Some country names have formatting issues (like trailing periods), let's clean them up
UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE country LIKE 'United States%';

-- Convert date field from TEXT to DATE so we can analyze it properly
UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d') WHERE `date` IS NOT NULL AND `date` != '';
ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;

-- Check for null or blank industries that we might be able to fill in
SELECT DISTINCT industry FROM layoffs_staging2 WHERE industry IS NULL OR industry = '';

-- Fill missing industry values by matching company and location to existing records
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '') AND t2.industry IS NOT NULL;

-- Some rows have no layoff data at all—those aren't useful, so let's remove them
DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- The row_num column is no longer needed, let's drop it
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;

-- Final check to ensure data is cleaned
SELECT * FROM layoffs_staging2;
