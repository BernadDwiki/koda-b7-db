CREATE TABLE users (
    id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255),
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    pin CHAR(6),
    picture VARCHAR(255),
    phone_number VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

CREATE TABLE ewallets (
    id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_id int NOT NULL UNIQUE,
    balance bigint DEFAULT 0,
    income bigint DEFAULT 0,
    expense bigint DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE payment_methods (
    id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    method_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

-- table payment_methods;

INSERT INTO payment_methods (method_name)
VALUES ('BRI'), ('Dana'), ('BCA'), ('Gopay'), ('Ovo');

CREATE TYPE transaction_type AS ENUM ('transfer', 'top_up');
CREATE TYPE transaction_status AS ENUM ('pending', 'success', 'failed');

CREATE TABLE transactions (
    id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    amount bigint NOT NULL,
    transaction_type transaction_type NOT NULL,
    note VARCHAR(255),
    status transaction_status NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP
);

CREATE TABLE transfer_details (
    id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    transaction_id int NOT NULL UNIQUE,
    sender_id int NOT NULL,
    receiver_id int NOT NULL,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id)
);

CREATE TABLE top_up_details (
    id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    transaction_id int NOT NULL UNIQUE,
    receiver_id int NOT NULL,
    payment_method_id int NOT NULL,
    discount bigint,
    tax bigint,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id),
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
);

--Login
SELECT id, name, email, picture, phone_number, pin
FROM users
WHERE email = 'bernad@example.com' AND password = 'dwiki123';

UPDATE users
SET pin = '123456', updated_at = NOW()
WHERE email = 'bernad@example.com';

-- Register
INSERT INTO users (email, password)
VALUES ('bernad@example.com', 'dwiki123'),
       ('yuki@example.com', 'yukipassword');

INSERT INTO ewallets (user_id, balance, income, expense)
VALUES ((SELECT id FROM users WHERE email = 'bernad@example.com'), 0, 0, 0),
       ((SELECT id FROM users WHERE email = 'yuki@example.com'), 0, 0, 0);

-- get user login information
SELECT id, name, email, picture, phone_number
FROM users
WHERE id = 1;

-- get/check user pin
SELECT pin
FROM users
WHERE id = 1;

-- get transaction history for a user
SELECT t.id, u1.name AS sender_name, u2.name AS receiver_name, t.amount, t.transaction_type, t.created_at, t.note, t.status
FROM transactions t
JOIN transfer_details td ON t.id = td.transaction_id
LEFT JOIN users u1 ON td.sender_id = u1.id
JOIN users u2 ON td.receiver_id = u2.id
WHERE td.sender_id = (SELECT id FROM users WHERE email = 'bernad@example.com' AND password = 'dwiki123')
OR td.receiver_id = (SELECT id FROM users WHERE email = 'bernad@example.com' AND password = 'dwiki123')
ORDER BY t.created_at DESC;

-- get user history with option (income/expense, date range)
-- income
SELECT t.id, u1.name AS sender_name, u2.name AS receiver_name, t.amount, t.transaction_type, t.created_at, t.note, t.status
FROM transactions t
JOIN transfer_details td ON t.id = td.transaction_id
LEFT JOIN users u1 ON td.sender_id = u1.id
JOIN users u2 ON td.receiver_id = u2.id
WHERE td.receiver_id = (SELECT id FROM users WHERE email = 'yuki@example.com' AND password = 'yukipassword')
ORDER BY t.created_at DESC;

-- expense
SELECT t.id, u1.name AS sender_name, u2.name AS receiver_name, t.amount, t.transaction_type, t.created_at, t.note, t.status
FROM transactions t
JOIN transfer_details td ON t.id = td.transaction_id
LEFT JOIN users u1 ON td.sender_id = u1.id
JOIN users u2 ON td.receiver_id = u2.id
WHERE td.sender_id = (SELECT id FROM users WHERE email = 'bernad@example.com' AND password = 'dwiki123')
ORDER BY t.created_at DESC;

-- date range
SELECT t.id, u1.name AS sender_name, u2.name AS receiver_name, t.amount, t.transaction_type, t.created_at, t.note, t.status
FROM transactions t
JOIN transfer_details td ON t.id = td.transaction_id
LEFT JOIN users u1 ON td.sender_id = u1.id
JOIN users u2 ON td.receiver_id = u2.id
WHERE t.created_at BETWEEN '2026-01-01 00:00:00' AND '2026-12-31 23:59:59'
AND (t.sender_id = (SELECT id FROM users WHERE email = 'bernad@example.com' AND password = 'dwiki123')
OR t.receiver_id = (SELECT id FROM users WHERE email = 'bernad@example.com' AND password = 'dwiki123'))
ORDER BY t.created_at DESC;

-- get account information (balance, income, expense)
SELECT balance, income, expense
FROM ewallets
WHERE user_id = (SELECT id FROM users WHERE email = 'bernad@example.com' AND password = 'dwiki123');

--table ewallets;
--table transactions;
--table users;

-- find receiver with pagination
SELECT name, picture, phone_number
FROM users
WHERE id != (SELECT id FROM users WHERE email = 'bernad@example.com')
AND name ILIKE '%a%'
ORDER BY name
LIMIT 10 OFFSET 0;

-- create transaction/top up
--- transfer
SELECT *
FROM ewallets
WHERE user_id = 1
AND balance >= 10000;

BEGIN;

WITH new_transaction AS (
    INSERT INTO transactions (amount, transaction_type, note, status)
    VALUES (10000, 'transfer', 'Transfer to Yuki', 'success')
    RETURNING id
)

INSERT INTO transfer_details (transaction_id, sender_id, receiver_id)
SELECT id, 1, 2
FROM new_transaction;

UPDATE ewallets
SET balance = balance - 10000, expense = expense + 10000, updated_at = NOW()
WHERE user_id = 1
AND balance >= 10000;

UPDATE ewallets
SET balance = balance + 10000, income = income + 10000, updated_at = NOW()
WHERE user_id = 2;

COMMIT;

--- top up
BEGIN;

WITH new_transaction AS (
    INSERT INTO transactions (amount, transaction_type, note, status)
    VALUES (50000, 'top_up', 'Top up via BRI', 'success')
    RETURNING id
)

INSERT INTO top_up_details (transaction_id, receiver_id, payment_method_id, discount, tax)
SELECT id, 1, (SELECT id FROM payment_methods WHERE method_name = 'BRI'), 0, 0
FROM new_transaction;

UPDATE ewallets
SET balance = balance + 50000, income = income + 50000, updated_at = NOW()
WHERE user_id = 1;

COMMIT;

-- get user profile (photo, name, email, phone number)
SELECT name, email, picture, phone_number
FROM users
WHERE id = 1;

-- change pin
UPDATE users
SET pin = '654321', updated_at = NOW()
WHERE id = 1;

-- change password
UPDATE users
SET password = 'bernad123', updated_at = NOW()
WHERE id = 1;

-- change user profile
UPDATE users
SET name = 'Bernadus Dwiki', picture = 'newpicture.jpg', phone_number = '081234567899', updated_at = NOW()
WHERE id = 1;
