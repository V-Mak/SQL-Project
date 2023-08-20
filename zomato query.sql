drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);




-- what is total amount each customer spent on zomato ?
select userid, sum(product.price) as total_amount_spent
from sales
join product on product.product_id = sales.product_id
group by userid
order by userid;



-- How many days has each customer visited zomato ?
select userid, count(distinct created_date) as total_visited_date
from sales
group by userid;



-- what was the first product purchased by each customer?
select * from 
(select *, rank() over(partition by userid order by created_date) rk from sales) as T
where rk = 1;



-- what is most purchased item on menu & how many times was it purchased by all customers ?
select userid, count(product_id) from sales
where product_id=(select product_id from sales
group by product_id
order by count(product_id) desc
limit 1)
group by userid;



-- which item was purchased first by customer after they become a member ?
with tbl as 
(select c.*, row_number() over(partition by userid order by created_date) rw from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s
join goldusers_signup g on s.userid=g.userid and created_date>gold_signup_date) as  c)

select * from tbl where rw=1



-- which item was purchased just before the customer became a member?
with tbl as 
(select c.*, row_number() over(partition by userid order by created_date desc) rw from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s
join goldusers_signup g on s.userid=g.userid and created_date<gold_signup_date) as  c)

select * from tbl where rw=1



-- what is total orders and amount spent for each member before they become a member?
with tbl as
(select c.*, p.price from 
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s
join goldusers_signup g on s.userid=g.userid and created_date<=gold_signup_date) c
join product p on c.product_id=p.product_id
)
select userid, count(created_date) as order_purchased, sum(price) as total_spent from tbl
group by userid



-- If buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point and p3 5rs=1 zomato point  2rs =1zomato point, calculate points collected by each customer and for which product most points have been given till now.
select userid, sum(total_points)*2.5 total_money_earned from 
(select A.*, round(amount/points) as total_points from
(select tbl.*,
case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) as amount from
(select s.*, p.price from sales s 
join product p on p.product_id=s.product_id) c
group by userid, product_id) tbl) A) Z group by userid;


select product_id, sum(total_points) total_points_earned from 
(select A.*, round(amount/points) as total_points from
(select tbl.*,
case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) as amount from
(select s.*, p.price from sales s 
join product p on p.product_id=s.product_id) c
group by userid, product_id) tbl) A) Z group by product_id;




-- rnk all transaction of the customers	
select *,rank() over(partition by userid order by created_date) rk from sales;



-- rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na
select A.*, case when rk=0 then "na" else rk end from
(select c.*,cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end) as varchar) as rk from 
select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s
left join goldusers_signup g on s.userid=g.userid and created_date>gold_signup_date) c) A;
