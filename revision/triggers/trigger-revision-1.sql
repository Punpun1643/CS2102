-- Note: current_date function is used --
-- create trigger function
create or replace function log_score()
returns trigger as $$
	begin
		insert into Scores_log values
		-- note that current_date is plpgsql function that returns the current date 
			(new.StuName, current_date);
		-- note that we must have a return in trigger function
		return new;
	end
$$ language plpgsql;

-- create trigger
create trigger log_score_trigger
-- specify trigger timing (e.g. after, before, instead of)
after 
	insert 
	on New_Scores
-- specify granularity (e.g. for each row, for each statement)
for each row 
	execute function log_score();
	
insert into New_Scores values
('nupnup', 20);

-- check table whether the results are as expected
select * from New_Scores;
select * from Scores_log;