-- Step 4: compare the source and normalized data before archiving the source.

USE sales_norm_lab2;

SELECT 'before_normalization' AS stage,
       COUNT(*) AS rows_count,
       SUM(unit_price * quantity) AS total_amount
FROM orders_bad
UNION ALL
SELECT 'after_normalization',
       COUNT(*),
       SUM(p.unit_price * i.quantity)
FROM sale_items i
JOIN products p ON p.product_id = i.product_id;

SELECT 'clients' AS entity,
       (SELECT COUNT(DISTINCT client_id) FROM orders_bad) AS source_count,
       (SELECT COUNT(*) FROM clients) AS normalized_count
UNION ALL
SELECT 'products',
       (SELECT COUNT(DISTINCT product_id) FROM orders_bad),
       (SELECT COUNT(*) FROM products)
UNION ALL
SELECT 'sales',
       (SELECT COUNT(DISTINCT sale_id) FROM orders_bad),
       (SELECT COUNT(*) FROM sales)
UNION ALL
SELECT 'sale_items',
       (SELECT COUNT(*) FROM orders_bad),
       (SELECT COUNT(*) FROM sale_items);

SELECT 'missing_from_3nf' AS check_name, COUNT(*) AS rows_count
FROM orders_bad b
LEFT JOIN sales s ON s.sale_id = b.sale_id
LEFT JOIN clients c ON c.client_id = s.client_id
LEFT JOIN sale_items i
       ON i.sale_id = b.sale_id AND i.product_id = b.product_id
LEFT JOIN products p ON p.product_id = i.product_id
WHERE s.sale_id IS NULL
   OR c.client_id IS NULL
   OR i.sale_id IS NULL
   OR p.product_id IS NULL
   OR NOT (s.sale_date <=> b.sale_date)
   OR NOT (s.client_id <=> b.client_id)
   OR NOT (c.client_name <=> b.client_name)
   OR NOT (c.client_city <=> b.client_city)
   OR NOT (p.product_name <=> b.product_name)
   OR NOT (p.unit_price <=> b.unit_price)
   OR NOT (i.quantity <=> b.quantity)
UNION ALL
SELECT 'extra_in_3nf', COUNT(*)
FROM sale_items i
LEFT JOIN orders_bad b
       ON b.sale_id = i.sale_id AND b.product_id = i.product_id
WHERE b.sale_id IS NULL;

SELECT s.sale_id,
       s.sale_date,
       c.client_id,
       c.client_name,
       c.client_city,
       p.product_id,
       p.product_name,
       p.unit_price,
       i.quantity
FROM sales s
JOIN clients c ON c.client_id = s.client_id
JOIN sale_items i ON i.sale_id = s.sale_id
JOIN products p ON p.product_id = i.product_id
ORDER BY s.sale_id, p.product_id;

SELECT c.client_id,
       c.client_name,
       SUM(p.unit_price * i.quantity) AS total_spent
FROM clients c
JOIN sales s ON s.client_id = c.client_id
JOIN sale_items i ON i.sale_id = s.sale_id
JOIN products p ON p.product_id = i.product_id
GROUP BY c.client_id, c.client_name
ORDER BY c.client_id;

SELECT p.product_id,
       p.product_name,
       SUM(i.quantity) AS quantity_sold
FROM products p
JOIN sale_items i ON i.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY p.product_id;
