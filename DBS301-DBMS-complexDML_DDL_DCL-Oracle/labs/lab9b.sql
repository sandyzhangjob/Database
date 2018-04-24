--1) ???	Display the names of the employees whose salary is the same 
-- as the lowest salaried employee in any department.
select last_name
from employees
where salary = any(select min(salary) from employees group by department_id);

-- 2) ???	Display the names of the employee(s) whose salary is the lowest in each department.
select last_name
from employees
where salary = any (
  select min(salary)
  from employees
  group by department_id
);

--3)	Give each of the employees in question 2 a $100 bonus.
select last_name, salary + 100 as "bonus salary"
from employees
where salary = any (
  select min(salary)
  from employees
  group by department_id
);

--4  !!!left join
-- Create a view named ALLEMPS that consists of all employees includes employee_id, 
-- last_name, salary, department_id, department_name, city and country (if applicable)
create or replace view allemps
as 
select employee_id, last_name, salary, e.department_id, d.department_name, l.city, l.country_id
from employees e
left join departments d on e.department_id = d.department_id
left join locations l   on d.location_id   = l.location_id;

select * from allemps;
-- 5)	Use the ALLEMPS view to:
  --a.	Display the employee_id, last_name, salary and city for all employees
        select employee_id, last_name, salary, city from allemps;
        
  --b.	Display the total salary of all employees by city
        select sum(salary) as "toal salary", city from allemps group by city;
        
  --c.	Increase the salary of the lowest paid employee(s) in each department by 100 
        select department_id, min(salary)+100 as "bonus salary" from allemps
        group by department_id;
  
  --d.	What happens if you try to insert an employee by providing values for all columns in this view?
        select * from employees where last_name = 'Vargas';
        insert into allemps values(200, 'aaa', 10000, 50, 'IT', 'Southlake', 'US');
        
  --e.	Delete the employee named Vargas. Did it work? Show proof.
        delete from allemps 
        where last_name = 'Vargas';

--6)	Create a view named ALLDEPTS that consists of all departments and includes 
-- department_id, department_name, city and country (if applicable)
create or replace view alldepts
as
select d.department_id, d.department_name, city, l.country_id
from departments d 
left join locations l   on d.location_id   = l.location_id;


--7)	Use the ALLDEPTS view to:
  --a.	For all departments display the department_id, name and city
        select department_id, department_name, city from alldepts;
  --b.	For each city that has departments located in it display the number of departments by city
        select count(department_id) as "number of departments", city from alldepts
        group by city;
        
--8) group位置
-- Create a view called ALLDEPTSUMM that consists of all departments and includes 
-- for each department: department_id, department_name, number of employees, number 
-- of salaried employees, total salary of all employees. 
-- Number of Salaried must be different from number of employees. The difference is some get commission.
create view ALLDEPTSUMM
as
select 
  e.department_id, 
  d.department_name,
  count(employee_id) as "number of employees", 
  count(salary) as "number of salaried employees", 
  sum(salary) as "total salary"
from employees e 
left join departments d on e.department_id = d.department_id
group by e.department_id, d.department_name
order by e.department_id;

--9)	Use the ALLDEPTSUMM view to display department name and number of employees 
-- for departments that have more than the average number of employees 
select department_name, "number of employees"
from ALLDEPTSUMM
where "number of employees" > (select avg("number of employees") from ALLDEPTSUMM);

--10)	Use the GRANT statement to allow another student (Neptune account ) to retrieve 
--data for your employees table and to allow them to retrieve, insert and update data 
-- in your departments table. Show proof
grant select, insert, update
on  departments
to  Neptune;

--11)	Use the REVOKE statement to remove permission for that student to insert and 
-- update data in your departments table
revoke select, insert, update
on  departments
from  Neptune;



