SET SERVEROUTPUT ON
SET VERIFY OFF
    
DECLARE 
    TYPE dept_table_type IS TABLE OF departments.department_name%TYPE INDEX BY PLS_INTEGER;
    my_dept_table dept_table_type;
    
    loop_count NUMBER := 10;
    deptno NUMBER := 0;
BEGIN
    WHILE loop_count <= 100 LOOP 
        SELECT department_name INTO my_dept_table(deptno) FROM departments WHERE department_id = loop_count;
        loop_count := loop_count + 10;
        deptno := deptno + 1;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(my_dept_table.count);
	    
    FOR i in my_dept_table.FIRST..my_dept_table.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(my_dept_table(i));        
    END LOOP;
END;
/
