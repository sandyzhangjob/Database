--check how many department in that location
SELECT d.department_id
into v_dptid
FROM locations l, departments d
WHERE l.location_id = 1800
AND l.location_id = d.location_id;

--check how many employees in that location based on up's result
SELECT count(last_name)
FROM employees
where department_id = v_dptid;