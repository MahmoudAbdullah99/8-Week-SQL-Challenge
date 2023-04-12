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
WITH extra_flat_cte AS (SELECT DISTINCT UNNEST(STRING_TO_ARRAY(extras, ', '))::INT                                AS extra,
                                        COUNT(order_id)
                                        OVER (PARTITION BY UNNEST(STRING_TO_ARRAY(extras, ', ')))                 AS count
                        FROM customer_orders_temp)

SELECT top.topping_name, count
FROM extra_flat_cte AS cte
         INNER JOIN pizza_runner.pizza_toppings AS top
                    ON cte.extra = top.topping_id
WHERE count = (SELECT MAX(count) FROM extra_flat_cte)
;