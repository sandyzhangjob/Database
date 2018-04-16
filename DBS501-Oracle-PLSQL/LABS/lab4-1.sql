CREATE OR REPLACE PROCEDURE mine(v_visaexpdate VARCHAR2,  v_type VARCHAR2) IS 
  v_day         VARCHAR2(20);
  v_count       NUMBER(5);
  e_wrong_type  EXCEPTION;
  e_invalid_format  EXCEPTION;
  vtype VARCHAR2(20);
BEGIN
  IF upper(v_type) = 'P' THEN
    vtype := 'PROCEDURE';
  ELSIF upper(v_type) = 'F' THEN
    vtype := 'FUNCTION';
  ELSIF upper(v_type) = 'B' THEN
    vtype := 'PACKAGE';
  ELSE
    RAISE e_wrong_type;
  END IF;
  
  IF substr(v_visaexpdate, 1, 2) > 12 OR substr(v_visaexpdate, 1, 2) < 0 THEN
    raise e_invalid_format;
  END IF;
  
  SELECT to_char(last_day(to_date(v_visaexpdate,'MM/YY')),'DAY') INTO v_day FROM dual;
  SELECT count(*) INTO v_count FROM user_objects WHERE object_type= vtype;
  
  dbms_output.put_line('Last day of the month '|| v_visaexpdate || ' is ' || v_day );
  dbms_output.put_line('Number of stored objects of type '||v_type||' is '|| v_count);

EXCEPTION
  WHEN e_wrong_type THEN
    DBMS_OUTPUT.PUT_LINE('You have entered an Invalid letter for the stored object. Try P, F or B.');
  WHEN e_invalid_format THEN
    DBMS_OUTPUT.PUT_LINE('You have entered an Invalid FORMAT for the MONTH and YEAR. Try MM/YY.');
END mine;
/

SET serveroutput ON
--EXECUTE  mine ('11/09','P')
--EXECUTE  mine ('12/09','f')
--EXECUTE  mine ('01/10','T')
EXECUTE  mine ('13/09','P')

show errors;

