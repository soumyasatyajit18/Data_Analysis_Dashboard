CREATE DATABASE insurance;
USE insurance;
SELECT * FROM `insuranceanalytics`.brokerage_cln;
SELECT * FROM `insuranceanalytics`.fees;
SELECT * FROM `insuranceanalytics`.`individual budget cln`;
SELECT * FROM `insuranceanalytics`.invoice_table_cln;
SELECT * FROM `insuranceanalytics`.meeting1;
SELECT * FROM `insuranceanalytics`.`opportunity_clean data set`;


CREATE TABLE insurance.individual_budget_cln AS 
SELECT * FROM `insuranceanalytics`.`individual budget cln`;


CREATE TABLE insurance.brokerage_cln AS 
SELECT * FROM `insuranceanalytics`.brokerage_cln;

CREATE TABLE insurance.fees AS 
SELECT * FROM `insuranceanalytics`.fees; 

CREATE TABLE insurance.invoice_table_cln AS 
SELECT * FROM `insuranceanalytics`.invoice_table_cln;

CREATE TABLE insurance.meeting1 AS 
SELECT * FROM `insuranceanalytics`.meeting1;

CREATE TABLE insurance.opportunity_clean_data_set AS 
SELECT * FROM `insuranceanalytics`.`opportunity_clean data set`;


-- 1. No of Invoice by Account Executive (Direct Aggregation)
SELECT
    ' No of Invoices by Account Executive' AS KPI_Name,
    Account_Executive,
    COUNT(DISTINCT Invoice_No) AS Number_of_Invoices
FROM insurance.invoice_table_cln
GROUP BY Account_Executive
ORDER BY Number_of_Invoices DESC;



/* 2. Yearly Meeting Count (Using a CTE for date parsing) */
WITH Meeting_Years AS (
    SELECT
        -- Extract the year (last 4 characters) and cast it to an integer
        CAST(SUBSTRING(meeting_date, -4) AS SIGNED) AS Meeting_Year
    FROM insurance.meeting1
    WHERE meeting_date IS NOT NULL AND LENGTH(meeting_date) >= 4 -- Ensure the field has enough characters for extraction
)
SELECT
    'Yearly Meeting Count' AS KPI_Name,
    Meeting_Year,
    COUNT(*) AS Total_Meetings
FROM Meeting_Years
GROUP BY Meeting_Year
ORDER BY Meeting_Year DESC;
  

WITH Meeting_Years AS (
    SELECT
        CAST(SUBSTRING(meeting_date, -4) AS SIGNED) AS Meeting_Year
    FROM insurance.meeting1
    WHERE meeting_date IS NOT NULL
      AND LENGTH(meeting_date) >= 4
      AND SUBSTRING(meeting_date, -4) IN ('2019', '2020')
),
Yearly_Count AS (
    SELECT
        Meeting_Year,
        COUNT(*) AS Year_Count
    FROM Meeting_Years
    GROUP BY Meeting_Year
)
SELECT
    'Yearly Meeting Count' AS KPI_Name,
    Meeting_Year,
    SUM(Year_Count) OVER (ORDER BY Meeting_Year) AS Total_Meetings
FROM Yearly_Count
ORDER BY Meeting_Year;




/* 3. Cross Sell/New/Renewal Achievement (Target, Achieved, %) */
-- CROSS SELL KPIs (JOIN/UNION Version)

-- 1. Cross Sell Target (CT)
SELECT
    'Cross Sell Target (CT)' AS KPI_Name,
    SUM(
        CAST(
            TRIM(REPLACE(REPLACE(T1.`Cross sell bugdet`, '?', ''), ',', ''))
            AS DECIMAL(18,2)
        )
    ) AS KPI_Value
FROM insurance.individual_budget_cln AS T1

UNION ALL

-- 2. Cross Sell Invoice (CI)
SELECT
    'Cross Sell Invoice (CI)' AS KPI_Name,
    SUM(
        CAST(
            TRIM(REPLACE(REPLACE(T2.Invoice_Amount, '?', ''), ',', ''))
            AS DECIMAL(18,2)
        )
    ) AS KPI_Value
FROM insurance.invoice_table_cln AS T2
WHERE T2.income_class = 'Cross Sell'

UNION ALL

-- 3. Cross Sell Achieve (CA)
SELECT
    'Cross Sell Achieve (CA)' AS KPI_Name,
    SUM(Amount) AS KPI_Value
FROM (
        SELECT 
            CAST(TRIM(REPLACE(REPLACE(F.Fee_Amount, '?', ''), ',', '')) AS DECIMAL(18,2)) AS Amount
        FROM insurance.fees F
        WHERE F.Income_Class = 'Cross Sell'
        
        UNION ALL
        
        SELECT 
            CAST(TRIM(REPLACE(REPLACE(B.Revenue_Amount, '?', ''), ',', '')) AS DECIMAL(18,2)) AS Amount
        FROM insurance.brokerage_cln B
        WHERE B.Income_Class = 'Cross Sell'
) AS T;


-- RENEWAL KPIs (JOIN/UNION )

-- 1. Renewal Target (RT)
SELECT
    'Renewal Target (RT)' AS KPI_Name,
    SUM(
        CAST(
            TRIM(REPLACE(REPLACE(T1.`Renewal budget`, '?', ''), ',', ''))
            AS DECIMAL(18,2)
        )
    ) AS KPI_Value
