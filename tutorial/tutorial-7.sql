drop table if exists Offices, Departments, Employees, Engineers, Managers, Projects, WorkType, Works cascade;

CREATE TABLE Offices (
  oid      INTEGER,
  address  VARCHAR(60),
  PRIMARY  KEY (oid)
);

-- eid = eid of department 's manager
CREATE TABLE Departments (
  did      INTEGER,
  dbudget  INTEGER NOT NULL,
  oid      INTEGER NOT NULL,
  eid      INTEGER NOT NULL, -- no FK to manager
  PRIMARY  KEY (did),
  FOREIGN  KEY (oid) REFERENCES Offices
);

CREATE TABLE Employees (
  eid INTEGER,
  did INTEGER NOT NULL,
  PRIMARY KEY (eid),
  FOREIGN KEY (did) REFERENCES Departments
);

CREATE TABLE Engineers (
  eid INTEGER,
  PRIMARY KEY (eid),
  FOREIGN KEY (eid) REFERENCES Employees
);

CREATE TABLE Managers (
  eid INTEGER,
  PRIMARY KEY (eid),
  FOREIGN KEY (eid) REFERENCES Employees
);

-- eid = eid of project's supervisor
CREATE TABLE Projects (
  pid      INTEGER,
  pbudget  INTEGER NOT NULL,
  eid      INTEGER NOT NULL,
  PRIMARY KEY (pid),
  FOREIGN KEY (eid) REFERENCES Managers
);

CREATE TABLE WorkType (
  wid        INTEGER,
  max_hours  INTEGER NOT NULL,
  PRIMARY KEY (wid)
);

CREATE TABLE Works (
  pid    INTEGER,
  eid    INTEGER,
  wid    INTEGER,
  hours  INTEGER NOT NULL,
  PRIMARY KEY (pid,eid),
  FOREIGN KEY (eid) REFERENCES Engineers,
  FOREIGN KEY (pid) REFERENCES Projects,
  FOREIGN KEY (wid) REFERENCES WorkType
  ON DELETE CASCADE
);

---------- QUESTION 1 ----------

create or replace function check_engineer_manager_function() 
returns trigger as $$
begin
	if ((new.eid in (select eid from Managers)) or (new.eid in (select eid from Engineers))) then
		raise exception 'employee cannot be both manager and engineer';
		return null;
	else 
		return new;
	end if;
end;
$$ language plpgsql;

create trigger check_not_manager
before insert or update on Engineers
for each row
execute function check_engineer_manager_function();

create trigger check_not_engineer
before insert or update on Managers
for each row
execute function check_engineer_manager_function();

insert into Offices values
(1, 'office1');

insert into Departments values
(1, 1, 1, 1);

insert into Employees values
(1, 1);

insert into Employees values
(2, 1);

insert into Managers values
(1);

insert into Engineers values
(1);

insert into Engineers values 
(2);

insert into Managers values
(2);

---------- END QUESTION 1 ----------

---------- QUESTION 2 ----------

create or replace function check_work_function() 
returns trigger as $$
declare
project_budget int;
total_hours int;
begin
	-- get the project budget
	select pbudget into project_budget
	from Projects
	where new.pid = Projects.pid;
	
	select coalesce(sum(hours), 0) into total_hours
	from Works
	where new.pid = Works.pid
	and new.eid <> Works.eid;
	
	if ((total_hours + new.hours) * 100 > project_budget) then
		new.hours := new.hours - total_hours;
		return new;
	else
		return new;
	end if;
end;
$$ language plpgsql;

create trigger check_work
before insert or update on Works
for each row
execute function check_work_function();

---------- END QUESTION 2 ----------
---------- QUESTION 3 ----------
create or replace function check_work_function_new() 
returns trigger as $$
declare
	total_hours int;
	max_hours_possible int;
begin
	
	-- get total number of hours of that work
	select coalesce(sum(hours), 0) into total_hours
	from Works
	where new.wid = Works.wid;
	
	select max_hours into max_hours_possible
	from WorkType 
	where WorkType.wid = new.wid;
	
	if (new.hours + total_hours > max_hours_possible) then
		new.hours := max_hours_possible - total_hours;
		return new;
	else
		return new;
	end if;
end;
$$ language plpgsql;

create trigger check_work_new
before insert or update on Works
for each row execute function check_work_function_new();
---------- END QUESTION 3 ----------
---------- QUESTION 4 ----------
create or replace function prevent_modification_function()
returns trigger as $$
begin
	raise notice 'someone is trying to modify default work';
	return null;
end;
$$ language plpgsql;

create trigger prevent_modification 
before update or delete on WorkType
for each row
execute function prevent_modification_function();
---------- END QUESTION 4 ----------