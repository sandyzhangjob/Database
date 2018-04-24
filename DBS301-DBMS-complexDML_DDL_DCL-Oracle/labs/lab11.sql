--1 Create table CITIES from table LOCATIONS, but only for location numbers less than 2000 (do NOT create this table from scratch).
create table lab11cities 
as
select * 
from locations
where location_id < 2000;

desc lab11cities;

--2. 	Create table TOWNS from table LOCATIONS, but only for location numbers less than 1500 
-- (do NOT create this table from scratch). This table will have same structure as table CITIES. 
create table lab11TOWNS
as
select * from LOCATIONS
where location_id < 1500;

desc lab11TOWNS;
select * from lab11TOWNS;

-- 3,	Now you will empty your RECYCLE BIN with one powerful command. Then remove your table TOWNS, 
-- so that will remain in the recycle bin. Check that it is really there and what time was removed.
select * from recyclebin;
PURGE recyclebin; 
drop table lab11TOWNS;

-- 4.	Restore your table TOWNS from recycle bin and describe it. Check what is in your recycle bin now.
--法一：
flashback table "BIN$EEfGKOvRSii6+mN/NirFxQ==$0" to before drop;
--法二：
flashback table lab11towns to before drop ;

drop table lab11TOWNS;
select * from recyclebin;
desc lab11TOWNS;

-- 5.	Now remove table TOWNS so that does NOT remain in the recycle bin. 
-- Check that is really NOT there and then try to restore it. Explain what happened? 
-- (cannot flashback *Cause:    Trying to Flashback Drop an object which is not in RecycleBin.)
flashback table lab11towns222 to before drop ;

-- 6.Create simple view called CAN_CITY_VU, based on table CITIES so that will contain only 
-- columns Street_Address, Postal_Code, City and State_Province for locations only in CANADA. 
-- Then display all data from this view.
create or replace view lab11_CAN_CITY_VU 
as
select Street_Address, Postal_Code, City, State_Province
from lab11cities
where COUNTRY_ID  = 'CA';

select * from lab11_CAN_CITY_VU;

-- 7.	Modify your simple view so that will have following aliases instead of original column names: 
-- Str_Adr, P_Code, City and Prov and also will include cities from ITALY as well. Then display all data from this view. 
create or replace view lab11_CAN_CITY_VU 
(Str_Adr, P_Code, City, Prov)
as
select Street_Address, Postal_Code, City, State_Province
from lab11cities
where COUNTRY_ID in ('CA', 'IT');


--8.	Create complex view called CITY_DNAME_VU, based on tables LOCATIONS and DEPARTMENTS, 
-- so that  will contain only columns Department_Name, City and State_Province for locations in ITALY or CANADA. 
-- Include situations even when city does NOT have department established yet. Then display all data from this view.
create or replace view lab11_CITY_DNAME_VU
as
select d.Department_Name, l.city, l.state_province
from departments d right join locations l on d.location_id = l.location_id
where l.COUNTRY_ID in ('CA', 'IT'); 

select * from lab11_CITY_DNAME_VU;

-- 9.	Modify your complex view so that will have following aliases instead of original column names: 
-- DName, City and Prov and also will include all cities outside United States 
-- Include situations even when city does NOT have department established yet. Then display all data from this view.
create or replace view lab11_CITY_DNAME_VU
(DName, City, Prov)
as
select d.Department_Name, l.city, l.state_province
from departments d right join locations l on d.location_id = l.location_id
where l.COUNTRY_ID not in ('US'); 

select * from lab11_CITY_DNAME_VU;

--10.	Check in the Data Dictionary what Views (their names and definitions) are created so far in your account. 
-- Then drop your CITY_DNAME_VU and check Data Dictionary again. What is different?
select view_name, text from user_views;
drop view lab11_CITY_DNAME_VU;
