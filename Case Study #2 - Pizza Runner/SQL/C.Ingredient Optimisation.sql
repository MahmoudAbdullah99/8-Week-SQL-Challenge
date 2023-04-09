-- Create a clean copies of customer_orders and runner_orders tables
CALL clean_transform_data();

-- Sho all data
SELECT *
FROM customer_orders_temp;
SELECT *
FROM runner_orders_temp;
SELECT *
FROM pizza_runner.pizza_names;
SELECT *
FROM pizza_runner.runners;
SELECT *
FROM pizza_runner.pizza_recipes;
SELECT *
FROM pizza_runner.pizza_toppings;

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
-- 3.What was the most common exclusion?
-- 4.Generate an order item for each record in the customers_orders table in the format of one of the following:
--     Meat Lovers
--     Meat Lovers - Exclude Beef
--     Meat Lovers - Extra Bacon
--     Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--     For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?