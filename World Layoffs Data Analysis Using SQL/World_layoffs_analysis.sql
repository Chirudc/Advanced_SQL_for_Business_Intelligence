-- 1. Creating a Staging Table
CREATE TABLE layoffs_staging LIKE layoffs;

INSERT INTO layoffs_staging
SELECT * FROM layoffs;

/* - Creates a copy of the raw layoffs table for safe transformations and analysis.
   - Ensures the original dataset remains unchanged for reference. */

-- 2. Analyzing Layoffs by Year with Running Total
SELECT fiscal_year, 
       SUM(total_laid_off) AS yearly_layoffs, 
       SUM(SUM(total_laid_off)) OVER (ORDER BY fiscal_year) AS running_total 
FROM layoffs_staging 
GROUP BY fiscal_year 
ORDER BY fiscal_year;

/* - Tracks yearly layoff trends.
   - Calculates a running total of layoffs over the years. */

-- 3. Ranking Industries by Layoff Contribution
SELECT industry, 
       SUM(total_laid_off) AS total_layoffs, 
       ROUND(100 * SUM(total_laid_off) / (SELECT SUM(total_laid_off) FROM layoffs_staging), 2) AS percentage_contribution 
FROM layoffs_staging 
GROUP BY industry 
ORDER BY percentage_contribution DESC;

/* - Identifies which industries contributed the most to layoffs.
   - Helps understand the sectors most affected by job losses. */

-- 4. Layoffs by Region with Ranking
SELECT region, 
       SUM(total_laid_off) AS layoffs_count,
       RANK() OVER (ORDER BY SUM(total_laid_off) DESC) AS region_rank
FROM layoffs_staging
GROUP BY region;

/* - Identifies the regions most affected by layoffs.
   - Helps policymakers analyze regional employment trends. */

-- 5. Identifying Industries with Recurring Layoffs
SELECT industry, 
       COUNT(DISTINCT fiscal_year) AS years_with_layoffs,
       SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging
GROUP BY industry
HAVING COUNT(DISTINCT fiscal_year) > 2
ORDER BY total_layoffs DESC;

/* - Identifies industries experiencing layoffs across multiple years.
   - Highlights ongoing workforce instability within certain sectors. */
   
-- 6. Ranking Companies with Highest Layoffs Per Year
SELECT company, 
       fiscal_year, 
       total_laid_off,
       RANK() OVER (PARTITION BY fiscal_year ORDER BY total_laid_off DESC) AS ranking
FROM layoffs_staging;

/* - Ranks companies based on layoffs within each year.
   - Helps analyze corporate downsizing trends. */

-- 7. Find the total layoffs per industry and sort in descending order
SELECT industry, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging
GROUP BY industry
ORDER BY total_layoffs DESC;

-- 8. Count the number of companies that experienced layoffs in each year
SELECT fiscal_year, COUNT(DISTINCT company) AS companies_affected
FROM layoffs_staging
GROUP BY fiscal_year
ORDER BY fiscal_year;

-- 9. Find the average layoffs per company in each industry
SELECT industry, ROUND(AVG(total_laid_off), 2) AS avg_layoffs_per_company
FROM layoffs_staging
GROUP BY industry
ORDER BY avg_layoffs_per_company DESC;

-- 10. Identify the top 5 companies with the highest layoffs
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 5;

-- 11. Find the total layoffs per region and sort in descending order
SELECT region, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging
GROUP BY region
ORDER BY total_layoffs DESC;

-- 12. Identify the most common layoff month across all years
SELECT MONTH(layoff_date) AS layoff_month, COUNT(*) AS occurrences
FROM layoffs_staging
GROUP BY MONTH(layoff_date)
ORDER BY occurrences DESC
LIMIT 1;

-- 13. Find companies that laid off more than 10,000 employees in a single year
SELECT company, fiscal_year, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging
GROUP BY company, fiscal_year
HAVING SUM(total_laid_off) > 10000
ORDER BY total_layoffs DESC;

-- 14. Determine industries where layoffs happened every year in the dataset
SELECT industry, COUNT(DISTINCT fiscal_year) AS years_with_layoffs
FROM layoffs_staging
GROUP BY industry
HAVING COUNT(DISTINCT fiscal_year) = (SELECT COUNT(DISTINCT fiscal_year) FROM layoffs_staging)
ORDER BY years_with_layoffs DESC;

-- 15. Calculate the cumulative layoffs per industry over time
WITH industry_yearly AS (
    SELECT industry, fiscal_year, SUM(total_laid_off) AS yearly_layoffs
    FROM layoffs_staging
    GROUP BY industry, fiscal_year
)
SELECT industry, fiscal_year, yearly_layoffs,
       SUM(yearly_layoffs) OVER (PARTITION BY industry ORDER BY fiscal_year) AS cumulative_layoffs
FROM industry_yearly;

-- 16. Identify companies that had layoffs in multiple years
SELECT company, COUNT(DISTINCT fiscal_year) AS years_with_layoffs
FROM layoffs_staging
GROUP BY company
HAVING COUNT(DISTINCT fiscal_year) > 1
ORDER BY years_with_layoffs DESC;

-- 17. Using CTE to calculate cumulative layoffs per industry over time
WITH industry_yearly AS (
    SELECT industry, fiscal_year, SUM(total_laid_off) AS yearly_layoffs
    FROM layoffs_staging
    GROUP BY industry, fiscal_year
)
SELECT industry, fiscal_year, yearly_layoffs,
       SUM(yearly_layoffs) OVER (PARTITION BY industry ORDER BY fiscal_year) AS cumulative_layoffs
FROM industry_yearly;

-- 18. Creating a Temporary View for analyzing top companies with layoffs
CREATE TEMPORARY VIEW top_companies AS 
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 10;

-- Selecting data from the temporary view
SELECT * FROM top_companies;

-- 19. Creating a Temporary Table to store layoffs per region
CREATE TEMPORARY TABLE temp_region_layoffs AS 
SELECT region, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging
GROUP BY region;

-- Selecting data from the temporary table
SELECT * FROM temp_region_layoffs;

-- 20. Creating a Stored Procedure to get layoffs by industry for a given year
DELIMITER $$
CREATE PROCEDURE GetIndustryLayoffs(IN input_year INT)
BEGIN
    SELECT industry, SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging
    WHERE fiscal_year = input_year
    GROUP BY industry
    ORDER BY total_layoffs DESC;
END $$
DELIMITER ;

-- Calling the Stored Procedure for a specific year (example: 2022)
CALL GetIndustryLayoffs(2022);