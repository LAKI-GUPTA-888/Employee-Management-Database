-- Employee Management & Attendance Tracker (MySQL 8.x)

drop database if exists employee_mgmt_attendance;
create database employee_mgmt_attendance;

-- Departments
create table Departments(
department_id int primary key auto_increment,
department_name varchar(100) not null unique
)engine=InnoDB;


-- Roles 
create table Roles(
role_id int primary key auto_increment,
role_name varchar(100) not null,
department_id int not null,
constraint fk_department_id foreign key(department_id)
references departments(department_id)
on update cascade on delete restrict,
unique key uk_role_department (role_name,department_id)
)engine=InnoDB;



-- Shifts 
create table Shifts(
shift_id int primary key auto_increment,
shift_name varchar(100) not null unique,
shift_start time not null,
shift_end time not null,
grace_minutes int not null default 10
)engine=InnoDB;


-- Employees
create table employees(
employee_id int primary key auto_increment,
first_name varchar(100) not null,
last_name varchar(100) not null,
email varchar(120) not null unique,
phone varchar(20) not null unique,
department_id int not null,
role_id int not null,
shift_id int not null,
hire_date date not null,
salary decimal(12,2) not null check (salary >0),
status enum('Active','Inactive') not null default 'Active',
constraint fk_emp_dept foreign key (department_id)
references departments(department_id)
on update cascade on delete restrict,
constraint fk_emp_role foreign key (role_id)
references roles(role_id)
on update cascade on delete restrict,
constraint fk_emp_shift foreign key (shift_id)
references shifts(shift_id)
on update cascade on delete restrict
)engine=InnoDB;


-- Helpfull Indexes
create index ix_emp_dept on employees(department_id);
create index ix_emp_role on employees(role_id);
create index ix_emp_shift on employees(shift_id);

-- Attendance 

create table attendance(
attendance_id int primary key auto_increment,
employee_id int not null,
att_date date not null,
clock_in time not null,
clock_out time not null,
status enum('P','L','A','WFH','LEAVE') null, -- present,late,absent,work from home, paid-leave
notes varchar(255) null,
constraint fk_att_emp foreign key (employee_id)
references employees (employee_id)
on update cascade on delete restrict,
constraint uq_att_emp_date unique(employee_id,att_date)
)engine=InnoDB;

create index ix_att_emp_date on attendance(employee_id ,att_date);
create index ix_att_date on attendance (att_date);

-- Holiday

create table holidays(
holiday_date date primary key,
name varchar(100) not null
)engine=InnoDB;




/* ==========================
   2) SEED LOOKUP DATA
   ========================== */
INSERT INTO departments (department_name) VALUES
 ('Human Resources'),
 ('Engineering'),
 ('Sales'),
 ('Marketing'),
 ('Finance');

INSERT INTO roles (role_name, department_id) VALUES
 ('HR Executive', 1),
 ('HR Manager', 1),
 ('Software Engineer', 2),
 ('Senior Software Engineer', 2),
 ('QA Engineer', 2),
 ('Sales Associate', 3),
 ('Sales Manager', 3),
 ('Marketing Executive', 4),
 ('Content Strategist', 4),
 ('Accountant', 5);

INSERT INTO shifts (shift_name, shift_start, shift_end, grace_minutes) VALUES
 ('General', '09:30:00', '18:30:00', 10),
 ('Early',   '08:00:00', '17:00:00', 10),
 ('Late',    '12:00:00', '21:00:00', 10);

/* ==========================
   3) GENERATE 200+ EMPLOYEES
   ========================== */

-- Helper name pools
CREATE TEMPORARY TABLE tmp_firstnames (name VARCHAR(50) PRIMARY KEY);
INSERT INTO tmp_firstnames (name) VALUES
 ('Aarav'),('Vivaan'),('Aditya'),('Vihaan'),('Arjun'),('Reyansh'),('Mohammad'),('Sai'),('Ayaan'),('Krishna'),
 ('Ishaan'),('Rohan'),('Kartik'),('Rudra'),('Kabir'),('Dhruv'),('Shivansh'),('Anay'),('Parth'),('Yug'),
 ('Anika'),('Aadhya'),('Anaya'),('Diya'),('Ira'),('Myra'),('Sara'),('Aarohi'),('Aarya'),('Kiara');

