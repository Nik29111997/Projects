use supply_db ;

/*  Question: Month-wise NIKE sales

	Description:
		Find the combined month-wise sales and quantities sold for all the Nike products. 
        The months should be formatted as ‘YYYY-MM’ (for example, ‘2019-01’ for January 2019). 
        Sort the output based on the month column (from the oldest to newest). The output should have following columns :
			-Month
			-Quantities_sold
			-Sales
		HINT:
			Use orders, ordered_items, and product_info tables from the Supply chain dataset.
*/		

select date_format(order_date, '%Y-%m') as Month, 
 sum(Quantity) as Quantities_Sold, sum(Sales) as Sales
 from orders ord left join ordered_items ord_i
 on ord.order_id = ord_i.order_id
 inner join product_info as prod_i 
 on ord_i.item_id=prod_i.product_id
 where Product_name like '%Nike%'
 group by Month
 order by Month;



-- **********************************************************************************************************************************
/*

Question : Costliest products

Description: What are the top five costliest products in the catalogue? Provide the following information/details:
-Product_Id
-Product_Name
-Category_Name
-Department_Name
-Product_Price

Sort the result in the descending order of the Product_Price.

HINT:
Use product_info, category, and department tables from the Supply chain dataset.


*/

select Product_Id, Product_Name, cat.Name as Category_Name,
 dept.name as Department_Name, Product_price 
 from category cat inner join product_info prod_i 
 on cat.ID = prod_i.category_id
 inner join department dept 
 on prod_i.Department_Id = dept.id 
 order by product_price desc
 limit 5;

-- **********************************************************************************************************************************

/*

Question : Cash customers

Description: Identify the top 10 most ordered items based on sales from all the ‘CASH’ type orders. 
Provide the Product Name, Sales, and Distinct Order count for these items. Sort the table in descending
 order of Order counts and for the cases where the order count is the same, sort based on sales (highest to
 lowest) within that group.
 
HINT: Use orders, ordered_items, and product_info tables from the Supply chain dataset.


*/

select Product_Name as 'Product Name' , sum(Sales) as Sales , count( distinct ord.Order_Id) as 'Order Count' 
from orders ord left join ordered_items ord_i on ord.order_id = ord_i.order_id
right join product_info prod_i on ord_i.item_id = prod_i.Product_Id
where ord.type = 'Cash'
group by Product_Name
order by 3 desc, 2 desc
limit 10;


-- **********************************************************************************************************************************
/*
Question : Customers from texas

Obtain all the details from the Orders table (all columns) for customer orders in the state of Texas (TX),
whose street address contains the word ‘Plaza’ but not the word ‘Mountain’. The output should be sorted by the Order_Id.

HINT: Use orders and customer_info tables from the Supply chain dataset.

*/

select * from orders AS ord
LEFT JOIN
customer_info AS cust
ON ord.Customer_Id = cust.Id
where state = 'TX'
having street like '%Plaza%' and street not like '%Mountain%'
order by order_ID;


-- **********************************************************************************************************************************
/*
 
Question: Home office

For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging to
“Apparel” or “Outdoors” departments. Compute the total count of such orders. The final output should contain the 
following columns:
-Order_Count

*/

select count(segment) as Order_Count from customer_info cust 
inner join orders ord on cust.Id=ord.Customer_Id
inner join ordered_items ord_i on ord.Order_Id = ord_i.Order_Id
inner join product_info prod_i on ord_i.Item_Id = prod_i.Product_Id
inner join department dept on dept.Id = prod_i.Department_Id
where Segment = 'Home Office'
and dept.Name in  ('Apparel','Outdoors');

-- **********************************************************************************************************************************
/*

Question : Within state ranking
 
For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging
to “Apparel” or “Outdoors” departments. Compute the count of orders for all combinations of Order_State and Order_City. 
Rank each Order_City within each Order State based on the descending order of their order count (use dense_rank). 
The states should be ordered alphabetically, and Order_Cities within each state should be ordered based on their rank. 
If there is a clash in the city ranking, in such cases, it must be ordered alphabetically based on the city name. 
The final output should contain the following columns:
-Order_State
-Order_City
-Order_Count
-City_rank

HINT: Use orders, ordered_items, product_info, customer_info, and department tables from the Supply chain dataset.

*/

select o.Order_State,
o.Order_City,COUNT(o.order_id) as order_count,
dense_rank() over (partition by order_state
order by COUNT(o.order_id) desc,order_city) as city_rank 
from orders o
JOIN(SELECT id FROM supply_db.customer_info
where segment='Home Office') H 
on H.id = o.Customer_Id
JOIN ordered_items oi on oi.Order_Id=o.Order_Id
JOIN product_info p on oi.Item_Id=p.Product_Id
JOIN department d on d.Id=p.Department_Id
where d.Name='Apparel' or d.Name='Outdoors'
group by Order_City,Order_state;

-- **********************************************************************************************************************************
/*
Question : Underestimated orders

Rank (using row_number so that irrespective of the duplicates, so you obtain a unique ranking) the 
shipping mode for each year, based on the number of orders when the shipping days were underestimated 
(i.e., Scheduled_Shipping_Days < Real_Shipping_Days). The shipping mode with the highest orders that meet 
the required criteria should appear first. Consider only ‘COMPLETE’ and ‘CLOSED’ orders and those belonging to 
the customer segment: ‘Consumer’. The final output should contain the following columns:
-Shipping_Mode,
-Shipping_Underestimated_Order_Count,
-Shipping_Mode_Rank

HINT: Use orders and customer_info tables from the Supply chain dataset.


*/

with ord_summary as 
( 
select *
from orders ord 
inner join customer_info cust
on  ord.Customer_Id = cust.Id 
where ord.Order_Status in ('COMPLETE','CLOSED')
and ord.Scheduled_Shipping_Days < ord.Real_Shipping_Days
and cust.Segment = 'Consumer'
) 
select Shipping_Mode,year(Order_Date) as year,
count(Order_Id) as Shipping_Underestimated_Order_Count,
row_number() over( order by count(Order_Id) desc ) as Shipping_Mode_Rank
from ord_summary
group by shipping_mode, year(Order_Date);

-- **********************************************************************************************************************************





