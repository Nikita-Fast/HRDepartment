--2) может ли несколько сотрудников в одном отделе иметь одинаковую должность? Ответ: да. В отделе м.б. 4 программиста-разработчика.
--3) должность VS позиция в штатном расписании:
--    - у нескольких сотрудников может быть одинаковая должность(speciality)
--    - позиция в штатном рапсисании может быть занята максимум одним сотрудником

CREATE DATABASE hr_department;
GO

USE hr_department

 --Создаем таблицы
create table department(
    department_id integer CONSTRAINT department_pk PRIMARY KEY,
    name varchar(50) not null
);

create table speciality(
    speciality_id integer CONSTRAINT speciality_pk PRIMARY KEY,
    name varchar(50) not null,
	salary integer not null
);

create table employee(
    employee_id integer CONSTRAINT employee_pk PRIMARY KEY,
    full_name varchar(50) not null,
	main_speciality integer not null,
	hire_date date not null,
	expirience integer not null,
	education varchar(100) not null
);

create table timetable(
    department_id integer not null,
    speciality_id integer not null,
    employee_id   integer null
);

create table course(
    course_id integer CONSTRAINT course_pk PRIMARY KEY,
    name varchar(100)  not null
);

create table emp_course(
    employee_id integer not null,
    course_id integer not null,
	pass_date Date not null
);

 --Добавляем внешние ключи
alter table employee add constraint FK_employee_speciality
	FOREIGN KEY (main_speciality)
	REFERENCES speciality(speciality_id)
;

alter table timetable add constraint FK_timetable_department
    FOREIGN KEY (department_id)
    REFERENCES department(department_id)
;

alter table timetable add constraint FK_timetable_speciality
    FOREIGN KEY (speciality_id)
    REFERENCES speciality(speciality_id)
;

alter table timetable add constraint FK_timetable_employee
    FOREIGN KEY (employee_id)
    REFERENCES employee(employee_id)
;

alter table emp_course add constraint FK_emp_course_employee
   FOREIGN KEY (employee_id)
    REFERENCES employee(employee_id)
;

alter table emp_course add constraint FK_emp_course_course
   FOREIGN KEY (course_id)
    REFERENCES course(course_id)
;

GO

-- ПРОЦЕДУРЫ
GO
-- курсы могут иметь одинаковые имена, ведь name не является PK
CREATE PROCEDURE add_course
@name as varchar(255) AS
BEGIN
	DECLARE @new_course_id as integer;
	SELECT @new_course_id=MAX(course_id) FROM course;
	if @new_course_id is not null
		begin
			INSERT INTO course(course_id, name) VALUES(@new_course_id + 1, @name);
		end
	else
		INSERT INTO course(course_id, name) VALUES(1, @name);
END;
GO

GO
CREATE PROCEDURE add_speciality
@name as varchar(255),
@salary as integer AS
BEGIN
	DECLARE @new_speciality_id as integer;
	SELECT @new_speciality_id=MAX(speciality_id) FROM speciality;
	if @new_speciality_id is not null
		begin
			INSERT INTO speciality(speciality_id, name, salary) VALUES(@new_speciality_id + 1, @name, @salary);
		end
	else
		INSERT INTO speciality(speciality_id, name, salary) VALUES(1, @name, @salary);
END;
GO

GO
CREATE PROCEDURE add_employee
@full_name as varchar(255),
@main_speciality as integer,
@education as varchar(255),
@expirience as integer = 0 AS
BEGIN
	DECLARE @new_employee_id as integer;
	SELECT @new_employee_id=MAX(employee_id) FROM employee;

	DECLARE @curr_date as Date;
	SELECT @curr_date=GETDATE();

	if @new_employee_id is not null
		INSERT INTO employee(employee_id, full_name, main_speciality, hire_date, expirience, education)
		VALUES(@new_employee_id + 1, @full_name, @main_speciality, @curr_date, @expirience, @education);
	else
		INSERT INTO employee(employee_id, full_name, main_speciality, hire_date, expirience, education)
		VALUES(1, @full_name, @main_speciality, @curr_date, @expirience, @education);
END;
GO

