USE branch_dashboard;
CREATE TABLE brokerage (
    `client_name` VARCHAR(100),
    `policy_number` VARCHAR(50),
    `policy_status` VARCHAR(50),
    `policy_start_date` DATE,
    `policy_end_date` DATE,
    `product_group` VARCHAR(100),
    `Account Executive` VARCHAR(100),
    `branch_name` VARCHAR(100),
    `solution_group` VARCHAR(100),
    `income_class` VARCHAR(50),
    `Amount` DECIMAL(15,2),
    `income_due_date` DATE,
    `revenue_transaction_type` VARCHAR(50),
    `renewal_status` VARCHAR(50),
    `lapse_reason` VARCHAR(255),
    `last_updated_date` DATE
);
select * from brokerage;

CREATE TABLE fees (
    `client_name` VARCHAR(100),
    `branch_name` VARCHAR(100),
    `solution_group` VARCHAR(100),
    `Account Executive` VARCHAR(100),
    `income_class` VARCHAR(50),
    `Amount` DECIMAL(15,2),
    `income_due_date` DATE,
    `revenue_transaction_type` VARCHAR(50)
);
select * from fees;

CREATE TABLE budgets(
    `Branch` VARCHAR(100),
    `Employee Name` VARCHAR(100),
    `New Role2` VARCHAR(50),
    `New Budget` DECIMAL(15,2),
    `Cross-sell Budget` DECIMAL(15,2),
    `Renewal Budget` DECIMAL(15,2)
);
select * from budgets;

CREATE TABLE invoice (
    `invoice_number` VARCHAR(50),
    `invoice_date` DATE,
    `revenue_transaction_type` VARCHAR(50),
    `branch_name` VARCHAR(100),
    `solution_group` VARCHAR(100),
    `Account Executive` VARCHAR(100),
    `income_class` VARCHAR(50),
    `client_name` VARCHAR(100),
    `policy_number` VARCHAR(50),
    `Amount` DECIMAL(15,2),
    `income_due_date` DATE
);
select * from invoice;

CREATE TABLE meeting (
    `Account Executive` VARCHAR(100),
    `branch_name` VARCHAR(100),
    `global_attendees` INT,
    `meeting_date` DATE
);
select * from meeting;

CREATE TABLE opportunity (
    `opportunity_name` VARCHAR(100),
    `opportunity_id` VARCHAR(50),
    `Account Executive` VARCHAR(100),
    `premium_amount` DECIMAL(15,2),
    `revenue_amount` DECIMAL(15,2),
    `closing_date` DATE,
    `stage` VARCHAR(100),
    `branch` VARCHAR(100),
    `specialty` VARCHAR(100),
    `product_group` VARCHAR(100),
    `product_sub_group` VARCHAR(100),
    `risk_details` VARCHAR(255)
);
select * from opportunity;

-------------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT `income_class`
FROM invoice;
## KPI 1 — No of Invoice by Account Executive

SELECT 
    `Account Executive`,

    COUNT(CASE 
        WHEN LOWER(TRIM(`income_class`)) = 'cross sell'
        THEN 1 END) AS cross_sell_count,

    COUNT(CASE 
        WHEN LOWER(TRIM(`income_class`)) = 'new'
        THEN 1 END) AS new_count,

    COUNT(CASE 
        WHEN LOWER(TRIM(`income_class`)) = 'renewal'
        THEN 1 END) AS renewal_count,

    COUNT(CASE 
        WHEN `income_class` IS NULL OR TRIM(`income_class`) = ''
        THEN 1 END) AS null_count,

    COUNT(*) AS total_count

FROM invoice

GROUP BY `Account Executive`

ORDER BY renewal_count DESC;

-------------------------------------------------------------------------------------------------------------------------------
##  KPI 2 — Yearly Meeting Count

SELECT 
    YEAR(`meeting_date`) AS meeting_year,
    COUNT(*) AS meeting_count
FROM meeting
GROUP BY YEAR(`meeting_date`)
ORDER BY meeting_year;

## No of Meeting by Account Executive

SELECT 
    `Account Executive`,
    COUNT(*) AS meeting_count
FROM meeting
WHERE `Account Executive` IS NOT NULL
GROUP BY `Account Executive`
ORDER BY meeting_count DESC;

-----------------------------------------------------------------------------------------------------------------------------------
## Top Open Opportunities (Top 4)

SELECT
    ï»¿opportunity_name,
    SUM(revenue_amount) AS Revenue
FROM opportunity
GROUP BY ï»¿opportunity_name
ORDER BY Revenue DESC
LIMIT 4;

ALTER TABLE opportunity 
CHANGE COLUMN ï»¿opportunity_name opportunity_name TEXT;

SELECT
    opportunity_name,
    SUM(revenue_amount) AS Revenue
FROM opportunity
GROUP BY opportunity_name
ORDER BY Revenue DESC
LIMIT 4;

-------------------------------------------------------------------------------------------------------------------------------

##Total Opportunities
SELECT 
    COUNT(*) AS total_opportunities
FROM opportunity;

## Opportunity Product Distribution

SELECT 
    `product_group`,
    COUNT(*) AS opportunity_count
FROM opportunity
GROUP BY `product_group`
ORDER BY opportunity_count DESC;

DESCRIBE budgets;

--------------------------------------------------------------------------------------------------------------------------

