CREATE OR REPLACE PACKAGE Lab5 IS
	FUNCTION Get_Descr (
        secid section.section_id%TYPE
    ) RETURN VARCHAR2 ;
	
	PROCEDURE show_bizdays (
        v_startdate         IN  DATE := sysdate,
        v_noofbusinessday   IN  NUMBER:= 30
    ) ;
END Lab5;
/

CREATE OR REPLACE PACKAGE BODY Lab5 IS
    FUNCTION Get_Descr (
        secid section.section_id%TYPE
    ) RETURN VARCHAR2 IS
        v_desc  VARCHAR2(100);
    BEGIN
        select description into v_desc
            from course where course_no = (
                select course_no from section where section_id = secid);
            
        v_desc := 'Course Description for Section Id '|| secid || ' is '|| v_desc ;
        return v_desc;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_desc := 'There is NO such Section id: ' || secid;
            RETURN v_desc;
    END Get_Descr;

    PROCEDURE show_bizdays (
        v_startdate         IN  DATE := sysdate,
        v_noofbusinessday   IN  NUMBER:= 30
    ) IS
        v_sysdate DATE;
    BEGIN
        v_sysdate := v_startdate;
        FOR i IN 1..v_noofbusinessday LOOP
            v_sysdate := v_sysdate + 1;
            IF to_char(v_sysdate, 'D') = 1 THEN
                v_sysdate := v_sysdate + 1;
            ELSIF to_char(v_sysdate, 'D') = 7 THEN
                v_sysdate := v_sysdate + 2;
            END IF;     
            dbms_output.put_line('The index is : '|| i ||' and the table value is: ' || v_sysdate);
        END LOOP;
    END show_bizdays;
END Lab5;
/

SET  SERVEROUTPUT ON
SET  VERIFY OFF
execute Lab5.show_bizdays;
execute Lab5.show_bizdays(sysdate+7,10);
