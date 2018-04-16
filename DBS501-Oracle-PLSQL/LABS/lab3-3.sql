SET SERVEROUTPUT ON
SET VERIFY OFF

ACCEPT azip PROMPT 'Enter the zip code: '; 
DECLARE
    CURSOR c_std_cursor IS 
        SELECT zip, COUNT(student_id) countstd
        FROM student
        WHERE zip LIKE '&azip%'
        GROUP BY zip
        order by zip;
    
    v_zip student.zip%TYPE;
    v_count number(3);
    counter_zip number(3) := 0;
    counter_std number(3) := 0;
BEGIN
    OPEN c_std_cursor;
    LOOP
        FETCH c_std_cursor INTO v_zip, v_count;
        EXIT WHEN c_std_cursor%notfound;
        DBMS_OUTPUT.PUT_LINE('Zip code: ' || v_zip || ' has exactly ' || v_count || ' students enrolled.');
        counter_zip := counter_zip + 1;
        counter_std := counter_std + v_count;
    END LOOP;    
    CLOSE c_std_cursor;
    
    IF counter_zip = 0 THEN
        DBMS_OUTPUT.PUT_LINE('This zip area is student empty. Please, try again.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('*****************************************');
        DBMS_OUTPUT.PUT_LINE('Total # of zip codes under '|| v_zip || ' is ' || counter_zip);
        DBMS_OUTPUT.PUT_LINE('Total # of Students under zip code '|| v_zip ||' is ' || counter_std);
    END IF;
END;
/