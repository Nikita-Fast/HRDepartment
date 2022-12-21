--2) может ли несколько сотрудников в одном отделе иметь одинаковую должность? Ответ: да. В отделе м.б. 4 программиста-разработчика.
--3) должность VS позиция в штатном расписании:
--    - у нескольких сотрудников может быть одинаковая должность(speciality)
--    - позиция в штатном рапсисании может быть занята максимум одним сотрудником

--CREATE DATABASE hr_department;
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
	education varchar(255) not null
	--main_speciality integer not null,
	--expirience integer not null,
);

create table timetable(
	id integer CONSTRAINT timetable_pk PRIMARY KEY,
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


CREATE TABLE employee_speciality(
	employee_speciality_id integer CONSTRAINT employee_speciality_pk PRIMARY KEY,
	employee_id integer not null,
	speciality_id integer not null,
	hire_date Date not null,
	is_main_spec bit default 0 not null
);

CREATE TABLE work_log(
	emp_id integer not null,
	spec_id integer not null,
	days_of_work integer not null
);



 --Добавляем внешние ключи
alter table timetable add constraint FK_timetable_department
    FOREIGN KEY (department_id)
    REFERENCES department(department_id)
	ON DELETE CASCADE
;


alter table timetable add constraint FK_timetable_speciality
    FOREIGN KEY (speciality_id)
    REFERENCES speciality(speciality_id)
;

alter table timetable add constraint FK_timetable_employee
    FOREIGN KEY (employee_id)
    REFERENCES employee(employee_id)
	ON DELETE CASCADE	
;

alter table emp_course add constraint FK_emp_course_employee
   FOREIGN KEY (employee_id)
    REFERENCES employee(employee_id)
	ON DELETE CASCADE
;

alter table emp_course add constraint FK_emp_course_course
   FOREIGN KEY (course_id)
    REFERENCES course(course_id)
;

ALTER TABLE employee_speciality ADD CONSTRAINT FK_employee_speciality_employee
	FOREIGN KEY (employee_id)
    REFERENCES employee(employee_id)
	ON DELETE CASCADE
;

ALTER TABLE employee_speciality ADD CONSTRAINT FK_employee_speciality_speciality
	FOREIGN KEY (speciality_id)
    REFERENCES speciality(speciality_id)
	ON DELETE CASCADE
;

ALTER TABLE work_log ADD CONSTRAINT FK_work_log_employee
	FOREIGN KEY (emp_id)
    REFERENCES employee(employee_id)
	ON DELETE CASCADE
;

ALTER TABLE work_log ADD CONSTRAINT FK_work_log_speciality
	FOREIGN KEY (spec_id)
    REFERENCES speciality(speciality_id)
	ON DELETE CASCADE
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
@education as varchar(255),
@expirience as integer = 0 AS
BEGIN
	DECLARE @new_employee_id as integer;
	SELECT @new_employee_id=MAX(employee_id) FROM employee;

	if @new_employee_id is not null
		INSERT INTO employee(employee_id, full_name, education)
		VALUES(@new_employee_id + 1, @full_name, @education);
	else
		INSERT INTO employee(employee_id, full_name, education)
		VALUES(1, @full_name, @education);
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
	--навесить на timetable триггер после вставки, чтобы в табли emp_spec были добавлены данные
	--о сотрудниках на должностях
	DECLARE @id integer;
	SELECT @id = ISNULL(MAX(id), 0) FROM timetable;
	SET @id = @id + 1

	INSERT INTO timetable(id, department_id, speciality_id, employee_id) 
	VALUES(@id, @department_id, @speciality_id, @employee_id);
END;
GO


-- СОЗДАЕМ СПЕЦИАЛЬНЫЙ ТИП ДЛЯ ОПИСАНИЕ ТОГО, КАКИЕ ДОЛЖНОСТИ ДОЛЖНЫ БЫТЬ В ОТДЕЛЕ И СКОЛЬКО СОТРУДНИКОВ
-- ДОЛЖНЫ НА НИХ РАБОТАТЬ
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
	SET @new_department_id = @new_department_id + 1;

	INSERT INTO department(department_id, name) VALUES(@new_department_id, @department_name);

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

GO
-- УВОЛИТЬ СОТРУДНИКА И УДАЛИТЬ ВСЕ ЗАПИСИ О НЕМ ИЗ БД
CREATE PROCEDURE fire_employee
@emp_id integer
AS
BEGIN
	EXEC('DISABLE TRIGGER tr_del_emp_course ON emp_course');
	DELETE FROM employee WHERE employee_id = @emp_id;
	EXEC('ENABLE TRIGGER tr_del_emp_course ON emp_course');
END;
GO


GO
CREATE PROCEDURE assign_work_to_emp
@dep_id integer,
@spec_id integer,
@emp_id integer
AS
BEGIN
	DECLARE @vacant_num integer;

	SELECT @vacant_num = COUNT(*) FROM timetable 
	WHERE department_id = @dep_id AND speciality_id = @spec_id AND employee_id is null

	if @vacant_num > 0
	begin
		UPDATE timetable
		SET employee_id = @emp_id
		WHERE id = 
		(SELECT TOP 1 id FROM timetable
		WHERE department_id = @dep_id AND speciality_id = @spec_id AND employee_id is null);
	end;
END;


--GO


GO
CREATE VIEW v_timetable(dep_id, dep_name, speciality, emp_name)
-- ПОКАЗАТЬ ШТАТНОЕ РАСПИСАНИЕ ЦЕЛИКОМ
AS
SELECT d.department_id, d.name, s.name, e.full_name
FROM timetable as t
JOIN department as d ON d.department_id = t.department_id
JOIN speciality as s ON s.speciality_id = t.speciality_id
LEFT JOIN employee as e ON e.employee_id = t.employee_id
;
GO

GO
CREATE VIEW v_emp_course(emp_name, course_name, pass_date)
AS
SELECT e.full_name, c.name, emp_course.pass_date 
FROM emp_course 
JOIN employee as e ON e.employee_id = emp_course.employee_id
JOIN course as c ON c.course_id = emp_course.course_id
;
GO

GO
CREATE VIEW v_employee_speciality(emp_name, spec_name, hire_date, is_main_spec)
AS
SELECT e.full_name, s.name, hire_date, is_main_spec FROM employee_speciality as es
JOIN employee as e ON e.employee_id = es.employee_id
JOIN speciality as s ON s.speciality_id = es.speciality_id
;
GO

GO
CREATE VIEW v_work_log(emp_name, spec_name, days_worked)
AS
SELECT e.full_name, s.name, wl.days_of_work FROM work_log as wl
JOIN employee as e ON e.employee_id = wl.emp_id
JOIN speciality as s ON s.speciality_id = wl.spec_id
;
GO

--SELECT * FROM v_timetable ORDER BY speciality;
--SELECT * FROM v_emp_course ORDER BY pass_date, emp_name;
--SELECT * FROM v_employee_speciality ORDER BY emp_name;
--SELECT * FROM v_work_log ORDER BY emp_name;


-------TRIGGERS--------------
GO
-- ЗАПРЕТ НА УДАЛЕНИЕ ЗАПИСЕЙ О ПРОХОЖДЕНИИ СОТРУДНИКАМИ КУРСОВ ПОВЫШЕНИЯ КВАЛИФИКАЦИИ
CREATE TRIGGER tr_del_emp_course
ON emp_course FOR DELETE
AS ROLLBACK
;
GO

---- УДАЛИТЬ НЕ ПОЛУЧИТСЯ
--DELETE FROM emp_course WHERE employee_id = 2;
--select * from v_emp_course;

---- УДАЛИТЬ НЕ ПОЛУЧИТСЯ, ХОТЯ И ВКЛЮЧЕНО КАСКАДНОЕ УДАЛЕНИЕ У ТАБЛИЦЫ ССЫЛАЮЩИХСЯ НА employee
--DELETE FROM employee
--WHERE employee_id = 1
--;

GO
CREATE TRIGGER tr_ins_upd_timetable
ON timetable AFTER INSERT, UPDATE
AS
	--если в расписание добавилась строка с не нулевым полем сотрудника, то
	--данные о сотруднике и должности надо добавить в emp_spec
	DECLARE @new_id as integer;
	SELECT @new_id= ISNULL(MAX(employee_speciality_id), 0) FROM employee_speciality;
	SET @new_id = @new_id + 1;

	--нужно понять, как правильно указывать главну специальность (trigger on emp_spec?)
	INSERT INTO employee_speciality(employee_speciality_id, employee_id, speciality_id, is_main_spec, hire_date)
	SELECT @new_id, t.emp_id, t.spec_id, 0, GETDATE() FROM 
	(SELECT employee_id as emp_id, speciality_id as spec_id FROM 
	inserted WHERE employee_id IS NOT NULL) AS t
GO

GO
CREATE TRIGGER tr_ins_employee_speciality
ON employee_speciality AFTER INSERT
AS
BEGIN
	-- если сотрудник появился в таблице впервые, то пусть его первая должность будет основной,
	-- последующие будут по совместительству
	DECLARE @spec_num as integer;

	-- (SELECT employee_id FROM inserted)  может ли давать несколько значений?

	SELECT @spec_num = COUNT(*) FROM 
		employee_speciality WHERE employee_id =
			(SELECT employee_id FROM inserted);
	IF @spec_num = 1 
		UPDATE employee_speciality
		SET is_main_spec = 1
		WHERE employee_id = (SELECT employee_id FROM inserted);
END;
GO

GO
CREATE TRIGGER tr_del_employee_speciality
ON employee_speciality AFTER DELETE
AS
BEGIN
	INSERT INTO work_log(emp_id, spec_id, days_of_work)
	SELECT 
		employee_id, 
		speciality_id,
		DATEDIFF(DAY, hire_date, GETDATE())
	FROM deleted


	-- если удалили главную должность сотрудника, то сделать главной должностью одну из по-совместительству
	--как быть если удалили больше одной строки?
	--пройти все строки по одной с помощью курсора?

	DECLARE @emp_id integer, @is_main_spec integer;

	DECLARE my_cursor CURSOR
	FOR SELECT employee_id, is_main_spec
	FROM deleted;

	OPEN my_cursor;

	FETCH NEXT FROM my_cursor INTO @emp_id, @is_main_spec;

	WHILE @@FETCH_STATUS=0
	begin
		IF @is_main_spec = 1
		begin
			DECLARE @spec_num as integer;
			SELECT @spec_num = COUNT(speciality_id) FROM 
			employee_speciality WHERE employee_id = @emp_id;

			IF @spec_num >= 1
			begin
				--значит изначально у сотрудника было хотя бы 2 должности, значит была по-совместительству
				UPDATE employee_speciality
				SET is_main_spec = 1
				FROM (SELECT TOP 1 * FROM employee_speciality WHERE employee_id = @emp_id) as selected
				WHERE employee_speciality.employee_speciality_id = selected.employee_speciality_id;	
			end
		end

		FETCH NEXT FROM my_cursor INTO @emp_id, @is_main_spec;
	end;

	CLOSE my_cursor;
	DEALLOCATE my_cursor;
END;
GO



-- ВЫЗОВЫ ПРОЦЕДУР
GO
EXEC add_course 'Основы финансовой грамотности';
EXEC add_course 'Технический английский язык';
EXEC add_course 'Лекции по MS SQL SERVER';
EXEC add_course 'Теория веротяностей для чайников';
EXEC add_course 'Deadline или как успеть то, что нужно было закончить вчера';
EXEC add_course 'Time managment для всех';

EXEC add_speciality @name='Тестировщик UI', @salary=45000;
EXEC add_speciality @name='Python разработчик', @salary=60000;
EXEC add_speciality @name='Специалист по ПЛИС', @salary=55000;
EXEC add_speciality @name='Начальник отдела программирования', @salary=95000;
EXEC add_speciality @name='менеджер', @salary=60000;
EXEC add_speciality @name='Руководитель отдела кадров', @salary=75000;
EXEC add_speciality @name='Специалсит отдела кадров', @salary=50000;
EXEC add_speciality @name='Специалист по тестировнию', @salary=80000;

EXEC add_employee @full_name='Фаст Никита', @education='Программная инженерия СПБГУ';
EXEC add_employee @full_name='Кривоногов Александр', @education='ЛЭТИ';
EXEC add_employee @full_name='Абрамова Дарья', @education='ПетрГУ';
EXEC add_employee @full_name='Мармеладова Соня', @education='ИТМО';
EXEC add_employee @full_name='Прохоров Генадий', @education='МТУСИ';
EXEC add_employee @full_name='Тереньтьев Александр', @education='ГПТУ';
EXEC add_employee @full_name='Петренко Сергей', @education='МАИ';
EXEC add_employee @full_name='Кочерыгина Евгения', @education='МГУ';

EXEC add_passed_course 1, 1, '2022-12-19';
EXEC add_passed_course 1, 3, '2022-12-01';
EXEC add_passed_course 1, 5, '2021-05-12';

EXEC add_passed_course 2, 1, '2017-01-29';
EXEC add_passed_course 2, 2, '2020-11-23';
EXEC add_passed_course 2, 6, '2016-03-13';

EXEC add_passed_course 3, 5, '2021-05-12';

EXEC add_passed_course 6, 4, '2015-08-09';

EXEC add_passed_course 7, 3, '2012-08-19';
EXEC add_passed_course 7, 4, '2015-08-09';

DECLARE @t1 department_description;
INSERT INTO @t1 VALUES(4, 1);
INSERT INTO @t1 VALUES(5, 1);
INSERT INTO @t1 VALUES(2, 2);
INSERT INTO @t1 VALUES(3, 3);
EXEC add_department 'отдел программирования', @t1;

DECLARE @t2 department_description;
INSERT INTO @t2 VALUES(6, 1);
INSERT INTO @t2 VALUES(7, 2);
EXEC add_department 'отдел кадров', @t2;

DECLARE @t3 department_description;
INSERT INTO @t3 VALUES(8, 2);
INSERT INTO @t3 VALUES(1, 1);
EXEC add_department 'отдел тестирования', @t3;

-- заполняем трудовую историю сотрудников
INSERT INTO work_log(emp_id, spec_id, days_of_work)
VALUES 
(1, 1, 60),
(2, 2, 1350),
(2, 4, 590),
(2, 8, 700),
(3, 1, 250),
(4, 7, 900),
(5, 5, 300),
(5, 2, 300),
(6, 3, 220),
(7, 1, 1200),
(7, 8, 2600),
(8, 7, 540),
(8, 6, 1350)

EXEC assign_work_to_emp @dep_id=1, @spec_id=4, @emp_id=2;
EXEC assign_work_to_emp			1,			5,		   2;
EXEC assign_work_to_emp			1,			3,		   2;
EXEC assign_work_to_emp			1,			2,		   1;
EXEC assign_work_to_emp			1,			3,		   3;
EXEC assign_work_to_emp			1,			2,		   3;
EXEC assign_work_to_emp			2,			7,		   8;
EXEC assign_work_to_emp			3,			8,		   4;
EXEC assign_work_to_emp			3,			8,		   5;
EXEC assign_work_to_emp			3,			7,		   6;


--EXEC fire_employee @emp_id = 4;

GO

--#1 ПОЛУЧИТЬ СТАЖ ВСЕХ СОТРУДНИКОВ В ДНЯХ
-- GETDATE() заменить на CAST('2022-12-31' as DATE) для быстрого теста

SELECT t1.employee_id, t1.days + t2.days as work_expirience_in_days
FROM 
(
	SELECT e.employee_id, SUM(ISNULL(days_of_work, 0)) as days FROM work_log
	RIGHT JOIN employee as e ON e.employee_id=work_log.emp_id
	GROUP BY e.employee_id
) as t1 
JOIN 
(
	SELECT e.employee_id, SUM( ISNULL( DATEDIFF(DAY, es.hire_date, CAST('2022-12-31' as DATE)) , 0) ) as days 
	FROM employee_speciality as es
	RIGHT JOIN employee as e ON e.employee_id=es.employee_id
	GROUP BY e.employee_id
) as t2 
ON t1.employee_id=t2.employee_id
;

----### ПРЕДЫДЩУИЙ ЗАПРОС СОСТОИТ ИЗ СЛЕДЮУЩИХ ДВУХ
---- ДЛЯ КАЖДОГО СТРУДНИКА ПОЛУЧИТЬ ЕГО СТАЖ НА ПРОШЛЫХ ДОЛЖНОСТЯХ
--SELECT e.employee_id, SUM(ISNULL(days_of_work, 0)) as days FROM work_log
--RIGHT JOIN employee as e ON e.employee_id=work_log.emp_id
--GROUP BY e.employee_id
--;

---- ДЛЯ КАЖДОГО СТРУДНИКА ПОЛУЧИТЬ ЕГО СТАЖ НА ТЕКУЩИХ ДОЛЖНОСТЯХ
--SELECT 
--e.employee_id, 
--SUM( ISNULL( DATEDIFF(DAY, es.hire_date, CAST('2022-12-31' as DATE)) , 0) ) as days 
--FROM employee_speciality as es
--RIGHT JOIN employee as e ON e.employee_id=es.employee_id
--GROUP BY e.employee_id
--;

--#2 НАЙТИ НАИМЕНЕЕ ЗАНЯТЫХ СОТРУДНИКОВ
	SELECT 
		e.employee_id, 
		e.full_name, 
		SUM(case when es.speciality_id is null then 0 else 1 end) as cnt
	FROM employee_speciality as es
	RIGHT JOIN employee as e ON e.employee_id = es.employee_id
	GROUP BY e.employee_id, e.full_name
	HAVING SUM(case when es.speciality_id is null then 0 else 1 end) = 0
	ORDER BY employee_id
	;

--#3 ЧИСЛО КУРСОВ ПРОЙДЕННЫХ СОТРУДНИКАМИ ЗА ПОСЛЕДНИЕ 36 МЕСЯЦЕВ
SELECT e.full_name, COUNT(*) as courses_passed FROM emp_course as ec
JOIN employee as e ON ec.employee_id = e.employee_id
WHERE DATEDIFF(MONTH, ec.pass_date, GETDATE()) < 36
GROUP BY e.full_name
ORDER BY courses_passed
;

--#4 ПОДСЧИТАТЬ ЗАРПЛАТУ ВСЕХ СОТРУДНИКОВ

-------(ЗАПРОСЫ)----------
-- ПОЛУЧИТЬ ПЕРЕЧЕНЬ СОТРУДНИКОВ ОТДЕЛА 
--SELECT DISTINCT d.name, e.full_name FROM 
--timetable as t 
--JOIN department as d ON d.department_id = t.department_id
--JOIN employee as e ON e.employee_id = t.employee_id
--;

---- ПОЛУЧИТЬ ЗАНИМАЕМЫЕ СОТРУДНИКОМ ДОЛЖНОСТИ
--SELECT e.full_name, s.name FROM
--timetable as t
--JOIN employee as e ON e.employee_id = t.employee_id
--JOIN speciality as s ON s.speciality_id = t.speciality_id
--ORDER BY e.full_name
--;

---- основная специальность сотрудников
--SELECT e.full_name, s.name FROM 
--timetable as t
--JOIN employee as e ON e.employee_id = t.employee_id
--JOIN speciality as s ON e.main_speciality = s.speciality_id
--ORDER BY e.full_name, s.name
--;


---- количество сотрудников на каждой должности в каждом отделе
--SELECT d.department_id, d.name as dep_name, s.name as spec_name, COUNT(t.employee_id) as emp_num FROM 
--timetable as t
--JOIN department as d ON d.department_id = t.department_id
--JOIN speciality as s ON s.speciality_id = t.speciality_id
--GROUP BY d.department_id, d.name, s.name
--ORDER BY d.department_id, spec_name
--;

--GO
--CREATE FUNCTION get_emp_num()
--RETURNS TABLE
--AS
--RETURN(
--	SELECT d.department_id, d.name as dep_name, s.name as spec_name, COUNT(t.employee_id) as emp_num FROM 
--	timetable as t
--	JOIN department as d ON d.department_id = t.department_id
--	JOIN speciality as s ON s.speciality_id = t.speciality_id
--	GROUP BY d.department_id, d.name, s.name
--)
--;
--GO


---- требуемое количество сотрудников на каждой должности в каждом отделе
--SELECT d.department_id, d.name as dep_name, s.name as spec_name, COUNT(*) as required_emp_num FROM 
--timetable as t
--JOIN department as d ON d.department_id = t.department_id
--JOIN speciality as s ON s.speciality_id = t.speciality_id
--GROUP BY d.department_id, d.name, s.name
--ORDER BY d.department_id, spec_name
--;

--GO
--CREATE FUNCTION get_req_emp_num()
--RETURNS TABLE
--AS
--RETURN(
--	SELECT d.department_id, d.name as dep_name, s.name as spec_name, COUNT(*) as req_emp_num FROM 
--	timetable as t
--	JOIN department as d ON d.department_id = t.department_id
--	JOIN speciality as s ON s.speciality_id = t.speciality_id
--	GROUP BY d.department_id, d.name, s.name
--)
--;
--GO


---- ПОЛУЧИТЬ КОЛИЧЕСТВО ВАКАНТНЫХ МЕСТ
--SELECT	a.department_id as dep_id, 
--		a.dep_name, 
--		a.spec_name, 
--		a.req_emp_num - b.emp_num as vakant 
--FROM 
--get_req_emp_num() as a 
--JOIN get_emp_num() as b ON 
--a.department_id=b.department_id and a.spec_name=b.spec_name
--;

--DROP TABLE work_log;
--DROP TABLE employee_speciality;
--DROP TABLE emp_course;
--DROP TABLE course;
--DROP TABLE timetable;
--DROP TABLE employee;
--DROP TABLE speciality;
--DROP TABLE department;

--DROP VIEW v_emp_course;
--DROP VIEW v_employee_speciality;
--DROP VIEW v_timetable;
--DROP VIEW v_work_log;

--DROP PROCEDURE add_course;
--DROP PROCEDURE add_department;
--DROP PROCEDURE add_employee;
--DROP PROCEDURE add_passed_course;
--DROP PROCEDURE add_position_to_timetable;
--DROP PROCEDURE add_speciality;
--DROP PROCEDURE assign_work_to_emp;
--DROP PROCEDURE fire_employee;

--DROP TYPE department_description;

--DROP TRIGGER tr_del_emp_course;
--DROP TRIGGER tr_ins_upd_timetable;
--DROP TRIGGER tr_ins_employee_speciality;
--DROP TRIGGER tr_del_employee_speciality;

