-- MySQL 8.0.16+ (enforced CHECK constraints). Run in a fresh database.

CREATE TABLE sales_reps (
    rep_id           VARCHAR(12)   PRIMARY KEY,
    rep_name         VARCHAR(100)  NOT NULL,
    region           VARCHAR(40)   NOT NULL,
    monthly_quota    DECIMAL(14,2) NOT NULL,
    commission_rate  DECIMAL(7,6)  NOT NULL,
    CONSTRAINT chk_rep_quota CHECK (monthly_quota > 0),
    CONSTRAINT chk_rep_rate CHECK (commission_rate BETWEEN 0 AND 1)
);

CREATE TABLE sales_transactions (
    txn_id            VARCHAR(12)   PRIMARY KEY,
    rep_id            VARCHAR(12)   NOT NULL,
    close_date        DATE          NOT NULL,
    client            VARCHAR(100)  NOT NULL,
    product           VARCHAR(100)  NOT NULL,
    gross_amount      DECIMAL(14,2) NOT NULL,
    discount          DECIMAL(14,2) NOT NULL,
    status            VARCHAR(12)   NOT NULL,
    eligible_revenue  DECIMAL(14,2) NOT NULL COMMENT 'Excel control value',
    commission        DECIMAL(14,2) NOT NULL COMMENT 'Excel control value',
    CONSTRAINT fk_txn_rep FOREIGN KEY (rep_id) REFERENCES sales_reps (rep_id),
    CONSTRAINT chk_txn_amounts CHECK (gross_amount >= 0 AND discount BETWEEN 0 AND gross_amount),
    CONSTRAINT chk_txn_status CHECK (status IN ('Won', 'Pending', 'Cancelled')),
    CONSTRAINT chk_txn_control_values CHECK (eligible_revenue >= 0 AND commission >= 0),
    INDEX ix_txn_rep_date (rep_id, close_date)
);

CREATE TABLE commission_payouts (
    payout_id      VARCHAR(12)   PRIMARY KEY,
    rep_id         VARCHAR(12)   NOT NULL,
    payout_month   DATE          NOT NULL,
    payout_amount  DECIMAL(14,2) NOT NULL COMMENT 'Amount actually disbursed',
    payout_status  VARCHAR(12)   NOT NULL,
    CONSTRAINT fk_payout_rep FOREIGN KEY (rep_id) REFERENCES sales_reps (rep_id),
    CONSTRAINT uq_payout_rep_month UNIQUE (rep_id, payout_month),
    CONSTRAINT chk_payout_month CHECK (DAYOFMONTH(payout_month) = 1),
    CONSTRAINT chk_payout_amount CHECK (payout_amount >= 0),
    CONSTRAINT chk_payout_status CHECK (payout_status IN ('Paid', 'Pending')),
    CONSTRAINT chk_pending_unpaid CHECK (payout_status <> 'Pending' OR payout_amount = 0)
);

-- Recompute financials from deal inputs and the rep's rate. Retain the
-- workbook values so Q15 can independently compare both sets of figures.
CREATE SQL SECURITY INVOKER VIEW deal_financials AS
SELECT
    d.*,
    ROUND(d.eligible_revenue * d.commission_rate, 2) AS commission
FROM (
    SELECT
        t.txn_id,
        t.rep_id,
        t.close_date,
        t.client,
        t.product,
        t.gross_amount,
        t.discount,
        t.status,
        r.commission_rate,
        t.eligible_revenue AS workbook_eligible_revenue,
        t.commission AS workbook_commission,
        CASE WHEN t.status = 'Won' THEN t.gross_amount - t.discount ELSE 0 END AS eligible_revenue
    FROM sales_transactions AS t
    JOIN sales_reps AS r ON r.rep_id = t.rep_id
) AS d;

-- One row per rep and reporting month, including months without any sales.
CREATE SQL SECURITY INVOKER VIEW rep_month_performance AS
WITH RECURSIVE reporting_months AS (
    SELECT DATE('2025-01-01') AS month_start
    UNION ALL
    SELECT month_start + INTERVAL 1 MONTH
    FROM reporting_months
    WHERE month_start < DATE('2025-06-01')
)
SELECT
    r.rep_id,
    m.month_start,
    COUNT(d.txn_id) AS won_deals,
    COALESCE(SUM(d.eligible_revenue), 0) AS eligible_revenue,
    COALESCE(SUM(d.commission), 0) AS expected_commission
FROM sales_reps AS r
CROSS JOIN reporting_months AS m
LEFT JOIN deal_financials AS d
    ON d.rep_id = r.rep_id
    AND d.close_date >= m.month_start
    AND d.close_date < m.month_start + INTERVAL 1 MONTH
    AND d.status = 'Won'
GROUP BY r.rep_id, m.month_start;
