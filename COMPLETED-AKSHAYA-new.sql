create database restaurant; 
use restaurant;
create database sales_delivery;
use sales_delivery;
select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;
-- Part:1 Sales and Delivery
-- Question 1: Find the top 3 customers who have the maximum number of orders
SELECT CUST_ID, COUNT(DISTINCT M.ORD_ID) AS NO_OF_ORDERS 
FROM MARKET_FACT M JOIN ORDERS_DIMEN O
ON M.ORD_ID=O.ORD_ID
GROUP BY CUST_ID
ORDER BY NO_OF_ORDERS DESC LIMIT 3; -- Gives the top 3 customers

-- Question 2: Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date
SELECT O.ORD_ID, ORDER_DATE, SHIP_DATE, DATEDIFF(STR_TO_DATE(SHIP_DATE,'%d-%m-%Y'),STR_TO_DATE(ORDER_DATE,'%d-%m-%Y')) AS DaysTakenForDelivery
FROM ORDERS_DIMEN O JOIN SHIPPING_DIMEN S
ON O.ORDER_ID=S.ORDER_ID; -- date difference gives the number of days between the 2 dates

-- Question 3: Find the customer whose order took the maximum time to get delivered.
SELECT CUSTOMER_NAME, O.ORD_ID, DATEDIFF(STR_TO_DATE(SHIP_DATE,'%d-%m-%Y'),STR_TO_DATE(ORDER_DATE,'%d-%m-%Y')) AS DaysTakenForDelivery
FROM ORDERS_DIMEN O JOIN SHIPPING_DIMEN S
ON O.ORDER_ID=S.ORDER_ID
JOIN MARKET_FACT M
ON O.ORD_ID=M.ORD_ID
JOIN CUST_DIMEN C
ON M.CUST_ID=C.CUST_ID
ORDER BY DaysTakenForDelivery DESC LIMIT 1; -- Displays only 1 customer who got the order after many days (maxmimum date difference)

-- Question 4: Retrieve total sales made by each product from the data (use Windows function)
SELECT DISTINCT PROD_ID, ROUND((SUM(SALES)OVER(PARTITION BY PROD_ID)),2) AS TOTAL_SALES
FROM MARKET_FACT
ORDER BY TOTAL_SALES DESC; -- Shows total sales of every product ID and display will be from the highest sale to the lowest sale

-- Question 5: Retrieve the total profit made from each product from the data (use windows function)
SELECT DISTINCT PROD_ID, ROUND((SUM(PROFIT)OVER(PARTITION BY PROD_ID)),2) AS TOTAL_PROFIT
FROM MARKET_FACT
ORDER BY TOTAL_PROFIT DESC; -- shows the total profit of each product ID in descending order

-- Question 6: Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
CREATE VIEW CUST_JAN AS
SELECT DISTINCT CUST_ID
FROM MARKET_FACT M JOIN ORDERS_DIMEN O
ON M.ORD_ID=O.ORD_ID
WHERE MONTH(STR_TO_DATE(ORDER_DATE,'%d-%m-%Y'))=1
GROUP BY CUST_ID; -- view with 411 customers in January

CREATE VIEW CUST_IN_2011 AS
SELECT DISTINCT CUST_ID,ORDER_DATE
FROM MARKET_FACT M JOIN ORDERS_DIMEN O
ON M.ORD_ID=O.ORD_ID
WHERE YEAR(STR_TO_DATE(ORDER_DATE,'%d-%m-%Y'))=2011;-- view with 955 CUSTOMERS IN 2011

CREATE VIEW JAN_AND_2011 AS
SELECT DISTINCT J.CUST_ID, MONTH(STR_TO_DATE(ORDER_DATE,'%d-%m-%Y')) AS MONTH_2011
FROM CUST_JAN J JOIN CUST_IN_2011 CII
USING (CUST_ID)
ORDER BY MONTH_2011; -- view with common customers between CUST_JAN and CUST_IN_2011. Each month will not contain same customer ID more than once

