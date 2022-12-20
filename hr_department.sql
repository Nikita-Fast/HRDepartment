--2) может ли несколько сотрудников в одном отделе иметь одинаковую должность? Ответ: да. В отделе м.б. 4 программиста-разработчика.
--3) должность VS позиция в штатном расписании:
--    - у нескольких сотрудников может быть одинаковая должность(speciality)
--    - позиция в штатном рапсисании может быть занята максимум одним сотрудником

CREATE DATABASE hr_department;
GO

USE hr_department

-- Создаем таблицы
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
);

-- Добавляем внешние ключи
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

-- Данные теперь неактуальны
---- создаем отделы
--insert into department(department_id, name) values (1, 'дирекция');
--insert into department(department_id, name) values (2, 'отдел программирования');
--insert into department(department_id, name) values (3, 'отдел кадров');
--insert into department(department_id, name) values (4, 'аналитический отдел');

----создаем должности
--insert into speciality(speciality_id, name) values (1, 'начальник отдела программирования');
--insert into speciality(speciality_id, name) values (2, 'C-программист');
--insert into speciality(speciality_id, name) values (3, 'Python-программист');
--insert into speciality(speciality_id, name) values (4, 'тестировщик');

--insert into speciality(speciality_id, name) values (5, 'гендиректор');

--insert into speciality(speciality_id, name) values (6, 'Начальник отдела кадров');
--insert into speciality(speciality_id, name) values (7, 'Менеджер по персоналу');
--insert into speciality(speciality_id, name) values (8, 'Рекрутер');
--insert into speciality(speciality_id, name) values (9, 'Специалист по кадровому делопроизводству'); 

--insert into speciality(speciality_id, name) values (10, 'Ведущий специалист аналитического отдела');
--insert into speciality(speciality_id, name) values (11, 'Специалист аналитического отдела');


---- добавляем в базу сотрудников
--insert into employee(employee_id, name) values (1, 'Александр Кривоногов');
--insert into employee(employee_id, name) values (2, 'Алексей Наумов');
--insert into employee(employee_id, name) values (3, 'Александр Карпов');
--insert into employee(employee_id, name) values (4, 'Андрей Ромель');
--insert into employee(employee_id, name) values (5, 'Анастасия Петрова');
--insert into employee(employee_id, name) values (6, 'Елена Пупкова');
--insert into employee(employee_id, name) values (7, 'Зоя Кондратьева');
--insert into employee(employee_id, name) values (8, 'Владимир Басов');
--insert into employee(employee_id, name) values (9, 'Илья Попов');
--insert into employee(employee_id, name) values (10, 'Виктория Соколова');

---- добавляем в базу курсы
--insert into course(course_id, name) values (1, 'Python для опытных');
--insert into course(course_id, name) values (2, 'Английский язык для делового общения');
--insert into course(course_id, name) values (3, 'Программирование микро-контроллеров на C');
--insert into course(course_id, name) values (4, 'Time managment для начинающих');
--insert into course(course_id, name) values (5, 'Управление персоналом');
--insert into course(course_id, name) values (6, 'Секреты и хитрости MS Office');
--insert into course(course_id, name) values (7, 'Основы финансовой грамотности');

---- вносим информацию о том какие курсы прошли сотрудники
--insert into emp_course(employee_id, course_id, date) values (1, 5, '2019-01-14');
--insert into emp_course(employee_id, course_id, date) values (1, 2, '2020-01-14');
--insert into emp_course(employee_id, course_id, date) values (2, 3, '2019-01-14');
--insert into emp_course(employee_id, course_id, date) values (3, 1, '2021-01-14');

--insert into emp_course(employee_id, course_id, date) values (5, 4, '2019-02-01');
--insert into emp_course(employee_id, course_id, date) values (6, 6, '2019-02-22');

--insert into emp_course(employee_id, course_id, date) values (8, 2, '2020-01-14');
--insert into emp_course(employee_id, course_id, date) values (8, 7, '2007-03-14');

--insert into emp_course(employee_id, course_id, date) values (9, 7, '2022-09-14');


----      заполняем позиции в штатном расписании
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (2, 1, 1);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (2, 2, 1);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (2, 2, 2);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (2, 4, 2);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (2, 2, 3);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (2, 3, null);

--insert into position_in_timetable(department_id, speciality_id, employee_id) values (2, 5, 8);

--insert into position_in_timetable(department_id, speciality_id, employee_id) values (3, 6, 5);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (3, 7, 10);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (3, 8, 5);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (3, 8, 9);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (3, 9, 6);

--insert into position_in_timetable(department_id, speciality_id, employee_id) values (4, 10, null);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (4, 11, 4);
--insert into position_in_timetable(department_id, speciality_id, employee_id) values (4, 11, 7);


-- drop table position_in_timetable;
-- drop table emp_course;
-- drop table employee;
-- drop table course;
-- drop table department;
-- drop table speciality;


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