CREATE TEMPORARY TABLE tmp_lastnames (name VARCHAR(50) PRIMARY KEY);
INSERT INTO tmp_lastnames (name) VALUES
 ('Sharma'),('Verma'),('Patel'),('Gupta'),('Kumar'),('Shah'),('Iyer'),('Reddy'),('Naidu'),('Chatterjee'),
 ('Bose'),('Nair'),('Mishra'),('Dubey'),('Yadav'),('Tiwari'),('Jain'),('Singh'),('Das'),('Mehta');
 
 
 
-- Sequence 1..220 (recursive CTE)
-- WITH RECURSIVE seq(n) AS (
--   SELECT 1
--   UNION ALL
--   SELECT n+1 FROM seq WHERE n < 220
-- )

-- INSERT INTO employees (first_name, last_name, email, phone, department_id, role_id, shift_id, hire_date, salary, status)
-- SELECT
--   (SELECT name FROM tmp_firstnames ORDER BY RAND() LIMIT 1) AS first_name,
--   (SELECT name FROM tmp_lastnames  ORDER BY RAND() LIMIT 1) AS last_name,
--   CONCAT('user', LPAD(n,3,'0'), '@example.com') AS email,
--   CONCAT('9', LPAD(FLOOR(RAND()*999999999),9,'0')) AS phone,
--   (SELECT department_id FROM departments ORDER BY RAND() LIMIT 1) AS department_id,
--   (SELECT role_id FROM roles ORDER BY RAND() LIMIT 1) AS role_id,
--   (SELECT shift_id FROM shifts ORDER BY RAND() LIMIT 1) AS shift_id,
--   DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*1000) DAY) AS hire_date,
--   ROUND(300000 + RAND()*900000, 0) AS salary,
--   'ACTIVE' AS status
-- FROM seq;

DROP TEMPORARY TABLE IF EXISTS tmp_firstnames;
DROP TEMPORARY TABLE IF EXISTS tmp_lastnames;

/* ==========================
   4) ATTENDANCE DATA (one month)
   Generate business days for a target month and sample attendance
   ========================== */

-- Choose month to generate (change as needed)
SET @start_date := DATE('2025-07-01');
SET @end_date   := DATE('2025-07-31');

