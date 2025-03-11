/*1. Retrieve a list of unique markets where the customer "Atliq Exclusive" operates within the APAC region. The output should display only distinct market names associated with this customer.
The final result should include the following field:
- market. */

WITH CustomerMarkets AS (
    SELECT market 
    FROM dim_customer 
    WHERE customer = 'Atliq Exclusive' 
    AND region = 'APAC'
)
SELECT DISTINCT market FROM CustomerMarkets;

-- Alternative simpler approach
SELECT DISTINCT market 
FROM dim_customer 
WHERE customer = 'Atliq Exclusive' 
AND region = 'APAC';
      
/*2. Calculate the percentage increase in the number of unique products from 2020 to 2021. The report should display the total count of distinct products for each year and the percentage change
in unique products.
The final output should include the following fields:
- unique_products_2020, unique_products_2021, percentage_change */

SELECT COUNT(DISTINCT product_code) FROM dim_product;

WITH CTE2 AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021
    FROM fact_sales_monthly
)
SELECT 
    *, 
    ROUND(((unique_products_2021 - unique_products_2020) * 100.0 / NULLIF(unique_products_2020, 0)), 2) 
    AS percentage_change 
FROM CTE2;

/* 3. Generate a report that displays the total number of unique products within each segment. The results should be sorted in descending order based on the product count. 
The final output should include the following fields: 
- segment, product_count. */

SELECT COUNT(DISTINCT segment) FROM dim_product;

SELECT 
    segment, 
    COUNT(*) AS product_count 
FROM dim_product 
GROUP BY segment 
ORDER BY product_count DESC;     
     
/*4. Identify the segment that experienced the highest increase in unique products from 2020 to 2021.
The final output should include the following fields:
- segment, product_count_2020, product_count_2021, difference.*/

-- Count of distinct segments in the dataset
SELECT COUNT(DISTINCT segment) FROM dim_product;

-- Retrieve unique product counts per segment for the year 2020
WITH ProductCount2020 AS (
    SELECT 
        dp.segment, 
        COUNT(DISTINCT fsm.product_code) AS product_count_2020
    FROM fact_sales_monthly AS fsm
    JOIN dim_product AS dp ON fsm.product_code = dp.product_code
    WHERE fsm.fiscal_year = 2020
    GROUP BY dp.segment
),

-- Retrieve unique product counts per segment for the year 2021
ProductCount2021 AS (
    SELECT 
        dp.segment, 
        COUNT(DISTINCT fsm.product_code) AS product_count_2021
    FROM fact_sales_monthly AS fsm
    JOIN dim_product AS dp ON fsm.product_code = dp.product_code
    WHERE fsm.fiscal_year = 2021
    GROUP BY dp.segment
)

-- Compute the difference in unique product counts between 2021 and 2020
SELECT 
    p20.segment, 
    p20.product_count_2020, 
    p21.product_count_2021, 
    (p21.product_count_2021 - p20.product_count_2020) AS difference
FROM ProductCount2020 p20
JOIN ProductCount2021 p21 ON p20.segment = p21.segment
ORDER BY difference DESC;

/*5. Retrieve the products with the highest and lowest manufacturing costs. The final report should display the product code, product name, and manufacturing cost for each.
The output should include the following fields:
- product_code, product, manufacturing_cost.*/

SELECT 
    dp.product_code, 
    dp.product, 
    fmc.manufacturing_cost, 
    fmc.cost_year
