CREATE OR REPLACE PROCEDURE clean_transform_data()
LANGUAGE plpgsql 
AS
$ $

BEGIN

-- Create a temporary table of customer_orders with all the columns
-- Remove null values in exlusions and extras columns and replace with blank space ''.
CREATE TEMPORARY TABLE customer_orders_temp AS (
    SELECT
        order_id,
        customer_id,
        pizza_id,
        order_time,
        (
            CASE
                WHEN exclusions IS NULL
                OR exclusions LIKE 'null' THEN ''
                ELSE exclusions
            END
        ) AS exclusions,
        (
            CASE
                WHEN extras IS NULL
                OR extras LIKE 'null' THEN ''
                ELSE extras
            END
        ) AS extras
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
        (
            CASE
                WHEN pickup_time LIKE 'null' THEN NULL
                ELSE pickup_time
            END
        ) AS pickup_time,
        (
            CASE
                WHEN distance LIKE 'null' THEN NULL
                WHEN distance LIKE '%km' THEN TRIM(
                    'km'
                    FROM
                        distance
                )
                ELSE distance
            END
        ) AS distance,
        (
            CASE
                WHEN duration LIKE 'null' THEN NULL
                WHEN duration LIKE '%min%' THEN LEFT(duration, STRPOS(duration, 'min') -1)
                ELSE duration
            END
        ) AS duration,
        (
            CASE
                WHEN cancellation LIKE 'null' THEN NULL
                ELSE cancellation
            END
        ) AS cancellation
    FROM
        pizza_runner.runner_orders
);

-- Alter runner_orders_temp cloumns data type
ALTER TABLE
    runner_orders_temp
ALTER COLUMN
    pickup_time TYPE TIMESTAMP USING to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS'),
ALTER COLUMN
    distance TYPE FLOAT USING distance :: FLOAT,
ALTER COLUMN
    duration TYPE INT USING duration :: INT;

END;

$ $;

CALL clean_transform_data();

-- A. Pizza Metrics
-- 1.How many pizzas were ordered?
SELECT
    COUNT(o.pizza_id) AS pizza_count
FROM
    customer_orders_temp AS o;

-- 2.How many unique customer orders were made?
SELECT
    COUNT(DISTINCT o.order_id) AS unique_orders
FROM
    customer_orders_temp AS o;

-- 3.How many successful orders were delivered by each runner?
SELECT
    rot.runner_id,
    COUNT(distance) AS complete_orders
FROM
    runner_orders_temp AS rot
GROUP BY
    rot.runner_id
ORDER BY
    rot.runner_id;
