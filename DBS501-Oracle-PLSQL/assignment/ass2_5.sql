CREATE OR REPLACE PROCEDURE mod_grade (
    p_courseno  IN      course.course_no%TYPE,
    p_grade     IN      DECIMAL
)IS
    v_cno               course.course_no%TYPE;
    grade_outof_range   EXCEPTION;
    count_stu           NUMBER(3);
    NObody_enroll       EXCEPTION;
    CURSOR c1 IS
        select e.student_id, e.section_id
        from enrollment e, section s, course c
        where e.section_id = s.section_id and s.course_no = c.course_no
        and c.course_no = p_courseno;
    TotalNoGrade#       NUMBER(3) := 0;
BEGIN
    SELECT course_no INTO v_cno FROM course WHERE course_no = p_courseno;
    
    IF p_grade > 100 OR p_grade < 0 THEN
        RAISE grade_outof_range;
    END IF;
    
    SELECT COUNT(1) INTO count_stu
    FROM enrollment E, section S, course C
    WHERE E.section_id = S.section_id AND S.course_no = C.course_no
    AND C.course_no = p_courseno;
    IF count_stu = 0 THEN
        RAISE NObody_enroll;
    END IF;
    
    FOR i IN c1 LOOP
        update enrollment set final_grade = p_grade
        where student_id = i.student_id and section_id = i.section_id;
        TotalNoGrade# := TotalNoGrade# + 1;
        dbms_output.put_line('Student_id: '||i.student_id||' FinalGrade: '|| p_grade);
    END LOOP;
    dbms_output.put_line('Total # of grades changed to '||p_grade||' for course number '||p_courseno||' is '||TotalNoGrade#); 
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('This Course Number is invalid: ' || p_courseno);
    WHEN grade_outof_range THEN
        dbms_output.put_line('This Grade invalid: '|| p_grade ||'  It must be between 0 and 100. Try again. ');
    WHEN NObody_enroll THEN
        dbms_output.put_line('This Course has NOBODY enrolled so far: ' || p_courseno );
END mod_grade;
/

SET  SERVEROUTPUT ON
SET  VERIFY OFF
execute mod_grade(144, 75);
execute mod_grade(99, 75);
execute mod_grade(130, 101);
execute mod_grade(130, 75);