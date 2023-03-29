-- Create a temporary table with all the columns
-- Remove null values in exlusions and extras columns and replace with blank space ''.

CREATE TEMPORARY TABLE customer_orders_temp AS (
    SELECT
        order_id,
        customer_id,
        pizza_id,
        order_time,
        (CASE
            WHEN exclusions IS NULL OR exclusions LIKE 'null'
                THEN ''
            ELSE exclusions
            END) AS exclusions,
        (CASE
            WHEN extras IS NULL OR extras LIKE 'null'
                THEN ''
            ELSE extras
            END) AS extras
    FROM
        pizza_runner.customer_orders
);
