-- EXERCISE 1: Define "Team Velocity"
-- ============================================================
-- 1. Business Question: How fast is each organizational team delivering work, and which teams are underperforming?
-- 2. Exact Definition: "Velocity" is defined here as "Completed Tasks Per Active Team Member" within the analyzed sprint window.
--    Formula: SUM(tasks with status = 'completed') / COUNT(DISTINCT users in that team).
-- 3. Edge Cases:
--    - Zero Completed Tasks: Handled using NVL to display 0 instead of NULL.
--    - Teams with 0 Members: Left join ensures the team is preserved; NVL handles division by zero using a CASE check.
--    - Cancelled / Blocked / Open Tasks: Explicitly filtered out of the numerator; they do not count toward throughput.
-- 4. Unit: Count of completed tasks per capita (dimensionless ratio).
-- 5. Misleading Traits: Equalizes a 10-minute typo fix with a 40-hour architectural migration. A team closing high volumes of trivial tasks will artificially appear faster than a team tackling critical system regressions.
-- ============================================================

WITH team_stats AS (
SELECT
t.id AS team_id,
t.name AS team_name,
COUNT(DISTINCT u.id) AS team_members,
COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END) AS completed_tasks,
ROUND(
COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END) /
NULLIF(COUNT(DISTINCT u.id), 0), 2
) AS team_velocity
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
),
overall_avg AS (
SELECT AVG(team_velocity) AS system_avg_velocity FROM team_stats WHERE team_members > 0
)
SELECT
ts.team_name,
ts.team_members,
ts.completed_tasks,
ts.team_velocity,
CASE
WHEN ts.team_velocity < (SELECT system_avg_velocity FROM overall_avg) THEN 'BELOW AVERAGE'
ELSE 'TARGET MET'
END AS performance_flag
FROM team_stats ts;

-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================
-- 1. Business Question: Are we delivering tasks before our agreed deadlines, broken down by critical severity?
-- 2. Exact Definition:
--    - "On-Time": A task where CAST(completed_at AS DATE) <= due_date.
--    - Tasks completed at 23:59:59 on the due date are validly On-Time. 00:01:00 the next day is Late.
--    - "Rate": (On-Time Tasks / Total Completed Tasks) * 100.
-- 3. Edge Cases:
--    - Tasks without a due_date: Excluded entirely from both numerator and denominator since no delivery window contract existed.
--    - Cancelled / Open / Blocked: Excluded; rate is calculated solely against realized completions.
-- 4. Unit: Percentage (%). Lateness is measured in hours.
-- 5. Misleading Traits: Setting realistic deadlines can hide systematic bottlenecks. If the team defaults to extremely far-out due dates, the rate looks perfect even if operations are moving sluggishly.
-- ============================================================

SELECT
priority,
COUNT(id) AS total_completed_with_due,
ROUND(
(COUNT(CASE WHEN CAST(completed_at AS DATE) <= due_date THEN 1 END) / COUNT(id)) * 100, 2
) AS on_time_delivery_rate,
ROUND(
AVG(
CASE
WHEN CAST(completed_at AS DATE) > due_date THEN
EXTRACT(DAY FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24 +
EXTRACT(HOUR FROM (completed_at - CAST(due_date AS TIMESTAMP))) +
EXTRACT(MINUTE FROM (completed_at - CAST(due_date AS TIMESTAMP))) / 60
ELSE NULL
END
), 1
) AS avg_lateness_hours
FROM tasks
WHERE status = 'completed'
AND due_date IS NOT NULL
AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY CASE priority
WHEN 'critical' THEN 1
WHEN 'high' THEN 2
WHEN 'medium' THEN 3
WHEN 'low' THEN 4
END;

-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team"
-- ============================================================

SELECT
t.name AS team_name,
COUNT(ts.id) AS total_tasks,
COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) AS active_tasks,
ROUND(
COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) /
NULLIF(COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END), 0) * 100, 1
) AS completion_rate,
CASE
WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) > 10 THEN 'Overloaded'
WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) BETWEEN 5 AND 10 THEN 'Healthy'
ELSE 'Underutilized'
END AS health_score
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY active_tasks DESC;

-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time"
-- ============================================================
-- Edge case resolution: If COUNT(*) = 1, the string flag warns downstream analytics that the baseline is volatile.
-- ============================================================

