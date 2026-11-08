-- Q15 | Review workbook calculation differences and potential duplicate deals.
-- Primary, foreign and check constraints reject invalid keys, amounts and statuses.
-- Identical deal attributes can be legitimate; review the listed IDs before acting.
SELECT
    'Workbook calculation mismatch' AS issue,
    txn_id AS transaction_ids,
    CONCAT('Eligible: ', workbook_eligible_revenue, ' vs ', eligible_revenue,
           '; commission: ', workbook_commission, ' vs ', commission) AS detail
FROM deal_financials
WHERE workbook_eligible_revenue <> eligible_revenue OR workbook_commission <> commission

UNION ALL

SELECT
    'Possible duplicate deal',
    GROUP_CONCAT(txn_id ORDER BY txn_id SEPARATOR ', '),
    CONCAT(COUNT(*), ' deals for ', rep_id, ' / ', client, ' / ', product, ' on ', close_date)
FROM sales_transactions
GROUP BY rep_id, close_date, client, product, gross_amount, discount, status
HAVING COUNT(*) > 1

ORDER BY issue, transaction_ids;