FROM dim_product AS dp
JOIN fact_manufacturing_cost AS fmc 
USING(product_code)
WHERE manufacturing_cost IN (
    (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
    UNION
    (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
);

/*6. Generate a report that lists the top 5 customers in the Indian market who received the highest average pre-invoice discount percentage in fiscal year 2021.
The final output should include the following fields:
- customer_code, customer, average_discount_percentage.*/

SELECT 
    dc.customer_code, 
    dc.customer, 
    ROUND(AVG(fpid.pre_invoice_discount_pct), 4) AS avg_discount_percentage
FROM dim_customer AS dc
JOIN fact_pre_invoice_deductions AS fpid 
ON dc.customer_code = fpid.customer_code
WHERE dc.market = 'India' 
AND fpid.fiscal_year = 2021
GROUP BY dc.customer_code, dc.customer
ORDER BY avg_discount_percentage DESC
LIMIT 5;

/*7. Generate a comprehensive report on the gross sales amount for the customer "Atliq Exclusive" on a monthly basis. This report will help in identifying high and low-performing months, 
assisting in strategic decision-making.
The final output should include the following fields:
- Month, Year, Gross Sales Amount.*/

SELECT 
    MONTHNAME(fsm.date) AS month, 
    YEAR(fsm.date) AS year, 
    fsm.fiscal_year, 
    dc.customer,
    SUM(fsm.sold_quantity) AS monthly_sold_qty, 
    SUM(fgp.gross_price) AS monthly_gross, 
    SUM(fsm.sold_quantity * fgp.gross_price) AS monthly_gross_sales_amt
FROM fact_sales_monthly AS fsm
JOIN dim_customer AS dc 
    ON fsm.customer_code = dc.customer_code
JOIN fact_gross_price AS fgp 
    ON fsm.product_code = fgp.product_code
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY month, year;

/*8. Determine which quarter in the year 2020 had the highest total sold quantity. The report should categorize months into their respective quarters and rank them based on total sales.
The final output should include:
- Quarters, Total Sold Quantity.*/

SELECT 
    CASE 
        WHEN month IN (9, 10, 11) THEN 'Q1'
        WHEN month IN (12, 1, 2) THEN 'Q2'
        WHEN month IN (3, 4, 5) THEN 'Q3'
        WHEN month IN (6, 7, 8) THEN 'Q4'
        ELSE 'Q0' 
    END AS quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM (
    SELECT 
        date, 
        MONTH(date) AS month, 
        sold_quantity, 
        fiscal_year 
    FROM fact_sales_monthly
) AS quarter_table
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

/*9. Identify the sales channel that contributed the most to gross sales in the fiscal year 2021 and calculate its percentage contribution to total sales.
The final output should include the following fields:
- channel, gross_sales_mln, percentage.*/

WITH CTE9 as( SELECT 
      #fsm.product_code,
      dc.channel,CONCAT(ROUND(SUM(fgp.gross_price*fsm.sold_quantity)/1000000,2)," M") as Gross_Sales_mlns
      FROM fact_sales_monthly as fsm
      JOIN dim_customer as dc ON fsm.customer_code =dc.customer_code
      JOIN fact_gross_price as fgp ON fsm.product_code =fgp.product_code 
      WHERE fsm.fiscal_year =2021
      GROUP BY channel) 
      SELECT *,CONCAT(ROUND(gross_sales_mlns*100/SUM(gross_sales_mlns) over(),2)," %") as Gross_Sales_pct
      FROM CTE9
      ORDER BY Gross_Sales_pct DESC;
      
/*10. Retrieve the top 3 products in each division that had the highest total sold quantity in the fiscal year 2021.
The final output should include the following fields:
- division, product_code, total_sold_quantity..*/

-- Get total sold quantity per product for each division in 2021
WITH CTE10 AS (
    SELECT 
        fsm.product_code, 
        dp.division, 
        SUM(fsm.sold_quantity) AS Total_Sold_Qty
    FROM dim_product AS dp
    JOIN fact_sales_monthly AS fsm 
        ON dp.product_code = fsm.product_code
    WHERE fsm.fiscal_year = 2021
    GROUP BY fsm.product_code, dp.division
),
-- Rank products within each division based on total sold quantity
CTE10_1 AS (
    SELECT 
        product_code,
        division,
        Total_Sold_Qty,
        DENSE_RANK() OVER(PARTITION BY division ORDER BY Total_Sold_Qty DESC) AS ranking
    FROM CTE10
)
-- Select top 3 products per division
SELECT 
    CTE10_1.product_code, 
    CTE10_1.division, 
    CTE10_1.Total_Sold_Qty, 
    CTE10_1.ranking
FROM CTE10_1
WHERE ranking <= 3;