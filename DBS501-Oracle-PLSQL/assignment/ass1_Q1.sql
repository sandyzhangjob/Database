SET  SERVEROUTPUT ON
SET  VERIFY  OFF

ACCEPT ctyid PROMPT 'Enter value for country:'
DECLARE
    v_ctyid VARCHAR2(30) := '&ctyid';
    v_count NUMBER(5);
    v_ctyname countries.country_name%TYPE;
    v_ctynameb VARCHAR2(5);
    v_charprovince VARCHAR2(50);
    v_char VARCHAR2(5);
    r_locations locations%ROWTYPE;
BEGIN
    SELECT LENGTH(street_address), city INTO v_count, v_ctyname FROM locations WHERE state_province IS NULL AND UPPER(country_id) = UPPER(v_ctyid);
    SELECT substr(v_ctyname,1,1) INTO v_ctynameb FROM dual;
    
    IF v_ctynameb in ('A', 'B', 'E', 'F') THEN
        v_char := '*';
    ELSIF v_ctynameb in ('C', 'D', 'E', 'H') THEN
        v_char := '&';
    ELSE
        v_char := '#';
    END IF;
    
    FOR i IN 1..v_count LOOP
        v_charprovince := v_charprovince || v_char;
    END LOOP;
    
    UPDATE locations SET state_province = v_charprovince WHERE state_province IS NULL AND UPPER(country_id) = UPPER(v_ctyid);
    DBMS_OUTPUT.PUT_LINE('City '|| v_ctyname || ' has modified its province to ' || v_charprovince);
EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
        DBMS_OUTPUT.PUT_LINE('This country has NO cities listed.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('This country has MORE THAN ONE City without province listed.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Other errors');      
END;
/
SELECT * FROM locations WHERE substr(state_province,1,1) in ('*', '&', '#');
ROLLBACK;
/
