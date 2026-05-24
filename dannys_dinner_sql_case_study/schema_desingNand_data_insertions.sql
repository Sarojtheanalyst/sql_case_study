-- Create Schema
CREATE Database dannys_dinner;

use dannys_dinner

-- Create Sales Table
CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INT
);

-- Insert Data into Sales Table
INSERT INTO sales (customer_id, order_date, product_id)
VALUES
('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);

-- View Sales Table
SELECT * FROM sales;


-- Create Menu Table
CREATE TABLE menu (
    product_id INT,
    product_name VARCHAR(10),
    price INT
);

-- Insert Data into Menu Table
INSERT INTO menu (product_id, product_name, price)
VALUES
(1, 'sushi', 10),
(2, 'curry', 15),
(3, 'ramen', 12);

-- View Menu Table
SELECT * FROM menu;


-- Create Members Table
CREATE TABLE members (
    customer_id VARCHAR(1),
    join_date DATE
);

-- Insert Data into Members Table
INSERT INTO members (customer_id, join_date)
VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

-- View Members Table
SELECT * FROM members;

