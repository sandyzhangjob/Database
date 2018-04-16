SET serveroutput ON
SET verify OFF

DECLARE
  TYPE course_table_type IS TABLE OF course.description%TYPE;
  course_table course_table_type := course_table_type();
  
  CURSOR c_course_cursor IS SELECT description FROM course WHERE prerequisite IS NULL order by description;
  counter integer:= 0;
BEGIN
  FOR n IN c_course_cursor loop
    counter := counter + 1;
    course_table.extend;
    course_table(counter) := n.description;
    DBMS_OUTPUT.PUT_LINE('Course Desciption:'||counter ||': '|| course_table(counter));
  END loop;
  DBMS_OUTPUT.PUT_LINE('**************************************');
  DBMS_OUTPUT.PUT_LINE('Total# of Courses without the Prerequisite is: '||course_table.count);
END;
/