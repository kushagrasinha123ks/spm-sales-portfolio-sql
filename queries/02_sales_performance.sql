-- Q05 | How did eligible revenue change month to month?
SELECT
    month_start,
    SUM(won_deals) AS won_deals,
    SUM(eligible_revenue) AS eligible_revenue,
    SUM(expected_commission) AS earned_commission
FROM rep_month_performance
GROUP BY month_start
ORDER BY month_start;

-- Q06 | Which regions generated more than ₹50 lakh in eligible revenue?
SELECT
    r.region,
    SUM(d.eligible_revenue) AS eligible_revenue,
    COUNT(*) AS won_deals
FROM deal_financials AS d
JOIN sales_reps AS r ON r.rep_id = d.rep_id
WHERE d.status = 'Won'
GROUP BY r.region
HAVING SUM(d.eligible_revenue) > 5000000
ORDER BY eligible_revenue DESC, r.region;
