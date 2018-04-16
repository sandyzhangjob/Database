--1, add column
-- ALTER TABLE countries ADD (flag VARCHAR2(7));

SET SERVEROUTPUT ON
SET VERIFY OFF

ACCEPT inputregid PROMPT 'Enter value for region: ';
DECLARE
    v_cid   countries.country_id%TYPE;
    v_cname countries.country_name%TYPE;
    v_rid   countries.region_id%TYPE;
    v_regid NUMBER := &inputregid;
    v_cnt   NUMBER;
    v_flag  VARCHAR2(30);
    cursor c_rid is   
        SELECT c.country_id, c.REGION_ID
        FROM countries c LEFT JOIN locations l ON c.country_id = l.country_id
        WHERE l.city IS NULL AND c.region_id in (select region_id from regions)
        order by c.region_id, c.country_name;
BEGIN
    SELECT c.country_id, c.country_name, c.REGION_ID
    INTO v_cid, v_cname, v_rid
    FROM countries c
    LEFT JOIN locations l ON c.country_id = l.country_id
    WHERE l.city IS NULL AND region_id = v_regid;
    DBMS_OUTPUT.PUT_LINE('In the region '|| v_regid || ' there is ONE country ' || v_cname || ' with NO city.');
    
    SELECT count(*) INTO v_cnt 
    FROM countries c LEFT JOIN locations l ON c.country_id = l.country_id
    WHERE l.city IS NULL;
    DBMS_OUTPUT.PUT_LINE('Number of countries with NO cities listed is: ' || v_cnt);
    
    FOR r in c_rid LOOP
        v_flag := 'Empty_' || r.region_id;
        UPDATE countries SET flag = v_flag WHERE region_id = r.region_id AND country_id = r.country_id;
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('This region ID does NOT exist: '|| v_regid);
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('This region ID has MORE THAN ONE country without cities listed: '|| v_regid);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Other errors');
END;
/
SELECT c.*
FROM countries c
LEFT JOIN locations l ON c.country_id = l.country_id
WHERE l.city IS NULL and c.flag is not null
order by c.region_id, c.country_name;
ROLLBACK;
/
