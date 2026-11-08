-- Q07 | How much revenue and commission did each rep with a win earn?
SELECT
    r.rep_id,
    r.rep_name,
    r.region,
    SUM(d.eligible_revenue) AS eligible_revenue,
    SUM(d.commission) AS earned_commission
FROM sales_reps AS r
INNER JOIN deal_financials AS d ON d.rep_id = r.rep_id
WHERE d.status = 'Won'
GROUP BY r.rep_id, r.rep_name, r.region
ORDER BY eligible_revenue DESC, r.rep_id;

-- Q08 | Which reps recorded no wins? Keep the status filter in ON so
-- the join retains reps with no transactions and reps with only non-wins.
SELECT r.rep_id, r.rep_name, r.region
FROM sales_reps AS r
LEFT JOIN sales_transactions AS t ON t.rep_id = r.rep_id AND t.status = 'Won'
WHERE t.txn_id IS NULL
ORDER BY r.rep_id;

-- Q09 | Who earned above the team average? Reps with no wins count as zero.
WITH rep_commissions AS (
    SELECT
        r.rep_id,
        r.rep_name,
        COALESCE(SUM(d.commission), 0) AS earned_commission
    FROM sales_reps AS r
    LEFT JOIN deal_financials AS d ON d.rep_id = r.rep_id
    GROUP BY r.rep_id, r.rep_name
)
SELECT rep_id, rep_name, earned_commission
FROM rep_commissions
WHERE earned_commission > (SELECT AVG(earned_commission) FROM rep_commissions)
ORDER BY earned_commission DESC, rep_id;
