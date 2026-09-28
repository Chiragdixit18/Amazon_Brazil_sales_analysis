--1.1 To simplify its financial reports, Amazon India needs to standardize payment values.
select payment_type, ROUND(AVG(payment_value)) AS rounded_avg_payment
from amazon_brazil.payments
group by payment_type
order by rounded_avg_payment ASC


--1.2 To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type.
select payment_type, 
 round((count(*) * 100.0 / (select count(*) from amazon_brazil.payments)), 1) as percentage_orders
 from amazon_brazil.payments
 group by payment_type
 order by percentage_orders desc


 --1.3 Amazon India seeks to create targeted promotions for products within specific price ranges.
SELECT p.product_id, oi.price FROM amazon_brazil.products p
JOIN
    amazon_brazil.order_items oi ON p.product_id = oi.product_id
WHERE
    oi.price BETWEEN 100 AND 500
    AND p.product_category_name ILIKE '%Smart%'
ORDER BY oi.price DESC;


--1.4 To identify seasonal sales patterns, Amazon India needs to focus on the most successful months.
select to_char(o.order_purchase_timestamp, 'Month') as month, 
       round(sum(p.payment_value)) as total_sales
from amazon_brazil.orders o
join
    amazon_brazil.payments p on o.order_id = p.order_id
group by month
order by total_sales desc
limit 3


--1.5 Amazon India is interested in product categories with significant price variations.
select p.product_category_name , (max(oi.price) - min(oi.price)) as price_difference
    from amazon_brazil.products p
 join 
    amazon_brazil.order_items oi on p.product_id = oi.product_id
 group by 
    p.product_category_name
 having  
    (max(oi.price) - min(oi.price)) > 500
 order by 
    price_difference desc


--1.6 To enhance the customer experience, Amazon India wants to find which payment types have the most consistent transaction amounts.
select payment_type, STDDEV(payment_value) AS std_deviation
   from amazon_brazil.payments
 group by
    payment_type
 order by
    std_deviation asc 


--1.7 Amazon India wants to identify products that may have incomplete name in order to fix it from their end.
select product_id, product_category_name 
    from amazon_brazil.products
 where
    product_category_name is null
    or length(product_category_name) = 1



--2.1 Amazon India wants to understand which payment types are most popular across different order value segments (e.g., low, medium, high).
select
    case
        when payment_value < 200 then 'Low Value (<200)'
        when payment_value between 200 and 1000 then 'Medium Value (200-1000)'
        else 'High Value (>1000)'
    end as order_value_segment,
    payment_type, count(*) as count
from
    amazon_brazil.payments
group by
    order_value_segment,
    payment_type
order by
    order_value_segment,
    count desc


--2.2 Amazon India wants to analyse the price range and average price for each product category.
select
    p.product_category_name,
    min(oi.price) as min_price,
    max(oi.price) as max_price,
    avg(oi.price) as avg_price
from 
    amazon_brazil.products p
join
    amazon_brazil.order_items oi on p.product_id = oi.product_id
where
    p.product_category_name is not null
group by
    p.product_category_name
order by
    avg_price desc


--2.3 Amazon India wants to identify the customers who have placed multiple orders over time.
select c.customer_unique_id, count(o.order_id) as total_orders
    from
    amazon_brazil.customers c
join
    amazon_brazil.orders o on c.customer_id = o.customer_id
group by
    c.customer_unique_id
having
    count(o.order_id) > 1
order by
    total_orders DESC


