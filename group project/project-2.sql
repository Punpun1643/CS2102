/* Additional routines */
/* Additional routine #1  */
CREATE OR REPLACE FUNCTION successful_project(pid INT, date DATE) 
RETURNS boolean AS $$
DECLARE
  total_pledge_amt NUMERIC;
BEGIN
  SELECT SUM(amount) INTO total_pledge_amt FROM Backs WHERE id = pid;
  IF total_pledge_amt < (SELECT goal FROM Projects WHERE id = pid) OR date <= (SELECT deadline FROM Projects WHERE id = pid) THEN
    RETURN FALSE;
  END IF;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
/* ------------------------ */

/* ----- TRIGGERS     ----- */

/*-------TRIGGER 1 ---------*/
CREATE OR REPLACE FUNCTION check_user_insertion_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.email NOT IN (SELECT email FROM Backers) AND NEW.email NOT IN (SELECT email FROM Creators) THEN
    RAISE EXCEPTION 'User must be a creator or a backer';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_user_insertion 
AFTER INSERT ON Users
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_user_insertion_function();

/*-------TRIGGER 2 ---------*/
CREATE OR REPLACE FUNCTION check_pledge_amt_function()
RETURNS TRIGGER AS $$
BEGIN 
  IF NEW.amount < (SELECT min_amt FROM Rewards WHERE name = NEW.name AND id = NEW.id) THEN
    RAISE NOTICE 'Pledge Amount should be more than or equals to the Reward Minimum Amount';
    RETURN NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_pledge_amt
BEFORE INSERT ON Backs
FOR EACH ROW
EXECUTE FUNCTION check_pledge_amt_function();

/*-------TRIGGER 3 ---------*/
CREATE OR REPLACE FUNCTION check_project_reward_level_function()
RETURNS TRIGGER AS $$
BEGIN 
  IF NEW.id NOT IN (SELECT id FROM Rewards) THEN
    RAISE EXCEPTION 'Project must have at least one reward level';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_project_reward_level
AFTER INSERT ON Projects
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_project_reward_level_function();

/*-------TRIGGER 4 ---------*/

CREATE OR REPLACE FUNCTION check_process_refund_function()
RETURNS TRIGGER AS $$
DECLARE request_date DATE;
BEGIN
  SELECT request INTO request_date FROM Backs WHERE NEW.pid = Backs.id AND NEW.email = Backs.email;
  IF request_date IS NULL THEN
    RAISE NOTICE 'Cannot approve or reject a refund that is not requested';
    RETURN NULL;
  END IF;
  IF request_date > ((SELECT deadline FROM Projects WHERE id = NEW.pid) + 90) THEN
    RAISE NOTICE 'Refund rejected as request is made more than 90 days after project deadline';
    NEW.accepted := FALSE;
    RETURN NEW;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_process_refund
BEFORE INSERT ON Refunds
FOR EACH ROW
EXECUTE FUNCTION check_process_refund_function();

/*-------TRIGGER 5 ---------*/
CREATE OR REPLACE FUNCTION check_backing_date_function()
RETURNS TRIGGER AS $$
BEGIN 
  IF NEW.backing > (SELECT deadline FROM Projects WHERE id = NEW.id) OR NEW.backing < (SELECT created FROM Projects WHERE id = NEW.id) THEN
    RAISE NOTICE 'Backing date should be after creation date and before deadline';
    RETURN NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_backing_date
BEFORE INSERT ON Backs
FOR EACH ROW
EXECUTE FUNCTION check_backing_date_function();

/*-------TRIGGER 6 ---------*/
CREATE OR REPLACE FUNCTION successful_project(pid INT, date DATE) 
RETURNS boolean AS $$
DECLARE
  total_pledge_amt NUMERIC;
