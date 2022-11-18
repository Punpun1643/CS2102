-- context: cname that likes at least one pizza sold by Corleone Corner
-- q1 without subquery
select distinct cname
from Likes l, Sells s
where l.pizza = s.pizza
and rname = 'Corleone Corner';

-- q1 with subquery
select distinct cname
from Likes l
where exists (
	select 1
	from Sells s
	where s.rname = 'Corleone Corner'
	and s.pizza = l.pizza
);

-- context: cname that does not like any pizza sold by Corleone Corner
-- q2 without subquery
select distinct cus.cname 
from Customers cus
except
select distinct l.cname
from Sells s, Likes l
where s.rname = 'Corleone Corner'
and l.pizza = s.pizza;

-- q2 with subquery
select distinct cname
from Customers c
where not exists (
	select 1
	from Sells s, Likes l
	where s.rname = 'Corleone Corner'
	and s.pizza = l.pizza
	and l.cname = c.cname
);

-- context: rname that sold at least a pizza that is more expensive than at least one pizza sold by CC
-- q3 without subquery
select distinct s2.rname
from Sells s1, Sells s2
where s1.rname = 'Corleone Corner'
and s2.rname <> 'Corleone Corner'
and s2.price > s1.price;

-- q3 with subquery
select distinct s.rname
from Sells s
where s.rname <> 'Corleone Corner'
and s.price > any (
	select s1.price
	from Sells s1
	where s1.rname = 'Corleone Corner'
);

-- context: for each restauratn, get the rname, pizza, price of the pizza with the highest price
-- q4 without subquery
select s3.rname, s3.pizza, s3.price
from Sells s3
except
select s1.rname, s1.pizza, s1.price
from Sells s1, Sells s2
where s1.rname = s2.rname
and s1.price < s2.price;

-- q4 with subquery
select rname, pizza, price
from Sells s
where price >= all (
	select s1.price
	from Sells s1
	where s1.price is not null
	and s.rname = s1.rname
);

-- note: if we don't want to use any or all, we can change our query to imitate the behaviour of cross product
-- this is done by using two tables and comparing the necessary attributes
-- see q3 and q4 for example of how this is done

---------- QUESTION 3(a) ----------
-- context: find pizzas that Alice likes but Bob does not like
select distinct l.pizza
from Likes l
where l.cname = 'Alice'
and l.pizza not in (
	select distinct l1.pizza
	from Likes l1
	where l1.cname = 'Bob'
);

-- example of wrong answer
-- this is wrong when Bob likes no pizza but there is at least a pizza that Alice likes
-- wrong because Bob will have empty table and 'any' will evaluate to false
-- note: any only evalute to true if at least one subquery row evaluates to true
create table test (
	cname text,
	pizza text,
	primary key (cname, pizza)
);

insert into test values 
('Alice', 'hawaian');

select pizza 
from test
where cname = 'Alice'
and pizza <> any (
	select pizza from test
	where cname = 'Bob'
);

---------- END QUESTION 3(a) ----------

---------- QUESTION 3(b) ----------
-- my attempt shorter solution using natural join
select distinct pizza
from Sells s
natural join Restaurants r
group by (pizza, area)
having (count(*) = 1 or count(*) = 0); 

-- another attempt from suggested solution idea
select distinct pizza 
from Sells s3
where not exists (
	select 1
	from Sells s1, Restaurants r1, Sells s2, Restaurants r2
	where r1.area = r2.area
	and r1.rname = s1.rname
	and r2.rname = s2.rname
	and r1.rname <> r2.rname
	and s1.pizza = s2.pizza
	and s1.pizza = s3.pizza
);

-- suggested solution
select distinct pizza 
from Sells s3
where not exists (
	select 1
	from Sells s, Restaurants r, Sells s2, Restaurants r2
	where s.rname = r.rname and s2.rname = r2.rname
	and s.pizza = s2.pizza and r.area = r2.area
	and r.rname <> r2.rname and s.pizza = s3.pizza
);

---------- END QUESTION 3(b) ----------

---------- QUESTION 3(c) ----------
-- my attempt shorter solution using natural join
select distinct area, pizza, min(price)
from Sells s
natural join Restaurants r
group by (pizza, area);

-- suggested answer
select distinct area, pizza, price
from Restaurants r, Sells s
where r.rname = s.rname
and s.price <= all (
	select s2.price
	from Restaurants r2, Sells s2
	where r2.rname = s2.rname
	and s.pizza = s2.pizza
	and r.area = r2.area
);
---------- END QUESTION 3(c) ----------

---------- QUESTION 3(d) ----------
-- my attempt using CTE
with temp_min as (
	select distinct area, pizza, min(price) as min_price
	from Sells s
	natural join Restaurants r
	group by (pizza, area)
),
temp_max as (
	select distinct area, pizza, max(price) as max_price
	from Sells s
	natural join Restaurants r
	group by (pizza, area)
)
select * 
from temp_min
natural join temp_max;
---------- END QUESTION 3(d) ----------

---------- QUESTION 6 ----------
update Employees
set office_id = (
	select office_id
	from Offices
	where room_number =11
	and level = 5
	and building = 'Tower1'
) where office_id = 123;

---------- END QUESTION 6 ----------

