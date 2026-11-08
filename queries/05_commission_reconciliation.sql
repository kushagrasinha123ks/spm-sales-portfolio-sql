-- Q14 | Compare settled payouts with SQL-calculated commission by rep and month.
-- Variance = settled payout minus expected commission. Pending and missing
-- payouts are tracked separately from discrepancies on paid records.
WITH reconciled AS (
    SELECT
        m.month_start AS payout_month,
        r.rep_id,
        r.rep_name,
        m.expected_commission,
        p.payout_status,
        COALESCE(p.payout_amount, 0) AS actual_payout,
        COALESCE(p.payout_amount, 0) - m.expected_commission AS variance,
        CASE
            WHEN p.payout_id IS NULL AND m.expected_commission = 0 THEN 'No commission due'
            WHEN p.payout_id IS NULL THEN 'Missing payout'
            WHEN p.payout_status = 'Pending' THEN 'Pending payout'
            WHEN p.payout_amount > m.expected_commission THEN 'Overpaid'
            WHEN p.payout_amount < m.expected_commission THEN 'Underpaid'
            ELSE 'Matched'
        END AS reconciliation_status
    FROM rep_month_performance AS m
    JOIN sales_reps AS r ON r.rep_id = m.rep_id
    LEFT JOIN commission_payouts AS p
        ON p.rep_id = m.rep_id AND p.payout_month = m.month_start
)
SELECT
    payout_month,
    rep_id,
    rep_name,
    expected_commission,
    actual_payout,
    variance,
    payout_status,
    reconciliation_status
FROM reconciled
ORDER BY
    reconciliation_status IN ('Matched', 'No commission due'),
    payout_month,
    rep_id;
