CREATE OR REPLACE FUNCTION instruct_status (
    fname# instructor.first_name%TYPE,
    lname# instructor.last_name%TYPE
) RETURN NUMBER IS
    v_lname         VARCHAR2(10);
    v_countsec      NUMBER(3);
    e_no_schedule   EXCEPTION;
BEGIN
    SELECT last_name INTO v_lname FROM instructor 
    WHERE UPPER(first_name)= fname# AND UPPER(last_name) = lname#;
    IF v_lname IS NULL THEN
        RAISE no_data_found;
    END IF;
    SELECT COUNT(*) INTO v_countsec FROM section
    WHERE instructor_id = (
        SELECT instructor_id FROM instructor 
        WHERE UPPER(first_name)= fname# AND UPPER(last_name) = lname#
    );
    IF v_countsec = 0 THEN
        RAISE e_no_schedule;
    END IF;
    RETURN v_countsec;
EXCEPTION
    WHEN no_data_found THEN
        RETURN -1;
    WHEN e_no_schedule THEN
        RETURN 0;
END instruct_status;
/

--test 1
DECLARE
    cursor c1 is select first_name, last_name from instructor order by last_name;
    v_instructor_record c1%ROWTYPE;
    countsec   NUMBER(2);
BEGIN
    OPEN c1;
    LOOP
        FETCH c1 INTO v_instructor_record;
        EXIT WHEN c1%NOTFOUND;
        countsec := instruct_status(UPPER(v_instructor_record.first_name), UPPER(v_instructor_record.last_name));
        
        IF   countsec = 0 THEN
            dbms_output.put_line(v_instructor_record.last_name||' This Instructor is NOT scheduled to teach.');
        ELSIF   countsec = -1 THEN
            dbms_output.put_line('There is NO such instructor');
        ELSE
            IF countsec > 9 THEN
                 dbms_output.put_line('This Instructor will teach ' || countsec ||' courses and needs a vacation');
            ELSE
                dbms_output.put_line('This Instructor will teach ' || countsec ||' courses');
            END IF;
        END IF;
    END LOOP;
    CLOSE c1;
END;
/

--test 2 & test 3
SET  SERVEROUTPUT ON
SET  VERIFY OFF
ACCEPT fname PROMPT 'Enter first name in upper case'
ACCEPT lname PROMPT 'Enter last name in upper case'
DECLARE
    countsec   NUMBER(2);
BEGIN
    countsec := instruct_status('&&fname', '&&lname');
    IF   countsec = 0 THEN
        dbms_output.put_line('This Instructor is NOT scheduled to teach.');
    ELSIF   countsec = -1 THEN
        dbms_output.put_line('There is NO such instructor');
    ELSE
        IF countsec > 9 THEN
             dbms_output.put_line('This Instructor will teach ' || countsec ||' courses and needs a vacation');
        ELSE
            dbms_output.put_line('This Instructor will teach ' || countsec ||' courses');
        END IF;
    END IF;
END;