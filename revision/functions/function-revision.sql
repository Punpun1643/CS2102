--------- DEFINING SCHEMA ---------

drop table if exists Scores;
drop table if exists Accounts;

drop function if exists topStudent();


create table Scores (
	Name text primary key,
	Mark integer
);

create table Accounts (
	Name text primary key,
	Balance numeric not null
);

insert into Scores values ('Alice', 92);
insert into Scores values ('Bob', 53);
insert into Scores values ('Cathy', 58);
insert into Scores values ('David', 47);

insert into Accounts values
('Alice', 2300),
('Bob', 3500);

--------- RETURN EXISTING TUPLES ---------
create or replace function topStudent()
-- return a set of tuple with the highest mark
-- this return ALL tuples with the highest mark
returns setof Scores as $$
select *
from Scores
where mark = (select max(mark) from Scores)
$$ language sql;

create or replace function topStudent()
-- return any ONE tuple that has the highest mark
returns Scores as $$
select *
from Scores 
where mark = (select max(mark) from Scores)
$$ language sql;

------------------------------------------

--------- CALL THE FUNCTION ---------
select * from topStudent();

update Scores 
set mark = 92
where name = 'David';

select * from Scores;

--------- RETURN NEW TUPLES ---------
drop function if exists topCount;

-- my attempt
create or replace function topCount(out mark integer, out count integer)
returns record as $$
select max(max_scores.mark), count(*) as count 
from (select * 
from Scores
where mark = (select max(mark) from Scores)
) as max_scores(name, mark)
$$ language sql;

-- suggested attempt 
create or replace function topCount(out TopMark numeric, out count int)
-- this will only return one tuple
returns record as $$
	select mark, count(*)
	from Scores
	where Mark = (select max(mark) from Scores)
	group by m
$$ language sql;

-- call the function
select * from topCount();

------------------------------------------
--------- RETURN NEW TUPLES ---------
create or replace function markCount(out Mark integer, out count integer)
-- this return set of tuples
returns setof record as $$
select Mark, count(*)
from Scores
group by Mark
$$ language sql;

-- call the function
select * from markCount();