-- Create a clean copies of customer_orders and runner_orders tables
CALL clean_transform_data();

-- 1.What are the standard ingredients for each pizza?
WITH toppings_uset_cte AS (SELECT pizza_id,
                                  UNNEST(STRING_TO_ARRAY(rec.toppings, ', ')) AS topping_id
                           FROM pizza_runner.pizza_recipes AS rec)

SELECT cte.pizza_id,
       ARRAY_TO_STRING(ARRAY_AGG(distinct top.topping_name), ', ') AS ingredients
FROM toppings_uset_cte AS cte
         INNER JOIN pizza_runner.pizza_toppings AS top
                    ON cte.topping_id::INT = top.topping_id
GROUP BY cte.pizza_id
;

-- 2.What was the most commonly added extra?
WITH extra_flat_cte AS (SELECT DISTINCT UNNEST(STRING_TO_ARRAY(extras, ', '))::INT                AS extra,
                                        COUNT(order_id)
                                        OVER (PARTITION BY UNNEST(STRING_TO_ARRAY(extras, ', '))) AS count
                        FROM customer_orders_temp)

SELECT top.topping_name, count
FROM extra_flat_cte AS cte
         INNER JOIN pizza_runner.pizza_toppings AS top
                    ON cte.extra = top.topping_id
WHERE count = (SELECT MAX(count) FROM extra_flat_cte)
;

-- 3.What was the most common exclusion?
WITH extra_flat_cte AS (SELECT DISTINCT UNNEST(STRING_TO_ARRAY(exclusions, ', '))::INT                AS extra,
                                        COUNT(order_id)
                                        OVER (PARTITION BY UNNEST(STRING_TO_ARRAY(exclusions, ', '))) AS count
                        FROM customer_orders_temp)

SELECT top.topping_name, count
FROM extra_flat_cte AS cte
         INNER JOIN pizza_runner.pizza_toppings AS top
                    ON cte.extra = top.topping_id
WHERE count = (SELECT MAX(count) FROM extra_flat_cte)
;

-- 4.Generate an order item for each record in the customers_orders table in the format of one of the following:
--     Meat Lovers
--     Meat Lovers - Exclude Beef
--     Meat Lovers - Extra Bacon
--     Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH ingredients_flat_cte AS (SELECT order_id,
                                     pizza_id,
                                     UNNEST(STRING_TO_ARRAY(extras, ', '))     AS extras,
                                     UNNEST(STRING_TO_ARRAY(exclusions, ', ')) AS exclusions
                              FROM customer_orders_temp)

SELECT cot.order_id,
       (CASE
            WHEN cot.exclusions IS NOT NULL AND cot.extras IS NOT NULL
                THEN CONCAT(pn.pizza_name, ' - Exclude ', ARRAY_TO_STRING(ARRAY_AGG(DISTINCT top2.topping_name), ', '),
                            ' - Extra ', ARRAY_TO_STRING(ARRAY_AGG(DISTINCT top1.topping_name), ', '))
            WHEN cot.exclusions IS NOT NULL
                THEN CONCAT(pn.pizza_name, ' - Exclude ', ARRAY_TO_STRING(ARRAY_AGG(DISTINCT top2.topping_name), ', '))
            WHEN cot.extras IS NOT NULL THEN CONCAT(pn.pizza_name, ' - Extra ',
                                                    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT top1.topping_name), ', '))
            ELSE pn.pizza_name
           END) AS full_order
FROM customer_orders_temp AS cot
         INNER JOIN pizza_runner.pizza_names AS pn
                    ON cot.pizza_id = pn.pizza_id
         LEFT JOIN ingredients_flat_cte AS cte
                   ON cot.order_id = cte.order_id
         LEFT JOIN pizza_runner.pizza_toppings As top1
                   ON cte.extras = top1.topping_id::VARCHAR
         LEFT JOIN pizza_runner.pizza_toppings As top2
                   ON cte.exclusions = top2.topping_id::VARCHAR
GROUP BY cot.order_id, pn.pizza_name, cot.exclusions, cot.extras
;

-- 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--     For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH main_extra_cte AS (SELECT cot.order_id,
                               cot.pizza_id,
                               ROW_NUMBER() OVER (PARTITION BY cot.order_id) AS id,
                               UNNEST(
                                       ARRAY_REMOVE(
                                               STRING_TO_ARRAY(
                                                       CONCAT(pr.toppings, ', ', cot.extras)
                                                   , ', ')
                                           , '')
                                   )::INT                                    AS ingredients
                        FROM customer_orders_temp AS cot
                                 INNER JOIN pizza_runner.pizza_recipes AS pr
                                            ON cot.pizza_id = pr.pizza_id)

SELECT cot.order_id, CONCAT(pn.pizza_name, ': ', ARRAY_TO_STRING(ARRAY_AGG(DISTINCT count_ingredient), ', '))
FROM customer_orders_temp AS cot
         INNER JOIN (SELECT cte.order_id,
                            cte.pizza_id,
                            cte.id,
                            (CASE
                                 WHEN count(*) <= 1
                                     THEN top.topping_name
                                 ELSE CONCAT('2x', top.topping_name) END) AS count_ingredient
                     FROM main_extra_cte AS cte
                              INNER JOIN pizza_runner.pizza_toppings AS top
                                         ON cte.ingredients = top.topping_id
                     WHERE cte.ingredients NOT IN (SELECT UNNEST(STRING_TO_ARRAY(exclusions, ','))::INT
                                                   FROM customer_orders_temp AS cot
                                                   WHERE cte.order_id = cot.order_id
                                                     AND cte.pizza_id = cot.pizza_id)
                     GROUP BY cte.order_id,
                              cte.pizza_id,
                              cte.id,
                              top.topping_name
                     ORDER BY cte.order_id,
                              cte.pizza_id,
                              cte.id,
                              count_ingredient DESC) AS temp_counter
                    ON cot.order_id = temp_counter.order_id
                        AND cot.pizza_id = temp_counter.pizza_id
         INNER JOIN pizza_runner.pizza_names AS pn ON cot.pizza_id = pn.pizza_id
GROUP BY cot.order_id, pn.pizza_name, temp_counter.id
;

-- 6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH main_extra_cte AS (SELECT cot.order_id,
                               cot.pizza_id,
                               ROW_NUMBER() OVER (PARTITION BY cot.order_id) AS id,
                               UNNEST(
                                       ARRAY_REMOVE(
                                               STRING_TO_ARRAY(
                                                       CONCAT(pr.toppings, ', ', cot.extras)
                                                   , ', ')
                                           , '')
                                   )::INT                                    AS ingredients
                        FROM customer_orders_temp AS cot
                                 INNER JOIN pizza_runner.pizza_recipes AS pr
                                            ON cot.pizza_id = pr.pizza_id
                                 INNER JOIN runner_orders_temp AS rot
                                     ON cot.order_id = rot.order_id AND rot.cancellation IS NULL)

SELECT top.topping_name,
       count(*) AS count_ingredient
FROM main_extra_cte AS cte
         INNER JOIN pizza_runner.pizza_toppings AS top
                    ON cte.ingredients = top.topping_id
WHERE cte.ingredients NOT IN (SELECT UNNEST(STRING_TO_ARRAY(exclusions, ','))::INT
                              FROM customer_orders_temp AS cot
                              WHERE cte.order_id = cot.order_id
                                AND cte.pizza_id = cot.pizza_id)
GROUP BY top.topping_name
ORDER BY count_ingredient DESC
;