SELECT CUST_ID, COUNT(CUST_ID) AS CUS_EVERY_MONTH FROM JAN_AND_2011 GROUP BY CUST_ID HAVING CUS_EVERY_MONTH=12; -- NO CONSISTENT CUSTOMERS FOR ALL THE 12 MONTHS

select * from chefmozaccepts;
select * from chefmozcuisine;
select * from chefmozhours4;
select * from chefmozparking;
select * from geoplaces2;
select * from rating_final;
select * from usercuisine; -- 1st row has the column names
select * from userpayment;
select * from userprofile;

-- Part:2 Restaurant Daataset
-- Question 1: - We need to find out the total visits to all restaurants under all alcohol categories available.
SELECT G.PLACEID, NAME, COUNT(UP.USERID) AS TOTAL_VISITS FROM GEOPLACES2 G 
JOIN RATING_FINAL R 
ON G.PLACEID=R.PLACEID
JOIN USERPAYMENT UP
ON R.USERID=UP.USERID
WHERE ALCOHOL NOT LIKE 'No_Alc%'
GROUP BY G.PLACEID, NAME
ORDER BY TOTAL_VISITS DESC; -- No alcohol category was removed from the analysis

-- Question 2: -Let's find out the average rating according to alcohol 
-- and price so that we can understand the rating in respective price categories as well.
SELECT DISTINCT ALCOHOL, AVG(RATING) AS AVG_RATING, PRICE FROM GEOPLACES2 G 
JOIN RATING_FINAL R 
ON G.PLACEID=R.PLACEID
WHERE ALCOHOL NOT LIKE 'No_Alc%'
GROUP BY ALCOHOL, PRICE
ORDER BY AVG_RATING DESC; -- Average rating of alcohol serving restaurant

-- Question 3:  Let’s write a query to quantify that what are the parking availability as well in different alcohol categories 
-- along with the total number of restaurants.
CREATE VIEW COUNT AS
SELECT COUNT(G.PLACEID) AS TOTAL_NUM_RESTAURANT
FROM GEOPLACES2 G 
WHERE ALCOHOL NOT LIKE 'No_Alc%';
SELECT G.PLACEID, NAME, PARKING_LOT, ALCOHOL, TOTAL_NUM_RESTAURANT
FROM GEOPLACES2 G JOIN CHEFMOZPARKING P
ON G.PLACEID=P.PLACEID
CROSS JOIN COUNT
WHERE ALCOHOL NOT LIKE 'No_Alc%'; -- counts of all alcohol serving restaurants along with parking availability

-- Question 4: -Also take out the percentage of different cuisine in each alcohol type.
CREATE VIEW CUIS_PERCENT AS 
WITH TEMP1 AS (SELECT COUNT(RCUISINE) AS TOTAL FROM CHEFMOZCUISINE), 
TEMP2 AS (SELECT RCUISINE, COUNT(RCUISINE) INDIV FROM CHEFMOZCUISINE GROUP BY RCUISINE)
SELECT RCUISINE,(INDIV/TOTAL)*100 AS CUISINE_PERCENT
FROM TEMP2 JOIN TEMP1 ;
SELECT * FROM CUIS_PERCENT;
SELECT G.PLACEID, ALCOHOL, C.RCUISINE, CUISINE_PERCENT
FROM GEOPLACES2 G JOIN CHEFMOZCUISINE C 
ON G.PLACEID=C.PLACEID
JOIN CUIS_PERCENT CU
ON C.RCUISINE=CU.RCUISINE
WHERE ALCOHOL NOT LIKE 'No_Alc%'; -- Each cuisine percentage was found and displayed along with alcohol category

-- Questions 5: - let’s take out the average rating of each state.
SELECT DISTINCT STATE, AVG(RATING)OVER(PARTITION BY STATE) AS AVERAGE_RATING
FROM GEOPLACES2 G JOIN RATING_FINAL R
ON G.PLACEID=R.PLACEID
ORDER BY AVERAGE_RATING DESC; -- Average rating of each state is calculated 

