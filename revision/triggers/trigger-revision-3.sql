drop table if exists Account;

create table Account (
	AID integer primary key,
	AName varchar(20),
	Balance decimal
);

insert into Account values
(1, 'Alice', 100),
(2, 'Alice', 100);

select * from Account;

-- deferrable trigger
-- note: contraints is that the total balance of all accounts must be at least 150

create or replace function check_balance_function()
returns trigger as $$
declare 
	curs cursor for (select * from Account);
	r1 record;
	begin
		open curs;
		loop
			fetch curs into r1;
			exit when not found;
			if (r1.Balance < 150) then
				raise exception 'balance cannot be less than 150';
				return null;
			end if;
			return null;
		end loop;
		close curs;
	end;
$$ language plpgsql;

create trigger check_balance
after
update on Account
for each row 
execute function check_balance_function();

-- example of invalid transaction if under non-deferrable trigger
BEGIN;
UPDATE Account
SET Balance = Balance - 100
WHERE AID = 1;

UPDATE Account 
SET Balance = Balance + 100
WHERE AID = 2;

UPDATE Account
SET Balance = Balance + 300
WHERE AID = 1;
COMMIT;

-- now we change trigger to deferrable 
drop function if exists check_balance;

-- initially deferred
create constraint trigger check_balance
after 
update on Account
deferrable initially deferred 
for each row
	execute function check_balance_function();

-- we can use initialy immediate too
create constraint trigger check_balance
after 
update on Account
deferrable initially immediate
for each row 
	execute function check_balance_function();
	
-- this is how we create transaction if we use initally immediate
begin;
-- we specify that we want to defer the trigger here first 
set constraints check_balance deferred;
update Account set balance = balance - 100 where AID = 1;
update Account set balance = balance + 100 where AID = 2;
commit;