--lab05a
--1
select 
  d.department_name, 
  l.city, 
  l.street_address, 
  l.postal_code
from departments d join locations l
on d.location_id = l.location_id
order by l.city, d.department_name;

--2
select 
  e.last_name || ' ' || e.first_name as "Full Name",
  e.hire_date, 
  e.salary,
  d.department_name,
  l.city
from employees e 
join departments d
  on e.department_id = d.department_id
join locations l
  on d.location_id = l.location_id
and upper(substr(d.department_name, 1, 1)) in ('A', 'S')
order by 4, 1;

--3
select 
  e.last_name || ' ' || e.first_name as "Manager Name",
  d.department_name, 
  l.city, 
  l.postal_code, 
  l.state_province
from departments d
left join employees e
  on d.manager_id = e.employee_id
join locations l
  on d.location_id = l.location_id
and l.state_province in ('Ontario', 'California', 'Washington')
order by l.city, d.department_name;

--4
select 
  a.last_name as "Employee",
  a.employee_id as "Emp#", 
  b.last_name as "Manager",
  b.employee_id as "Mgr# "
from employees a join employees b
  on a.manager_id = b.employee_id;