FROM insurance.individual_budget_cln AS T1

UNION ALL

-- 2. Renewal Invoice (RI)
SELECT
    'Renewal Invoice (RI)' AS KPI_Name,
    SUM(
        CAST(
            TRIM(REPLACE(REPLACE(T2.Invoice_Amount, '?', ''), ',', ''))
            AS DECIMAL(18,2)
        )
    ) AS KPI_Value
FROM insurance.invoice_table_cln AS T2
WHERE T2.income_class = 'Renewal'

UNION ALL

-- 3. Renewal Achieve (RA)
SELECT
    'Renewal Achieve (RA)' AS KPI_Name,
    SUM(Amount) AS KPI_Value
FROM (
        SELECT 
            CAST(TRIM(REPLACE(REPLACE(F.Fee_Amount, '?', ''), ',', '')) AS DECIMAL(18,2)) AS Amount
        FROM insurance.fees F
        WHERE F.Income_Class = 'Renewal'
        
        UNION ALL
        
        SELECT 
            CAST(TRIM(REPLACE(REPLACE(B.Revenue_Amount, '?', ''), ',', '')) AS DECIMAL(18,2)) AS Amount
        FROM insurance.brokerage_cln B
        WHERE B.Income_Class = 'Renewal'
) AS T;


-- NEW BUSINESS KPIs (JOIN/UNION Version)

-- 1. New Target (NT)
SELECT
    'New Target (NT)' AS KPI_Name,
    SUM(
        CAST(
            TRIM(REPLACE(REPLACE(T1.`New Budget`, '?', ''), ',', ''))
            AS DECIMAL(18,2)
        )
    ) AS KPI_Value
FROM insurance.individual_budget_cln AS T1

UNION ALL

-- 2. New Invoice (NI)
SELECT
    'New Invoice (NI)' AS KPI_Name,
    SUM(
        CAST(
            TRIM(REPLACE(REPLACE(T2.Invoice_Amount, '?', ''), ',', ''))
            AS DECIMAL(18,2)
        )
    ) AS KPI_Value
FROM insurance.invoice_table_cln AS T2
WHERE T2.income_class = 'New'

UNION ALL

-- 3. New Achieve (NA)
SELECT
    'New Achieve (NA)' AS KPI_Name,
    SUM(Amount) AS KPI_Value
FROM (
        SELECT 
            CAST(TRIM(REPLACE(REPLACE(F.Fee_Amount, '?', ''), ',', '')) AS DECIMAL(18,2)) AS Amount
        FROM insurance.fees F
        WHERE F.Income_Class = 'New'
        
        UNION ALL
        
        SELECT 
            CAST(TRIM(REPLACE(REPLACE(B.Revenue_Amount, '?', ''), ',', '')) AS DECIMAL(18,2)) AS Amount
        FROM insurance.brokerage_cln B
        WHERE B.Income_Class = 'New'
) AS T;


/* 4. Stage Funnel by Revenue */
WITH Cleaned_Opportunity_Revenue AS (
    SELECT
        stage,
        CAST(
            TRIM(REPLACE(REPLACE(revenue_amount, '?', ''), ',', '')) AS DECIMAL(18, 2)
        ) AS Revenue_Amount_USD
    FROM insurance.opportunity_clean_data_set
)
SELECT
    'KPI 4: Stage Funnel by Revenue' AS KPI_Name,
    stage,
    SUM(Revenue_Amount_USD) AS Total_Revenue
FROM Cleaned_Opportunity_Revenue
GROUP BY stage
ORDER BY Total_Revenue DESC;




/* 5. No of meeting By Account Exec (for Current Year - assuming 2020 based on data snippets) */
SELECT
    'KPI 5: No of Meetings by Account Executive' AS KPI_Name,
    -- CORRECTED: Account Executive field needs backticks because of the space
    `Account Executive`,
    COUNT(*) AS Meeting_Count
FROM insurance.meeting1
-- Filter for a specific year, e.g., 2020, by checking the last 4 characters of the date
WHERE SUBSTRING(meeting_date, -4) = '2020'
GROUP BY `Account Executive`
ORDER BY Meeting_Count DESC;




/* 6. Top Open Opportunity (Top 10 Opportunities currently in 'Open' stages by Revenue) */
WITH Cleaned_Opportunity_Revenue AS (
    -- Revenue for Stage Funnel (Opportunity report: Column E, F, G)
    SELECT
        opportunity_id,
        stage,
        Account_Executive,
        Branch,
        -- Clean and convert revenue amount
        CAST(
            TRIM(REPLACE(REPLACE(revenue_amount, '?', ''), ',', '')) AS DECIMAL(18, 2)
        ) AS Revenue_Amount_USD,
        opportunity_name
    FROM insurance.opportunity_clean_data_set
)
SELECT
    'KPI 6: Top Open Opportunity' AS KPI_Name,
    T1.Account_Executive,
    T1.opportunity_name,
    T1.stage,
    T1.Revenue_Amount_USD
FROM Cleaned_Opportunity_Revenue T1
ORDER BY T1.Revenue_Amount_USD DESC
LIMIT 10;











-- FROM Cleaned_Opportunity_Revenue T1
-- WHERE T1.stage IN ('Propose Solution', 'Qualify Opportunity')
-- ORDER BY T1.Revenue_Amount_USD DESC
