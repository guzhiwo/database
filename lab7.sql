-- 1. Добавить внешние ключи. --

ALTER TABLE student ADD CONSTRAINT student_group_id_group_fk
FOREIGN KEY (id_group) REFERENCES `group` (id_group) ON
UPDATE CASCADE ON
DELETE CASCADE;

ALTER TABLE mark ADD CONSTRAINT mark_lesson_id_lesson_fk
FOREIGN KEY (id_lesson) REFERENCES lesson (id_lesson) ON
UPDATE CASCADE ON
DELETE CASCADE,
       ADD CONSTRAINT mark_student_id_student_fk
FOREIGN KEY (id_student) REFERENCES student (id_student) ON
UPDATE CASCADE ON
DELETE CASCADE;

ALTER TABLE lesson ADD CONSTRAINT lesson_teacher_id_teacher_fk
FOREIGN KEY (id_teacher) REFERENCES teacher (id_teacher) ON
UPDATE CASCADE ON
DELETE CASCADE,
       ADD CONSTRAINT lesson_subject_id_subject_fk
FOREIGN KEY (id_subject) REFERENCES subject (id_subject) ON
UPDATE CASCADE ON
DELETE CASCADE,
       ADD CONSTRAINT lesson_group_id_group_fk
FOREIGN KEY (id_group) REFERENCES `group` (id_group) ON
UPDATE CASCADE ON
DELETE CASCADE;


-- 2. Выдать оценки студентов по информатикеесли они обучаются данному предмету. Оформить выдачу данных с использованием view. --

DROP VIEW IF EXISTS computer_science_marks;

CREATE VIEW computer_science_marks AS
SELECT g.name AS `group`,
       s.name AS student,
       m.mark
FROM `group` g
INNER JOIN student s ON g.id_group = s.id_group
INNER JOIN mark m ON s.id_student = m.id_student
INNER JOIN lesson l ON m.id_lesson = l.id_lesson
INNER JOIN subject s2 ON l.id_subject = s2.id_subject
AND s2.name = 'Информатика';

SELECT * FROM computer_science_marks;


/* 3. Дать информацию о должниках с указанием фамилии студента и названия предмета.
    Должниками считаются студенты, не имеющие оценки по предмету, который ведется в группе.
    Оформить в виде процедуры, на входе идентификатор группы. */

DROP PROCEDURE IF EXISTS get_debtor_students;

CREATE PROCEDURE get_debtor_students(IN id_group_of_debtor INT) BEGIN
SELECT DISTINCT s.name AS student, s2.name AS subject
FROM student s
INNER JOIN `group` g ON g.id_group = s.id_group
AND g.id_group = id_group_of_debtor
INNER JOIN lesson l ON l.id_group = g.id_group
INNER JOIN subject s2 ON s2.id_subject = l.id_subject
LEFT JOIN mark m ON m.id_student = s.id_student
AND m.id_lesson = l.id_lesson
WHERE m.id_mark IS NULL; END;

CALL get_debtor_students(1);


-- 4. Дать среднюю оценку студентов по каждому предмету для тех предметов, по которым занимается не менее 35 студентов.

WITH subjects_with_enough_students (id_subject, name) AS
  (SELECT s.id_subject, s.name
   FROM subject s
   INNER JOIN lesson l ON s.id_subject = l.id_subject
   INNER JOIN student st ON l.id_group = st.id_group
   GROUP BY s.id_subject
   HAVING COUNT(DISTINCT st.id_student) >= 35)
SELECT g.name AS `group`,
       st2.name AS student,
       swes.name AS subject,
       AVG(m.mark) AS average_mark
FROM subjects_with_enough_students swes
INNER JOIN lesson l ON l.id_subject = swes.id_subject
INNER JOIN `group` g ON l.id_group = g.id_group
INNER JOIN student st2 ON g.id_group = st2.id_group
INNER JOIN mark m ON l.id_lesson = m.id_lesson
AND m.id_student = st2.id_student
GROUP BY swes.name, st2.name;


/* 5. Дать оценки студентов специальности ВМ по всем проводимым предметам с указанием группы, фамилии, предмета, даты.
    При отсутствии оценки заполнить значениями NULL поля оценки. */

SELECT g.name AS `group`,
       st.name AS student,
       s.name AS subject,
       m.mark,
       l.date
FROM student st
INNER JOIN `group` g ON st.id_group = g.id_group
AND g.name = 'ВМ'
INNER JOIN lesson l ON g.id_group = l.id_group
INNER JOIN subject s ON l.id_subject = s.id_subject
LEFT JOIN mark m ON l.id_lesson = m.id_lesson
AND st.id_student = m.id_student
ORDER BY g.name, st.name;


-- 6. Всем студентам специальности ПС, получившим оценки меньшие 5 по предмету БД до 12.05, повысить эти оценки на 1 балл. 

START TRANSACTION;

UPDATE mark
INNER JOIN lesson l ON mark.id_lesson = l.id_lesson
AND l.date < '2019-05-12'
AND l.id_subject = 1
INNER JOIN student s ON mark.id_student = s.id_student
AND s.id_group = 1
SET mark = mark + 1
WHERE mark < 5;

ROLLBACK;

SELECT *
FROM mark
INNER JOIN lesson l ON mark.id_lesson = l.id_lesson
AND l.date < '2019-05-12'
AND l.id_subject = 1
INNER JOIN student s ON mark.id_student = s.id_student
AND s.id_group = 1
WHERE mark < 5;


-- 7. Добавить необходимые индексы. --

CREATE INDEX subject_name_idx ON subject (name);

CREATE INDEX group_name_idx ON `group` (name);

CREATE INDEX lesson_date_idx ON lesson (date);

CREATE INDEX mark_mark_idx ON mark (mark);