-- Example holidays (optional; you'll likely customize)
INSERT IGNORE INTO holidays (holiday_date, name) VALUES
 ('2025-07-17','Company Foundation Day');

-- Calendar CTE (all days in month)
-- WITH RECURSIVE d(dt) AS (
--   SELECT @start_date
--   UNION ALL
--   SELECT dt + INTERVAL 1 DAY FROM d WHERE dt < @end_date
-- ),
-- business_days AS (
--   SELECT dt
--   FROM d
--   WHERE DAYOFWEEK(dt) NOT IN (1,7) -- 1=Sunday, 7=Saturday
--     AND dt NOT IN (SELECT holiday_date FROM holidays)
-- )
-- INSERT INTO attendance (employee_id, att_date, clock_in, clock_out, status, notes)
-- SELECT
--   e.employee_id,
--   bd.dt AS att_date,
--   -- Randomize clock_in: 5% Absent (NULL clock_in), otherwise vary around shift start (-15 to +45 minutes)
--   CASE
--     WHEN RAND() < 0.05 THEN NULL
--     ELSE TIMESTAMP(
--            bd.dt,
--            ADDTIME(
--              s.shift_start,
--              SEC_TO_TIME(FLOOR(RAND()*3600) - 900)  -- -15 minutes to +45 minutes
--            )
--          )
--   END AS clock_in,
--   NULL AS clock_out,
--   NULL AS status,
--   NULL AS notes
-- FROM employees e
-- JOIN shifts s ON s.shift_id = e.shift_id
-- JOIN business_days bd;

-- Ensure we have some WFH and LEAVE sprinkled in
UPDATE attendance a
JOIN employees e ON e.employee_id = a.employee_id
SET a.status = CASE
                 WHEN RAND() < 0.03 THEN 'WFH'
                 WHEN RAND() < 0.02 THEN 'LEAVE'
                 ELSE NULL
               END
WHERE a.att_date BETWEEN @start_date AND @end_date;




/* ==========================
   5) TRIGGERS FOR AUTOMATION
   ========================== */
DELIMITER $$

-- BEFORE INSERT: default status & clock_out using shift times/grace
CREATE TRIGGER trg_attendance_bi
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
  DECLARE s_start TIME;
  DECLARE s_end   TIME;
  DECLARE g       INT;

  -- Fetch shift details for the employee
  SELECT s.shift_start, s.shift_end, s.grace_minutes
    INTO s_start, s_end, g
  FROM employees e
  JOIN shifts s ON s.shift_id = e.shift_id
  WHERE e.employee_id = NEW.employee_id;

  -- If status not provided, infer from clock_in vs grace
  IF NEW.status IS NULL THEN
    IF NEW.clock_in IS NULL THEN
      SET NEW.status = 'A';
    ELSE
      IF NEW.clock_in > TIMESTAMP(NEW.att_date, ADDTIME(s_start, SEC_TO_TIME(g*60))) THEN
        SET NEW.status = 'L';
      ELSE
        SET NEW.status = 'P';
      END IF;
    END IF;
  END IF;

  -- If present/late/wfh and no clock_out provided, default to shift_end
  IF NEW.clock_out IS NULL AND NEW.status IN ('P','L','WFH') THEN
    SET NEW.clock_out = TIMESTAMP(NEW.att_date, s_end);
  END IF;
END$$

-- BEFORE UPDATE: recompute status if times change
CREATE TRIGGER trg_attendance_bu
BEFORE UPDATE ON attendance
FOR EACH ROW
BEGIN
  DECLARE s_start TIME;
  DECLARE s_end   TIME;
  DECLARE g       INT;

  SELECT s.shift_start, s.shift_end, s.grace_minutes
    INTO s_start, s_end, g
  FROM employees e
  JOIN shifts s ON s.shift_id = e.shift_id
  WHERE e.employee_id = NEW.employee_id;

  -- Re-evaluate status only when times or status null
  IF (NEW.clock_in <> OLD.clock_in) OR (NEW.status IS NULL) THEN
    IF NEW.clock_in IS NULL THEN
      SET NEW.status = 'A';
    ELSE
      IF NEW.clock_in > TIMESTAMP(NEW.att_date, ADDTIME(s_start, SEC_TO_TIME(g*60))) THEN
        SET NEW.status = 'L';
      ELSE
        SET NEW.status = 'P';
      END IF;
    END IF;
  END IF;

  -- clock_out default if missing
  IF NEW.clock_out IS NULL AND NEW.status IN ('P','L','WFH') THEN
    SET NEW.clock_out = TIMESTAMP(NEW.att_date, s_end);
  END IF;
END$$

DELIMITER ;

-- Backfill triggers effect for rows already inserted (set status/clock_out where NULL)
UPDATE attendance SET status = NULL WHERE status IS NOT NULL; -- force recompute
UPDATE attendance SET status = status; -- triggers BEFORE UPDATE to recompute

/* ==========================
   6) FUNCTIONS FOR METRICS
   ========================== */
DELIMITER $$

-- 6.1 Daily work minutes for one employee & date
CREATE FUNCTION fn_daily_work_minutes(p_emp_id INT, p_date DATE)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE mins INT;
  SELECT IFNULL(TIMESTAMPDIFF(MINUTE, clock_in, clock_out), 0)
    INTO mins
  FROM attendance
  WHERE employee_id = p_emp_id
    AND att_date = p_date
    AND status IN ('P','L','WFH','LEAVE'); -- treat LEAVE as 0 later in reports if needed
  RETURN IFNULL(mins, 0);
END$$

-- 6.2 Monthly total work minutes for employee
CREATE FUNCTION fn_monthly_work_minutes(p_emp_id INT, p_year INT, p_month INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE mins INT;
  SELECT IFNULL(SUM(TIMESTAMPDIFF(MINUTE, clock_in, clock_out)), 0)
    INTO mins
  FROM attendance
  WHERE employee_id = p_emp_id
    AND YEAR(att_date) = p_year
    AND MONTH(att_date) = p_month
    AND status IN ('P','L','WFH');
  RETURN IFNULL(mins, 0);
END$$

DELIMITER ;

/* ==========================
   7) REPORTING & ANALYSIS QUERIES
   ========================== */

-- 7.1 Monthly attendance summary per employee (status counts)
-- Change @y and @m as needed
SET @y := 2025;
SET @m := 7;

SELECT
  e.employee_id,
  CONCAT(e.first_name,' ',e.last_name) AS employee_name,
  d.department_name,
  r.role_name,
  SUM(CASE WHEN a.status = 'P' THEN 1 ELSE 0 END) AS days_present,
  SUM(CASE WHEN a.status = 'L' THEN 1 ELSE 0 END) AS days_late,
  SUM(CASE WHEN a.status = 'WFH' THEN 1 ELSE 0 END) AS days_wfh,
  SUM(CASE WHEN a.status = 'LEAVE' THEN 1 ELSE 0 END) AS days_leave,
  SUM(CASE WHEN a.status = 'A' THEN 1 ELSE 0 END) AS days_absent
FROM employees e
JOIN departments d ON d.department_id = e.department_id
JOIN roles r       ON r.role_id = e.role_id
LEFT JOIN attendance a
       ON a.employee_id = e.employee_id
      AND YEAR(a.att_date) = @y
      AND MONTH(a.att_date) = @m
GROUP BY e.employee_id, employee_name, d.department_name, r.role_name
ORDER BY d.department_name, employee_name;

-- 7.2 Late arrivals with minutes late (top offenders)
SELECT
  e.employee_id,
  CONCAT(e.first_name,' ',e.last_name) AS employee_name,
  a.att_date,
  TIME(a.clock_in) AS clock_in_time,
  s.shift_start,
  s.grace_minutes,
  GREATEST(0,
    TIMESTAMPDIFF(MINUTE, TIMESTAMP(a.att_date, ADDTIME(s.shift_start, SEC_TO_TIME(s.grace_minutes*60))), a.clock_in)
  ) AS minutes_late
FROM attendance a
JOIN employees e ON e.employee_id = a.employee_id
JOIN shifts s    ON s.shift_id = e.shift_id
WHERE a.status = 'L'
  AND YEAR(a.att_date) = @y
  AND MONTH(a.att_date) = @m
ORDER BY minutes_late DESC, a.att_date DESC
LIMIT 100;

-- 7.3 Absentees by date (who was absent on a given day)
SET @absent_date := DATE('2025-07-15');
SELECT
  a.att_date,
  e.employee_id,
  CONCAT(e.first_name,' ',e.last_name) AS employee_name,
  d.department_name,
  r.role_name
FROM attendance a
JOIN employees e ON e.employee_id = a.employee_id
JOIN departments d ON d.department_id = e.department_id
JOIN roles r ON r.role_id = e.role_id
WHERE a.att_date = @absent_date
  AND a.status = 'A'
ORDER BY d.department_name, employee_name;

-- 7.4 Monthly work hours per employee (rounded hours)
SELECT
  e.employee_id,
  CONCAT(e.first_name,' ',e.last_name) AS employee_name,
  ROUND(fn_monthly_work_minutes(e.employee_id, @y, @m)/60, 2) AS work_hours
FROM employees e
ORDER BY work_hours DESC
LIMIT 100;

-- 7.5 Department-level KPIs (presence rate, avg hours)
WITH emp_month AS (
  SELECT
    e.employee_id,
    e.department_id,
    SUM(CASE WHEN a.status IN ('P','L','WFH') THEN 1 ELSE 0 END) AS attended_days,
    COUNT(*) AS total_days,
    SUM(CASE WHEN a.status IN ('P','L','WFH') THEN TIMESTAMPDIFF(MINUTE, a.clock_in, a.clock_out) ELSE 0 END) AS worked_mins
  FROM employees e
  JOIN attendance a ON a.employee_id = e.employee_id
  WHERE YEAR(a.att_date) = @y AND MONTH(a.att_date) = @m
  GROUP BY e.employee_id, e.department_id
)
SELECT
  d.department_name,
  ROUND(AVG(attended_days / NULLIF(total_days,0))*100,2) AS avg_presence_pct,
  ROUND(AVG(worked_mins)/60,2) AS avg_hours
FROM emp_month em
JOIN departments d ON d.department_id = em.department_id
GROUP BY d.department_name
ORDER BY d.department_name;

-- 7.6 HAVING example: employees with < 80% presence
WITH emp_days AS (
  SELECT
    e.employee_id,
    CONCAT(e.first_name,' ',e.last_name) AS employee_name,
    SUM(CASE WHEN a.status IN ('P','L','WFH') THEN 1 ELSE 0 END) AS attended_days,
    COUNT(*) AS total_days
  FROM employees e
  JOIN attendance a ON a.employee_id = e.employee_id
  WHERE YEAR(a.att_date) = @y AND MONTH(a.att_date) = @m
  GROUP BY e.employee_id
)
SELECT employee_id, employee_name,
       attended_days, total_days,
       ROUND(attended_days/total_days*100,2) AS presence_pct
FROM emp_days
HAVING presence_pct < 80
ORDER BY presence_pct ASC
LIMIT 100;

-- 7.7 Example of parameterized monthly attendance via view
DROP VIEW IF EXISTS v_attendance_month;
CREATE VIEW v_attendance_month AS
SELECT
  e.employee_id,
  CONCAT(e.first_name,' ',e.last_name) AS employee_name,
  YEAR(a.att_date) AS y,
  MONTH(a.att_date) AS m,
  SUM(CASE WHEN a.status='P' THEN 1 ELSE 0 END) AS P_days,
  SUM(CASE WHEN a.status='L' THEN 1 ELSE 0 END) AS L_days,
  SUM(CASE WHEN a.status='WFH' THEN 1 ELSE 0 END) AS WFH_days,
  SUM(CASE WHEN a.status='LEAVE' THEN 1 ELSE 0 END) AS LEAVE_days,
  SUM(CASE WHEN a.status='A' THEN 1 ELSE 0 END) AS A_days,
  ROUND(SUM(CASE WHEN a.status IN ('P','L','WFH') THEN TIMESTAMPDIFF(MINUTE, a.clock_in, a.clock_out) ELSE 0 END)/60,2) AS work_hours
FROM employees e
LEFT JOIN attendance a ON a.employee_id = e.employee_id
GROUP BY e.employee_id, employee_name, y, m;

-- Usage:
-- SELECT * FROM v_attendance_month WHERE y=2025 AND m=7 ORDER BY work_hours DESC;

-- =====================================================================
-- 8) PERFORMANCE TIPS
-- - Use EXPLAIN on heavy reports and ensure indexes (ix_att_emp_date) are used.
-- - Keep (employee_id, att_date) UNIQUE to avoid duplicate day entries.
-- - Consider partitioning attendance by RANGE COLUMNS(att_date) for very large datasets.
-- - For real systems, clock_in/out should come from app layer or biometric device imports.
-- ====================================================================