BEGIN
  SELECT SUM(amount) INTO total_pledge_amt FROM Backs WHERE id = pid;
  IF total_pledge_amt < (SELECT goal FROM Projects WHERE id = pid) OR date <= (SELECT deadline FROM Projects WHERE id = pid) THEN
    RETURN FALSE;
  END IF;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_refund_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.request IS NOT NULL AND NOT successful_project(OLD.id, NEW.request) THEN
    RAISE NOTICE 'Cannot refund not successful projects';
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_refund
BEFORE UPDATE ON Backs
FOR EACH ROW
EXECUTE FUNCTION check_refund_function();
/* ------------------------ */

/* ----- PROECEDURES  ----- */
/* Procedure #1 */
CREATE OR REPLACE PROCEDURE add_user(
  email TEXT, name    TEXT, cc1  TEXT,
  cc2   TEXT, street  TEXT, num  TEXT,
  zip   TEXT, country TEXT, kind TEXT
) AS $$
BEGIN
  INSERT INTO Users VALUES (email, name, cc1, cc2);
  
  -- if backer
  IF (kind = 'BACKER') THEN 
    INSERT INTO Backers VALUES (email, street, num, zip, country);
  END IF;
  
  -- if creator
  IF (kind = 'CREATOR') THEN
    INSERT INTO Creators VALUES (email, country);
  END IF;
  
  -- if both
  IF (kind = 'BOTH') THEN
    INSERT INTO Backers VALUES (email, street, num, zip, country);
    INSERT INTO Creators VALUES (email, country);
  END IF;
END;
$$ LANGUAGE plpgsql;



/* Procedure #2 */
CREATE OR REPLACE PROCEDURE add_project(
  id      INT,     email TEXT,   ptype    TEXT,
  created DATE,    name  TEXT,   deadline DATE,
  goal    NUMERIC, names TEXT[],
  amounts NUMERIC[]
) AS $$
DECLARE
  curr TEXT;
  curr_index INT;
BEGIN
  -- insert project first
  curr_index := 1;
  INSERT INTO Projects VALUES (id, email, ptype, created, name, deadline, goal); 
  
  -- insert rewards
  FOREACH curr IN ARRAY names
  LOOP
    INSERT INTO Rewards VALUES (names[curr_index], id, amounts[curr_index]);
    curr_index := curr_index + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;



/* Procedure #3 */
CREATE OR REPLACE PROCEDURE auto_reject(
  eid INT, today DATE
) AS $$
DECLARE 
  project_deadline DATE;
  project_id INT;
  curr RECORD;
  curs CURSOR FOR (SELECT * FROM Backs);
BEGIN
  OPEN curs;
  LOOP 
    FETCH curs INTO curr;
    EXIT WHEN NOT FOUND;
    IF (curr.request IS NOT NULL) THEN
    -- get project deadline
      SELECT deadline, id INTO project_deadline, project_id
        FROM Projects p
        WHERE curr.id = p.id;
      IF (curr.request > project_deadline + 90) THEN
        IF ((curr.email, project_id) NOT IN (SELECT email, pid FROM Refunds)) THEN
            INSERT INTO Refunds VALUES (curr.email, project_id, eid, today, false);
        END IF;
      END IF;
    END IF;
  END LOOP;
  CLOSE curs;
END;
$$ LANGUAGE plpgsql;
/* ------------------------ */



/* ----- FUNCTIONS    ----- */
/* Function #1  */
CREATE OR REPLACE FUNCTION find_superbackers(
  today DATE
) RETURNS TABLE(email TEXT, name TEXT) AS $$
BEGIN
  RETURN QUERY (
      SELECT Users.email, Users.name
      FROM Users
      WHERE Users.email IN

          /* verified backer */
          (SELECT Backers.email
          FROM Backers
          WHERE Backers.email IN (SELECT Verifies.email FROM Verifies WHERE today >= verified)

          INTERSECT 

          /* 1st condition */
          (SELECT Backs.email
          FROM Backs, Projects
          WHERE Backs.id = Projects.id
            AND successful_project(Projects.id, today) IS TRUE
            AND deadline >= today - 30
          GROUP BY Backs.email
          HAVING COUNT(Projects.id) >= 5
            AND COUNT(ptype) >= 3

          UNION

          /* 2nd condition part 1 */
          (SELECT Backs.email
          FROM Backs, Projects
          WHERE Backs.id = Projects.id
            AND successful_project(Projects.id, today) IS TRUE
            AND deadline >= today - 30
          GROUP BY Backs.email
          HAVING SUM(amount) >= 1500

          INTERSECT

          /* 2nd condition part 2 */
          SELECT DISTINCT Backs.email
          FROM Backs
          WHERE NOT EXISTS (SELECT Backs2.email FROM Backs Backs2 WHERE Backs2.email = Backs.email AND Backs2.request >= today - 30)
            AND NOT EXISTS (SELECT date FROM Refunds WHERE Refunds.email = Backs.email AND date >= today - 30))))

      ORDER BY Users.email ASC
  );
