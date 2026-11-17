-- Step 2: demonstrate update, insertion, and deletion anomalies.
-- Each example is rolled back, so the ten source rows remain unchanged.

USE sales_norm_lab2;

-- Update anomaly: changing only one occurrence creates inconsistent cities.
START TRANSACTION;
UPDATE orders_bad
SET client_city = 'Новосибирск'
WHERE client_id = 101 AND sale_id = 5001 AND product_id = 201;

SELECT client_id, client_name, client_city, COUNT(*) AS rows_count
FROM orders_bad
WHERE client_id = 101
GROUP BY client_id, client_name, client_city;
ROLLBACK;

-- Insertion anomaly: an independent client requires unrelated NULL fields.
START TRANSACTION;
INSERT INTO orders_bad
    (sale_id, sale_date, client_id, client_name, client_city,
     product_id, product_name, unit_price, quantity)
VALUES
    (NULL, NULL, 104, 'Новый клиент', 'Самара',
     NULL, NULL, NULL, NULL);

SELECT * FROM orders_bad WHERE client_id = 104;
ROLLBACK;

-- Deletion anomaly: removing the client's last sales also removes its details.
START TRANSACTION;
DELETE FROM orders_bad WHERE client_id = 102;

SELECT COUNT(*) AS remaining_rows_for_client_102
FROM orders_bad
WHERE client_id = 102;
SELECT DISTINCT client_id, client_name, client_city
FROM orders_bad
WHERE client_id = 102;
ROLLBACK;

-- Confirm that the demonstrations did not change the original data.
SELECT COUNT(*) AS source_rows_after_rollbacks
FROM orders_bad;
