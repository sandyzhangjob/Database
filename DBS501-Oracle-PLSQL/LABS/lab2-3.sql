SET SERVEROUTPUT ON
SET VERIFY OFF
ACCEPT posint  PROMPT 'Please enter a Positive Integer: ';

DECLARE
  v_posint NUMBER(5) := &posint;
  v_sum NUMBER(10) := 0;
  v_count NUMBER(5);
  v_msg CHAR(4);
BEGIN 
  IF v_posint < 0  THEN
    DBMS_OUTPUT.PUT_LINE('Not a Positive Interger'); 
  ELSE
    IF MOD(v_posint, 2) = 0 THEN
      v_msg := 'Even';
      v_count := v_posint;
      WHILE v_count > 0 LOOP
        v_sum := v_sum + v_count;
        v_count := v_count - 2;
      END LOOP;
    ELSE 
      v_msg := 'Odd';
      v_count := v_posint;
      WHILE v_count > 0 LOOP
        v_sum := v_sum + v_count;
        v_count := v_count - 2;
      END LOOP;
    END IF;

    DBMS_OUTPUT.PUT_LINE('The sum of ' || v_msg ||' integers between 1 and ' || v_posint || ' is ' || v_sum );
  END IF;

END;
/