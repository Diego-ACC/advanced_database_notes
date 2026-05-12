-- Create the table
DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',   1000.00);
INSERT INTO accounts VALUES (2, 'Bob',      500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);

-- Make data permanent
COMMIT;

-- Verify starting state
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;



UPDATE accounts SET balance = balance - 500 WHERE account_id = 1;

SELECT * FROM accounts ORDER BY account_id;

ROLLBACK;

SELECT * FROM accounts ORDER BY account_id;



UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;

SELECT * FROM accounts ORDER BY account_id;

COMMIT;



UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;

SAVEPOINT after_alice;

UPDATE accounts SET balance = balance + 100 WHERE account_id = 3;

ROLLBACK TO SAVEPOINT after_alice;

UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

COMMIT;

SELECT * FROM accounts ORDER BY account_id;