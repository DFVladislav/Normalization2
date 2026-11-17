-- Final checks after the source table has been archived.

USE sales_norm_lab2;

SELECT 'archived_source' AS stage,
       COUNT(*) AS rows_count,
       SUM(unit_price * quantity) AS total_amount
FROM orders_bad_archive
UNION ALL
SELECT 'normalized',
       COUNT(*),
       SUM(p.unit_price * i.quantity)
FROM sale_items i
JOIN products p ON p.product_id = i.product_id;

SELECT 'clients' AS table_name, COUNT(*) AS rows_count FROM clients
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'sale_items', COUNT(*) FROM sale_items;

SELECT c.client_id,
       c.client_name,
       SUM(p.unit_price * i.quantity) AS total_spent
FROM clients c
JOIN sales s ON s.client_id = c.client_id
JOIN sale_items i ON i.sale_id = s.sale_id
JOIN products p ON p.product_id = i.product_id
WHERE c.client_id = 101
GROUP BY c.client_id, c.client_name;
