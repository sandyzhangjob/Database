create or replace function Total_Cost (
    f_stuid IN  student.student_id%TYPE)
RETURN NUMBER IS
    v_stuid     student.student_id%TYPE;
    totalcost   NUMBER;
BEGIN
    SELECT student_id INTO v_stuid FROM student WHERE student_id = f_stuid;
    
    SELECT NVL(SUM(C.COST), 0) INTO totalcost
    FROM enrollment E, section S, course C
    WHERE E.section_id = S.section_id AND S.course_no = C.course_no
    AND E.student_id = f_stuid;
    
    IF totalcost is NULL THEN
        RETURN 0;
    END IF;
    
    RETURN totalcost;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;
END Total_Cost;
/

--test using bind variables, teacher ask
--test 194
VARIABLE cost NUMBER
EXECUTE :cost := Total_Cost(194)
PRINT cost
--test 294
VARIABLE cost NUMBER
EXECUTE :cost := Total_Cost(294)
PRINT cost
--test 494
VARIABLE cost NUMBER
EXECUTE :cost := Total_Cost(494)
PRINT cost


--test using variables
SET  SERVEROUTPUT ON
SET  VERIFY OFF
ACCEPT stuid PROMPT 'Enter a valid student Id :'
DECLARE
    Totalcost   NUMBER;
BEGIN
    Totalcost := Total_Cost(&&stuid);
    IF  Totalcost = -1 THEN
        DBMS_OUTPUT.PUT_LINE('This student is is invalid: ' || &stuid);
    ELSIF Totalcost = 0 THEN
        DBMS_OUTPUT.PUT_LINE('This student ' || &stuid ||' do not enroll any classes: ');
    ELSE
        DBMS_OUTPUT.PUT_LINE('This student costs '|| Totalcost);
    END IF;
END;