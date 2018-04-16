--1. Display the customer number, customer name and country code for all the customers 
--that are in SPAIN. The country code for Spain is SPA. 
--Please note that you are given SPA, or spa or SpA to use and not Spain.
select 
  cust_no,
  cname,
  country_cd
from customers 
where upper(country_cd) = 'SPA';

--2. How many orders have the product number 40302?
select count(*) as "Total Orders"
from orders o
join orderlines ol
  on o.order_no = ol.order_no
and ol.prod_no= 40302;

--3,List the customer number, customer name and order number for customers that 
--ordered product 40302. Put result in customer number order.
select 
  c.cust_no, 
  c.cname,
  o.order_no
from customers c
join orders o
  on c.cust_no = o.cust_no
join orderlines ol
  on o.order_no = ol.order_no
and ol.prod_no = 40302
order by c.cust_no;

--4 Display the customer number for Ultra Sports 5.
select cust_no
from customers
where cname = 'Ultra Sports 5';

--5Display the customer number, customer name, order number, product name, 
--the total dollars for that line. Give that last column the name of TOTAL. 
--Put the output into customer number order from highest to lowest 
--and display only order numbers less than 75
select 
  c.cust_no,
  c.cname,
  o.order_no,
  p.prod_name,
  sum(ol.price * ol.qty) as "TOTAL"
from customers c
join orders o
  on c.cust_no = o.cust_no
and o.order_no < 75
join orderlines ol
  on o.order_no = ol.order_no
join products p
  on ol.prod_no = p.prod_no 
group by c.cust_no, c.cname, o.order_no, p.prod_name 
order by c.cust_no desc;

--6 Display a count of how many different country codes there are
--? select count(country_id) from countries;
select count(distinct(country_cd)) as "Total Countries"
from customers;

--7 Find the total dollar value for all orders from London. Each row will show 
--customer name, order number and total dollars for the order. Sort by order number
--??? select price, qty from orderlines where prod_no = 40202;
--??? select prod_cost from products where prod_no = 40202;
select 
  c.cname, 
  o.order_no,
  sum(ol.price * ol.qty) as "Total Dollar Value"
from customers c
join orders o
  on c.cust_no = o.cust_no
and upper(c.branch_cd) = 'LON'
join orderlines ol
  on o.order_no = ol.order_no 
group by c.cname, o.order_no
order by o.order_no;

--8 Display the (a) employee number, (b) full employee name, (c) job and (d) hire date.
-- Limit the display to all employees hired in May, June, July, August or Dec
-- The most recently hired employees are displayed first.
-- Exclude people hired in 1992 to 1996
-- Full name should be in the form à  Lastname, Firstname  -- with an alias called Full Name.
-- Hire date should point to the last day in May, June, July, August or December of that year (NOT to the exact hire date)
-- The format is in the form of May 31st of 1997 –better if there is no big gap between month and 31st
-- The hire date column should be called Start Date.
--NOTE: Do NOT use a LIKE operator.
--You should display ONE row per output line by limiting the width of the Full Name to 25 characters.
select 
  employee_id,
  last_name || ', ' || first_name as "Full Name",
  job_id,
  to_char(last_day(hire_date), 'fmMonth fmDD"th of" YYYY') as "Start Date"
from employees
where 
  to_char(hire_date, 'fmMonth') in ('May', 'June', 'July', 'August', 'December')
  and to_number(to_char(hire_date, 'YYYY')) not between 1992 and 1996
order by hire_date desc;


--9 List the employee number, full name, job and the modified salary for all employees
-- whose monthly earning (without the increase) is outside the range $6,000 – $11,000
-- and who are employed as a Vice Presidents or Managers (President is not counted here).
	-- You should use Wild Card characters for this. 
-- the modified salary for a VP will be 30% higher 
-- and managers a 20% salary increase.
-- Sort the output by the top salaries (before this increase).
--Heading will be: 	Employees with Increased Pay
--The output lines should look like this sample line:
--Employee 101 named Neena Kochhar with Job ID of AD_VP will have a new salary of $22100
select 
  'Employee ' || employee_id || ' named ' || first_name || ' ' || last_name || 
  ' with Job ID of ' || job_id || ' will have a new salary of $' ||
  case 
    when upper(job_id) like '%VP' then salary * 1.3
    else salary * 1.2
  end as "Employees with Increased Pay"
from employees
where
  salary not between 6000 and 11000
  and upper(job_id) like '%VP'
  or  upper(job_id) like '%MGR'
order by salary desc;
  
--10 Display last_name, job id and salary for all employees who earn more than all lowest paid employees per department
--     that are in locations outside the US.
--Exclude President and Vice Presidents from this query.
-- the output by job id ascending.
--If a JOIN is needed you must use a “newer” method (USING/JOIN)
select
  last_name,
  job_id,
  salary
from employees
where 
  salary > all(
    select min(e.salary)
    from employees e join departments d on e.department_id = d.department_id
                     join locations l   on d.location_id   = l.location_id
                     and upper(l.country_id) <> 'US'
    group by e.department_id
  ) 
  and job_id not like '%VP' and job_id not like '%PRES'
order by job_id;

--11 Who are the employees (show last_name, salary and job) who work either in IT , ACCOUNTING or MARKETING department 
-- and earn more than the worst paid person in the SHIPPING department. 
-- Sort the output by the last name alphabetically.
-- You need to use ONLY the Subquery method (NO joins allowed).
select 
  last_name,
  salary,
  job_id
from employees
where department_id in (
  select department_id
  from departments
  where upper(department_name) in ('IT', 'ACCOUNTING', 'MARKETING')
)
and salary > (
  select min(salary)
  from employees
  where department_id = (
    select department_id
    from departments
    where upper(department_name) = 'SHIPPING'
  )
)
order by last_name;

--12 Display Department_id, Job_id and the Lowest salary for this combination
--      but only if that Lowest Pay falls in the range $6000 - $18000. 
--Exclude people who 
--	(a) work as some kind of Representative job from this query and 
--	(b) departments IT and SALES 
--Sort the output according to the Department_id and then by Job_id.
--You MUST NOT use the Subquery method.
select 
  e.department_id,
  e.job_id,
  min(e.salary)
from employees e 
join departments d 
  on e.department_id = d.department_id
  and upper(d.department_name) not in ('IT', 'SALES')
  and e.job_id not like '%REP'
group by e.department_id, e.job_id
having 
  min(e.salary) >= 6000 and min(e.salary) <= 18000
order by e.department_id, e.job_id;