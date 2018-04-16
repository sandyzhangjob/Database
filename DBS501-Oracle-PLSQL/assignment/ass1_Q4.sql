SET SERVEROUTPUT ON
SET VERIFY OFF

ACCEPT inputdesc  PROMPT 'Enter the piece of the course description in UPPER case: ';
ACCEPT inputlname PROMPT 'Enter the beginning of the Instructor last name in UPPER case: ';

DECLARE
    CURSOR c1 is
        SELECT course.course_no cno, course.DESCRIPTION cdes, section.section_id secid, instructor.last_name ilname, section.section_no secno
        FROM course, section, instructor
        WHERE course.course_no = section.course_no
            AND   section.instructor_id = instructor.instructor_id
            AND UPPER(DESCRIPTION) LIKE UPPER('%&inputdesc%')
            AND last_name LIKE UPPER('&inputlname%')
        ORDER BY 1 desc;
    
    v_count_secid NUMBER;
    CURSOR c2(v_section_id NUMBER) is 
        SELECT COUNT(*) ecount 
        FROM enrollment
        WHERE section_id = v_section_id;
   row_cnt NUMBER := 0;
BEGIN
    FOR r1 IN c1
    LOOP
        DBMS_OUTPUT.PUT_LINE('Course No: ' || r1.cno ||' '|| r1.cdes ||' with Section Id: '
        || r1.secid || ' is taught by '|| r1.ilname || ' in the Course Section: ' || r1.secno);
        
        FOR r2 in c2(r1.secid)
        LOOP
            DBMS_OUTPUT.PUT_LINE('           This Section Id has an enrollment of: '|| r2.ecount);
            DBMS_OUTPUT.PUT_LINE('***********************************************************************************************************');
            row_cnt := row_cnt + r2.ecount;
        END LOOP;
    END LOOP;
    
    IF row_cnt = 0 THEN
        DBMS_OUTPUT.PUT_LINE('There is NO data for this input match between the course description piece and the surname start of Instructor. Try again!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('This input match has a total enrollment of: ' || row_cnt || ' students.');
    END IF;
END;
/