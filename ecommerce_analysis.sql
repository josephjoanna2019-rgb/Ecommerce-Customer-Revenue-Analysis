USE online_retail_analysis;

LOAD DATA LOCAL INFILE 'C:/Users/josep/Downloads/online+retail+ii/online_retail_II.csv'
INTO TABLE retail_transactions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country);
USE online_retail_analysis;
SELECT SUM(Revenue) AS total_revenue
FROM clean_retail_transactions;
SELECT COUNT(DISTINCT Invoice) AS total_orders
FROM clean_retail_transactions;
SELECT COUNT(DISTINCT CustomerID) AS total_customers
FROM clean_retail_transactions
WHERE CustomerID IS NOT NULL;
SELECT 
    SUM(Revenue) / COUNT(DISTINCT Invoice) AS average_order_value
FROM clean_retail_transactions;
SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM clean_retail_transactions
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;
SELECT
    Description,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM clean_retail_transactions
WHERE Description IS NOT NULL
GROUP BY Description
ORDER BY total_revenue DESC
LIMIT 10;
SELECT
    Description,
    SUM(Quantity) AS units_sold
FROM clean_retail_transactions
WHERE Description IS NOT NULL
GROUP BY Description
ORDER BY units_sold DESC
LIMIT 10;
SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM clean_retail_transactions
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY month;
SELECT
    CustomerID,
    ROUND(SUM(Revenue), 2) AS customer_revenue
FROM clean_retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY customer_revenue DESC
LIMIT 10;
SELECT
    CustomerID,
    COUNT(DISTINCT Invoice) AS total_orders
FROM clean_retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_orders DESC
LIMIT 10;
SELECT
    customer_type,
    COUNT(*) AS customers
FROM (
    SELECT
        CustomerID,
        CASE
            WHEN COUNT(DISTINCT Invoice) = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS customer_type
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
) AS customer_orders
GROUP BY customer_type;
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM (
    SELECT
        CustomerID,
        COUNT(DISTINCT Invoice) AS total_orders
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
) AS customer_orders;
SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
    ROUND(SUM(Revenue), 2) AS revenue
FROM clean_retail_transactions
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY revenue DESC
LIMIT 1;
SELECT
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT CustomerID),
        2
    ) AS avg_revenue_per_customer
FROM clean_retail_transactions
WHERE CustomerID IS NOT NULL;
SELECT
    Country,
    COUNT(DISTINCT CustomerID) AS total_customers
FROM clean_retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY Country
ORDER BY total_customers DESC
LIMIT 10;
WITH customer_orders AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT Invoice) AS total_orders
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    CustomerID,
    total_orders,
    CASE
        WHEN total_orders >= 10 THEN 'VIP'
        WHEN total_orders >= 5 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_segment
FROM customer_orders
ORDER BY total_orders DESC;
WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(Revenue) AS total_revenue
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    CustomerID,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM customer_revenue;
WITH product_country_revenue AS (
    SELECT
        Country,
        Description,
        SUM(Revenue) AS total_revenue
    FROM clean_retail_transactions
    WHERE Description IS NOT NULL
    GROUP BY Country, Description
)

SELECT
    Country,
    Description,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER (
        PARTITION BY Country
        ORDER BY total_revenue DESC
    ) AS product_rank
FROM product_country_revenue;
WITH product_country_revenue AS (
    SELECT
        Country,
        Description,
        SUM(Revenue) AS total_revenue
    FROM clean_retail_transactions
    WHERE Description IS NOT NULL
    GROUP BY Country, Description
),
ranked_products AS (
    SELECT
        Country,
        Description,
        total_revenue,
        RANK() OVER (
            PARTITION BY Country
            ORDER BY total_revenue DESC
        ) AS product_rank
    FROM product_country_revenue
)

SELECT
    Country,
    Description,
    ROUND(total_revenue, 2) AS total_revenue,
    product_rank
