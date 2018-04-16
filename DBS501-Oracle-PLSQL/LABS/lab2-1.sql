SET SERVEROUTPUT ON
SET VERIFY OFF

ACCEPT temptype  PROMPT 'Enter your input scale (C or F) for temperature: ';
ACCEPT tempvalue PROMPT 'Enter your temperature value to be converted: 	 ';

DECLARE
  v_temptype CHAR(1) := '&temptype';
  v_tempvalue DECIMAL(4,1) := '&tempvalue';
BEGIN 
  IF UPPER(v_temptype) = 'C' THEN
    v_tempvalue := v_tempvalue * 9 / 5 + 32;
    DBMS_OUTPUT.PUT_LINE('Your converted temperature in F is exactly ' || v_tempvalue);
  ELSIF UPPER(v_temptype) = 'F' THEN
    v_tempvalue := (v_tempvalue - 32) / 1.8;
    DBMS_OUTPUT.PUT_LINE('Your converted temperature in C is exactly ' || v_tempvalue);
  ELSE
    DBMS_OUTPUT.PUT_LINE('This is NOT a valid scale. Must be C or F.'); 
  END IF;
END;
/