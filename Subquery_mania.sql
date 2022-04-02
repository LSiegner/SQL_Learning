/*
Question 1:
Provide the the name of the sales rep in each region with largest amount
of total_amt_usd.
*/

/*
First find the total_amt_usd total assocciated with each sales rep and
I also wanted to have each region with it.
*/
SELECT srep.name rep_name ,r.name region_name, SUM(o.total_amt_usd) total_amt
FROM sales_reps srep
JOIN accounts a
ON  srep.id = a.sales_rep_id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = srep.region_id
GROUP BY 1,2
ORDER BY 3 DESC

/*
Next i pulled the max from each region, and then we can pull those rows
in our final results
*/
SELECT  region_name , MAX(total_amt) total_amt
FROM(   SELECT srep.name rep_name ,r.name region_name, SUM(o.total_amt_usd) total_amt
        FROM sales_reps srep
        JOIN accounts a
        ON  srep.id = a.sales_rep_id
        JOIN orders o
        ON o.account_id = a.id
        JOIN region r
        ON r.id = srep.region_id
        GROUP BY 1,2
        ORDER BY 3 DESC) t1

/*
Now we can combine the two tables, where the region and amount match
*/

SELECT t3.rep_name, t3.region_name, t3.total_amt
FROM( SELECT region_name, MAX(total_amt) total_amt
      FROM(SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
      FROM sales_reps s
      JOIN accounts a
      ON a.sales_rep_id = s.id
      JOIN orders o
      ON o.account_id = a.id
      JOIN region r
      ON r.id = s.region_id
      GROUP BY 1, 2) t1
GROUP BY 1) t2
JOIN (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
     FROM sales_reps s
     JOIN accounts a
     ON a.sales_rep_id = s.id
     JOIN orders o
     ON o.account_id = a.id
     JOIN region r
     ON r.id = s.region_id
     GROUP BY 1,2
     ORDER BY 3 DESC) t3
ON t3.region_name = t2.region_name AND t3.total_amt = t2.total_amt;


/*
Question 2:
For the region with the largest(sum) of sales total_amt_usd, how many
total (count) orders were placed.
*/


/*
first pull the name of the region and the total amount spent in this region
*/
SELECT reg.name region_name, SUM(o.total_amt_usd) total_amt_usd
FROM sales_reps srep
JOIN accounts a
ON srep.id = a.sales_rep_id
JOIN region reg
ON reg.id = srep.region_id
JOIN orders o
ON a.id = o.account_id
GROUP BY reg.name;

SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name;

/*
Now  aggregate this query to show only the max
*/
SELECT MAX(t1.total_amt_usd)
FROM  (SELECT reg.name region_name, SUM(o.total_amt_usd) total_amt_usd
      FROM sales_reps srep
      JOIN accounts a
      ON srep.id = a.sales_rep_id
      JOIN region reg
      ON reg.id = srep.region_id
      JOIN orders o
      ON a.id = o.account_id
      GROUP BY reg.name) t1 ;
/*Now we have to calculate the total number of orders for this region and its corresponding name
For this we use the HAVING clause
*/

SELECT reg.name, COUNT(o.total) total_orders
FROM sales_reps sreps
JOIN accounts a
ON sreps.id = a.sales_rep_id
JOIN orders o
ON a.id = o.account_id
JOIN region reg
ON reg.id = sreps.region_id
GROUP BY reg.name
HAVING SUM(o.total_amt_usd) =   (SELECT MAX(t1.total_amt_usd)
                                FROM  (SELECT reg.name region_name, SUM(o.total_amt_usd) total_amt_usd
                                FROM sales_reps srep
                                JOIN accounts a
                                ON srep.id = a.sales_rep_id
                                JOIN region reg
                                ON reg.id = srep.region_id
                                JOIN orders o
                                ON a.id = o.account_id
                                GROUP BY reg.name) t1 );
/*
Question 3:
How many accounts had more total purchases than the account name which has
bought the most standard_qty paper throughout their lifetime as a customer
*/

/* First find the account with the most standard paper ordered */
SELECT a.name , SUM(o.standard_qty) total_std ,  SUM(o.total) total
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

