Create database banking;
use banking;
describe transactions;

select * from branch;
select * from customers2;
select * from transactions;
select * from employees3;
select * from accounts1;


/*Ques1*/
WITH recent_transactions AS (
    SELECT DISTINCT account_number
    FROM transactions
    WHERE transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
),
inactive_customers AS (
    SELECT DISTINCT a.customer_id
    FROM accounts1 a
    LEFT JOIN recent_transactions rt
    ON a.account_number = rt.account_number
    WHERE rt.account_number IS NULL
)
SELECT c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.city, c.state
FROM customers2 c
JOIN inactive_customers ic
ON c.customer_id = ic.customer_id;

/*Ques2*/
SELECT 
    account_number,
    DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
    SUM(amount) AS total_transaction_amount
FROM transactions
GROUP BY account_number, DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY account_number, transaction_month;

/*Ques3*/
WITH recent_transactions AS (
    SELECT 
        t.account_number, 
        t.amount, 
        a.branch_id
    FROM transactions t
    JOIN accounts1 a ON t.account_number = a.account_number
    WHERE t.transaction_type = 'Deposit'
      AND t.transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL QUARTER(CURRENT_DATE) - 1 QUARTER)
),

branch_totals AS (
    SELECT 
        branch_id,
        SUM(amount) AS total_deposit_amount
    FROM recent_transactions
    GROUP BY branch_id
)

SELECT 
    br.branch_id,
    br.branch_name,
    br.city,
    br.state,
    bt.total_deposit_amount,
    RANK() OVER (ORDER BY bt.total_deposit_amount DESC) AS rank1
FROM branch_totals bt
JOIN branch br ON bt.branch_id = br.branch_id;

/*Ques4*/
SELECT 
    c.first_name,
    c.last_name,
    c.customer_id,
    t.account_number,
    MAX(t.amount) AS highest_deposit
FROM transactions t
JOIN accounts1 a ON t.account_number = a.account_number
JOIN customers2 c ON a.customer_id = c.customer_id
WHERE t.transaction_type = 'Deposit'
GROUP BY c.customer_id, c.first_name, c.last_name, t.account_number
ORDER BY highest_deposit DESC
LIMIT 1;

/*Ques5*/
SELECT 
    t.account_number,
    t.transaction_date,
    COUNT(t.transaction_id) AS transaction_count
FROM transactions t
GROUP BY t.account_number, t.transaction_date
HAVING COUNT(t.transaction_id) > 2;

/*Ques6*/
WITH recent_transactions AS (
    SELECT 
        t.transaction_id,
        t.account_number,
        a.customer_id,
        DATE_FORMAT(t.transaction_date, '%Y-%m') AS transaction_month
    FROM transactions t
    JOIN accounts1 a ON t.account_number = a.account_number
    WHERE t.transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
),

monthly_transaction_counts AS (
    SELECT 
        rt.customer_id,
        rt.account_number,
        rt.transaction_month,
        COUNT(rt.transaction_id) AS monthly_transaction_count
    FROM recent_transactions rt
    GROUP BY rt.customer_id, rt.account_number, rt.transaction_month
),

average_transactions AS (
    SELECT 
        customer_id,
        account_number,
        AVG(monthly_transaction_count) AS avg_transactions_per_month
    FROM monthly_transaction_counts
    GROUP BY customer_id, account_number
)

SELECT 
    customer_id,
    account_number,
    avg_transactions_per_month
FROM average_transactions
ORDER BY avg_transactions_per_month DESC;

/*Ques7*/
SELECT 
    DATE(transaction_date) AS transaction_date,
    SUM(amount) AS daily_transaction_volume
FROM transactions
WHERE transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)
GROUP BY DATE(transaction_date)
ORDER BY transaction_date;

/*Ques8*/
WITH age_groups AS (
    SELECT 
        c.customer_id,
        TIMESTAMPDIFF(YEAR, c.date_of_birth, CURDATE()) AS age
    FROM customers2 c
),

transactions_with_age AS (
    SELECT 
        t.transaction_id,
        t.account_number,
        t.amount,
        t.transaction_date,
        ag.age,
        CASE
            WHEN ag.age BETWEEN 0 AND 17 THEN '0-17'
            WHEN ag.age BETWEEN 18 AND 30 THEN '18-30'
            WHEN ag.age BETWEEN 31 AND 60 THEN '31-60'
            ELSE '60+'
        END AS age_group
    FROM transactions t
    JOIN accounts1 a ON t.account_number = a.account_number
    JOIN age_groups ag ON a.customer_id = ag.customer_id
    WHERE t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
)

SELECT 
    age_group,
    SUM(amount) AS total_transaction_amount
FROM transactions_with_age
GROUP BY age_group
ORDER BY FIELD(age_group, '0-17', '18-30', '31-60', '60+');


/*Ques9*/
SELECT 
    b.branch_id,
    b.branch_name,
    b.city,
    b.state,
    AVG(a.balance) AS average_account_balance
FROM accounts1 a
JOIN branch b ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name, b.city, b.state
ORDER BY average_account_balance DESC
LIMIT 1;


/*Ques10*/
WITH monthly_balances AS (
    SELECT 
        a.customer_id,
        DATE_FORMAT(LAST_DAY(t.transaction_date), '%Y-%m-%d') AS month_end,
        SUM(CASE 
            WHEN t.transaction_type = 'Deposit' THEN t.amount
            WHEN t.transaction_type = 'Withdrawal' THEN -t.amount
            ELSE 0
        END) AS net_monthly_transaction
    FROM transactions t
    JOIN accounts1 a ON t.account_number = a.account_number
    WHERE t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY a.customer_id, DATE_FORMAT(LAST_DAY(t.transaction_date), '%Y-%m-%d')
),

customer_monthly_balances AS (
    SELECT 
        mb.customer_id,
        mb.month_end,
        COALESCE(SUM(mb.net_monthly_transaction), 0) + 
        (SELECT COALESCE(SUM(balance), 0) 
         FROM accounts1 a WHERE a.customer_id = mb.customer_id) AS month_end_balance
    FROM monthly_balances mb
)

SELECT 
    month_end,
    AVG(month_end_balance) AS avg_balance_per_customer
FROM customer_monthly_balances
GROUP BY month_end
ORDER BY month_end;

      
   
    
