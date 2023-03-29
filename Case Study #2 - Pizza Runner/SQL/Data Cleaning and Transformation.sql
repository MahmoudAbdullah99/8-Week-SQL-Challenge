-- Create a temporary table of customer_orders with all the columns
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

-- Create a temporary table of runner_orders with all the columns
-- Remove null values in pickup_time, distance, duration, and cancellation columns and replace with blank space ''.
-- Remove all unnecessary data like 'mins' and 'minutes' from duration columns and 'km' from distnce column.
CREATE TEMPORARY TABLE runner_orders_temp AS (
    SELECT
        order_id,
        runner_id,
        (CASE
            WHEN pickup_time IS NULL OR pickup_time LIKE 'null'
                THEN ''
            ELSE pickup_time
            END) AS pickup_time,
        (CASE
            WHEN distance IS NULL OR distance LIKE 'null'
                THEN ''
            WHEN distance LIKE '%km'
                THEN TRIM('km' FROM distance)
            ELSE distance
            END) AS distance,
        (CASE
            WHEN duration IS NULL OR duration LIKE 'null'
                THEN ''
            WHEN duration LIKE '%min%'
                THEN LEFT(duration, STRPOS(duration, 'min')-1)
            ELSE duration
            END) AS duration,
        (CASE
            WHEN cancellation IS NULL OR cancellation LIKE 'null'
                THEN ''
            ELSE cancellation
            END) AS cancellation
    FROM
        pizza_runner.runner_orders
);