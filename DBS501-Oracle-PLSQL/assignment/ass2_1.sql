CREATE OR REPLACE PROCEDURE modify_sal(
    p_dptid     departments.department_id%TYPE ) IS
    deptid      departments.department_id%TYPE;  
    avg_sal     employees.salary%TYPE;
    emp_dpt     EXCEPTION;
    cursor c1 is
        select department_id, salary, first_name, last_name, employee_id from employees
        where department_id = p_dptid;
    count#      NUMBER(5) := 0;
    diff_sal    NUMBER(5);
BEGIN
    SELECT department_id INTO deptid FROM departments WHERE department_id = p_dptid;
    SELECT AVG(salary) INTO avg_sal FROM employees WHERE department_id = p_dptid;
    
    IF avg_sal IS NULL THEN
        RAISE emp_dpt;
    ELSE
       FOR i IN c1 LOOP
            IF(i.salary) < avg_sal THEN
                UPDATE employees SET salary = avg_sal WHERE employee_id = i.employee_id;
                count# := count# + 1;
                select (avg_sal - i.salary) into diff_sal from dual;
                dbms_output.put_line('Employee '|| i.first_name ||' '|| i.last_name ||' just got an increase of $'|| diff_sal);
            END IF;
        END LOOP;
        
        IF count# = 0 THEN
            dbms_output.put_line('No salary was modified in Department: '||p_dptid);
        END IF;
        dbms_output.put_line('Total # of employees who received salary increase is: ' || count#);
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('This Department Id is invalid: '|| p_dptid);
    WHEN emp_dpt THEN
        dbms_output.put_line('This Department is EMPTY: '|| p_dptid);
END modify_sal;
/

set serveroutput on;
set verify off;
--execute modify_sal(99);
--execute modify_sal(190);
--execute modify_sal(10);
--execute modify_sal(110);
--rollback;
execute modify_sal(60);
rollback;