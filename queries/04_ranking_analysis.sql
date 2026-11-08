-- Q10 | Rank all reps by eligible revenue. Tied reps share a rank.
WITH rep_revenue AS (
    SELECT
        r.rep_id,
        r.rep_name,
        r.region,
        COALESCE(SUM(d.eligible_revenue), 0) AS eligible_revenue
    FROM sales_reps AS r
    LEFT JOIN deal_financials AS d ON d.rep_id = r.rep_id
    GROUP BY r.rep_id, r.rep_name, r.region
)
SELECT
    rep_id,
    rep_name,
    region,
    eligible_revenue,
    DENSE_RANK() OVER (ORDER BY eligible_revenue DESC) AS revenue_rank
FROM rep_revenue
ORDER BY revenue_rank, rep_id;

-- Q11 | Who are the top two reps in each region? Break ties by rep ID.
WITH rep_revenue AS (
    SELECT
        r.rep_id,
        r.rep_name,
        r.region,
        COALESCE(SUM(d.eligible_revenue), 0) AS eligible_revenue
    FROM sales_reps AS r
    LEFT JOIN deal_financials AS d ON d.rep_id = r.rep_id
    GROUP BY r.rep_id, r.rep_name, r.region
), ranked_reps AS (
    SELECT
        rep_id,
        rep_name,
        region,
        eligible_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY region ORDER BY eligible_revenue DESC, rep_id
        ) AS region_rank
    FROM rep_revenue
)
SELECT region, region_rank, rep_id, rep_name, eligible_revenue
FROM ranked_reps
WHERE region_rank <= 2
ORDER BY region, region_rank;

-- Q12 | What percentage of company eligible revenue came from each region?
WITH region_revenue AS (
    SELECT r.region, COALESCE(SUM(d.eligible_revenue), 0) AS eligible_revenue
    FROM sales_reps AS r
    LEFT JOIN deal_financials AS d ON d.rep_id = r.rep_id
    GROUP BY r.region
)
SELECT
    region,
    eligible_revenue,
    ROUND(100 * eligible_revenue / NULLIF(SUM(eligible_revenue) OVER (), 0), 2) AS revenue_share_pct
FROM region_revenue
ORDER BY eligible_revenue DESC, region;

-- Q13 | Which rep-months missed quota, including those with no wins?
SELECT
    m.month_start,
    r.rep_id,
    r.rep_name,
    r.region,
    m.won_deals,
    m.eligible_revenue,
    r.monthly_quota,
    ROUND(100 * m.eligible_revenue / r.monthly_quota, 2) AS attainment_pct,
    GREATEST(r.monthly_quota - m.eligible_revenue, 0) AS quota_shortfall,
    CASE WHEN m.eligible_revenue >= r.monthly_quota THEN 'Met' ELSE 'Below quota' END AS quota_status
FROM rep_month_performance AS m
JOIN sales_reps AS r ON r.rep_id = m.rep_id
ORDER BY m.month_start, quota_shortfall DESC, r.rep_id;