END;
$$ LANGUAGE plpgsql;



/* Function #2  */
CREATE OR REPLACE FUNCTION find_top_success(
  n INT, today DATE, ptype TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT,
                amount NUMERIC) AS $$
  SELECT id, name, email, amount
  FROM (                
    SELECT id, name, email, goal, deadline, ptype AS proj_type,
           (SELECT SUM(amount) 
            FROM Backs b, Rewards r
            WHERE r.id = p.id AND r.id = b.id AND r.name = b.name) AS amount
    FROM Projects p
  ) AS result
  WHERE proj_type = ptype AND deadline < today AND amount >= goal
  ORDER BY (amount/goal) DESC, deadline DESC, id ASC
  LIMIT n;
$$ LANGUAGE sql;



/* Function #3  */
CREATE OR REPLACE FUNCTION find_top_popular(
  n INT, today DATE, ptype TEXT
) RETURNS TABLE(id INT, name TEXT, email TEXT,
                days INT) AS $$
BEGIN
  RETURN QUERY SELECT * FROM find_top_popular_helper(today, ptype) ORDER BY daysout ASC, id ASC LIMIT n;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION find_top_popular_helper(today DATE, ptypein TEXT
) RETURNS TABLE(idout INT, nameout TEXT, emailout TEXT,
                daysout INT) AS $$
DECLARE
  proj RECORD;
  fund RECORD;
  currFunds INT;
  currDate DATE;
  numDays INT;
BEGIN
  FOR proj in (SELECT id, name, email, created, goal FROM Projects p WHERE p.ptype = ptypein AND p.created < today ORDER BY id ASC)
  LOOP
    currFunds := 0;
    currDate := NULL;
    FOR fund in (SELECT amount, backing FROM Backs b WHERE b.id = proj.id AND b.backing < today ORDER BY b.backing ASC)
    LOOP
      EXIT WHEN currFunds >= proj.goal;
      currFunds := currFunds + fund.amount;
      IF (currFunds >= proj.goal) THEN
        currDate := fund.backing;
      END IF;
    END LOOP;
    IF (currDate IS NOT NULL) THEN
      idout := proj.id;
      nameout := proj.name;
      emailout := proj.email;
      daysout := currDate - proj.created;
      RETURN NEXT;
    END IF;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;
/* ------------------------ */

/* ================= END ================= */


delete from Verifies cascade;
delete from Updates cascade;
delete from Refunds cascade;
delete from Backs cascade;
delete from Rewards cascade;
DELETE FROM Projects cascade;
delete from Projecttypes cascade;
delete from Backers cascade;
delete from Creators cascade;
DELETE FROM Users cascade;
delete from Employees cascade;

--check that user is backer or creator or both (trigger 1)
--invalid direct insertion into users table
--INSERT INTO Users Values ('creatorthatshdntbecreated@gmail.com', 'creatorthatshdntbecreated@gmail.com', '41341');
--commit

BEGIN;
INSERT INTO Users Values ('creator1@gmail.com', 'creator1', '41341');
INSERT INTO Creators values ('creator1@gmail.com', 'singapore');
commit;

BEGIN;
INSERT INTO Users Values ('creator2@gmail.com', 'creator2', '41341');
INSERT INTO Creators values ('creator2@gmail.com', 'singapore');
commit;