/*
Now we want to find the accounts who ordered more in total then account with the
highest std order
*/
SELECT a.name
FROM orders o
JOIN accounts a
ON a.id = o.account_id
GROUP BY 1
HAVING SUM(o.total) >   (SELECT total
                        FROM  (SELECT a.name , SUM(o.standard_qty) total_std ,  SUM(o.total) total
                              FROM accounts a
                              JOIN orders o
                              ON a.id = o.account_id
                              GROUP BY 1
                              ORDER BY 2 DESC
                              LIMIT 1)inner_tab
                            )
/*Now we want to count over all the accounts to see how many there are*/

SELECT COUNT(*)
FROM  (SELECT a.name
      FROM orders o
      JOIN accounts a
      ON a.id = o.account_id
      GROUP BY 1
      HAVING SUM(o.total) >   (SELECT total
                              FROM  (SELECT a.name , SUM(o.standard_qty) total_std ,  SUM(o.total) total
                                    FROM accounts a
                                    JOIN orders o
                                    ON a.id = o.account_id
                                    GROUP BY 1
                                    ORDER BY 2 DESC
                                    LIMIT 1) inner_tab
                                  ) )counter_tab;
/*
Question 4:
For the customer that spent the most (in total of the order over their
lifetime as a customer) total_amt_usd, how many web events did they have for their channnel
*/

/*
First find the customer with highest amount in total spending
*/
SELECT a.id ,a.name , SUM(total_amt_usd) tot_spent
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY a.id , a.name
ORDER BY 3 DESC
LIMIT 1;

SELECT a.id, a.name, SUM(o.total_amt_usd) tot_spent
FROM orders o
JOIN accounts a
ON a.id = o.account_id
GROUP BY a.id, a.name
ORDER BY 3 DESC
LIMIT 1;

/*
Now find the corresponding name and number of events that happened on that channnel
*/

SELECT a.name , web.channel, COUNT(*)
FROM accounts a
JOIN web_events web
ON a.id =  web.account_id AND a.id =   (SELECT id
                                        FROM(SELECT a.id ,a.name , SUM(total_amt_usd) tot_spent
                                        FROM accounts a
                                        JOIN orders o
                                        ON a.id = o.account_id
                                        GROUP BY a.id , a.name
                                        ORDER BY 3 DESC
                                        LIMIT 1) inner_table )
GROUP BY 1,2
ORDER BY 3 DESC

/*
Question 5:
What is the lifetime average amount of spent in terms of total_amt_usd
for the top 10 total spending accounts
*/

/*
First find the top 10 accounts with the highest spending
*/

SELECT a.name , a.id, SUM(o.total_amt_usd) total_spent
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY a.id, a.name
ORDER BY 3
LIMIT 10;

/*
Now we just have to average over the total amount spent
*/
SELECT AVG(total_spent)
FROM  (SELECT a.name , a.id, SUM(o.total_amt_usd) total_spent
      FROM accounts a
      JOIN orders o
      ON a.id = o.account_id
      GROUP BY a.id, a.name
      ORDER BY 3
      LIMIT 10) temp;

/*
Question 6:
What is the lifetime average amount spent in terms of total_amt_usd,
including only the companies that spent more per order, on average
, than the average of all orders
*/
/*
First calculate the overall ammount of order for Parch and Pousey
*/
SELECT AVG(o.total_amt_usd) avg_all
FROM orders o

/*
Now we shave to find the customers with a higher spending per day than our
average
*/
SELECT a.name , SUM(o.total_amt_usd) total_spent
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY a.name
HAVING AVG(o.total_amt_usd) > (SELECT AVG(o.total_amt_usd) avg_all
                              FROM orders o )


/*
Finally we have to calculate the average of our highest spending customer per day
*/
SELECT AVG(total_spent)
FROM  (SELECT a.name , SUM(o.total_amt_usd) total_spent
      FROM accounts a
      JOIN orders o
      ON a.id = o.account_id
      GROUP BY a.name
      HAVING AVG(o.total_amt_usd) > (SELECT AVG(o.total_amt_usd) avg_all
                              FROM orders o))inner;



SELECT AVG(avg_amt)
FROM   (SELECT a.name , AVG(o.total_amt_usd) avg_amt
        FROM accounts a
        JOIN orders o
        ON a.id = o.account_id
        GROUP BY 1
        HAVING AVG(o.total_amt_usd) > (SELECT AVG(o.total_amt_usd) avg_all
        FROM orders o)) temp_table;