-- Question 6: -' Tamaulipas' Is the lowest average rated state. 
-- Quantify the reason why it is the lowest rated by providing the summary on the basis of State, alcohol, and Cuisine.
SELECT DISTINCT G.PLACEID, STATE, ALCOHOL, RCUISINE AS CUISINE
FROM GEOPLACES2 G JOIN RATING_FINAL R
ON G.PLACEID=R.PLACEID
JOIN USERCUISINE U 
ON R.USERID=U.USERID WHERE STATE LIKE 'TAMA%'; -- Though Tamaulipa serves a variety of cuisines. Tamaulipa restaurants never served alcohol

-- Question 7:  - Find the average weight, food rating, and service rating of the customers who have visited KFC and tried Mexican or Italian types of cuisine, 
-- and also their budget level is low. We encourage you to give it a try by not using joins.
SELECT
(SELECT AVG(WEIGHT) FROM USERPROFILE WHERE BUDGET='LOW' AND 
USERID IN (SELECT USERID FROM USERCUISINE WHERE RCUISINE LIKE 'MEXI%' OR RCUISINE LIKE 'ITAL%' 
AND USERID IN (SELECT USERID FROM RATING_FINAL WHERE PLACEID=(SELECT PLACEID FROM GEOPLACES2 WHERE NAME LIKE 'KFC')))) AS AVERAGE_WEIGHT,
(SELECT AVG(FOOD_RATING)
 FROM RATING_FINAL
 WHERE USERID IN (SELECT USERID FROM USERCUISINE WHERE RCUISINE LIKE 'MEXI%' OR RCUISINE LIKE 'ITAL%' 
 AND USERID IN (SELECT USERID FROM RATING_FINAL WHERE PLACEID=
 (SELECT PLACEID FROM GEOPLACES2 WHERE NAME LIKE 'KFC')))) AS AVERAGE_FOOD_RATING,
(SELECT AVG(SERVICE_RATING)
FROM RATING_FINAL
 WHERE USERID IN (SELECT USERID FROM USERCUISINE WHERE RCUISINE LIKE 'MEXI%' OR RCUISINE LIKE 'ITAL%' AND
 USERID IN (SELECT USERID FROM RATING_FINAL WHERE PLACEID=
 (SELECT PLACEID FROM GEOPLACES2 WHERE NAME LIKE 'KFC')))) AS AVERAGE_SERVICE_RATING; -- All the conditions were applied to weight, food rating, and service rating
 
 -- Part:3 Triggers
 -- Question 1: Create two called Student_details and Student_details_backup. Insert some records into Student details. 
CREATE DATABASE TRIGGERS_DB;
USE TRIGGERS_DB;
CREATE TABLE STUDENT_DETAILS
(STUDENT_ID VARCHAR(7),
STUDENT_NAME VARCHAR(20),
MAIL_ID VARCHAR(30),
MOBILE_NO BIGINT); 

CREATE TABLE STUDENT_DETAILS_BACKUP
(STUDENT_ID VARCHAR(7),
STUDENT_NAME VARCHAR(20),
MAIL_ID VARCHAR(30),
MOBILE_NO BIGINT);

INSERT INTO STUDENT_DETAILS VALUES (60502,'RICKY', 'rickyhobb1@yahoo.com', 9578302340),
(65232,'JULIE','juliechristy5@gmail.com', 8934593745),
(65793,'DILIP','dilipraj123@gmail.com',9567934739),
(64593, 'MINA', 'minaprakash98@gmail.com', 9739259595);


CREATE TRIGGER STUDENT_BACKUP_DETAILS
BEFORE DELETE ON STUDENT_DETAILS
FOR EACH ROW
INSERT INTO STUDENT_DETAILS_BACKUP (STUDENT_ID,STUDENT_NAME,MAIL_ID,MOBILE_NO) 
VALUES (OLD.STUDENT_ID, OLD.STUDENT_NAME, OLD.MAIL_ID, OLD.MOBILE_NO); -- created a trigger. 
-- so whenever records on student details table are deleted, those records will be added to the student backup table