FROM ranked_products
WHERE product_rank <= 3;
SELECT
    CustomerID,
    MAX(InvoiceDate) AS last_purchase_date
FROM clean_retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;
SELECT 
    CustomerID,
    MIN(InvoiceDate) AS first_purchase_date,
    MAX(InvoiceDate) AS last_purchase_date,
    DATEDIFF(MAX(InvoiceDate), MIN(InvoiceDate)) AS customer_lifespan_days
FROM
    clean_retail_transactions
WHERE
    CustomerID IS NOT NULL
GROUP BY CustomerID;
WITH customer_orders AS (
    SELECT DISTINCT
        CustomerID,
        Invoice,
        InvoiceDate
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
),
purchase_gaps AS (
    SELECT
        CustomerID,
        InvoiceDate,
        LAG(InvoiceDate) OVER (
            PARTITION BY CustomerID
            ORDER BY InvoiceDate
        ) AS previous_purchase
    FROM customer_orders
)

SELECT
    CustomerID,
    ROUND(
        AVG(DATEDIFF(InvoiceDate, previous_purchase)),
        2
    ) AS avg_days_between_purchases
FROM purchase_gaps
WHERE previous_purchase IS NOT NULL
GROUP BY CustomerID;

WITH customer_orders AS (
    SELECT DISTINCT
        CustomerID,
        Invoice,
        InvoiceDate
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
),
purchase_gaps AS (
    SELECT
        CustomerID,
        InvoiceDate,
        LAG(InvoiceDate) OVER (
            PARTITION BY CustomerID
            ORDER BY InvoiceDate
        ) AS previous_purchase
    FROM customer_orders
)

SELECT
    CustomerID,
    ROUND(
        AVG(DATEDIFF(InvoiceDate, previous_purchase)),
        2
    ) AS avg_days_between_purchases
FROM purchase_gaps
WHERE previous_purchase IS NOT NULL
GROUP BY CustomerID;
SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
    COUNT(DISTINCT CustomerID) AS active_customers
FROM clean_retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY month;
WITH first_purchase AS (
    SELECT
        CustomerID,
        MIN(InvoiceDate) AS first_purchase_date
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    DATE_FORMAT(first_purchase_date, '%Y-%m') AS month,
    COUNT(*) AS new_customers
FROM first_purchase
GROUP BY DATE_FORMAT(first_purchase_date, '%Y-%m')
ORDER BY month;

WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(Revenue) AS total_revenue
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    CustomerID,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(
        100 * total_revenue / SUM(total_revenue) OVER (),
        2
    ) AS revenue_percentage
FROM customer_revenue
ORDER BY total_revenue DESC;

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
        SUM(Revenue) AS revenue
    FROM clean_retail_transactions
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)

SELECT
    month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (ORDER BY month),
        2
    ) AS running_revenue
FROM monthly_revenue;

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
        SUM(Revenue) AS revenue
    FROM clean_retail_transactions
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
),
revenue_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_revenue
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        ((revenue - previous_month_revenue)
        / previous_month_revenue) * 100,
        2
    ) AS growth_percentage
FROM revenue_growth;

WITH customer_value AS (
    SELECT
        CustomerID,
        SUM(Revenue) AS total_spent
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    CustomerID,
    ROUND(total_spent, 2) AS total_spent,
    CASE
        WHEN total_spent >= 10000 THEN 'High Value'
        WHEN total_spent >= 3000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_value
ORDER BY total_spent DESC;

WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(Revenue) AS total_revenue
    FROM clean_retail_transactions
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
customer_percentile AS (
    SELECT
        CustomerID,
        total_revenue,
        NTILE(10) OVER (
            ORDER BY total_revenue DESC
        ) AS spending_decile
    FROM customer_revenue
)

SELECT
    CustomerID,
    ROUND(total_revenue, 2) AS total_revenue
FROM customer_percentile
WHERE spending_decile = 1
ORDER BY total_revenue DESC;

