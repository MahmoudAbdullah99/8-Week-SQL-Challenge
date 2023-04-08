CALL clean_transform_data();

-- show all tables
SELECT *
FROM customer_orders_temp;
SELECT *
FROM runner_orders_temp;
SELECT *
FROM pizza_runner.pizza_names;
SELECT *
FROM pizza_runner.runners;

-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT ((registration_date - '2021-01-01') / 7) + 1 AS week,
       COUNT(runner_id)                             AS regestirations
FROM pizza_runner.runners
GROUP BY week
ORDER BY week
;

-- 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT rot.runner_id,
       ROUND(AVG(DATE_PART('minute', rot.pickup_time - cot.order_time))) AS avg_arrive_time
FROM customer_orders_temp AS cot
         INNER JOIN runner_orders_temp AS rot
                    ON cot.order_id = rot.order_id
WHERE rot.cancellation IS NULL
GROUP BY rot.runner_id
ORDER BY rot.runner_id
;