DELETE FROM STUDENT_DETAILS WHERE STUDENT_NAME='RICKY';
SELECT * FROM STUDENT_DETAILS;
SELECT * FROM STUDENT_DETAILS_BACKUP;

-- MAJOR CHALLENGES
USE SALES_DELIVERY;

-- 1 Use of GROUP_CONCAT function to show customers from same city.
SELECT PROVINCE, REGION, GROUP_CONCAT(CUSTOMER_NAME ORDER BY CUST_ID SEPARATOR ', ') AS CUSTOMER_LIST
FROM CUST_DIMEN
GROUP BY PROVINCE, REGION; -- GROUP_CONCAT() here is useful displaying all the customers from the same location in a single row.

-- 2 Creating stored procedure to retrieve user ids based on religion.
-- The stored procedure will be useful to make attractive offers during festival times.
DELIMITER //
CREATE PROCEDURE GetUsersByReligion(IN RELIGION_NAME VARCHAR(50))
BEGIN
    SELECT * FROM USERPROFILE WHERE RELIGION = RELIGION_NAME;
END;
//
DELIMITER ;
CALL GetUsersByReligion('Jewish'); 
-- Creating a stored procedure is useful in applying a set of code whenever required, 
-- just by calling the stored procedure’s name along with the wanted record name.


-- 3 Calculate delta values of order date for each customer
 SELECT CUST_ID, STR_TO_DATE(ORDER_DATE,'%d-%m-%Y') AS 'ORDER DATE', LAG(STR_TO_DATE(ORDER_DATE,'%d-%m-%Y'))OVER(PARTITION BY CUST_ID ORDER BY STR_TO_DATE(ORDER_DATE,'%d-%m-%Y'))
 AS 'PREVIOUS ORDER DATE', DATEDIFF(STR_TO_DATE(ORDER_DATE,'%d-%m-%Y'),LAG(STR_TO_DATE(ORDER_DATE,'%d-%m-%Y'))OVER(PARTITION BY CUST_ID ORDER BY STR_TO_DATE(ORDER_DATE,'%d-%m-%Y')))
 AS 'DAYS BETWEEN THE PURCHASES'
 FROM MARKET_FACT M JOIN ORDERS_DIMEN O
 ON M.ORD_ID=O.ORD_ID
 ORDER BY CUST_ID; 
 -- The purpose of getting delta values between the order dates for each customer is to get the number days 
 -- between the previous and current purchases
 
 -- 4 Creating index on food_rating to retrieve restaurant information easily.
 CREATE INDEX ID_FOOD_RATING
 ON RATING_FINAL(FOOD_RATING);
 
 SELECT R.PLACEID, NAME, RATING, FOOD_RATING, SERVICE_RATING
 FROM RATING_FINAL R JOIN GEOPLACES2 G
 ON R.PLACEID=G.PLACEID
 WHERE FOOD_RATING=2; -- Assigning indexes on food rating, allows the users to quickly sift through a list of restaurants
 -- based on the food rating. Here 2 is the highest rating.
 
 -- 5  Retrieve the total profit made from each product from the data and give percentile ranks where total profit is positive.
SELECT *, PERCENT_RANK()OVER(ORDER BY TOTAL_PROFIT) AS PCTRANK FROM
(SELECT DISTINCT PROD_ID, ROUND((SUM(PROFIT)OVER(PARTITION BY PROD_ID)),2) AS TOTAL_PROFIT
FROM MARKET_FACT
ORDER BY TOTAL_PROFIT DESC)TEMP
WHERE TOTAL_PROFIT>0;
-- The products are given percentile ranks between 0 to 1 where the total profit is positive. 
-- 0 is given for the lowest total profit and 1 for the highest total profit.


 
 
 


