CREATE OR REPLACE PROCEDURE clean_transform_data()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create temporary table of customer_orders
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

    -- Create temporary table of runner_orders
    CREATE TEMPORARY TABLE runner_orders_temp AS (
        SELECT
            order_id,
            runner_id,
            (CASE
                WHEN pickup_time LIKE 'null'
                    THEN NULL
                ELSE pickup_time
                END) AS pickup_time,
            (CASE
                WHEN distance LIKE 'null'
                    THEN NULL
                WHEN distance LIKE '%km'
                    THEN TRIM('km' FROM distance)
                ELSE distance
                END) AS distance,
            (CASE
                WHEN duration LIKE 'null'
                    THEN NULL
                WHEN duration LIKE '%min%'
                    THEN LEFT(duration, STRPOS(duration, 'min')-1)
                ELSE duration
                END) AS duration,
            (CASE
                WHEN cancellation LIKE 'null'
                    THEN NULL
                ELSE cancellation
                END) AS cancellation
        FROM
            pizza_runner.runner_orders
    );

    -- Alter temporary table of runner_orders
    ALTER TABLE runner_orders_temp
    ALTER COLUMN pickup_time TYPE TIMESTAMP USING to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS'),
    ALTER COLUMN distance TYPE FLOAT USING distance::FLOAT,
    ALTER COLUMN duration TYPE INT USING duration::INT;
END;
$$;