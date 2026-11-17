-- Step 7: verify that client, sale, and product facts can be maintained
-- independently in the normalized schema. All demonstrations are rolled back.

USE sales_norm_lab2;

-- Update a client's city once; every joined sale now sees the same client data.
START TRANSACTION;
UPDATE clients
SET client_city = 'Самара (тест)'
WHERE client_id = 101;

SELECT c.client_id, c.client_name, c.client_city, COUNT(*) AS sale_items
FROM clients c
JOIN sales s ON s.client_id = c.client_id
JOIN sale_items i ON i.sale_id = s.sale_id
WHERE c.client_id = 101
GROUP BY c.client_id, c.client_name, c.client_city;
ROLLBACK;

-- Add a client without inventing a sale or a product line.
START TRANSACTION;
INSERT INTO clients (client_id, client_name, client_city)
VALUES (104, 'Новый клиент', 'Самара');

SELECT * FROM clients WHERE client_id = 104;
ROLLBACK;

-- Remove a client's sales while retaining the independent client and products.
START TRANSACTION;
DELETE FROM sale_items
WHERE sale_id IN (SELECT sale_id FROM sales WHERE client_id = 102);
DELETE FROM sales WHERE client_id = 102;

SELECT * FROM clients WHERE client_id = 102;
SELECT product_id, product_name
FROM products
WHERE product_id IN (201, 203, 204)
ORDER BY product_id;
ROLLBACK;
