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