-- Question 1: SQL
-- SQL variation: MySQL

/* 
a) The average delivery time taken by buyers of the different 
tiers between 2021-Jan to 2021-May. 
*/

/* 
Query logic
------------
Note: For Buyer_Tier table, composite primary key (if exists) = (buyer_id, ds)

1) Concatenate the relevant data from both tables Buyer_Tier and Delivery
    - Use inner join based on 2 conditions:
	a) Same buyer_id (if join using only this might cause row explosion due to excessive matches; not primary key)
        b) Same ds and order_date (obtain buyer's tier during date of order for unique product)
    - Left join could be used if buyers’ tier is calculated daily and ds exists for all possible dates to match Delivery table
    
2) Filter the rows between 2021-Jan to 2021-May
    - Assume period from Jan 1 2021 to May 31 2021
    - Assume order takes at least 1 day to deliver
        a) Earliest order_date: 20210101 (Jan 1 2021)
        b) Latest order_date: 20210530 (May 30 2021)
        c) Earliest date_received: 20210102 (Jan 2 2021)
        d) Latest date_received: 20210531 (May 31 2021)
    - MySQL Keywords clarification for WHERE clause
	a) BETWEEN is inclusive of both start and end dates
        b) STR_TO_DATE converts String (e.g. '20210101') to Date format for manipulation of dates

3) Group the joined table based on the tiers

4) Select the following information
    - tier column
    - average_delivery_time column
	a) DATEDIFF finds the difference in days between date_received and order_date (date_received - order_date)
        b) Average all the delivery time based on tier
*/

-- Solution for part a --
SELECT
    tier,
    AVG(DATEDIFF(STR_TO_DATE(date_received, '%Y%m%d'),
            STR_TO_DATE(order_date, '%Y%m%d'))) AS average_delivery_time
FROM
    Buyer_Tier
        INNER JOIN
    Delivery ON Buyer_Tier.buyer_id = Delivery.buyer_id
	    AND Buyer_Tier.ds = Delivery.order_date
WHERE
    (STR_TO_DATE(Delivery.order_date, '%Y%m%d') BETWEEN STR_TO_DATE('20210101', '%Y%m%d') AND STR_TO_DATE('20210530', '%Y%m%d'))
        AND (STR_TO_DATE(Delivery.date_received, '%Y%m%d') BETWEEN STR_TO_DATE('20210102', '%Y%m%d') AND STR_TO_DATE('20210531', '%Y%m%d'))
GROUP BY tier;

-- ---------------------------------------------------------Next-----------------------------------------------------------

/* 
b) For an average buyer, between 2021-Jan to 2021-May, how long did it take for them to receive their 1st purchase, 
2nd purchase, …, nth purchase? 
*/

/* 
Query logic
------------
1) Understanding the problem:
    - Need a column representing the purchase order (1st purchase, 2nd purchase, ..., nth purchase)
    - Need a column representing the average buyer delivery time based on the purchase order value
    
2) Query structure:
    - Create a Common Table Expression (CTE) with all the columns and a new column showing the purchase order of each row
    - Select the relevant columns from the CTE and group the results based on the purchase order
    Note: Subquery can be used inplace of CTE but with less readability

3) Common Table Expression (CTE) query structure:
    - Retrieve all columns from Delivery table and create a new column purchase_order
    - purchase_order shows the order that the buyer bought the package based on package_id (smaller id = earlier purchase)
    - Can't use order_date to determine purchase order as multiple packages could be ordered on the same day
    - Filter the rows between 2021-Jan to 2021-May (same assumptions as part a)

4) Normal query structure:
    - Group the rows based on the purchase_order
    - Query from CTE
	- purchase_order column
	- average_buyer_delivery_time column
	    - Same logic as part a with DATEDIFF and STR_TO_DATE
            - Average the days taken to deliver for each purchase_order group (1st purchase, 2nd purchase, ..., nth purchase)
*/

-- Solution for part b --
WITH buyer_purchase_order AS
(
 SELECT
     buyer_id,
     package_id,
     order_date,
     date_received,
     ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY package_id ASC) AS purchase_order
 FROM
     Delivery
 WHERE
     (STR_TO_DATE(order_date, '%Y%m%d') BETWEEN STR_TO_DATE('20210101', '%Y%m%d') AND STR_TO_DATE('20210530', '%Y%m%d'))
         AND (STR_TO_DATE(date_received, '%Y%m%d') BETWEEN STR_TO_DATE('20210102', '%Y%m%d') AND STR_TO_DATE('20210531', '%Y%m%d'))
)

SELECT
    purchase_order,
    AVG(DATEDIFF(STR_TO_DATE(date_received, '%Y%m%d'),
            STR_TO_DATE(order_date, '%Y%m%d'))) AS average_buyer_delivery_time
FROM buyer_purchase_order
GROUP BY purchase_order;
