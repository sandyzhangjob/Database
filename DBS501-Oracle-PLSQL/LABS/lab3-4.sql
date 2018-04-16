SET SERVEROUTPUT ON
SET VERIFY OFF

DECLARE
    v_zip VARCHAR2(10) := &zip;
    
    TYPE stu_table_type IS TABLE OF NUMBER(3) INDEX BY VARCHAR(10);
    stu_table stu_table_type;
    
    CURSOR c_std_cursor IS 
        SELECT zip, COUNT(student_id) countstd
        FROM student
        WHERE zip LIKE v_zip||'%'
        GROUP BY zip
        order by zip;
    counter INTEGER := 0;
    
    counter_zip number(3) := 0;
    counter_std number(3) := 0;
    
BEGIN
    FOR stu_table IN c_std_cursor
    LOOP
        
        stu_table(c_std_cursor.counter_zip) := c_std_cursor.counter_std;
        DBMS_OUTPUT.PUT_LINE('Zip code: ' || std_record.zip || ' has exactly ' || std_record.countstd || ' students enrolled.');
        counter_zip := counter_zip + 1;
        counter_std := counter_std + std_record.countstd;
    END LOOP;

    
    /*
    DBMS_OUTPUT.PUT_LINE(v_zip);
    FOR std_record IN c_std_cursor 
    LOOP
        DBMS_OUTPUT.PUT_LINE('Zip code: ' || std_record.zip || ' has exactly ' || std_record.countstd || ' students enrolled.');
        counter_zip := counter_zip + 1;
        counter_std := counter_std + std_record.countstd;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE(counter_zip);
    
    IF counter_zip = 0 THEN
        DBMS_OUTPUT.PUT_LINE('This zip area is student empty. Please, try again.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('*****************************************');
        DBMS_OUTPUT.PUT_LINE('Total # of zip codes under '|| v_zip || ' is ' || counter_zip);
        DBMS_OUTPUT.PUT_LINE('Total # of Students under zip code '|| v_zip ||' is ' || counter_std);
    END IF;
    */
END;
/

