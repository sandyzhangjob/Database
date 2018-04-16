--1, add column
-- ALTER TABLE countries ADD (flag VARCHAR2(7));

SET SERVEROUTPUT ON
SET VERIFY OFF

ACCEPT inputregid PROMPT 'Enter value for region: ';

DECLARE
    v_regid NUMBER := &inputregid;
    v_cnt   NUMBER;
    v_flag  VARCHAR2(30);
    cnt     NUMBER := 0;

    CURSOR c1 IS
        SELECT c.country_id, c.country_name, c.REGION_ID
        FROM countries c LEFT JOIN locations l ON c.country_id = l.country_id
        WHERE l.city IS NULL AND region_id = v_regid;
    
    CURSOR c2 IS   
        SELECT c.country_id, c.country_name, c.REGION_ID
        FROM countries c LEFT JOIN locations l ON c.country_id = l.country_id
        WHERE l.city IS NULL AND c.region_id in (select region_id from regions)
        ORDER BY c.country_name;
    TYPE countryname IS TABLE OF countries.country_name%TYPE INDEX BY VARCHAR2(30);
    countryname_list countryname;
    idx integer := -4;
BEGIN
    FOR r in c1 LOOP
        cnt := cnt + 1;
    END LOOP;
    
    IF cnt = 0 THEN
        DBMS_OUTPUT.PUT_LINE('This region ID does NOT exist: '|| v_regid);
    ELSE
        FOR r2 in c2 LOOP
            v_flag := 'Empty_' || r2.region_id;
            UPDATE countries SET flag = v_flag WHERE region_id = r2.region_id AND country_id = r2.country_id;
    
            idx := idx + 5;
            countryname_list(idx) := r2.country_name;
            DBMS_OUTPUT.PUT_LINE('Index Table Key: '||idx||' has a value of '||countryname_list(idx));
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('======================================================================');
        DBMS_OUTPUT.PUT_LINE('Total number of elements in the Index Table or Number of countries with NO cities listed is: ' || countryname_list.COUNT);
        DBMS_OUTPUT.PUT_LINE('Second element (Country) in the Index Table is: '|| countryname_list(countryname_list.FIRST + 5));
        DBMS_OUTPUT.PUT_LINE('Before the last element (Country) in the Index Table is: '|| countryname_list(46));
        DBMS_OUTPUT.PUT_LINE('======================================================================');
        FOR r3 in c1 LOOP
            DBMS_OUTPUT.PUT_LINE('In the region '|| v_regid || ' there is ONE country ' || r3.country_name || ' with NO city.');
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('======================================================================');
        DBMS_OUTPUT.PUT_LINE('Total Number of countries with NO cities listed in the Region '||v_regid||' is: '|| cnt);          
    END IF;
END;
/
SELECT c.* 
FROM countries c LEFT JOIN locations l ON c.country_id = l.country_id
WHERE l.city IS NULL and c.flag is not null
ORDER BY c.region_id, c.country_name;
ROLLBACK;
/