##  Stage Funnel by Revenue
SELECT 
    `stage`,
    COUNT(`opportunity_id`) AS opportunity_count,
    CONCAT(FORMAT(SUM(`revenue_amount`) / 1000000, 2), 'M') AS revenue_in_M
FROM opportunity
GROUP BY `stage`
ORDER BY SUM(`revenue_amount`) DESC;

-----------------------------------------------------------------------------------------------------------------------------

## KPI 3 — Cross Sell Target vs Achieved vs Invoice

SELECT 
    b.`Branch`,

    SUM(b.`Cross-sell bugdet`) AS cross_sell_target,

    SUM(CASE 
        WHEN LOWER(TRIM(br.`income_class`)) = 'cross sell'
        THEN br.`Amount` ELSE 0 END) AS cross_sell_achieved,

    SUM(CASE 
        WHEN LOWER(TRIM(i.`income_class`)) = 'cross sell'
        THEN i.`Amount` ELSE 0 END) AS cross_sell_invoiced

FROM budgets b

LEFT JOIN brokerage br 
ON b.`Branch` = br.`branch_name`

LEFT JOIN invoice i 
ON b.`Branch` = i.`branch_name`

GROUP BY b.`Branch`;



##  Cross Sell — Target, Achieved, Invoice

SELECT 

'Cross Sell' AS category,

-- Target
SUM(b.`Cross sell bugdet`) AS target,

-- Achieved (Brokerage + Fees)
(
    SELECT SUM(`Amount`)
    FROM brokerage
    WHERE LOWER(TRIM(`income_class`)) = 'cross sell'
)
+
(
    SELECT SUM(`Amount`)
    FROM fees
    WHERE LOWER(TRIM(`income_class`)) = 'cross sell'
) AS achieved,

-- Invoice
(
    SELECT SUM(`Amount`)
    FROM invoice
    WHERE LOWER(TRIM(`income_class`)) = 'cross sell'
) AS invoiced

FROM budgets b;


## New — Target, Achieved, Invoice
SELECT 

'New' AS category,

SUM(b.`New Budget`) AS target,

(
    SELECT SUM(`Amount`)
    FROM brokerage
    WHERE LOWER(TRIM(`income_class`)) = 'new'
)
+
(
    SELECT SUM(`Amount`)
    FROM fees
    WHERE LOWER(TRIM(`income_class`)) = 'new'
) AS achieved,

(
    SELECT SUM(`Amount`)
    FROM invoice
    WHERE LOWER(TRIM(`income_class`)) = 'new'
) AS invoiced

FROM budgets b;

## Renewal — Target, Achieved, Invoice
SELECT 

'Renewal' AS category,

SUM(b.`Renewal Budget`) AS target,

(
    SELECT SUM(`Amount`)
    FROM brokerage
    WHERE LOWER(TRIM(`income_class`)) = 'renewal'
)
+
(
    SELECT SUM(`Amount`)
    FROM fees
    WHERE LOWER(TRIM(`income_class`)) = 'renewal'
) AS achieved,

(
    SELECT SUM(`Amount`)
    FROM invoice
    WHERE LOWER(TRIM(`income_class`)) = 'renewal'
) AS invoiced

FROM budgets b;


###  FINAL MASTER QUERY (exactly like dashboard)

SELECT 
    category,

    CONCAT(ROUND(target / 1000000, 2), 'M') AS target,

    CONCAT(ROUND(achieved / 1000000, 2), 'M') AS achieved,

    CONCAT(ROUND(invoiced / 1000000, 2), 'M') AS invoiced,

    CONCAT(ROUND((achieved / target) * 100, 2), '%') AS placed_achievement_percent,

    CONCAT(ROUND((invoiced / target) * 100, 2), '%') AS invoice_achievement_percent

FROM (

SELECT 
'Cross sell' AS category,

SUM(b.`Cross sell bugdet`) AS target,

(
    SELECT SUM(`Amount`) FROM brokerage 
    WHERE LOWER(TRIM(`income_class`)) = 'cross sell'
)
+
(
    SELECT SUM(`Amount`) FROM fees 
    WHERE LOWER(TRIM(`income_class`)) = 'cross sell'
) AS achieved,

(
    SELECT SUM(`Amount`) FROM invoice 
    WHERE LOWER(TRIM(`income_class`)) = 'cross sell'
) AS invoiced

FROM budgets b

UNION ALL

SELECT 
'New',

SUM(b.`New Budget`),

(
    SELECT SUM(`Amount`) FROM brokerage 
    WHERE LOWER(TRIM(`income_class`)) = 'new'
)
+
(
    SELECT SUM(`Amount`) FROM fees 
    WHERE LOWER(TRIM(`income_class`)) = 'new'
),

(
    SELECT SUM(`Amount`) FROM invoice 
    WHERE LOWER(TRIM(`income_class`)) = 'new'
)

FROM budgets b

UNION ALL

SELECT 
'Renewal',

SUM(b.`Renewal Budget`),

(
    SELECT SUM(`Amount`) FROM brokerage 
    WHERE LOWER(TRIM(`income_class`)) = 'renewal'
)
+
(
    SELECT SUM(`Amount`) FROM fees 
    WHERE LOWER(TRIM(`income_class`)) = 'renewal'
),

(
    SELECT SUM(`Amount`) FROM invoice 
    WHERE LOWER(TRIM(`income_class`)) = 'renewal'
)

FROM budgets b

) t;

