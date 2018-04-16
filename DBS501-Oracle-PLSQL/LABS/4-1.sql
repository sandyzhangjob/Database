SET serveroutput ON
SET verify OFF

DECLARE
  TYPE course_table_type IS TABLE OF course.description%TYPE INDEX BY pls_integer;
  course_table course_table_type;
  
  CURSOR c_course_cursor IS SELECT description FROM course WHERE prerequisite IS NULL order by description;
  counter integer:= 0;
  v_desc course.description%TYPE;
BEGIN
  OPEN c_course_cursor;
  LOOP
    fetch c_course_cursor into v_desc;
    EXIT WHEN c_course_cursor%NOTFOUND;
    counter := counter + 1;
    course_table(counter) := v_desc;
  END LOOP;
  CLOSE c_course_cursor;
  DBMS_OUTPUT.PUT_LINE('**************************************');
  DBMS_OUTPUT.PUT_LINE('Total# of Courses without the Prerequisite is: '||course_table.count);
END;
/