SELECT
priority,
COUNT(*) AS completed_task_count,
ROUND(AVG(
EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
EXTRACT(HOUR FROM (completed_at - created_at)) +
EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
), 1) AS avg_resolution_hours,
ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
ORDER BY (EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
EXTRACT(HOUR FROM (completed_at - created_at)) +
EXTRACT(MINUTE FROM (completed_at - created_at)) / 60)
), 1) AS median_resolution_hours,
ROUND(MIN(
EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
EXTRACT(HOUR FROM (completed_at - created_at)) +
EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
), 1) AS fastest_resolution_hours,
ROUND(MAX(
EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
EXTRACT(HOUR FROM (completed_at - created_at)) +
EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
), 1) AS slowest_resolution_hours,
CASE
WHEN priority = 'critical' AND AVG(EXTRACT(DAY FROM (completed_at - created_at))*24 + EXTRACT(HOUR FROM (completed_at - created_at))) <= 24 THEN 'SLA MET'
WHEN priority = 'high'     AND AVG(EXTRACT(DAY FROM (completed_at - created_at))*24 + EXTRACT(HOUR FROM (completed_at - created_at))) <= 72 THEN 'SLA MET'
WHEN priority = 'medium'   AND AVG(EXTRACT(DAY FROM (completed_at - created_at))*24 + EXTRACT(HOUR FROM (completed_at - created_at))) <= 168 THEN 'SLA MET'
WHEN priority = 'low'      AND AVG(EXTRACT(DAY FROM (completed_at - created_at))24 + EXTRACT(HOUR FROM (completed_at - created_at))) <= 336 THEN 'SLA MET'
ELSE 'SLA BREACHED'
END AS sla_status,
CASE WHEN COUNT() = 1 THEN 'WARNING: Insufficient Sample Size' ELSE 'Stable' END AS data_reliability
FROM tasks
WHERE status = 'completed'
AND completed_at IS NOT NULL
GROUP BY priority
ORDER BY CASE priority
WHEN 'critical' THEN 1
WHEN 'high' THEN 2
WHEN 'medium' THEN 3
WHEN 'low' THEN 4
END;

-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks"
-- ============================================================
-- Using a fixed evaluation point matching the seed architecture window
-- ============================================================

WITH base_overdue_report AS (
SELECT
ts.title,
NVL(u.full_name, 'UNASSIGNED') AS assignee,
NVL(t.name, 'NO TEAM') AS team_name,
ts.priority,
ts.due_date,
CEIL(CAST(TIMESTAMP '2026-05-15 00:00:00' AS DATE) - ts.due_date) AS days_overdue
FROM tasks ts
LEFT JOIN users u ON ts.assigned_to = u.id
LEFT JOIN teams t ON u.team_id = t.id
WHERE ts.due_date < CAST(TIMESTAMP '2026-05-15 00:00:00' AS DATE)
AND ts.status NOT IN ('completed', 'cancelled')
AND ts.due_date IS NOT NULL
),
enriched_report AS (
SELECT
title, assignee, team_name, priority, due_date, days_overdue,
CASE
WHEN priority = 'critical' AND days_overdue > 0 THEN '1-CRITICAL'
WHEN priority = 'high'     AND days_overdue > 2 THEN '2-HIGH'
WHEN priority = 'medium'   AND days_overdue > 5 THEN '3-MEDIUM'
ELSE '4-LOW'
END AS severity
FROM base_overdue_report
)
SELECT title, assignee, team_name, priority, due_date, days_overdue, severity
FROM enriched_report
UNION ALL
SELECT
'=== SUMMARY ROW ===' AS title,
NULL AS assignee,
NULL AS team_name,
severity AS priority,
NULL AS due_date,
ROUND(AVG(days_overdue), 1) AS days_overdue,
'TOTAL COUNT: ' || TO_CHAR(COUNT(*)) AS severity
FROM enriched_report
GROUP BY severity
ORDER BY severity ASC, days_overdue DESC;

-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================
-- PROBLEM: The bad query uses an INNER JOIN on assigned tasks and counts everything.
-- 1. It conflates merely opening/getting assigned a task with completing it.
-- 2. It values trivial tasks identically to major system overhauls.
-- 3. It hides unassigned tasks and penalizes developers on deep, complex individual issues.
-- REWRITE: Weight finished tasks by priority values (Critical=4, High=3, Medium=2, Low=1).
-- ============================================================

SELECT
u.full_name,
COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS tasks_completed,
SUM(CASE WHEN ts.status = 'completed' THEN
CASE ts.priority
WHEN 'critical' THEN 4
WHEN 'high'     THEN 3
WHEN 'medium'   THEN 2
WHEN 'low'      THEN 1
ELSE 0
END
ELSE 0 END) AS weighted_productivity_score
FROM users u
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY u.id, u.full_name
ORDER BY weighted_productivity_score DESC;

-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================
-- PROBLEM: The query evaluates AVG(ts.id). Mathematically, finding the mean average
-- of an autoincrementing, non-ordinal internal surrogate primary key produces absolute garbage data.
-- It represents nothing related to corporate efficiency.
-- REWRITE: Calculate completed work as a functional percentage of total non-cancelled requests.
-- ============================================================

SELECT
t.name AS team_name,
COUNT(ts.id) AS total_scoped_tasks,
COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
ROUND(
COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) /
NULLIF(COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END), 0) * 100, 2
) || '%' AS operational_efficiency_rate
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) / NULLIF(COUNT(*),0) DESC;

-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================
-- PROBLEM: The bad query attempts arithmetic concatenation across strong primitive boundaries
-- by evaluating a string literal (priority) combined directly with a temporal object (DUE_DATE).
-- This completely breaks standard type systems and results in ORA errors during execution.
-- REWRITE: Extract an integer representation from priority and subtract proximity distance.
-- ============================================================

SELECT
title,
priority,
due_date,
status,
(
CASE priority
WHEN 'critical' THEN 40
WHEN 'high'     THEN 30
WHEN 'medium'   THEN 20
WHEN 'low'      THEN 10
ELSE 0
END
) + (
CEIL(CAST(TIMESTAMP '2026-05-15 00:00:00' AS DATE) - due_date) * 2
) AS analytical_urgency_index
FROM tasks
WHERE status NOT IN ('completed', 'cancelled') AND due_date IS NOT NULL
ORDER BY analytical_urgency_index DESC;