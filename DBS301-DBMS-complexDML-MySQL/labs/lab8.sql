--1 The HR department needs a list of Department IDs for departments that do not 
--  conbtain the job ID of ST_CLERK> Use a set operator to create this report.
select department_id
from departments
minus
select department_id from employees 
where job_id = 'ST_CLERK';

--2 ??? Same department requests a list of countries that have no departments located in them. 
--  Display country ID and the country name. Use SET operators.
select country_id, country_name from countries
minus
select distinct(country_id), to_char(null) as country_name
from departments join locations using(location_id);

Select * From Countries;
Select Distinct(Country_Id), To_Char(Null) As Country_Name From Locations;
Select * From Departments;

--3 The Vice President needs very quickly a list of departments 10, 50, 20 in that order. 
--  job and department ID are to be displayed
select job_id,department_id from job_history
where Department_Id in (10, 50, 20)
union
select job_id,department_id from Employees
where Department_Id in (10, 50, 20);

--4 create a report that lists the employee IDs and job IDs of those employees 
-- who currently have a job title that is the same as their job title when they were
-- initially hired by the compnay(that is, they chaged jobs but have now gone back to doing their original job).
Select Employee_Id, Job_Id From Employees 
intersect
select employee_id, job_id from job_history;

--5 Last name and epartment ID of all the employees from the employees table, regardless of 
-- whether or not they belong to a department
-- department ID and department name of all the departments from the departments table, regardless of 
-- whether or not they have employees working in them.
Select last_name, department_id, to_char(null) as department_name
From Employees
union
Select to_char(null) as last_name, department_id, department_name
from departments;