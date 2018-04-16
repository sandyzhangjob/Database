CREATE OR REPLACE PROCEDURE show_bizdays (
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
/

execute show_bizdays;
execute show_bizdays(sysdate+7,10);
