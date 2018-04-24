--1
--SET AUTOCOMMIT ON;
--insert into employees values(120, 'SANDY', 'ZHANG', 'SANDYZH', '416.123.8888', '05-OCT-16', 'IP_PROG', null, 0.2, 100, 90);

--update employees set salary = 2500
--where last_name = 'Matos';

--update employees set salary = 3500
--where last_name = 'Whalen';

--select * from employees 
--where department_id=90 and COMMISSION_PCT = 0.2;

--select last_name, salary from employees 
--where last_name in  ('Matos', 'Whalen');

--2 Display the last names of all employees who are in the same department as the employee named davies. 
-- You need to consider that the name can be input in any mix of case (example AbEl, abel, abEL)
select 
  last_name
from employees
where department_id = ( select 
                         department_id
                        from employees
                        where lower(last_name) = 'davies' 
                        );
  
--3 Display the first name of the lowest paid employee(s)
select
  first_name
from employees
where salary = (select 
                  min(salary)
                from employees
                );


--4 Display the city that the highest paid employee(s) are located in
select 
  city
from locations 
where location_id = ( select
                       location_id
                      from departments
                      where department_id = (select 
                                                department_id
                                              from employees
                                              where salary = (select 
                                                                max(salary)
                                                              from employees
                                                              )
                                            )
                    );      
                    
--5 Display the last name, salary, department_id of the lowest paid employee(s) 
-- in each department as long as the department_id is above 75
select 
  last_name, 
  salary, 
  department_id
from employees
where (department_id, salary) in ( select 
                                      department_id, min(salary)
                                    from employees
                                    GROUP BY department_id
                                    having department_id > 75 
                                  );


-- 6 Display the last name of the lowest paid employee(s) in each city
select 
  e.last_name
from employees e
join departments d on e.department_id = d.department_id
join locations l on d.location_id = l.location_id
where (e.salary, l.city) in ( select min(e.salary), l.city
                          from employees e 
                          join departments d on e.department_id = d.department_id
                          join locations l on d.location_id = l.location_id
                          group by l.city
                          );
                          

--7 Display last name and salary for all employees who earn less than the lowest salary 
-- in ANY department.
-- Sort the output by top salaries first and then by last name.
select 
  last_name, 
  salary
from employees
where salary < any ( select min(salary)
                      from employees
                      group by department_id)
order by salary, last_name desc;


--8 Display last name, job title and salary for all employees whose salary matches 
-- any of the salaries from the IT Department.
-- Do NOT use Join method.
-- Sort the output by salary ascending first and then by last_name
select 
  last_name,
  job_id,
  salary
from employees
where salary in ( select salary
                  from employees
                  where department_id = (select 
                                            department_id 
                                          from departments
                                          where upper(department_name) = 'IT')
                );
                
--9 Display the department_id and lowest salary for any department_id that is a department_id greater than that of Abel
select
  department_id,
  min(salary)
from employees
where department_id > (select department_id
                        from employees
                        where upper(last_name) = upper('Abel')
                      )
group by department_id;