--2.4 Amazon India wants to categorize customers into different types ('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) based on their purchase history.
with customer_order_counts as (
 select c.customer_unique_id,
        count(o.order_id) as total_orders
    from
        amazon_brazil.customers c
    join
        amazon_brazil.orders o on c.customer_id = o.customer_id
    group by
        c.customer_unique_id
)
select customer_unique_id,
    case
        when total_orders = 1 then 'New'
        when total_orders between 2 and 4 then 'Returning'
        else 'Loyal'
    end as customer_type
from
    customer_order_counts
order by
    total_orders desc	


--2.5 Amazon India wants to know which product categories generate the most revenue.
select p.product_category_name, sum(oi.price) as total_revenue
    from amazon_brazil.products p
join
    amazon_brazil.order_items oi on p.product_id = oi.product_id
where
    p.product_category_name is not null
group by
    p.product_category_name
order by
    total_revenue desc
limit 5



--3.1 The marketing team wants to compare the total sales between different seasons.
select season, sum(total_sales) as total_sales
from (
    select p.payment_value as total_sales,
        case
            when extract(month from o.order_purchase_timestamp) in (3, 4, 5) then 'Spring'
            when extract(month from o.order_purchase_timestamp) in (6, 7, 8) then 'Summer'
            when extract(month from o.order_purchase_timestamp) in (9, 10, 11) then 'Autumn'
            else 'Winter'
        end as season
    from
        amazon_brazil.orders o
    join
        amazon_brazil.payments p on o.order_id = p.order_id
) as seasonal_sales
group by
    season
order by
    total_sales desc


--3.2 The inventory team is interested in identifying products that have sales volumes above the overall average.
with product_sales as (
    select product_id, count(order_item_id) as total_quantity_sold
    from amazon_brazil.order_items
    group by product_id
)
select product_id, total_quantity_sold
from product_sales
where
    total_quantity_sold > (select avg(total_quantity_sold) from product_sales)
order by total_quantity_sold desc


--3.3 To understand seasonal sales patterns, the finance team is analysing the monthly revenue trends over the past year (year 2018)
select
    to_char(o.order_purchase_timestamp, 'YYYY-MM') as month, sum(p.payment_value) as total_revenue
from amazon_brazil.orders o
join
    amazon_brazil.payments p on o.order_id = p.order_id
where extract(year from o.order_purchase_timestamp) = 2018
group by month
order by month


--3.4 A loyalty program is being designed  for Amazon India.
with customer_order_counts as (
    select c.customer_unique_id, count(o.order_id) as order_count
    from amazon_brazil.customers c
    join
        amazon_brazil.orders o on c.customer_id = o.customer_id
    group by c.customer_unique_id
),
customer_segments as (
    select
        case
            when order_count between 1 and 2 then 'Occasional'
            when order_count between 3 and 5 then 'Regular'
            when order_count > 5 then 'Loyal'
        end as customer_type
    from customer_order_counts
)
select customer_type, count(*) as count
from customer_segments
where customer_type is not null
group by customer_type
order by count DESC


--3.5 Amazon wants to identify high-value customers to target for an exclusive rewards program.
with order_values as (
    select order_id, sum(payment_value) as total_order_value
    from amazon_brazil.payments
    group by order_id
),
customer_avg_order_value as (
    select o.customer_id, avg(ov.total_order_value) as avg_order_value
   from amazon_brazil.orders o
    join
        order_values ov on o.order_id = ov.order_id
    group by o.customer_id
)
select customer_id, avg_order_value,
    rank() over (order by avg_order_value desc) as customer_rank
from customer_avg_order_value
limit 20


--3.6 Amazon wants to analyze sales growth trends for its key products over their lifecycle.
with monthly_product_sales as (
    select oi.product_id,
        date_trunc('month', o.order_purchase_timestamp)::date as sale_month,
        sum(oi.price) as monthly_sales
    from amazon_brazil.order_items oi
    join
        amazon_brazil.orders o on oi.order_id = o.order_id
    group by oi.product_id, sale_month
)
select product_id, sale_month,
    sum(monthly_sales) over (partition by product_id order by sale_month) as total_sales
from monthly_product_sales
order by product_id, sale_month


--3.7 To understand how different payment methods affect monthly sales growth, Amazon wants to compute the total sales for each payment method and calculate the month-over-month growth rate for the past year (year 2018).
with monthly_payment_sales as (
    select p.payment_type, DATE_TRUNC('month', o.order_purchase_timestamp)::date as sale_month,
        sum(p.payment_value) as monthly_total
    from amazon_brazil.payments p
    join
        amazon_brazil.orders o ON p.order_id = o.order_id
    where extract(year from o.order_purchase_timestamp) = 2018
    group by p.payment_type, sale_month
),
sales_with_previous_month as (
    select payment_type, sale_month, monthly_total,
        lag(monthly_total, 1, 0) over (partition by payment_type order by sale_month) as previous_month_total
    from monthly_payment_sales
)
select payment_type, sale_month, monthly_total,
    case
        when previous_month_total = 0 then null
        else (monthly_total - previous_month_total) * 100.0 / previous_month_total
    end as monthly_change
from sales_with_previous_month
order by payment_type, sale_month
