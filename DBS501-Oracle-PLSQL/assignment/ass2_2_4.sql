CREATE OR REPLACE PACKAGE My_pack IS
    PROCEDURE modify_sal( p_dptid   IN   departments.department_id%TYPE ) ;
    FUNCTION Total_Cost( f_fname     IN  student.first_name%TYPE, f_lname IN  student.last_name%TYPE) RETURN NUMBER;
    FUNCTION total_cost ( f_zip   IN   student.zip%TYPE) RETURN NUMBER;
END My_pack;
/

CREATE OR REPLACE PACKAGE BODY My_pack IS
    --procedure
    PROCEDURE modify_sal(
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
    
    --function1
    function Total_Cost (
        f_fname IN  student.first_name%TYPE,
        f_lname IN  student.last_name%TYPE)
    RETURN NUMBER IS
        v_stuid     student.student_id%TYPE;
        totalcost   NUMBER;
    BEGIN
        SELECT student_id INTO v_stuid FROM student 
        WHERE upper(first_name) = f_fname and upper(last_name) = f_lname;
        
        SELECT SUM(C.COST) INTO totalcost
        FROM enrollment E, section S, course C
        WHERE E.section_id = S.section_id AND S.course_no = C.course_no
        AND E.student_id = v_stuid;
        
        IF totalcost is NULL THEN
            RETURN 0;
        END IF;
        
        RETURN totalcost;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;
    END Total_Cost;
    
    --function2
    FUNCTION total_cost (
        f_zip   IN   student.zip%TYPE)
    RETURN NUMBER IS
        v_zipcount   NUMBER;
        CURSOR c1 IS
            SELECT student_id FROM student WHERE zip = f_zip;
        v_cost      NUMBER;  
        totalcost   NUMBER := 0;
    BEGIN
        SELECT count(1) INTO v_zipcount FROM student WHERE zip = f_zip;
        IF v_zipcount = 0 THEN
            raise NO_DATA_FOUND;
        END IF;
        
        FOR I IN c1 LOOP
            --test
            DBMS_OUTPUT.PUT_LINE(i.student_id);
            
            SELECT NVL(SUM(C.COST), 0) INTO v_cost
            FROM enrollment E, section S, course C
            WHERE E.section_id = S.section_id AND S.course_no = C.course_no
            AND E.student_id = I.student_id;
            totalcost := totalcost + v_cost;
        END LOOP;
        
        IF totalcost IS NULL THEN
            RETURN 0;
        END IF;
        
        RETURN totalcost;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN -1;
    END total_cost;
END My_pack;
/

--test
VARIABLE cost NUMBER
EXECUTE :cost := My_pack.Total_Cost('VERONA', 'GRANT')
PRINT cost
--test
VARIABLE cost NUMBER
EXECUTE :cost := My_pack.Total_Cost('YVONNE', 'WINNICKI')
PRINT cost
--test
VARIABLE cost NUMBER
EXECUTE :cost := My_pack.Total_Cost('PETER', 'PAN')
PRINT cost
--test
VARIABLE cost NUMBER
EXECUTE :cost := My_pack.Total_Cost(07044)
PRINT cost
--test
VARIABLE cost NUMBER
EXECUTE :cost := My_pack.Total_Cost(11209)
PRINT cost
--test
VARIABLE cost NUMBER
EXECUTE :cost := My_pack.Total_Cost(11111)
PRINT cost