BEGIN;
INSERT INTO Users Values ('creator3@gmail.com', 'creator3', '41341');
INSERT INTO Creators values ('creator3@gmail.com', 'singapore');
commit;

BEGIN;
INSERT INTO Users Values ('backer1@gmail.com', 'backer1', '413412');
INSERT INTO Backers values ('backer1@gmail.com', 'street1', '99998888', '1', 'singapore');
commit;

BEGIN;
INSERT INTO Users Values ('backer2@gmail.com', 'backer2', '413412');
INSERT INTO Backers values ('backer2@gmail.com', 'street1', '99998888', '1', 'singapore');
commit;

BEGIN;
INSERT INTO Users Values ('backer3@gmail.com', 'backer2', '413412');
INSERT INTO Backers values ('backer3@gmail.com', 'street1', '99998888', '1', 'singapore');
commit;

insert into employees values (1, 'yh', 9999);
insert into projecttypes values ('type1', 1);
INSERT into projects values (1, 'creator1@gmail.com', 'type1', '2022-10-29', 'project1', '2022-12-29', 9999);
insert into rewards values ('tier1', 1, 500);
INSERT into projects values (2, 'creator2@gmail.com', 'type1', '2022-10-29', 'project2', '2022-12-29', 1000);
insert into rewards values ('tier1', 2, 500);

--test that backing amt is higher than min (trigger 2)
--invalid min amt
insert into backs values ('backer3@gmail.com', 'tier1', 1, '2022-10-29', NULL, 50);

--test that project has at least 1 reward level (trigger 3)
--INSERT into projects values (2, 'creator1@gmail.com', 'type1', '2022-10-29', 'projectthatshouldntbecreated', '2022-12-29', 9999);

--test that backing date is valid (trigger 5)
--invalid date
insert into backs values ('backer2@gmail.com', 'tier1', 1, '2022-01-29', NULL, 500);--before creation
insert into backs values ('backer2@gmail.com', 'tier1', 1, '2024-01-29', NULL, 500);--after deadline
--valid backs
insert into backs values ('backer2@gmail.com', 'tier1', 1, '2022-10-29', NULL, 500);--on the creation date
insert into backs values ('backer1@gmail.com', 'tier1', 1, '2022-12-29', NULL, 500);--on the deadline

--test that if refund request date is changed, then the project should be successful (trigger 6)
--invalid update
update backs set request = '2022-10-10' where id = 1 and email = 'backer1@gmail.com';  --project deadline not yet met, so not successful yet

insert into backs values ('backer2@gmail.com', 'tier1', 2, '2022-12-29', NULL, 500);
update backs set request = '2023-10-10' where id = 2 and email = 'backer2@gmail.com';  --project funding goal not yet met(goal is 1000)

--valid update
insert into backs values ('backer1@gmail.com', 'tier1', 2, '2022-12-29', NULL, 500); --ensure funding goal met
update backs set request = '2023-10-10' where id = 2 and email = 'backer1@gmail.com';  --project should now be successful

--test that refund approval/rejection is within 90 days and backs request date is not null, i.e. request has been made (trigger 4)
--invalid refund
insert into refunds values ('backer2@gmail.com', 2, 1, '2023-03-30', true);--not requested
insert into refunds values ('backer1@gmail.com', 2, 1, '2023-03-30', true);--more than 90 days after deadline
--valid refund
update backs set request = '2022-12-30' where id = 2 and email = 'backer2@gmail.com';  --project should now be successful
insert into refunds values ('backer2@gmail.com', 2, 1, '2023-03-29', true);--valid refund request, approval subject to what was keyed in
select * from refunds

