drop table if exists New_Scores;
drop table if exists Scores_log;
drop function if exists scores_log_function;

create table New_Scores (
	StuName text primary key,
	Mark integer
);

create table Scores_log (
	StuName text primary key,
	Op text,
	Date date
);

insert into New_Scores values
('Alice', 92),
('Bobby', 63),
('Cathy', 58),
('David', 47);

insert into Scores_log values
('Alice', 'Insert', '2022-10-01'),
('Bobby', 'Insert', '2022-10-09'),
('Cathy', 'Insert', '2022-10-10');

create or replace function scores_log_function()
returns trigger as $$
	begin
		if (tg_op = 'INSERT') then
			insert into Scores_log values (new.StuName, 'Insert', current_date);
			return new;
		elseif (tg_op = 'DELETE') then
			insert into Scores_log values (old.StuName, 'Delete', current_date);
			return old;
		elseif (tg_op = 'UPDATE') then
			insert into Scores_log values (new.StuName, 'Update', current_date);
			return new;
		end if;
	end;
$$ language plpgsql;

create trigger scores_log_trigger
after
	-- note how we can use or here
	delete on New_Scores
for each row
	execute function scores_log_function();

select * from New_Scores;
select * from Scores_log;

delete from New_Scores
where StuName = 'Cathy';
