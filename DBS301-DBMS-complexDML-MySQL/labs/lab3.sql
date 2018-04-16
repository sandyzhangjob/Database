--1
select to_char(sysdate + 1, 'FmMonth DD"th of year" YYYY') as Tomorrow from dual;

???
select to_char(sysdate + 1, 'FmMonth 
case when DD "01" then "1st"
     when DD "02" then "2nd"
     when DD "03" then "3rd"
else "DDth" end
||" of year" YYYY') as Tomorrow from dual;


--2
select last_name, first_name, 
salary, salary * 1.07 as "Good Salary", (salary * 0.07) * 12 as "Annual Pay Increase"
from employees 
where department_id in (20, 50, 60);

--3
select upper(last_name) ||','|| upper(first_name) || ' is ' || 
case job_id WHEN 'ST_CLERK' THEN 'Store Clerk'
            WHEN 'ST_MAN' THEN 'Store Manager'
            WHEN 'SA_REP' THEN 'Sales Representative'
            WHEN 'SA_MAN' THEN 'Sales Manager'
else  'No Job Title' end
as "Person and Job"
from employees
where upper(substr(last_name, -1, 1)) = 'S' and upper(substr(first_name,1,1)) in ('C', 'K');

Person and Job                                                         
---------------------------------------------------------------------- 
DAVIES,CURTIS is Store Clerk                                           
MOURGOS,KEVIN is Store Manager 

--4
select last_name, hire_date, round((sysdate - hire_date)/365) as "Years worked"
from employees 
where to_char(hire_date, 'YYYY') < 1992
order by "Years worked" desc;

--5
select city, country_id, NVL(state_province, 'Unknown Province')
from locations
where upper(substr(city, 0, 1)) = 'S'
and length(city) > 8;

--6
select last_name, hire_date, 
to_char(to_timestamp(next_day(hire_date + 365, 'Tuesday')), 'FmDAY","Month "the "fmDdspth" of year"YYYY') as "REVIEW DAY"
from employees
where to_char(hire_date, 'YYYY') > 1997;
