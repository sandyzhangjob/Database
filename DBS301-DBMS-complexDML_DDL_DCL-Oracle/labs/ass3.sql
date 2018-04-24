--1 line level not null, UNIQUE, CHECK(constraint),
-- division
create table division(
  division_id number(3),
  division_name varchar(25) not null  unique,
  constraint division_division_id_pk primary key(division_id)
);

insert into division values (10, 'East Coast');
insert into division values (20, 'Quebec');
insert into division values (30, 'Ontario');

--warehouse
create table warehouse (
  WAREHOUSE_ID number(3),
  CITY varchar(15) not null unique,
  RATING char(1) constraint warehouse_RATING_ck check(RATING in ('A','B','C','D')),
  FOUND_DATE date not null,
  DIVISION_ID number(3) not null,
  constraint warehouse_WAREHOUSE_ID_pk primary key(WAREHOUSE_ID),
  constraint warehouse_DIVISION_ID_fk foreign key(DIVISION_ID) references division(division_id)
);

insert into warehouse values(1, 'Montreal', 'A', sysdate, 10);
insert into warehouse values(7, 'Fredericton', 'B', sysdate, 10);
insert into warehouse values(10, 'Toronto', 'A', sysdate, 30);

--section
create table section (
  WAREHOUSE_ID number(3),
  SECTION_ID number(2),
  DESCRIPTION varchar(50) not null,
  CAPACITY number(8),
  constraint section_WHID_SECID_pk primary key(WAREHOUSE_ID, SECTION_ID),
  constraint section_WAREHOUSE_ID_fk foreign key(WAREHOUSE_ID) references warehouse(WAREHOUSE_ID)
);

insert into section values(1, 1, 'Whse 1 Floor 1', 2000);
insert into section values(1, 2, 'Whse 1 Floor 2', 500);
insert into section values(7, 1, 'Whse 7 Floor 1', 15000);

select * from division;
select * from warehouse;
select * from section;

--2
alter table section
add (MGR_ID number(6));
alter table section
add constraint section_mgr_id_fk foreign key(mgr_id) references employees(employee_id);

--3 Modify the CHECK constraint on column RATING in table WAREHOUSE, so that it also may accept a new value F.	
alter table WAREHOUSE drop constraint warehouse_RATING_ck;
alter table WAREHOUSE add constraint warehouse_RATING_ck check(RATING in ('A','B','C','D','F'));

-- 4 Create a new Sequence called Whse_id_seq that will generate unique numbers for PK values in table WAREHOUSE, 
-- so that the numbers start at 420 with the step of 5 and upper limit is 700 and will have NO values stored in the memory.
create sequence Whse_id_seq
increment by 5
start with 420
maxvalue 700
nocache;

--5 (3 marks) Add new row to table WAREHOUSE by using this sequence for a city in Atlanta with unknown rating and division 30.
-- You will assume today’s date as a foundation date. The date is to be entered automatically, meaning you cannot enter a specific date.
insert into WAREHOUSE
values(Whse_id_seq.nextval, 'Atlanta', NULL, sysdate, 30);

select * from WAREHOUSE;

-- 6 (5 marks) Create table CITIES from table LOCATIONS, but only for location numbers 
-- less than 2000 (do NOT create this table from scratch).   You will have 5 to 18 rows
create table cities 
as
select * 
from locations
where location_id < 2000;

--7 (2 marks) Issue command to show the structure of the table CITIES
describe cities;

--8 (1 mark) Issue the SELECT command on cities and show result here.
select * from cities;

--9 (5 marks) Create a View called WhsSec_Man_vu that will display for 
--each Warehouse_id and Section_id, the City, Division and manager’s Last_name. 
--Alias for Last_name should be LName and for Division should be Group.
create or replace view WhsSec_Man_vu
as
select w.warehouse_id, s.section_id, w.city, d.division_name as "Group", 
 e.last_name as "LName"
from warehouse w left join division d on (w.division_id = d.division_id)
full join section s on (w.warehouse_id = s.warehouse_id)
left join employees e on (s.mgr_id = e.employee_id); 

select * from WhsSec_Man_vu;

--10 (1 mark) What is the SELECT command to issue if in 2 months I want to test if a view was actually was created
select view_name, text from user_views where view_name=upper('WhsSec_Man_vu');


--11 (1 mark) If you want to modify the view what is the first line of the command
--create or replace view WhsSec_Man_vu
--…

12 Issue a SET operator to show the rows that were in LOCATIONS but not in CITIES 
select * from locations
minus
select * from cities;
