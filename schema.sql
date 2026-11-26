-- Expense Tracker: starter schema (SQL Server / T-SQL)

CREATE DATABASE ExpenseTracker;
GO

USE ExpenseTracker;
GO

CREATE TABLE users (
    user_id     INT IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(100) NOT NULL,
    email       NVARCHAR(150) NOT NULL UNIQUE,
    created_at  DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(user_id),
    name        NVARCHAR(100) NOT NULL,
    type        NVARCHAR(10) NOT NULL CHECK (type IN ('income', 'expense')),
    CONSTRAINT uq_category UNIQUE (user_id, name)
);
GO

CREATE TABLE transactions (
    transaction_id   INT IDENTITY(1,1) PRIMARY KEY,
    user_id          INT NOT NULL REFERENCES users(user_id),
    category_id      INT NOT NULL REFERENCES categories(category_id),
    amount           DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description      NVARCHAR(255) NULL,
    transaction_date DATE NOT NULL
);
GO

CREATE TABLE budgets (
    budget_id    INT IDENTITY(1,1) PRIMARY KEY,
    user_id      INT NOT NULL REFERENCES users(user_id),
    category_id  INT NOT NULL REFERENCES categories(category_id),
    month        DATE NOT NULL,  -- first day of the month, e.g. 2026-11-01
    limit_amount DECIMAL(10,2) NOT NULL CHECK (limit_amount > 0),
    CONSTRAINT uq_budget UNIQUE (user_id, category_id, month)
);
GO

CREATE INDEX ix_transactions_user_date
    ON transactions (user_id, transaction_date);
GO
