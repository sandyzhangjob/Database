select * from employees;

--1
select employee_id, last_name, salary from employees
where salary >= 8000 and salary <= 15000 order by salary desc, last_name;

--2
select employee_id, last_name, salary, job_id from employees
where salary >= 8000 and salary <= 15000
and job_id = 'IT_PROG' or job_id = 'SA_REP'
order by salary desc, last_name;

--3
select employee_id, last_name, salary, job_id from employees 
where job_id = 'IT_PROG' or job_id = 'SA_REP' 
and salary < 8000 and salary > 15000 
order by salary desc, last_name;

--4
select last_name, job_id, salary from employees
where hire_date < '1-JAN-98'
order by hire_date desc;

--5
select last_name, job_id, salary from employees
where hire_date < '1-JAN-98'
and salary > 10000
order by job_id, salary desc;

--6 
select job_id as "Job Title", first_name||last_name as "Full name" from employees
where first_name like '%e%' or first_name like '%E%';

--7
create VIEW R1_employees AS
  SELECT last_name, salary, commission_pct
    FROM employees
    where commission_pct is not null;
    
--8
create VIEW R1_salarydesc_employees AS
  SELECT last_name, salary, commission_pct
    FROM employees
    where commission_pct is not null
    order by salary desc;
    
--9
create VIEW R1_salarydesc2_employees AS
  SELECT last_name, salary, commission_pct
    FROM employees
    where commission_pct is not null
    order by 2 desc;
    