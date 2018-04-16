--Lab04 by Shan Zhang
--1
select
  avg(nvl(salary, 0)) -  min(salary) as "Real Amount"
from employees;
 
--2
select
  department_id,
  max(salary) as "High",
  min(salary) as "Low",
  round(avg(nvl(salary,0))) as "Avg"
from employees 
group by department_id
order by 3 desc;

--3
select
  department_id as "Dept#",
  job_id as "Job",
  count(job_id) as "How Many"
from employees
group by department_id, job_id
having count(job_id) > 1
order by 3 desc;

--4
select
  job_id as "Job Title",
  sum(salary) as "Total Paid Monthly"
from employees
group by job_id
having upper(job_id) not in ('AD_PRES', 'AD_VP')
and sum(salary) > 15000
order by 2 desc;

--5
select manager_id, count(last_name) as "Total Supervises"
from employees
group by manager_id
having manager_id not in (100, 101, 102)
and count(last_name) > 2
order by count(last_name) desc;
 
--6
select
  department_id, 
  max(hire_date) as "Latest Hire Date", 
  min(hire_date) as "Earliest Hire Date"
from employees
group by department_id
having department_id not in (10, 20)
and to_char(max(hire_date), 'CC') != to_char(sysdate, 'CC')
order by 2 desc;
