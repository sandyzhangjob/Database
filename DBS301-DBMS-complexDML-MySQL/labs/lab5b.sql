
SELECT l.location_id,
l.street_address,
l.city,
l.state_province,
c.country_name
FROM locations l JOIN countries c ON l.country_id = c.country_id;

select 
e.EMPLOYEE_ID,
e.LAST_NAME,
e.JOB_ID,
d.DEPARTMENT_NAME,
j.GRADE
from employees e left join departments d on e.department_id = d.department_id
left join job_grades j on e.salary
between j.lowest_sal and j.HIGHEST_SAL;

select 
a.EMPLOYEE_ID, 
a.LAST_NAME,
b.employee_id as "Employee's Manager ID",
b.last_name as "Employee's Manager Last_Name"
from employees a left join employees b on a.manager_id = b.employee_id;

select 
e.EMPLOYEE_ID, 
e.LAST_NAME,
d.DEPARTMENT_NAME,
l.CITY
from employees e
left join departments d on e.DEPARTMENT_ID = d.DEPARTMENT_ID
left join locations l on d.location_id = l.location_id;

select e.LAST_NAME || ' ' || e.FIRST_NAME as "Employee's Name", l.CITY
from employees e left join departments d   on e.DEPARTMENT_ID = d.DEPARTMENT_ID left join locations l   on d.location_id = l.location_id;

select l.CITY, e.LAST_NAME || ' ' || e.FIRST_NAME as "Employee's Name"  
from locations l left join departments d on l.LOCATION_ID = d.location_id
left join employees e on d.department_id = e.DEPARTMENT_ID;  

select  e.LAST_NAME || ' ' || e.FIRST_NAME as "Employee's Name", l.CITY
from employees e full join departments d on e.DEPARTMENT_ID = d.DEPARTMENT_ID
full join locations l on d.location_id = l.location_id;

SELECT city, employee_id, last_name, first_name
FROM employees FULL JOIN departments using (department_id) 
FULL JOIN locations using (location_id);