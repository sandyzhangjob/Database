--1 Create table SALESREP and load it with data from table EMPLOYEES table. 
-- Use only the equivalent columns from EMPLOYEE as shown below. 
-- (Do NOT create this table from scratch), AND only for people in department 80.

create table lab10salesrep (
  RepId number(6),
  FName		VARCHAR2(20),    
  LName		VARCHAR2(25),   
  Phone#		VARCHAR2(20),
  Salary			NUMBER(8,2),                            
  Commission		NUMBER(2,2)
);

insert into lab10salesrep 
  select employee_id, first_name, last_name, phone_number, salary, commission_pct
  from employees where department_id = 80;

select * from lab10salesrep;

--2a.	Create CUST table.
CREATE TABLE lab10CUST
(CUST#     NUMBER(6),
 CUSTNAME  VARCHAR2(30) not null,
 CITY      VARCHAR2(20) not null,
 RATING    CHAR(1),
 COMMENTS  VARCHAR2(200),
 SALESREP# NUMBER(7),
 constraint cust_cust#_pk primary key(CUST#),
 constraint cust_CUSTNAME_city_uk unique(CUSTNAME, CITY),
 constraint cust_RATING_ck check(rating in ('A', 'B', 'C', 'D')),
 constraint cust_SALESREP#_fk foreign key(SALESREP#) references employees(employee_id)
);

INSERT INTO lab10CUST VALUES (501, 'ABC LTD', 'Montreal', 'C', NULL, 201) ;
INSERT INTO lab10CUST VALUES (502, 'Black Giant', 'Ottawa', 'B', NULL, 202);
INSERT INTO lab10CUST VALUES (503, 'Mother Goose', 'London', 'B', NULL, 202);

INSERT INTO lab10CUST values (701, 'BLUE SKY LTD', 'Vancouver', 'B', NULL, 102); 
INSERT INTO lab10CUST values (702, 'MIKE and SAM inc.', 'Kingston', 'A', NULL, 107);
INSERT INTO lab10CUST values (703, 'RED PLANET', 'Mississauga', 'C', NULL, 107);
INSERT INTO lab10CUST  values (717, 'blue sky ltd', 'Regina', 'D', NULL, 102);


--2b.	Create table GOODCUST from table CUST by using following columns 
-- (do NOT create this table from scratch), but only if their rating is A or B. 
create table lab10goodcust
as
select CUST#, CUSTNAME, CITY, SALESREP#
from lab10CUST where RATING in ('A', 'B');

select * from lab10goodcust;

--3.	Now add new column to table SALESREP called JobCode  that will be of variable 
-- character type with maximum length of 12. Do a DESC SALESREP to ensure it executed
alter table lab10salesrep
add (jobcode varchar2(12));

desc lab10salesrep;

--4.	Declare column Salary in table SALESREP as mandatory one and 
alter table lab10salesrep
modify (Salary			NUMBER(8,2)   constraint lab10salesrep_salary_NN not null);
-- Column Location in table GOODCUST as optional one. You can see location is already optional.
alter table lab10GOODCUST modify CITY null;
desc lab10GOODCUST;

--5.	Lengthen FNAME in SALESREP to 37. The result of a DESCIBE should show it happening
desc lab10SALESREP;
alter table lab10SALESREP
modify (FNAME VARCHAR2(37));

--6. ??? Now get rid of the column JobCode in table SALESREP in a way that will not affect daily performance. 

--7.	Declare PK constraints in both new tables  RepId and CustId
alter table lab10SALESREP
add constraint lab10SALESREP_RepId_pk primary key(RepId);
--alter table lab10CUST
--add constraint lab10CUST_CustId_pk primary key(CustId);

--8.	Declare UK constraints in both new tables  Phone# and Name
alter table lab10SALESREP
add constraint lab10SALESREP_Phone#_uk unique (Phone#);
desc lab10SALESREP;

--9.	Restrict amount of Salary column to be in the range [6000, 12000] 
-- and Commission to be not more than 50%.
alter table lab10SALESREP
add constraint lab10SALESREP_Salary_ck check (Salary >= 6000 and Salary <= 12000);
alter table lab10SALESREP
add constraint lab10SALESREP_Commission_ck check (Commission <= 0.5);

--10.	Ensure that only valid RepId numbers from table SALESREP may be entered in 
-- the table GOODCUST. Why this statement has failed? (an alter table validating constraint failed
-- because the table has child records)
alter table lab10GOODCUST
add constraint lab10GOODCUST_CUST#_fk foreign key(CUST#) references lab10SALESREP(RepId);

--11.	Firstly write down the values for RepId column in table GOODCUST and then make all these values blank. Now redo the question 10. Was it successful? 
-- yes
select * from lab10GOODCUST;
update lab10GOODCUST set cust#='';
rollback;

--12.	Disable this FK constraint now and enter old values for RepId in table GOODCUST and save them. 
-- Then try to enable your FK constraint. What happened? 
alter table lab10GOODCUST disable constraint lab10GOODCUST_CUST#_fk;
update lab10GOODCUST set cust#='502' where city='Ottawa';
update lab10GOODCUST set cust#='503' where city='London';
update lab10GOODCUST set cust#='701' where city='Vancouver';
update lab10GOODCUST set cust#='702' where city='Kingston';
alter table lab10GOODCUST enable constraint lab10GOODCUST_CUST#_fk;

--13. 	Get rid of this FK constraint. Then modify your CK constraint from question 9 to allow Salary amounts from 5000 to 15000.
alter table lab10SALESREP drop constraint lab10SALESREP_Salary_ck;
alter table lab10SALESREP
add constraint lab10SALESREP_Salary_ck check (Salary >= 5000 and Salary <= 15000);

--14.	Describe both new tables SALESREP and GOODCUST and then show all constraints 
--    for these two tables by running the following query:
desc lab10SALESREP;
desc lab10GOODCUST;
SELECT  constraint_name, constraint_type, search_condition, table_name
FROM     user_constraints       
WHERE upper(table_name) IN ('LAB10SALESREP','LAB10GOODCUST')
ORDER  BY  4 , 2;
