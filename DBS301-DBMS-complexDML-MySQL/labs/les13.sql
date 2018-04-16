--1 
CREATE TABLE  les13STAFF AS
     SELECT  employee_id, last_name, hire_date, job_id, 
             salary, department_id
     FROM    employees;

CREATE TABLE  les13MINISTAFF AS
     SELECT  employee_id, last_name, hire_date, job_id, salary
     FROM     employees
     WHERE   department_id IN   (10,20,60,80);

SELECT * FROM les13ministaff;

-- drop table temporary
drop table les13STAFF;
select original_name,droptime from recyclebin;
desc les13STAFF;

-- flashback
flashback table les13STAFF to before drop;
desc les13STAFF;

-- drop table 
drop table les13ministaff purge;
select original_name,droptime from recyclebin;

-- index
create index staff_salary_idx on les13STAFF(salary);
CREATE INDEX staff_lname_idx ON les13STAFF(last_name);
CREATE INDEX staff_lname_salary_idx 
                  ON les13STAFF(last_name, salary);
                  
select index_name, uniqueness from user_indexes where table_name = upper('les13STAFF');
SELECT index_name, column_name, column_position 
     FROM user_ind_columns
     WHERE  table_name = upper('les13STAFF');
     
     
--sequence
create sequence les13STAFF_empid_seq
start with 111
maxvalue 200
nocache;

insert into les13STAFF values(les13STAFF_empid_seq.nextval, 'Moose', sysdate, 'IT_PROG', 8000, 60);
select * from les13STAFF;

SELECT sequence_name, last_number
     FROM   user_sequences 
     where sequence_name = upper('les13STAFF_empid_seq');


ALTER SEQUENCE les13STAFF_empid_seq
     MAXVALUE  140
     CACHE 10;

SELECT sequence_name, last_number, cache_size
     FROM   user_sequences 
     WHERE  sequence_name = upper('les13STAFF_empid_seq');


INSERT INTO les13staff VALUES (les13STAFF_empid_seq.NEXTVAL,'Dunn',sysdate,'IT_PROG',7000,60);

select * from les13staff;

ROLLBACK;
INSERT INTO les13staff VALUES (les13STAFF_empid_seq.NEXTVAL,'Dunn',sysdate,'IT_PROG',7000,60);
select * from les13staff;
rollback;

ALTER SEQUENCE les13STAFF_empid_seq
     MAXVALUE  140
     nocache;
