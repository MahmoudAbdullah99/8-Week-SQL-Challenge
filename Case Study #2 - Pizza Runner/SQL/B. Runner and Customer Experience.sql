CALL clean_transform_data();

-- show all tables
SELECT * FROM customer_orders_temp;
SELECT * FROM runner_orders_temp;
SELECT * FROM pizza_runner.pizza_names;
SELECT * FROM pizza_runner.runners;

-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
    ((registration_date - '2021-01-01') / 7) + 1 AS week, COUNT(runner_id) AS regestirations
FROM
    pizza_runner.runners
GROUP BY
    week
ORDER BY
    week
;