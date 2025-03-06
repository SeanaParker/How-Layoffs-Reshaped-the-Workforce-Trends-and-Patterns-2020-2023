-- Global Layoffs Analysis Project (Exploratory Data Analysis)


-- Find the largest single layoff on record (not cumulative).
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IN (
    SELECT MAX(total_laid_off) FROM layoffs_staging2
);
-- Google had the largest single layoff on record with 12,000 employees laid off on Jan 20, 2023, representing 6% of its workforce. This layoff occurred in the Post-IPO stage and was based in the SF Bay Area, United States, with Google having raised $26B in funds.

-- Identify companies that shut down, ranked by number of layoffs.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;
-- Katerra (2,434) had the largest shutdown layoffs, followed by Butler Hospitality (1,000) and Deliv (669). Other notable closures include Jump (500), SEND (300), and Britishvolt (206).
-- Many of these closures occurred in industries that may have been affected by broader economic trends.

-- Identify companies that shut down, ranked by highest funds raised.
SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- Britishvolt raised the most funds before closing ($2.4B), followed by Quibi ($1.8B) and Deliveroo Australia ($1.7B). Katerra ($1.6B) and BlockFi ($1B) were also among the highest-funded companies that shut down.
-- This may indicate challenges faced by high-growth, high-burn-rate startups.

-- List total layoffs per company in descending order.
SELECT company, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
-- Amazon had the highest total layoffs (18,150), followed by Google (12,000) and Meta (11,000). Salesforce (10,090) and Microsoft (10,000) were also among the companies with the highest layoffs.
-- These layoffs may have been influenced by post-pandemic cost-cutting and restructuring efforts.

-- Check the date range of layoffs.
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
-- Layoffs range from March 11, 2020, to March 6, 2023.
-- The majority of layoffs occurred post-2021, possibly due to economic shifts following the pandemic.

-- List total layoffs per industry in descending order.
SELECT industry, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
-- Consumer sector had the most layoffs (45,182), followed by Retail (43,613) and 'Other' (36,289). Transportation (33,748) and Finance (28,344) also had significant layoffs.
-- High layoffs in these industries may indicate shifts in consumer behavior and market trends.

-- List total layoffs per country in descending order.
SELECT country, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
-- The U.S. had the most layoffs (256,559), followed by India (35,993) and the Netherlands (17,220). Sweden (11,264) and Brazil (10,391) also saw significant layoffs.
-- The U.S. had the highest layoffs, which could be related to its large tech and corporate job market.

-- List total layoffs per year in descending order.
SELECT YEAR(`date`), SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
-- Layoffs peaked in 2022 with 160,661 recorded job losses, a significant increase from 2021 (15,823) and 2020 (80,998). 
-- The 2023 total (125,677) is already high despite covering only the first few months, suggesting an ongoing wave of layoffs.


-- Compare layoff distributions across company stages.
SELECT stage, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_layoffs DESC;
-- Post-IPO companies had the highest layoffs (204,132), followed by Unknown (40,716) and Acquired (27,576). Series C (20,017) and Series D (19,225) also saw significant layoffs.
-- Layoffs at post-IPO firms may suggest challenges in sustaining profitability after going public.

-- Find the highest-impact stages using a weighted average.
SELECT stage, 
       ROUND(SUM(total_laid_off * percentage_laid_off) / SUM(total_laid_off), 4) AS weighted_avg_layoff
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL AND percentage_laid_off > 0.01  -- Exclude unrealistically small percentages
GROUP BY stage
ORDER BY weighted_avg_layoff DESC;
-- Weighted analysis shows that Seed-stage companies had the highest relative impact of layoffs (69.95%), 
-- followed by Series A (40.46%), Series B (38.76%), and Unknown (33.44%). 
-- Series C (32.06%) and Acquired companies (28.42%) also had significant workforce reductions.
-- Lower layoff impact was observed in later-stage companies such as Post-IPO (11.78%), Series I (10.73%), 
-- and Subsidiary companies (5.96%), suggesting that earlier-stage companies may have been more vulnerable 
-- to workforce reductions relative to their size.

-- Track the rolling total of layoffs by month.
SELECT 
    DISTINCT SUBSTRING(date,1,7) as Month, 
    SUM(total_laid_off) OVER(PARTITION BY SUBSTRING(date, 1,7)) as total_layoffs,
    SUM(total_laid_off) OVER(ORDER BY SUBSTRING(date, 1,7)) as layoffs_rolling
FROM layoffs_staging2
WHERE SUBSTRING(date,1,7) IS NOT NULL
ORDER BY 1;
-- The cumulative layoffs reached 257,482 by Dec 2022, with an accelerating trend in early 2023.
-- Monthly breakdown shows that layoffs started at 9,628 in March 2020 and saw significant spikes in May 2022 (12,885), October 2022 (17,406), and November 2022 (53,451).
-- The highest single-month layoffs occurred in January 2023 (84,714), contributing to a rolling total of 342,196 by that time.
-- The rapid increase in early 2023 may indicate companies responding to economic uncertainty and market corrections.

-- Rank the top 5 companies with the most layoffs per year.
-- Identifies companies with the largest layoffs each year, highlighting industry trends and economic shifts.
WITH company_year AS (
    SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
), 
company_year_rank AS (
    SELECT *, 
    DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
    FROM company_year
    WHERE years IS NOT NULL
)
SELECT * 
FROM company_year_rank
WHERE ranking <= 5;
-- In 2020, Uber had the most layoffs (7,525), followed by Booking.com (4,375) and Groupon (2,800), reflecting the impact of pandemic-driven travel and consumer downturns.
-- In 2021, Bytedance ranked #1 (3,600), followed by Katerra (2,434) and Zillow (2,000), with layoffs concentrated in tech and real estate.
-- In 2022, Meta led with 11,000 layoffs, followed by Amazon (10,150) and Cisco (4,100), as tech firms adjusted to post-pandemic market conditions.
-- In early 2023, Google led layoffs (12,000), followed by Microsoft (10,000) and Ericsson (8,500), possibly reflecting workforce adjustments in major tech companies.

-- Rank the top 5 industries with the most layoffs per year.
WITH industry_year AS (
    SELECT industry, YEAR(`date`) AS years, SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY industry, YEAR(`date`)
), 
industry_year_rank AS (
    SELECT *, 
    DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
    FROM industry_year
    WHERE years IS NOT NULL
)
SELECT * 
FROM industry_year_rank
WHERE ranking <= 5;
-- In 2020, Transportation had the highest layoffs (14,656), followed by Travel (13,983) and Finance (8,624). Retail and Food also saw significant layoffs, possibly due to pandemic-related shutdowns.
-- In 2021, Consumer had the highest layoffs (3,600), followed by Real Estate (2,900) and Food (2,644), suggesting that shifting consumer demand and economic uncertainty may have impacted these sectors.
-- In 2022, Retail led with 20,914 layoffs, followed by Consumer (19,856) and Transportation (15,227), as companies adjusted operations post-pandemic.
-- In 2023, 'Other' had the highest layoffs (28,512), followed by Consumer (15,663) and Retail (13,609). Hardware and Healthcare also saw high layoffs, possibly indicating broader restructuring across industries.
