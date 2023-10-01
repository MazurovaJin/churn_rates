--Q1 We take a look at the first 100 rows of data in the subscriptions table. How many different segments do we see?

 SELECT * FROM subscriptions
 LIMIT 100;
 
-- 87, 30
 
--Q2 We determine the range of months of data provided. Which months will we be able to calculate churn for? 

 SELECT MIN(subscription_start) as start, MAX(subscription_start) as end
 FROM subscriptions;
 
/*Query Results
|start	     |end     |
|-----------|-----------|
|2016-12-01 |	2017-03-30|
*/

--Q3 We’ll be calculating the churn rate for both segments (87 and 30) over the first 3 months of 2017 (we can’t calculate it for December, since there are no subscription_end values yet). To get started, we create a temporary table of months.

WITH months AS
(SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
UNION
 SELECT 
  '2017-02-01' as first_day,
  '2017-02-28' as last_day
UNION
 SELECT 
  '2017-03-01' as first_day,
  '2017-03-31' as last_day
)
SELECT * FROM months;
 
--Q4 We create a temporary table, cross_join, from subscriptions and our months. 

WITH months AS 
 (SELECT 
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
    UNION
     SELECT
      '2017-02-01' AS first_day,
      '2017-02-28' AS last_day
    UNION
     SELECT
      '2017-03-01' AS first_day,
      '2017-03-31' AS last_day      
 ),
cross_join AS
  (SELECT *
  FROM subscriptions
  CROSS JOIN months
  )
SELECT *
FROM cross_join
LIMIT 3;

/*
|id	|subscription_start	|subscription_end|	segment |	first_day	|last_day
|1	|2016-12-01|	2017-02-01|	87|	2017-01-01|	2017-01-31|
|1 |2016-12-01	|2017-02-01|	87|	2017-02-01|	2017-02-28|
|1	|2016-12-01|	2017-02-01|	87|	2017-03-01|	2017-03-31| */

/*Q5 We create a temporary table, status, from the cross_join table you created. This table should contain:
-id selected from cross_join
-month as an alias of first_day
-is_active_87 created using a CASE WHEN to find any users from segment 87 who existed prior to the beginning of the month. This is 1 if true and 0 otherwise.
-is_active_30 created using a CASE WHEN to find any users from segment 30 who existed prior to the beginning of the month. This is 1 if true and 0 otherwise. */

WITH months AS 
 (SELECT 
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
    UNION
     SELECT
      '2017-02-01' AS first_day,
      '2017-02-28' AS last_day
    UNION
     SELECT
      '2017-03-01' AS first_day,
      '2017-03-31' AS last_day      
 ),
cross_join AS
  (SELECT *
  FROM subscriptions
  CROSS JOIN months
  ),
  status AS (SELECT id, first_day as month, 
    CASE WHEN (subscription_start < first_day) AND (subscription_end > first_day OR subscription_end is NULL) AND (segment = 87) THAN 1
    ELSE 0
    END AS is_active_87,
    CASE WHEN (subscription_start < first_day) AND (subscription_end > first_day OR subscription_end is NULL) AND (segment = 30) THAN 1
    ELSE 0
    END as is_active_30,


/*Q6 We add an is_canceled_87 and an is_canceled_30 column to the status temporary table. This should be 1 if the subscription is canceled during the month and 0 otherwise. */

WITH months AS 
 (SELECT 
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
    UNION
     SELECT
      '2017-02-01' AS first_day,
      '2017-02-28' AS last_day
    UNION
     SELECT
      '2017-03-01' AS first_day,
      '2017-03-31' AS last_day      
 ),
cross_join AS
  (SELECT *
  FROM subscriptions
  CROSS JOIN months
  ),
status AS 
(SELECT 
   id,
   first_day AS month,
   CASE
    WHEN (subscription_start < first_day) AND(subscription_end > first_day OR subscription_end IS NULL) AND (segment = 87)  THEN 1
  ELSE 0
END AS is_active_87,
CASE
    WHEN (subscription_start < first_day) AND (subscription_end > first_day OR subscription_end IS NULL) AND (segment = 30)THEN 1
 ELSE 0
END AS is_active_30,
CASE
    WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 87) THEN 1
    ELSE 0
    END AS is_canceled_87,
CASE
    WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 30) THEN 1
    ELSE 0
    END AS is_canceled_30
  FROM cross_join
  )
SELECT *
FROM status
LIMIT 10;

