/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT
	s.customer_id,
	SUM(m.price)
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
	customer_id,
    COUNT(order_date)
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH customer_order_cte AS (
  SELECT
      s.customer_id,
      s.product_id,
      m.product_name,
      ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as rank
  FROM dannys_diner.sales as s
  INNER JOIN dannys_diner.menu as m
  ON s.product_id = m.product_id
)

SELECT
	customer_id,
    product_name
FROM customer_order_cte
WHERE rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	m.product_name,
    t.count
FROM 
	(SELECT 
       s.product_id,
       COUNT(s.order_date) as count
     FROM 
     	dannys_diner.sales as s
     GROUP BY 
     	product_id
     ORDER BY 
     	count DESC
     LIMIT 1) AS t
INNER JOIN dannys_diner.menu as m
ON t.product_id = m.product_id;

-- OR

SELECT
	m.product_name,
    MAX(COUNT(s.order_date)) AS count
FROM menu as m
INNER JOIN sales as s
ON m.product_id = s.product_id
GROUP BY m.product_name, s.product_id
ORDER BY count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
