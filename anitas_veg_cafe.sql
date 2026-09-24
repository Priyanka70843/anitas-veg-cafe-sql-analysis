-- Create a database for projects
CREATE DATABASE projects;

-- Create schema for Anita's Veg Café
CREATE SCHEMA anitas_veg_cafe;

-- Orders table (same as sales in original)
CREATE TABLE sales (
  "customer_id" VARCHAR(10),
  "order_date" DATE,
  "product_id" INTEGER
);

-- Insert orders data
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('Aarav', '2021-01-01', 1),
  ('Aarav', '2021-01-01', 2),
  ('Aarav', '2021-01-07', 2),
  ('Aarav', '2021-01-10', 3),
  ('Aarav', '2021-01-11', 3),
  ('Aarav', '2021-01-11', 3),
  ('Meera', '2021-01-01', 2),
  ('Meera', '2021-01-02', 2),
  ('Meera', '2021-01-04', 1),
  ('Meera', '2021-01-11', 1),
  ('Meera', '2021-01-16', 3),
  ('Meera', '2021-02-01', 3),
  ('Rohan', '2021-01-01', 3),
  ('Rohan', '2021-01-01', 3),
  ('Rohan', '2021-01-07', 3);

-- Menu table
CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(50),
  "price" INTEGER
);

-- Insert menu data
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  (1, 'Paneer Butter Masala', 180),
  (2, 'Veg Biryani', 150),
  (3, 'Masala Dosa', 120);

-- Members table (loyalty customers)
CREATE TABLE members (
  "customer_id" VARCHAR(10),
  "join_date" DATE
);

-- Insert members data
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('Aarav', '2021-01-07'),
  ('Meera', '2021-01-09');

  SELECT * FROM sales

  SELECT * FROM menu

  SELECT * FROM members
  
--1)What is the total amount each customer has spent at the café? 
SELECT s.customer_id,SUM(m.price) AS total_amount
FROM sales s
JOIN menu m  USING (product_id)
GROUP BY s.customer_id

--2)How many distinct days has each customer placed an order?
SELECT customer_id,COUNT(DISTINCT order_date) as days
FROM sales
GROUP BY customer_id

--3)What was the first dish ordered by each customer?
SELECT s.customer_id,m.product_name,s.order_date
FROM sales s
JOIN menu m USING (product_id)
WHERE s.order_date = (SELECT MIN(order_date)
                      FROM sales s2
                      WHERE s2.customer_id = s.customer_id)

--4)Which menu item is the most popular overall?
SELECT m.product_name, COUNT(*) AS total_orders
FROM sales s
JOIN menu m USING (product_id)
GROUP BY m.product_name
ORDER BY total_orders DESC
LIMIT 1

--5)What is the most frequently ordered dish for each customer?
SELECT customer_id, product_name, total_orders
FROM (SELECT s.customer_id, m.product_name, COUNT(*) AS total_orders,
      RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rn
      FROM sales s
      JOIN menu m USING (product_id)
      GROUP BY s.customer_id, m.product_name) t
WHERE rn = 1

--6)After joining the loyalty program, what dish did each member first order?
SELECT customer_id, product_name
FROM (
    SELECT s.customer_id,m.product_name,s.order_date,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM sales s
    JOIN members mem USING (customer_id)
    JOIN menu m USING (product_id)
    WHERE s.order_date >= mem.join_date
    ) t
WHERE rn = 1

--7)Before joining the loyalty program, what dish did each customer order last? 
SELECT s.customer_id, s.order_date, m.product_name
FROM sales s
JOIN members mem USING (customer_id)
JOIN menu m USING (product_id)
WHERE s.order_date < mem.join_date
  AND s.order_date = (
      SELECT MAX(s2.order_date)
      FROM sales s2
      WHERE s2.customer_id = s.customer_id
        AND s2.order_date < mem.join_date)

--8)For each member, how many items and how much did they spend before joining? 
SELECT s.customer_id,COUNT(*) AS total_items,SUM(m.price) AS total_spent
FROM sales s
JOIN members mem USING (customer_id)
JOIN menu m USING (product_id)
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id

--9)If each ₹1 = 10 points, and Paneer Butter Masala earns double points, how many points does each customer earn? 
SELECT s.customer_id,
SUM(CASE
 WHEN m.product_name = 'Paneer Butter Masala' THEN m.price * 20
 ELSE m.price * 10
        END
    ) AS points
FROM sales s
JOIN menu m USING (product_id)
GROUP BY s.customer_id

--10)In their first loyalty week (starting from join_date), members earn double points on 
--all items. How many points do Aarav and Meera have by the end of January?
SELECT s.customer_id,SUM(
        CASE WHEN s.order_date BETWEEN mem.join_date 
         AND mem.join_date + INTERVAL '6 days' THEN m.price * 20
         WHEN m.product_name = 'Paneer Butter Masala'
         THEN m.price * 20 ELSE m.price * 10
         END) AS total_points
FROM sales s
JOIN members mem ON s.customer_id = mem.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY s.customer_id