/*
|id	|month	|is_active_87	|is_active_30	|is_canceled_87	|is_canceled_30|
|1 |	2017-01-01|	1	0	0	0
|1	| 2017-02-01|	0	0	1	0
|1	| 2017-03-01|	0	0	0	0
|2 | 2017-01-01|	1	0	1	0
|2	| 2017-02-01|	0	0	0	0
|2 |	2017-03-01|	0	0	0	0
|3 |	2017-01-01|	1	0	0	0
|3 |	2017-02-01|	1	0	0	0
|3 |	2017-03-01|	1	0	1	0
|4 |	2017-01-01|	1	0	0	0 
*/

/*Q7 We create a status_aggregate temporary table that is a SUM of the active and canceled subscriptions for each segment, for each month.

The resulting columns should be:

sum_active_87
sum_active_30
sum_canceled_87
sum_canceled_30 */

WITH months AS 
 (SELECT 
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
    UNION
     SELECT
      '2017-02-01' AS first_day,
      '2017-02-28' AS last_day
    UNION
     SELECT
      '2017-03-01' AS first_day,
      '2017-03-31' AS last_day      
 ),
cross_join AS
  (SELECT *
  FROM subscriptions
  CROSS JOIN months
  ),
status AS 
(SELECT 
   id,
   first_day AS month,
   CASE
    WHEN (subscription_start < first_day) AND(subscription_end > first_day OR subscription_end IS NULL) AND (segment = 87)  THEN 1
  ELSE 0
END AS is_active_87,
CASE
    WHEN (subscription_start < first_day) AND (subscription_end > first_day OR subscription_end IS NULL) AND (segment = 30)THEN 1
 ELSE 0
END AS is_active_30,
CASE
    WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 87) THEN 1
    ELSE 0
    END AS is_canceled_87,
CASE
    WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 30) THEN 1
    ELSE 0
    END AS is_canceled_30
  FROM cross_join
  ),
  status_aggregate AS
  (SELECT 
    month,
    SUM(is_active_87) AS sum_active_87,
    SUM(is_active_30) AS sum_active_30,
    SUM(is_canceled_87) AS sum_canceled_87,
    SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY month)
SELECT *
FROM status_aggregate;

/*
|month	sum_active_87|sum_active_30|sum_canceled_87|sum_canceled_30
|2017-01-01|278	|291	|70	|22
|2017-02-01|462	|518	|148	|38
|2017-03-01|531	|716	|258	|84
*/



--Q8 We calculate the churn rates for the two segments over the three month period. Which segment has a lower churn rate?

 WITH months AS 
 (SELECT 
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
    UNION
     SELECT
      '2017-02-01' AS first_day,
      '2017-02-28' AS last_day
    UNION
     SELECT
      '2017-03-01' AS first_day,
      '2017-03-31' AS last_day      
 ),
cross_join AS
  (SELECT *
  FROM subscriptions
  CROSS JOIN months
  ),
status AS 
(SELECT 
   id,
   first_day AS month,
   CASE
    WHEN (subscription_start < first_day) AND(subscription_end > first_day OR subscription_end IS NULL) AND (segment = 87)  THEN 1
  ELSE 0
END AS is_active_87,
CASE
    WHEN (subscription_start < first_day) AND (subscription_end > first_day OR subscription_end IS NULL) AND (segment = 30)THEN 1
 ELSE 0
END AS is_active_30,
CASE
    WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 87) THEN 1
    ELSE 0
    END AS is_canceled_87,
CASE
    WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 30) THEN 1
    ELSE 0
    END AS is_canceled_30
  FROM cross_join
  ),
  status_aggregate AS
  (SELECT 
    month,
    SUM(is_active_87) AS sum_active_87,
    SUM(is_active_30) AS sum_active_30,
    SUM(is_canceled_87) AS sum_canceled_87,
    SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY month)
  SELECT month,
   ROUND(1.0 * sum_canceled_87/sum_active_87, 2) AS churn_rate_87,
  ROUND(1.0 * sum_canceled_30/sum_active_30, 2) AS churn_rate_30
   FROM status_aggregate;
   
/*
   Query Results
|month	|churn_rate_87	|churn_rate_30
|2017-01-01	|0.25	|0.08
|2017-02-01	|0.32	|0.07
|2017-03-01	|0.49	|0.12
We see, that segment 30 is much better in churn rates, maybe more specific. They are able to attract more people
*/   
   










 
 
