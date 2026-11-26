-- Expense Tracker: sample data (run AFTER schema.sql)

USE ExpenseTracker;
GO

-- 1. A demo user
INSERT INTO users (name, email)
VALUES ('Demo User', 'demo@example.com');
GO

-- 2. Categories for that user
INSERT INTO categories (user_id, name, type)
SELECT 1, name, type
FROM (VALUES
    ('Salary',         'income'),
    ('Side Income',    'income'),
    ('Rent',           'expense'),
    ('Groceries',      'expense'),
    ('Transport',      'expense'),
    ('Data & Airtime', 'expense'),
    ('Eating Out',     'expense'),
    ('Entertainment',  'expense'),
    ('Utilities',      'expense')
) AS c(name, type);
GO

-- 3. Fixed monthly items (salary, rent, data, utilities), Jul to Nov 2026
INSERT INTO transactions (user_id, category_id, amount, description, transaction_date)
SELECT 1, c.category_id, f.amount, f.descr,
       DATEADD(DAY, f.day_offset, CAST(m.month_start AS DATE))
FROM (VALUES ('2026-07-01'), ('2026-08-01'), ('2026-09-01'),
             ('2026-10-01'), ('2026-11-01')) AS m(month_start)
CROSS JOIN (VALUES
    ('Salary',         9500.00, 'Monthly salary',      24),
    ('Rent',           3200.00, 'Room rent',            0),
    ('Data & Airtime',  349.00, 'Monthly data bundle',  4),
    ('Utilities',       450.00, 'Prepaid electricity',  9)
) AS f(cat, amount, descr, day_offset)
JOIN categories c ON c.name = f.cat AND c.user_id = 1
WHERE DATEADD(DAY, f.day_offset, CAST(m.month_start AS DATE)) <= CAST(GETDATE() AS DATE);
GO

-- 4. Variable spending (amounts vary a little each month)
INSERT INTO transactions (user_id, category_id, amount, description, transaction_date)
SELECT 1, c.category_id,
       CAST(v.base + ABS(CHECKSUM(m.month_start, v.cat, v.day_offset) % v.spread) AS DECIMAL(10,2)),
       v.descr,
       DATEADD(DAY, v.day_offset, CAST(m.month_start AS DATE))
FROM (VALUES ('2026-07-01'), ('2026-08-01'), ('2026-09-01'),
             ('2026-10-01'), ('2026-11-01')) AS m(month_start)
CROSS JOIN (VALUES
    ('Groceries',     350, 250, 'Weekly groceries',  2),
    ('Groceries',     350, 250, 'Weekly groceries',  9),
    ('Groceries',     350, 250, 'Weekly groceries', 16),
    ('Groceries',     350, 250, 'Weekly groceries', 23),
    ('Transport',     150, 200, 'Taxi / transport',  3),
    ('Transport',     150, 200, 'Taxi / transport', 10),
    ('Transport',     150, 200, 'Taxi / transport', 17),
    ('Transport',     150, 200, 'Taxi / transport', 24),
    ('Eating Out',     80, 300, 'Takeaways',         6),
    ('Eating Out',     80, 300, 'Takeaways',        13),
    ('Eating Out',     80, 300, 'Takeaways',        20),
    ('Eating Out',     80, 300, 'Takeaways',        27),
    ('Entertainment', 100, 300, 'Movies / outing',  14),
    ('Side Income',   600, 900, 'Freelance work',   18)
) AS v(cat, base, spread, descr, day_offset)
JOIN categories c ON c.name = v.cat AND c.user_id = 1
WHERE DATEADD(DAY, v.day_offset, CAST(m.month_start AS DATE)) <= CAST(GETDATE() AS DATE);
GO

-- 5. Monthly budgets for expense categories
INSERT INTO budgets (user_id, category_id, month, limit_amount)
SELECT 1, c.category_id, CAST(m.month_start AS DATE), b.limit_amount
FROM (VALUES ('2026-07-01'), ('2026-08-01'), ('2026-09-01'),
             ('2026-10-01'), ('2026-11-01')) AS m(month_start)
CROSS JOIN (VALUES
    ('Rent',           3200.00),
    ('Groceries',      2000.00),
    ('Transport',       800.00),
    ('Data & Airtime',  400.00),
    ('Eating Out',      700.00),
    ('Entertainment',   400.00),
    ('Utilities',       500.00)
) AS b(cat, limit_amount)
JOIN categories c ON c.name = b.cat AND c.user_id = 1;
GO

-- ---------------------------------------------------------
-- Check the data: these are also good queries for your README
-- ---------------------------------------------------------

-- Row counts
SELECT 'users' AS tbl, COUNT(*) AS rows_count FROM users
UNION ALL SELECT 'categories',   COUNT(*) FROM categories
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'budgets',      COUNT(*) FROM budgets;
GO

-- Budget vs actual per category per month
SELECT b.month,
       c.name AS category,
       b.limit_amount AS budget,
       ISNULL(SUM(t.amount), 0) AS actual,
       b.limit_amount - ISNULL(SUM(t.amount), 0) AS remaining,
       CASE WHEN ISNULL(SUM(t.amount), 0) > b.limit_amount
            THEN 'OVER BUDGET' ELSE 'OK' END AS status
FROM budgets b
JOIN categories c ON c.category_id = b.category_id
LEFT JOIN transactions t
       ON t.category_id = b.category_id
      AND t.user_id = b.user_id
      AND t.transaction_date >= b.month
      AND t.transaction_date <  DATEADD(MONTH, 1, b.month)
GROUP BY b.month, c.name, b.limit_amount
ORDER BY b.month, c.name;
GO
