CREATE OR REPLACE FUNCTION Get_Descr (
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
/

-- If you test with 150 then: 
SET  SERVEROUTPUT ON
SET  VERIFY OFF
VARIABLE a VARCHAR2(100)
EXECUTE :a := Get_Descr(150)
print a

-- If you test with 999 then: 
VARIABLE a VARCHAR2(100)
EXECUTE :a := Get_Descr(999)
print a


