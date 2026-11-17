-- Run only after sql/04_check.sql reports equal amounts/counts and zero
-- missing/extra rows. Keep the original data for auditing and comparison.

USE sales_norm_lab2;

RENAME TABLE orders_bad TO orders_bad_archive;

SHOW TABLES;
SELECT COUNT(*) AS archived_source_rows FROM orders_bad_archive;
