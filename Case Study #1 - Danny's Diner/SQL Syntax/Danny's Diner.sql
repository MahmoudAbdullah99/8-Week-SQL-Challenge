/* --------------------
 Case Study Questions
 --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?
SELECT
  s.customer_id,
  SUM(m.price)
FROM
  dannys_diner.sales as s
  INNER JOIN dannys_diner.menu as m ON s.product_id = m.product_id
GROUP BY
  s.customer_id
ORDER BY
  customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
  customer_id,
  COUNT(order_date)
FROM
  dannys_diner.sales
GROUP BY
  customer_id
ORDER BY
  customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH customer_order_cte AS (
  SELECT
    s.customer_id,
    s.product_id,
    m.product_name,
    ROW_NUMBER() OVER (
      PARTITION BY s.customer_id
      ORDER BY
        s.order_date
    ) as rank
  FROM
    dannys_diner.sales as s
    INNER JOIN dannys_diner.menu as m ON s.product_id = m.product_id
)
SELECT
  customer_id,
  product_name
FROM
  customer_order_cte
WHERE
  rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
  m.product_name,
  t.count
FROM
  (
    SELECT
      s.product_id,
      COUNT(s.order_date) as count
    FROM
      dannys_diner.sales as s
    GROUP BY
      product_id
    ORDER BY
      count DESC
    LIMIT
      1
  ) AS t
  INNER JOIN dannys_diner.menu as m ON t.product_id = m.product_id;

-- OR
SELECT
  m.product_name,
  MAX(COUNT(s.order_date)) AS count
FROM
  menu as m
  INNER JOIN sales as s ON m.product_id = s.product_id
GROUP BY
  m.product_name,
  s.product_id
ORDER BY
  count DESC
LIMIT
  1;

-- 5. Which item was the most popular for each customer?
WITH count_customer_product_cte AS (
  SELECT
    s.customer_id,
    m.product_name,
    RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY
        COUNT(s.product_id) DESC
    ) AS rank
  FROM
    dannys_diner.sales AS s
    INNER JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
  GROUP BY
    s.customer_id,
    m.product_name
)
SELECT
  cte.customer_id,
  cte.product_name
FROM
  count_customer_product_cte as cte
WHERE
  rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH customer_after_join AS (
  SELECT
    s.customer_id,
    men.product_name,
    RANK() OVER(
      PARTITION BY s.customer_id
      ORDER BY
        COUNT(men.product_name) DESC
    ) AS rank
  FROM
    dbo.sales AS s
    INNER JOIN dbo.members AS mem ON s.customer_id = mem.customer_id
    INNER JOIN dbo.menu AS men ON s.product_id = men.product_id
  WHERE
    s.order_date > mem.join_date
  GROUP BY
    s.customer_id,
    men.product_name
)
SELECT
  cte.customer_id,
  cte.product_name
FROM
  customer_after_join AS cte
WHERE
  cte.rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH order_befort_join AS (
  SELECT
    s.customer_id,
    men.product_name,
    s.order_date,
    RANK() OVER(
      PARTITION BY s.customer_id
      ORDER BY
        s.order_date DESC
    ) AS rank
  FROM
    dannys_diner.sales AS s
    INNER JOIN dannys_diner.menu AS men ON s.product_id = men.product_id
    INNER JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
  WHERE
    s.order_date <= mem.join_date
  GROUP BY
    s.customer_id,
    men.product_name,
    s.order_date
)
SELECT
  cte.customer_id,
  cte.product_name
FROM
  order_befort_join AS cte
WHERE
  rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    s.customer_id,
    COUNT(s.product_id),
    SUM(men.price)
FROM
    dannys_diner.sales AS s
    INNER JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
    INNER JOIN dannys_diner.menu AS men ON s.product_id = men.product_id
WHERE
    s.order_date <= mem.join_date
GROUP BY
    s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN u.product_name = 'sushi' THEN 20 * u.price
            ELSE 10 * u.price
        END
    ) AS points
FROM
    dannys_diner.sales AS s
    INNER JOIN dannys_diner.menu AS u ON s.product_id = u.product_id
GROUP BY
    s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
