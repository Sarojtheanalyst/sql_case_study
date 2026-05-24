create schema dannys_dinner;
  
  create table dannys_dinner.sales(
  customer_id varchar(1),
  order_date date,
  product_id int);

  insert into dannys_dinner.sales(customer_id, order_date,product_id)
  values
 ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  select* from dannys_dinner.sales;
  
  create table dannys_dinner.menu(
  product_id int,
  product_name varchar(10),
  price int);
  
  insert into dannys_dinner.menu(product_id, product_name, price)
  values
 ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  select*from dannys_dinner.menu;
  
  create table dannys_dinner.members (
  customer_id VARCHAR(1), 
  join_date DATE);
  
  
  insert into dannys_dinner.members(customer_id,join_date)
  values
  ('A','2021-01-07'),
  ('B','2021-01-09');
  
  select* from dannys_dinner.members;
  
  
  
  #CASE STUDY QUESTIONS
  #1. What is the total amount each customer spent at the restaurant?
SELECT 
    sales.customer_id,
    SUM(price) AS total_sales

FROM dannys_dinner.sales AS sales

JOIN dannys_dinner.menu AS menu
    ON sales.product_id = menu.product_id

GROUP BY customer_id;
  
  #2. How many days has each customer visited the restaurant?
SELECT 
    sales.customer_id,
    COUNT(DISTINCT order_date) AS days_visited

FROM dannys_dinner.sales AS sales

GROUP BY customer_id;
  #3. What was the first item from the menu purchased by each customer?
#ranking the order_date 
# row number is a function that assigns a sequential integer to each row within the partition
# using dense_rank() instead of row_number
WITH ordered_sales AS (

    SELECT 
        customer_id,
        product_name,
        order_date,

        DENSE_RANK() OVER (
            PARTITION BY sales.customer_id
            ORDER BY sales.order_date
        ) AS ranks

    FROM dannys_dinner.sales AS sales

    JOIN dannys_dinner.menu AS menu
        ON sales.product_id = menu.product_id
)

SELECT 
    customer_id,
    product_name

FROM ordered_sales

WHERE ranks = 1

GROUP BY customer_id, product_name;

  #4. What is the most purchased item on the menu and how many times was it purchased by all customers?
  
SELECT  
    COUNT(sales.customer_id) AS most_purchased,
    product_name

FROM dannys_dinner.sales AS sales

JOIN dannys_dinner.menu AS menu
    ON sales.product_id = menu.product_id

GROUP BY 
    sales.product_id,
    menu.product_name

ORDER BY most_purchased DESC;

#5. Which item was the most popular for each customer?

WITH popular_food AS (
    SELECT 
        COUNT(menu.product_id) AS order_count,
        sales.customer_id,
        menu.product_name,

        DENSE_RANK() OVER (
            PARTITION BY sales.customer_id
            ORDER BY COUNT(sales.customer_id) DESC
        ) AS ranks

    FROM dannys_dinner.menu AS menu

    JOIN dannys_dinner.sales AS sales
        ON sales.product_id = menu.product_id

    GROUP BY 
        sales.customer_id,
        menu.product_name
)

SELECT 
    customer_id,
    product_name,
    order_count

FROM popular_food

WHERE ranks = 1;

 #6. Which item was purchased first by the customer after they became a member?
 WITH member_customer AS (
    SELECT 
        members.join_date,
        sales.product_id,
        sales.customer_id,
        sales.order_date,

        DENSE_RANK() OVER (
            PARTITION BY sales.customer_id
            ORDER BY sales.order_date
        ) AS ranks

    FROM dannys_dinner.sales AS sales

    JOIN dannys_dinner.members AS members
        ON sales.customer_id = members.customer_id

    WHERE sales.order_date >= members.join_date
)

SELECT 
    s2.customer_id,
    menu.product_name,
    s2.order_date

FROM member_customer AS s2

JOIN dannys_dinner.menu AS menu
    ON s2.product_id = menu.product_id

