# Employee-Management-Database
Employee Management & Attendance Tracker (MySQL)
Project Overview

The Employee Management & Attendance Tracker is a MySQL database system designed to manage employee records, departments, roles, and track attendance effectively.
It provides a scalable and optimized structure for organizations to handle employee lifecycle management, shift tracking, attendance logging, and report generation.

Objectives

Efficiently store and manage employee data.

Track daily attendance including Present (P), Late (L), and Absent (A) status.

Automatically update attendance status using triggers.

Generate summary reports (monthly attendance, late arrivals, absentees).

Maintain data integrity with foreign key relationships and cascading actions.

Database Schema

The database consists of 4 core tables with relationships enforced using foreign keys:

Table Name	Purpose
departments	Stores company departments like HR, IT, Finance, etc.
roles	Defines roles like Manager, Analyst, Developer, etc.
employees	Maintains employee details and their assigned department/role.
attendance	Tracks daily attendance logs for each employee.
**Relationships**
departments → employees

One-to-Many (One department has many employees)

ON DELETE RESTRICT – Cannot delete a department if it has active employees.

roles → employees

One-to-Many (One role can be assigned to many employees)

ON DELETE RESTRICT – Cannot delete a role if it is assigned to employees.

employees → attendance

One-to-Many (One employee has many attendance records)

ON DELETE CASCADE – Deletes attendance automatically if an employee record is deleted.

**ER Diagram**
[Departments] 1 ----- * [Employees] * ----- 1 [Roles]
                               |
                               |
                               * 
                           [Attendance]

**Key Features

Normalization:**

Fully normalized to 3rd Normal Form (3NF) to prevent redundancy.

Constraints:

UNIQUE, NOT NULL, CHECK, and ENUM constraints ensure data quality.

Cascade Rules:

Automatic child record cleanup with ON DELETE CASCADE.

Triggers:

Automatically marks employees as Present, Late, or Absent based on clock-in time.

Functions:

Calculate total work hours between two dates.

Indexes:

Optimized indexing for faster queries and reporting.

Table Structure
1. departments
Column	Type	Description
department_id	INT (PK)	Unique identifier for each department
department_name	VARCHAR(100)	Name of the department
2. roles
Column	Type	Description
role_id	INT (PK)	Unique identifier for each role
role_name	VARCHAR(100)	Role title
3. employees
Column	Type	Description
employee_id	INT (PK)	Unique ID for each employee
first_name	VARCHAR(50)	Employee's first name
last_name	VARCHAR(50)	Employee's last name
email	VARCHAR(100)	Unique email ID
phone	VARCHAR(15)	Contact number
department_id	INT (FK)	Department reference
role_id	INT (FK)	Role reference
hire_date	DATE	Date of joining
status	ENUM	Active / Inactive
4. attendance
Column	Type	Description
attendance_id	INT (PK)	Unique ID for attendance record
employee_id	INT (FK)	Employee reference
attendance_date	DATE	Date of the attendance
clock_in	TIME	Clock-in time
clock_out	TIME	Clock-out time
status	ENUM('P','A','L')	Present, Absent, Late
total_hours	DECIMAL(5,2)	Total hours worked
**Sample Constraints**

UNIQUE (employee_id, attendance_date)
Prevents multiple attendance entries for the same employee on the same day.

ON DELETE CASCADE on attendance
Automatically deletes attendance when the employee record is deleted.

ON DELETE RESTRICT on department and role
Prevents accidental deletion of departments or roles if employees exist.


How to Use

Install MySQL 8.0+ and MySQL Workbench.

Run the provided SQL script:

SOURCE employee_mgmt_attendance.sql;


Insert sample data:

INSERT INTO departments (department_name) VALUES ('HR'), ('IT'), ('Finance'), ('Sales');


Start adding employees and attendance logs.

Example Query

Get monthly attendance summary per employee:

SELECT e.employee_id, e.first_name, e.last_name,
       COUNT(a.attendance_id) AS total_days_present,
       SUM(CASE WHEN a.status = 'L' THEN 1 ELSE 0 END) AS total_days_late
FROM employees e
LEFT JOIN attendance a ON e.employee_id = a.employee_id
WHERE MONTH(a.attendance_date) = 8 AND YEAR(a.attendance_date) = 2025
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_days_present DESC;

Tech Stack

Database: MySQL 8.0+ (InnoDB)

Client Tool: MySQL Workbench

Future Integration: Power BI / Tableau / Flutter
