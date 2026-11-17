-- Step 3: create the four 3NF tables and transfer the source data.

USE sales_norm_lab2;

CREATE TABLE clients (
    client_id   INT          NOT NULL,
    client_name VARCHAR(100) NOT NULL,
    client_city VARCHAR(100) NOT NULL,
    PRIMARY KEY (client_id)
);

CREATE TABLE products (
    product_id   INT           NOT NULL,
    product_name VARCHAR(100)  NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (product_id)
);

CREATE TABLE sales (
    sale_id   INT  NOT NULL,
    sale_date DATE NOT NULL,
    client_id INT  NOT NULL,
    PRIMARY KEY (sale_id),
    FOREIGN KEY (client_id) REFERENCES clients (client_id)
);

CREATE TABLE sale_items (
    sale_id    INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    PRIMARY KEY (sale_id, product_id),
    FOREIGN KEY (sale_id) REFERENCES sales (sale_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id)
);

INSERT INTO clients (client_id, client_name, client_city)
SELECT DISTINCT client_id, client_name, client_city
FROM orders_bad;

INSERT INTO products (product_id, product_name, unit_price)
SELECT DISTINCT product_id, product_name, unit_price
FROM orders_bad;

INSERT INTO sales (sale_id, sale_date, client_id)
SELECT DISTINCT sale_id, sale_date, client_id
FROM orders_bad;

INSERT INTO sale_items (sale_id, product_id, quantity)
SELECT sale_id, product_id, quantity
FROM orders_bad;

SELECT 'clients' AS table_name, COUNT(*) AS rows_count FROM clients
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'sale_items', COUNT(*) FROM sale_items;