WHERE ranks = 1;
 
 #7. Which item was purchased just before the customer became a member?
 WITH member_customer AS (

    SELECT 
        members.join_date,
        sales.product_id,
        sales.customer_id,
        sales.order_date,

        DENSE_RANK() OVER (
            PARTITION BY sales.customer_id
            ORDER BY sales.order_date DESC
        ) AS ranks

    FROM dannys_dinner.sales AS sales

    JOIN dannys_dinner.members AS members
        ON sales.customer_id = members.customer_id

    WHERE sales.order_date < members.join_date
)

SELECT 
    s2.customer_id,
    menu.product_name,
    s2.order_date

FROM member_customer AS s2

JOIN dannys_dinner.menu AS menu
    ON s2.product_id = menu.product_id

WHERE ranks = 1;
 
 #8. What is the total items and amount spent for each member before they become a member?
 SELECT 
    sales.customer_id,
    COUNT(sales.product_id) AS total_items,
    SUM(menu.price) AS total_price

FROM dannys_dinner.sales AS sales

JOIN dannys_dinner.menu AS menu
    ON sales.product_id = menu.product_id

JOIN dannys_dinner.members AS members
    ON sales.customer_id = members.customer_id

WHERE sales.order_date < members.join_date

GROUP BY sales.customer_id;
 #9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier- how many points would each customer have?
#To create conditional statement use- case when
WITH customer_points AS (

    SELECT 
        menu.product_id,
        menu.product_name,
        menu.price,
        
        CASE 
            WHEN menu.product_id = 1 THEN menu.price * 20
            ELSE menu.price * 10
        END AS points

    FROM dannys_dinner.menu AS menu
)

SELECT 
    sales.customer_id,
    SUM(p.points) AS total_points

FROM dannys_dinner.sales AS sales

JOIN customer_points AS p
    ON sales.product_id = p.product_id

GROUP BY sales.customer_id;

#10. In the first week after a customer joins the program (including their join date) they earn 2x points 
-- on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH customer_points AS (
    SELECT 
        sales.customer_id,
        sales.order_date,
        members.join_date,
        sales.product_id,
        menu.price,

        CASE 
            WHEN sales.product_id = 1 THEN menu.price * 20
            WHEN sales.order_date >= members.join_date THEN menu.price * 20
            ELSE menu.price * 10
        END AS points
    FROM dannys_dinner.sales AS sales
    JOIN dannys_dinner.members AS members
        ON sales.customer_id = members.customer_id
    JOIN dannys_dinner.menu AS menu
        ON sales.product_id = menu.product_id
    WHERE sales.order_date <= '2021-01-31'
)

SELECT 
    customer_id,
    SUM(points) AS total_points
FROM customer_points
GROUP BY customer_id;


-- 11 For each transaction in Danny’s Diner, identify whether the customer was a member at the time of 
-- purchase.
SELECT 
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    CASE 
        WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
    END AS membership_status
FROM dannys_dinner.sales AS sales
LEFT JOIN dannys_dinner.menu AS menu
    ON sales.product_id = menu.product_id
LEFT JOIN dannys_dinner.members AS members
    ON sales.customer_id = members.customer_id;





# 12 )For each customer’s transaction history in Danny’s Diner, classify whether the purchase was made
--  before or after becoming a member
WITH ranking_values AS (
    SELECT 
        sales.customer_id,
        sales.order_date,
        menu.price,
        menu.product_name,
        CASE 
            WHEN members.join_date <= sales.order_date THEN 'Y'
            ELSE 'N'
        END AS members
    FROM dannys_dinner.sales AS sales
    LEFT JOIN dannys_dinner.menu AS menu
        ON sales.product_id = menu.product_id
    LEFT JOIN dannys_dinner.members AS members
        ON sales.customer_id = members.customer_id
)

SELECT 
    *,
    CASE 
        WHEN members = 'N' THEN NULL
        ELSE DENSE_RANK() OVER (
            PARTITION BY customer_id, members
            ORDER BY order_date
        )
    END AS ranking
FROM ranking_values;