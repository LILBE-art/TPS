--   Q1 : Afficher le nom du departement qui a le budget le plus eleve.
SELECT dept_name
FROM department
WHERE budget IN (
    SELECT MAX(budget)
    FROM department
);

-- Q 2 : Afficher les salaires et les noms des enseignants qui gagnent plus que le salaire moyen.
SELECT a.name, a.salary
FROM teacher a
WHERE a.salary > (
    SELECT AVG(b.salary)
    FROM teacher b
);

-- Q 3 : Pour chaque enseignant, afficher tous les etudiants qui ont suivi plus de deux cours dispenses par cet enseignant, avec HAVING.
SELECT i.name, s.name, COUNT(*) AS total_cours
FROM teacher i
JOIN teaches te ON te.id = i.id
JOIN takes t
  ON t.course_id = te.course_id
 AND t.sec_id = te.sec_id
 AND t.semester = te.semester
 AND t.year = te.year
JOIN student s ON s.id = t.id
GROUP BY i.name, s.name
HAVING COUNT(*) >= 2;

-- Q 4 : Meme demande que la question 3, mais sans utiliser HAVING.
SELECT t1.teachername, t1.studentname, t1.totalcount
FROM (
    SELECT i.name AS teachername, s.name AS studentname, COUNT(*) AS totalcount
    FROM teacher i
    JOIN teaches te ON te.id = i.id
    JOIN takes t
      ON t.course_id = te.course_id
     AND t.sec_id = te.sec_id
     AND t.semester = te.semester
     AND t.year = te.year
    JOIN student s ON s.id = t.id
    GROUP BY i.name, s.name
) t1
WHERE t1.totalcount >= 2
ORDER BY t1.teachername;

-- Q 5 : Afficher les identifiants et les noms des etudiants qui n'ont pas suivi de cours avant 2010.
SELECT s.id, s.name
FROM student s
EXCEPT
SELECT s.id, s.name
FROM student s
JOIN takes t ON t.id = s.id
WHERE t.year < 2010;

-- Q 6 : Afficher tous les enseignants dont les noms commencent par E.
SELECT *
FROM teacher
WHERE name LIKE 'E%';

-- Q 7 : Afficher les salaires et les noms des enseignants qui percoivent le quatrieme salaire le plus eleve.
SELECT t1.name, t1.salary
FROM teacher t1
WHERE 3 = (
    SELECT COUNT(DISTINCT t2.salary)
    FROM teacher t2
    WHERE t2.salary > t1.salary
);

-- Q 8 : Afficher les noms et salaires des trois enseignants ayant les salaires les moins eleves (ordre decroissant).
SELECT t1.name, t1.salary
FROM teacher t1
WHERE 2 >= (
    SELECT COUNT(DISTINCT t2.salary)
    FROM teacher t2
    WHERE t2.salary < t1.salary
)
ORDER BY t1.salary DESC;

-- Q 9 : Afficher les noms des etudiants qui ont suivi un cours en automne 2009, en utilisant IN.
SELECT s.name
FROM student s
WHERE s.id IN (
    SELECT t.id
    FROM takes t
    WHERE t.semester = 'Fall'
      AND t.year = 2009
);

-- Q 10 : Afficher les noms des etudiants qui ont suivi un cours en automne 2009, en utilisant SOME.
SELECT s.name
FROM student s
WHERE s.id = SOME (
    SELECT t.id
    FROM takes t
    WHERE t.semester = 'Fall'
      AND t.year = 2009
);

-- Q 11 : Afficher les noms des etudiants qui ont suivi un cours en automne 2009, avec NATURAL INNER JOIN.
SELECT DISTINCT name
FROM takes NATURAL INNER JOIN student
WHERE takes.semester = 'Fall'
  AND takes.year = 2009;

-- Q 12 : Afficher les noms des etudiants qui ont suivi un cours en automne 2009, en utilisant EXISTS.
SELECT s.name
FROM student s
WHERE EXISTS (
    SELECT 1
    FROM takes t
    WHERE t.id = s.id
      AND t.semester = 'Fall'
      AND t.year = 2009
);

-- Q 13 : Afficher toutes les paires d'etudiants qui ont suivi au moins un cours ensemble.
SELECT s1.name AS etudiant_1, s2.name AS etudiant_2
FROM takes a
JOIN takes b
  ON a.course_id = b.course_id
 AND a.sec_id = b.sec_id
 AND a.semester = b.semester
 AND a.year = b.year
 AND a.id < b.id
JOIN student s1 ON s1.id = a.id
JOIN student s2 ON s2.id = b.id
GROUP BY s1.name, s2.name
HAVING COUNT(*) >= 1;

-- Q 14 :  
SELECT i.name, COUNT(*) AS total_etudiants
FROM takes t
INNER JOIN teaches te
  ON te.course_id = t.course_id
 AND te.sec_id = t.sec_id
 AND te.semester = t.semester
 AND te.year = t.year
INNER JOIN teacher i ON i.id = te.id
GROUP BY i.name, i.id
ORDER BY COUNT(*) DESC;

-- Q 15 :  
SELECT i.name, COUNT(t.id) AS total_etudiants
FROM teacher i
LEFT JOIN teaches te ON te.id = i.id
LEFT JOIN takes t
  ON t.course_id = te.course_id
 AND t.sec_id = te.sec_id
 AND t.semester = te.semester
 AND t.year = te.year
GROUP BY i.name, i.id
ORDER BY COUNT(t.id) DESC;

-- Q 16 : Pour chaque enseignant, afficher le nombre total de grades A qu'il a attribues.
WITH mytakes AS (
    SELECT id, course_id, sec_id, semester, year, grade
    FROM takes
    WHERE grade = 'A'
)
SELECT i.name, COUNT(mt.course_id) AS total_grades_a
FROM teacher i
LEFT JOIN teaches te ON te.id = i.id
LEFT JOIN mytakes mt
  ON mt.course_id = te.course_id
 AND mt.sec_id = te.sec_id
 AND mt.semester = te.semester
 AND mt.year = te.year
GROUP BY i.name, i.id
ORDER BY COUNT(mt.course_id) DESC;

-- Q 17 : Afficher toutes les paires enseignant-eleve ou un eleve a suivi le cours de l'enseignant, ainsi que le nombre de fois.
SELECT i.name, s.name, COUNT(*) AS nb_cours
FROM teacher i
JOIN teaches te ON te.id = i.id
JOIN takes t
  ON t.course_id = te.course_id
 AND t.sec_id = te.sec_id
 AND t.semester = te.semester
 AND t.year = te.year
JOIN student s ON s.id = t.id
GROUP BY i.name, s.name;

-- Q 18 : Afficher les paires enseignant-eleve ou l'eleve a suivi au moins deux cours dispenses par cet enseignant.
SELECT i.name, s.name, COUNT(*) AS nb_cours
FROM teacher i
JOIN teaches te ON te.id = i.id
JOIN takes t
  ON t.course_id = te.course_id
 AND t.sec_id = te.sec_id
 AND t.semester = te.semester
 AND t.year = te.year
JOIN student s ON s.id = t.id
GROUP BY i.name, s.name
HAVING COUNT(*) >= 2;