--test for finding top popular(function 3)
BEGIN;
insert into projecttypes values('type2', 1);
INSERT into projects values (3, 'creator2@gmail.com', 'type2', '2022-10-29', 'project3', '2022-12-29', 9999);
insert into rewards values ('tier1', 3, 500);
INSERT into projects values (4, 'creator1@gmail.com', 'type1', '2022-10-1', 'project4', '2022-12-29', 500);
insert into rewards values ('tier1', 4, 500);
INSERT into projects values (5, 'creator1@gmail.com', 'type1', '2022-10-1', 'project5', '2022-12-29', 500);
insert into rewards values ('tier1', 5, 500);
INSERT into projects values (6, 'creator1@gmail.com', 'type1', '2022-10-1', 'project6', '2022-12-29', 2000);
insert into rewards values ('tier1', 6, 500);
INSERT into projects values (7, 'creator1@gmail.com', 'type1', '2022-10-1', 'project7', '2022-12-29', 2000);
insert into rewards values ('tier1', 7, 500);
INSERT into projects values (8, 'creator1@gmail.com', 'type2', '2022-10-1', 'project8', '2022-12-29', 500);
insert into rewards values ('tier1', 8, 500);--project different type
INSERT into projects values (9, 'creator1@gmail.com', 'type1', '2022-12-1', 'project9', '2022-12-29', 500);
insert into rewards values ('tier1', 9, 500);--project not yet created
INSERT into projects values (10, 'creator1@gmail.com', 'type1', '2022-10-1', 'project10', '2022-12-29', 500);
insert into rewards values ('tier1', 10, 500);
INSERT into projects values (11, 'creator1@gmail.com', 'type1', '2022-10-1', 'project11', '2022-12-29', 1000);
insert into rewards values ('tier1', 11, 500);
INSERT into projects values (12, 'creator1@gmail.com', 'type1', '2022-10-1', 'project11', '2022-12-29', 400);
insert into rewards values ('tier1', 12, 200);
INSERT into projects values (13, 'creator1@gmail.com', 'type1', '2022-10-1', 'project11', '2022-12-29', 400);
insert into rewards values ('tier1', 13, 200);
INSERT into projects values (14, 'creator1@gmail.com', 'type1', '2022-10-1', 'project11', '2022-12-29', 400);
insert into rewards values ('tier1', 14, 200);

insert into backs values ('backer1@gmail.com', 'tier1', 10, '2022-10-25', NULL, 500);--proj10 completes in 24 days
insert into backs values ('backer1@gmail.com', 'tier1', 4, '2022-10-25', NULL, 500);--proj4 completes in 24 days
insert into backs values ('backer1@gmail.com', 'tier1', 5, '2022-10-27', NULL, 500);--proj5 completes in 26 days
insert into backs values ('backer1@gmail.com', 'tier1', 6, '2022-10-03', NULL, 900);--proj6 completes in 2 days
insert into backs values ('backer1@gmail.com', 'tier1', 7, '2022-10-06', NULL, 1100);
insert into backs values ('backer2@gmail.com', 'tier1', 6, '2022-10-01', NULL, 1100);
insert into backs values ('backer2@gmail.com', 'tier1', 7, '2022-10-14', NULL, 900);--proj7 complete in 13 days
insert into backs values ('backer1@gmail.com', 'tier1', 8, '2022-10-25', NULL, 500);--proj8 not type1
insert into backs values ('backer1@gmail.com', 'tier1', 9, '2022-12-25', NULL, 500);--proj9 not yet created
insert into backs values ('backer1@gmail.com', 'tier1', 11, '2022-10-25', NULL, 500);--proj11 does not meet goal

insert into backs values ('backer1@gmail.com', 'tier1', 12, '2022-10-25', NULL, 200);--proj12 and proj13 same num of days
insert into backs values ('backer1@gmail.com', 'tier1', 13, '2022-10-25', NULL, 400);
insert into backs values ('backer2@gmail.com', 'tier1', 12, '2022-10-25', NULL, 200);
insert into backs values ('backer2@gmail.com', 'tier1', 13, '2022-10-25', NULL, 400);

insert into backs values ('backer2@gmail.com', 'tier1', 14, '2022-10-29', NULL, 400); --backing date after checked date
COMMIT;

select * from find_top_popular(4, '2022-10-25', 'type1') -- only 6 and 7 completed
select * from find_top_popular(4, '2022-10-26', 'type1') --proj 12 and 13 becomes successful on 2022-10-25, but limit 4
select * from find_top_popular(10, '2022-10-26', 'type1') --same days -> order by id