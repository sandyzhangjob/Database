-- 1,ok
create or replace view employees_vu 
As 
select employee_id, last_name employee, department_id
From Employees;

--2, ok
select * from employees_vu;

--3, ok
Select Employee, DEPARTMENT_ID
From Employees_Vu;

--4, for security purposes, do not allow an employee to be reassigned to another department through the view.
create or replace view dept50
(empno, employee, deptno)
as
select employee_id, last_name, department_id
from employees
where department_id = 50
WITH CHECK OPTION CONSTRAINT emp_dept_50;

--5 show structure of dept50 
desc dept50;
select * from dept50;

--6 ok
select * from dept50;
update dept50 set deptno=80 where employee='Matos';

--7