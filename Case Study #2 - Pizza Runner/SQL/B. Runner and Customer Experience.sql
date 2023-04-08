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

-- 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH average_time_cte AS (SELECT COUNT(cot.pizza_id)                                        AS pizza_count,
                                 AVG(DATE_PART('MINUTE', rot.pickup_time - cot.order_time)) AS avg_prepararion_time
                          FROM customer_orders_temp AS cot
                                   INNER JOIN runner_orders_temp AS rot
                                              ON cot.order_id = rot.order_id
                          WHERE rot.cancellation IS NULL
                          GROUP BY cot.order_id
                          ORDER BY pizza_count)

SELECT pizza_count,
       ROUND(AVG(avg_prepararion_time)) AS average_per_count
FROM average_time_cte
GROUP BY pizza_count
ORDER BY pizza_count
;

-- 4.What was the average distance travelled for each customer?
WITH order_disance_cte AS (SELECT DISTINCT rot.order_id,
                                           rot.distance,
                                           cot.customer_id
                           FROM runner_orders_temp AS rot
                                    INNER JOIN customer_orders_temp AS cot
                                               ON cot.order_id = rot.order_id)

SELECT cte.customer_id,
       AVG(cte.distance) AS avg_distance
FROM order_disance_cte AS cte
GROUP BY cte.customer_id
ORDER BY cte.customer_id
;

-- 5.What was the difference between the longest and shortest delivery times for all orders?
SELECT
    (MAX(duration) - MIN(duration)) AS difference
FROM
    runner_orders_temp
;