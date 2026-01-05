/* PROJECT: Quantitative Macro-Economic Modeling
MODULE 1: The SQL Engine
PURPOSE: Calculate annual GDP growth and volatility (Standard Deviation)
*/

WITH gdp_raw AS (
  -- Step 1: Extract the specific GDP indicator for all countries
  SELECT 
    country_name,
    country_code,
    year,
    value AS gdp_value
  FROM `bigquery-public-data.world_bank_wdi.indicators`
  WHERE indicator_code = 'NY.GDP.MKTP.CD' -- Code for GDP (current US$)
    AND year > 2010
),

gdp_with_lag AS (
  -- Step 2: Use LAG to see last year's GDP on the same row
  SELECT 
    *,
    LAG(gdp_value) OVER (PARTITION BY country_code ORDER BY year) as prev_year_gdp
  FROM gdp_raw
),

growth_calculations AS (
  -- Step 3: Calculate the Annual Growth Rate (Delta)
  SELECT 
    *,
    (gdp_value - prev_year_gdp) / prev_year_gdp AS annual_growth_rate
  FROM gdp_with_lag
  WHERE prev_year_gdp IS NOT NULL
)

-- Step 4: Aggregate to find the most volatile economies
SELECT 
    country_name,
    AVG(annual_growth_rate) AS avg_growth,
    STDDEV(annual_growth_rate) AS growth_volatility, -- The key math metric
    COUNT(*) as years_recorded
FROM growth_calculations
GROUP BY country_name
HAVING years_recorded > 5
ORDER BY growth_volatility DESC;
