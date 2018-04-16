--a.	Declares two variables to hold values for columns of table Lab1_tab 
/*
CREATE TABLE lab1_tab (
  ID    NUMBER,
  lname VARCHAR2(20)
);

--b.	sequence called Lab1_seq, increments 5, starts with 1.
CREATE SEQUENCE lab1_seq 
START WITH 1 INCREMENT BY 5;
*/

-- c. to g.
SET serveroutput ON
SET verify OFF

DECLARE 
  v_lname student.last_name%TYPE;
BEGIN
    --b. The block then inserts into the table the last name of the student that 
    --   is enrolled in the most classes and his/her last name contains less than 9
    --   characters. Here use a sequence for the Id
    BEGIN
      SELECT s.last_name
      INTO v_lname
      FROM enrollment e, student s
      WHERE e.student_id = s.student_id
      AND LENGTH(s.last_name) < 9
      GROUP BY s.last_name
      HAVING COUNT(*) = (
        SELECT MAX(count(student_id))
        FROM enrollment
        GROUP BY student_id);
    EXCEPTION 
      WHEN TOO_MANY_ROWS THEN
        v_lname := 'Multiple Names';
    END;
    
    INSERT INTO lab1_tab
    VALUES (LAB1_SEQ.NEXTVAL, v_lname);
    
    --c. the student with the least enrollments is inserted in the table, 
    --   use sequence as well.
    BEGIN
      SELECT s.last_name
      INTO v_lname
      FROM enrollment e, student s
      WHERE e.student_id = s.student_id
      AND LENGTH(s.last_name) < 9
      GROUP BY s.last_name
      having count(*) = (
        SELECT MIN(count(student_id))
        FROM enrollment
        GROUP BY student_id);
    EXCEPTION 
      WHEN TOO_MANY_ROWS THEN
        v_lname := 'Multiple Names';
    END;
    
    INSERT INTO lab1_tab
    VALUES (LAB1_SEQ.NEXTVAL, v_lname);
 
    --d. Insert the instructor’s last name teaching the least amount of courses 
    --   if his/her last name does NOT end on “s”. Here do not use the sequence to generate the ID; instead use your first variable.
    BEGIN
        SELECT i.last_name
        INTO v_lname
        FROM instructor i, section s
        WHERE s.instructor_id = i.instructor_id
        AND i.last_name NOT LIKE '%s'
        GROUP BY i.last_name
        having count(*) = (
            SELECT MIN(count(*))
            FROM section
            GROUP BY instructor_id
        );
    EXCEPTION 
      WHEN TOO_MANY_ROWS THEN
        v_lname := 'Multiple Names';
    END;
    
    INSERT INTO lab1_tab
    VALUES (1, v_lname);  
    
    --e.Now insert the instructor teaching the most number of courses and use 
    --  the sequence to populate his/her Id
    BEGIN
        SELECT i.last_name
        INTO v_lname
        FROM instructor i, section s
        WHERE s.instructor_id = i.instructor_id
        AND i.last_name NOT LIKE '%s'
        GROUP BY i.last_name
        having count(*) = (
            SELECT MAX(count(*))
            FROM section
            GROUP BY instructor_id
        );
    EXCEPTION 
      WHEN TOO_MANY_ROWS THEN
        v_lname := 'Multiple Names';
    END;
    INSERT INTO lab1_tab
    VALUES (LAB1_SEQ.NEXTVAL, v_lname);  
END;
/



select * from lab1_tab;
--delete from lab1_tab;


