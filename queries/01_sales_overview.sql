-- Q01 | Which deals were won? Show the most recent first.
SELECT txn_id, close_date, rep_id, client, product, eligible_revenue
FROM deal_financials
WHERE status = 'Won'
ORDER BY close_date DESC, txn_id;

-- Q02 | Which won deals generated more than ₹2 lakh after discount?
SELECT txn_id, close_date, rep_id, client, eligible_revenue
FROM deal_financials
WHERE status = 'Won' AND eligible_revenue > 200000
ORDER BY eligible_revenue DESC, txn_id;

-- Q03 | Which products and sales regions are represented?
SELECT DISTINCT 'Product' AS dimension, product AS label
FROM sales_transactions
UNION ALL
SELECT DISTINCT 'Region', region
FROM sales_reps
ORDER BY dimension, label;

-- Q04 | How much eligible revenue did we earn, and what was the average won deal?
SELECT
    COUNT(*) AS won_deals,
    COALESCE(SUM(eligible_revenue), 0) AS total_eligible_revenue,
    ROUND(AVG(eligible_revenue), 2) AS avg_won_deal_value,
    COALESCE(SUM(commission), 0) AS total_earned_commission
FROM deal_financials
WHERE status = 'Won';
