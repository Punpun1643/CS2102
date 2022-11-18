drop function if exists max_min;
drop table if exists Exams cascade;

create table Exams (
	sid int, 
	cid int,
	score int,
	primary key (sid, cid)
);

insert into Exams values 
(1, 100, 10),
(1, 200, 20),
(2, 100, 20),
(2, 200, 20);

---------- QUESTION 1 ----------
create or replace function max_min (in stu_id int, out max_cid int, out min_cid int)
returns record as $$
declare
	stu_max_score int;
	stu_min_score int;
	min_cid int;
	max_cid int;
begin
	with student_score as (
		select *
		from Exams
		where sid = stu_id
	)
	select cid, score into max_cid, stu_max_score
	from student_score
	-- this is wrong btw, CTE is out of scope already
	-- that's why it will throw 'student_score' doesn't exist
	where score = (select max(score) from student_score);
	
	select cid, score into min_cid, stu_min_score
	from student_score
	where score = (select min(score) from student_score);
	
	if stu_min_score >= stu_max_score then
		min_cid := null;
	end if;
end;
$$ language plpgsql;

-- correct attempt
create or replace function max_min (in stu_id int, out max_cid int, out min_cid int)
returns record as $$
declare
	max_score int;
	min_score int;
begin	
	select cid, score into max_cid, max_score
	from Exams
	where sid = stu_id
	and score = (select max(score) from Exams where sid = stu_id);
	
	select cid, score into min_cid, min_score
	from Exams
	where sid = stu_id
	and score = (select min(score) from Exams where sid = stu_id);
	
	if (min_score >= max_score) then
		min_cid := null;
	end if;
end;
$$ language plpgsql;


select * from max_min(1);
select * from max_min(2);

---------- END QUESTION 1 ----------

---------- QUESTION 2 ----------

create or replace function revised_avg (in stu_id int, out r_avg float)
returns float as $$
declare
count_occ int;
max_score int;
min_score int;
total_score float;
begin 
	select max(score), min(score), sum(score), count(*) into max_score, min_score, total_score, count_occ
	from Exams
	where stu_id = sid;
	
	if (count_occ >= 3) then
		total_score = total_score - (max_score + min_score);
		r_avg := total_score / (count_occ - 2);
	else 
		r_avg := null;
	end if;
end;
$$ language plpgsql;

---------- END QUESTION 2 ----------

---------- QUESTION 3 ----------

create or replace function list_r_avg() 
returns table (stu_id int, ravg float) as $$
declare
 curs cursor for (select * from Exams order by sid);
 r1 record;
 sum_score float;
 ctx_score int;
 max_score int;
 min_score int;
begin
	stu_id = -1;
	open curs;
	loop
		fetch curs into r1;
		if r1.sid <> stu_id or not found then
			if (stu_id <> -1) then
				if (ctx_score < 3) then 
					ravg := null;
				else
					ravg := (sum_score - max_score - min_score) / (ctx_score - 2);
				end if;
				return next;
			end if;
			exit when not found;
			stu_id := r1.sid;
			max_score := r1.score;
			min_score := r1.score;
			sum_score := r1.score;
			ctx_score := 1;
		else
			sum_score = sum_score + r1.score;
			ctx_score = ctx_score + 1;
			if (r1.score > max_score) then
				max_score := r1.score;
			end if;
			if (r1.score < min_score) then
				min_score := r1.score;
			end if;
		end if;
	end loop;
	close curs;
	return;
end;
$$ language plpgsql;


select * from list_r_avg();

---------- END QUESTION 3 ----------

---------- QUESTION 4 ----------
create or replace function list_scnd_highest()
returns table (stu_id int, scnd_highest int) as $$
declare
	curs cursor for (select * from Exams order by sid);
	r record;
	first_highest int;
begin
	stu_id = -1;
	open curs;
	loop
		fetch curs into r;
		-- either we change student id or it's the first student
		if r.sid <> stu_id or not found then
			if (stu_id <> -1) then
				if (scnd_highest = 0) then
						scnd_highest := null;
				end if;
				return next;
			end if;
			exit when not found;
			stu_id := r.sid;
			first_highest := r.score;
			scnd_highest := 0;
		-- iterate	
		else
			if (first_highest > r.score and r.score > scnd_highest) then
				scnd_highest := r.score;
			end if;
			
			if (r.score > first_highest and first_highest > scnd_highest) then
				scnd_highest := first_highest;
				first_highest := r.score;
			end if;
		end if;
	end loop;
	close curs;
	return;
end;
$$ language plpgsql;

-- test
select * from Exams;

insert into Exams values 
(1, 400, 60),
(1, 500, 80), 
(1, 600, 10);

select * from list_scnd_highest();

---------- END QUESTION 4 ----------