CREATE OR REPLACE PROCEDURE add_zip (
  v_zip   IN  zipcode.zip%TYPE,
  v_city  IN  zipcode.city%TYPE,
  v_state IN  zipcode.state%TYPE,
  v_flag  OUT VARCHAR2,
  v_currows OUT NUMBER ) 
IS
  vzip  VARCHAR2(20);
BEGIN
  SELECT count(zip) INTO vzip FROM zipcode WHERE zip = v_zip;
  IF vzip = 0 THEN
    INSERT INTO zipcode 
    VALUES(v_zip, v_city, v_state, 'DBS501_173A32', to_char(sysdate, 'DD-MON-YY'), 'DBS501_173A32', to_char(sysdate, 'DD-MON-YY'));
    v_flag := 'SUCCESS';
  ELSE
    DBMS_OUTPUT.PUT_LINE('This ZIPCODE '|| v_zip ||' is already in the Dataase. Try again.');
    v_flag := 'FAILURE';
  END IF;
  select count(*) into v_currows from  zipcode WHERE state = v_state;
END add_zip;
/

set serveroutput on
--1) test add_zip(18104, 'Chicago', 'MI', :vflag, :vcount)
VARIABLE vflag VARCHAR2(10)
VARIABLE vcount NUMBER
EXECUTE add_zip(18104, 'Chicago', 'MI', :vflag, :vcount)
PRINT vflag vcount
SELECT  * FROM zipcode WHERE state = 'MI';
rollback

--2) test add_zip(48104, 'Chicago', 'MI', :vflag, :vcount) 
VARIABLE vflag VARCHAR2(10)
VARIABLE vcount NUMBER
EXECUTE add_zip(48104, 'Chicago', 'MI', :vflag, :vcount) 
PRINT vflag vcount
SELECT  * FROM zipcode WHERE state = 'MI';