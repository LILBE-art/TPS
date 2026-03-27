-- Question 1 : Afficher la structure de la relation section et son contenu (cours proposes).
DESC section;
SELECT *
FROM section;

-- Question 2 : Afficher tous les renseignements sur les cours que l'on peut programmer (relation course).
SELECT *
FROM course;

-- Question 3 : Afficher les titres des cours et les departements qui les proposent.
SELECT title, dept_name
FROM course;

-- Question 4 : Afficher les noms des departements ainsi que leur budget.
SELECT dept_name, budget
FROM department;

-- Question 5 : Afficher tous les noms des enseignants et leur departement.
SELECT name, dept_name
FROM teacher;

-- Question 6 : Afficher tous les noms des enseignants ayant un salaire superieur strictement a 65.000 $.
SELECT name
FROM teacher
WHERE salary > 65000;

-- Question 7 : Afficher les noms des enseignants ayant un salaire compris entre 55.000 $ et 85.000 $.
SELECT name
FROM teacher
WHERE salary BETWEEN 55000 AND 85000;

-- Question 8 : Afficher les noms des departements, en utilisant la relation teacher et eliminer les doublons.
SELECT DISTINCT dept_name
FROM teacher;

-- Question 9 : Afficher tous les noms des enseignants du departement informatique ayant un salaire superieur strictement a 65.000 $.
SELECT name
FROM teacher
WHERE salary > 65000
  AND dept_name = 'Comp. Sci.';

-- Question 10 : Afficher tous les renseignements sur les cours proposes au printemps 2010 (relation section).
SELECT *
FROM section
WHERE semester = 'Spring'
  AND year = 2010;

-- Question 11 : Afficher tous les titres des cours dispenses par le departement informatique qui ont plus de trois credits.
SELECT title
FROM course
WHERE dept_name = 'Comp. Sci.'
  AND credits > 3;

-- Question 12 : Afficher tous les noms des enseignants ainsi que le nom de leur departement et les noms des batiments qui les hebergent.
SELECT t.name, t.dept_name, d.building
FROM teacher t
JOIN department d ON d.dept_name = t.dept_name;

-- Question 13 : Afficher tous les etudiants ayant suivi au moins un cours en informatique.
SELECT DISTINCT s.name
FROM student s
JOIN takes t ON t.id = s.id
JOIN course c ON c.course_id = t.course_id
WHERE c.dept_name = 'Comp. Sci.';

-- Question 14 : Afficher les noms des etudiants ayant suivi un cours dispense par un enseignant nomme Einstein (eliminer les doublons).
SELECT DISTINCT s.name
FROM student s
JOIN takes t ON t.id = s.id
JOIN teaches te
  ON te.course_id = t.course_id
 AND te.sec_id = t.sec_id
 AND te.semester = t.semester
 AND te.year = t.year
JOIN teacher i ON i.id = te.id
WHERE i.name = 'Einstein';

-- Question 15 : Afficher tous les identifiants des cours et les enseignants qui les ont assures.
SELECT i.name, te.course_id
FROM teacher i
JOIN teaches te ON te.id = i.id;

-- Question 16 : Afficher le nombre d'inscrits pour chaque enseignement propose au printemps 2010.
SELECT t.course_id, t.sec_id, t.semester, t.year, COUNT(*) AS nb_inscrits
FROM takes t
WHERE t.semester = 'Spring'
  AND t.year = 2010
GROUP BY t.course_id, t.sec_id, t.semester, t.year;

-- Question 17 : Afficher les noms des departements et les salaires maximum de leurs enseignants.
SELECT dept_name, MAX(salary) AS salaire_max
FROM teacher
GROUP BY dept_name;

-- Question 18 : Afficher le nombre d'inscrits pour chaque enseignement propose.
SELECT t.course_id, t.sec_id, t.semester, t.year, COUNT(*) AS nb_inscrits
FROM takes t
GROUP BY t.course_id, t.sec_id, t.semester, t.year;

-- Question 19 : Afficher le nombre total de cours qui ont eu lieu dans chaque batiment, pendant l'automne 2009 et le printemps 2010.
SELECT building, COUNT(*) AS nb_cours
FROM section
WHERE (semester = 'Fall' AND year = 2009)
   OR (semester = 'Spring' AND year = 2010)
GROUP BY building;

-- Question 20 : Afficher le nombre total de cours dispenses par chaque departement et qui ont eu lieu dans le meme batiment que ce departement.
SELECT d.dept_name, COUNT(*) AS nb_cours
FROM section s
JOIN teaches te
  ON te.course_id = s.course_id
 AND te.sec_id = s.sec_id
 AND te.semester = s.semester
 AND te.year = s.year
JOIN teacher i ON i.id = te.id
JOIN department d ON d.dept_name = i.dept_name
WHERE d.building = s.building
GROUP BY d.dept_name;

-- Question 21 : Afficher les titres des cours proposes et qui ont eu lieu et les enseignants qui les ont assures.
SELECT c.title, i.name
FROM section s
JOIN teaches te
  ON te.course_id = s.course_id
 AND te.sec_id = s.sec_id
 AND te.semester = s.semester
 AND te.year = s.year
JOIN teacher i ON i.id = te.id
JOIN course c ON c.course_id = s.course_id
ORDER BY c.title;

-- Question 22 : Afficher le nombre total de cours qui ont eu lieu pour chacune des periodes Summer, Fall et Spring.
SELECT s.semester, COUNT(*) AS nb_cours
FROM section s
WHERE s.semester IN ('Summer', 'Fall', 'Spring')
GROUP BY s.semester;

-- Question 23 : Afficher pour chaque etudiant le nombre total de credits qu'il a obtenu, en suivant des cours qui n'ont pas ete proposes par son departement.
SELECT s.name, SUM(c.credits) AS total_credits
FROM student s
JOIN takes t ON t.id = s.id
JOIN course c ON c.course_id = t.course_id
WHERE s.dept_name <> c.dept_name
GROUP BY s.name;

-- Question 24 : Pour chaque departement, afficher le nombre total de credits des cours qui ont eu lieu dans ce departement.
SELECT d.dept_name, SUM(c.credits) AS total_credits
FROM section s
JOIN course c ON c.course_id = s.course_id
JOIN department d ON d.building = s.building
GROUP BY d.dept_name;