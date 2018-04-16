SET SERVEROUTPUT ON
SET VERIFY OFF
DECLARE
  v_des VARCHAR2(30);
  v_number NUMBER(8,2);
  v_constant CONSTANT VARCHAR2(10) := '704B';
  v_boolean BOOLEAN;
  v_date DATE := TRUNC(SYSDATE) + 7;
BEGIN
    DBMS_OUTPUT.PUT_LINE ('The constant is: '||v_constant||'.');
    DBMS_OUTPUT.PUT_LINE ('The date is: '||v_date||'.');
    
    --D
    v_des := 'C++ advanced';
    
    IF v_des LIKE '%SQL%' THEN
      DBMS_OUTPUT.PUT_LINE(v_des);
    ELSE
      IF v_constant LIKE '%704B%' THEN
        IF v_des IS NOT NULL THEN
          DBMS_OUTPUT.PUT_LINE('Course name: ' || v_des || ' Room name: ' || v_constant );
        ELSE
          DBMS_OUTPUT.PUT_LINE('Course is unknown' || ' Room name: ' || v_constant );
        END IF;
      ELSE
        DBMS_OUTPUT.PUT_LINE('Course and location could not be determined');
      END IF;
    END IF;
END;
/