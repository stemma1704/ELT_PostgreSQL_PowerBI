
select * from df_orders;
ALTER TABLE df_orders ALTER COLUMN discount TYPE numeric(10,2);
ALTER TABLE df_orders ALTER COLUMN sale_price TYPE numeric(10,2);
ALTER TABLE df_orders ALTER COLUMN profit TYPE numeric(10,2);

--find the top 10 highest revenue generating products.
select product_id,sum(sale_price) as sales
from df_orders
group by product_id
order by sales desc
limit 10;

--find top 5 highest selling products in each region
with cte1 as ( --this is a cte
select region,product_id,sum(sale_price) as sales
from df_orders
group by product_id,region)
select * from  --subquery within a cte
(
select *,
rank() over (partition by region order by sales desc) as _rank
from cte1 ) A
where _rank<6;


--find month over month gorwth comparision for 2022,2023 sales
select distinct extract(year from order_date) from df_orders;
WITH cte1 AS (
    SELECT EXTRACT(YEAR FROM order_date) AS order_year,
           EXTRACT(MONTH FROM order_date) AS order_month,
		   to_char(order_date,'Month') as _month,
           SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY order_year, order_month,_month
)
SELECT cte1.order_month,cte1._month,
       sum(CASE WHEN cte1.order_year = 2022 THEN sales ELSE 0 END) AS "2022_sales",
       sum(CASE WHEN cte1.order_year = 2023 THEN sales ELSE 0 END) AS "2023_sales",
FROM cte1
GROUP BY cte1.order_month,cte1._month
ORDER BY cte1.order_month,cte1._month;

--for each category which month has highest sales
with cte as
(
SELECT category,
       TO_CHAR(order_date, 'MM-yyyy') AS order_month_year,
       SUM(sale_price) AS sales
FROM df_orders
GROUP BY category, TO_CHAR(order_date, 'MM-yyyy')
ORDER BY category, TO_CHAR(order_date, 'MM-yyyy')
)
select * from
(
select *,
rank() over (partition by category order by sales desc) as _rank
from cte
) a
where _rank=1;

--which sub category had the highest growth by profit in 2023 comapred to 2022
WITH cte1 AS (
    SELECT sub_category,
           EXTRACT(YEAR FROM order_date) AS order_year,
           SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY sub_category, order_year
),
cte2 AS (
    SELECT sub_category,
           SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS "sales_2022",
           SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS "sales_2023"
    FROM cte1
    GROUP BY sub_category
)
SELECT sub_category,
       sales_2022,
       sales_2023,
       round((sales_2023 - sales_2022) * 100.0 / (sales_2022),2) AS growth_percent
FROM cte2
ORDER BY growth_percent DESC
limit 1;


