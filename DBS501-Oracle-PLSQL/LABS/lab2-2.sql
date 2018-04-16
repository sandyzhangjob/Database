SET SERVEROUTPUT ON
SET VERIFY OFF
ACCEPT istid  PROMPT 'Please enter the Instructor Id:  ';

DECLARE
  v_istid NUMBER(3) := &istid;
  v_seccount NUMBER(3);
  v_istname instructor.first_name%TYPE;
  v_message VARCHAR2(50);
BEGIN 
  SELECT first_name || ' ' || last_name
  INTO v_istname
  FROM instructor
  WHERE instructor_id = v_istid;
  
  SELECT count(section_id)
  into v_seccount
  FROM section s
  WHERE instructor_id = v_istid;
  DBMS_OUTPUT.PUT_LINE('Instructor, '|| v_istname ||', teaches '|| v_seccount ||' section(s)');
  
  v_message := CASE
        WHEN v_seccount < 5  THEN 'This instructor may teach more sections. '
        WHEN v_seccount <= 9  THEN 'This instructor may teach more sections. '
        WHEN v_seccount > 9 THEN 'This instructor needs to rest in the next term.'
        ELSE 
          'This instructor teaches enough sections. '
  END;
  DBMS_OUTPUT.PUT_LINE(v_message);
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('This is not a valid instructor');
END;
/