GO
CREATE PROCEDURE add_passed_course
-- добавить прохождение сотрудником курса повышения квалификации
@employee_id as integer,
@course_id as integer,
@pass_date as Date = null
AS
BEGIN
	if @pass_date is null
		SET @pass_date=GETDATE();
	INSERT INTO emp_course(employee_id, course_id, pass_date) VALUES(@employee_id, @course_id, @pass_date);
END;
GO

GO
CREATE PROCEDURE add_position_to_timetable
@department_id as integer,
@speciality_id as integer,
@employee_id as integer = null --по умолчанию, сотрудник не назначен на позицию в штатном расписании
AS
BEGIN
	INSERT INTO timetable(department_id, speciality_id, employee_id) 
	VALUES(@department_id, @speciality_id, @employee_id);
END;
GO

CREATE TYPE department_description AS TABLE (speciality_id integer, required_employee_num integer);

GO
CREATE PROCEDURE add_department
--вообще добавление нового отдела означает перечисление должностей этого отдела и указание
--человеко-единиц, требуемых на каждую должность. Соответствующее число строк должно быть 
--добавлено в таблицу timetable
@department_name as varchar(255),
@department_description as department_description READONLY
AS
BEGIN
	DECLARE @new_department_id as integer;
	SELECT @new_department_id=MAX(department_id) FROM department;

	if @new_department_id is null
		SET @new_department_id=0;
	INSERT INTO department(department_id, name) VALUES(@new_department_id + 1, @department_name);

	-- добавляем строки в штатное расписание
	DECLARE @spec_id integer, @req_emp_num integer;

	DECLARE my_cursor CURSOR
	FOR SELECT speciality_id, required_employee_num
	FROM @department_description;

	OPEN my_cursor;

	FETCH NEXT FROM my_cursor INTO @spec_id, @req_emp_num;

	WHILE @@FETCH_STATUS=0
		begin
			DECLARE @i integer;
			SET @i=0
			PRINT @spec_id;
			PRINT @req_emp_num;
			WHILE @i < @req_emp_num
				begin
					EXEC add_position_to_timetable @new_department_id, @spec_id
					SET @i = @i + 1
				end;

			FETCH NEXT FROM my_cursor INTO @spec_id, @req_emp_num;
		end;

	CLOSE my_cursor;
	DEALLOCATE my_cursor;
END;
GO


-- ВЫЗОВЫ ПРОЦЕДУР
GO
exec add_course 'Основы финансовой грамотности';
select * from course;

EXEC add_speciality @name='Тестировщик UI', @salary=45000;
EXEC add_speciality @name='Python разработчик', @salary=60000;
SELECT * FROM speciality;

EXEC add_employee @full_name='Фаст Никита', @main_speciality='1', @education='Программная инженерия СПБГУ';
SELECT * FROM employee;

EXEC add_position_to_timetable 4, 2, 1;

EXEC add_passed_course 1, 1

DECLARE @t1 department_description;
INSERT INTO @t1 VALUES(1, 3);
INSERT INTO @t1 VALUES(2, 5);

EXEC add_department 'отдел программирования', @t1;
select * from department;
select * from timetable;
GO

GO
CREATE VIEW v_timetable(dep_name, speciality, emp_name)
-- показать все расписание
AS
SELECT d.name, s.name, e.full_name
FROM timetable as t
JOIN department as d ON d.department_id = t.department_id
JOIN speciality as s ON s.speciality_id = t.speciality_id
LEFT JOIN employee as e ON e.employee_id = t.employee_id
;
GO

SELECT * FROM v_timetable ORDER BY speciality;

-- TRUNCATE TABLE TIMETABLE;

-- insert into position_in_timetable(department_id, speciality_id, employee_id)
-- select 2, 2, null
-- from generate_series(1, 4);

-- select * from department_info cross join generate_series(1, 4);


-- select * from department_info where department_id = 2;
-- select speciality_id from (
--     select department_info.* from department_info cross join generate_series(1,3)
-- );

-- select distinct speciality_id from department_info;


-- select staff_units from department_info where 
--     select distinct speciality_id from department_info where department_id = 2

-- select * from position_in_timetable;
-- truncate position_in_timetable;


