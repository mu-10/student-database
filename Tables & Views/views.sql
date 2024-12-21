
CREATE VIEW BasicInformation AS 
    SELECT s.idnr, s.name, s.login, s.program, sb.branch
    FROM Students s
    LEFT JOIN StudentBranches sb
    ON s.idnr = sb.student;

CREATE VIEW FinishedCourses AS
	SELECT t.student, c.code AS course, c.name AS courseName, t.grade, c.credits
    FROM Taken t
    JOIN Courses c ON t.course = c.code;

CREATE view Registrations AS
    SELECT student, course, 'registered' AS status
    FROM Registered

    UNION ALL

    SELECT student, course, 'waiting' AS status
    FROM WaitingList;

CREATE VIEW PassedCourses AS 
SELECT student, course, courseName, credits FROM FinishedCourses
WHERE grade !='U';

CREATE VIEW UnreadMandatory AS
SELECT Students.idnr AS student, MandatoryProgram.course
FROM Students
JOIN MandatoryProgram ON Students.program = MandatoryProgram.program
LEFT JOIN PassedCourses ON Students.idnr = PassedCourses.student AND MandatoryProgram.course = PassedCourses.course
WHERE PassedCourses.course IS NULL

UNION

SELECT sb.student, mb.course
FROM StudentBranches sb
JOIN MandatoryBranch mb ON sb.branch = mb.branch AND sb.program = mb.program
LEFT JOIN PassedCourses pc ON pc.student = sb.student AND mb.course = pc.course
WHERE pc.courseName IS NULL;


CREATE VIEW TotalCredits AS
SELECT student, SUM(credits) AS totalCredits
FROM PassedCourses
GROUP BY student;


CREATE VIEW MandatoryLeft AS
SELECT student, COUNT(course) AS mandatoryLeft
FROM UnreadMandatory
GROUP BY student;



CREATE VIEW MathCredits AS
SELECT pc.student, SUM(c.credits) AS mathCredits
FROM PassedCourses pc
JOIN Classified cl ON pc.course = cl.course
JOIN Courses c ON pc.course = c.code
WHERE cl.classification = 'math'
GROUP BY pc.student;


CREATE VIEW SeminarCourses AS
SELECT pc.student, COUNT(pc.course) AS seminarCourses
FROM PassedCourses pc
JOIN Classified cl ON pc.course = cl.course
WHERE cl.classification = 'seminar'
GROUP BY pc.student;

CREATE VIEW RecommendedCredits AS
SELECT 
    sb.student,
    SUM(c.credits) AS total_recommended_credits
FROM 
    StudentBranches sb
JOIN 
    RecommendedBranch rb 
    ON sb.branch = rb.branch AND sb.program = rb.program
JOIN 
    Taken t 
    ON sb.student = t.student AND rb.course = t.course
JOIN 
    Courses c 
    ON t.course = c.code
GROUP BY 
    sb.student;



CREATE VIEW PathToGraduation AS
SELECT s.idnr AS student, 
       COALESCE(tc.totalCredits, 0) AS totalCredits,
       COALESCE(ml.mandatoryLeft, 0) AS mandatoryLeft,
       COALESCE(mc.mathCredits, 0) AS mathCredits,
       COALESCE(sc.seminarCourses, 0) AS seminarCourses,
       (
            COALESCE(mc.mathCredits, 0) >= 20 AND 
            COALESCE(ml.mandatoryLeft, 0) = 0 AND 
            COALESCE(sc.seminarCourses, 0) >= 1 AND
            COALESCE(rc.total_recommended_credits, 0) >= 10

        ) AS qualified
FROM Students s
LEFT JOIN TotalCredits tc ON s.idnr = tc.student
LEFT JOIN MandatoryLeft ml ON s.idnr = ml.student
LEFT JOIN MathCredits mc ON s.idnr = mc.student
LEFT JOIN SeminarCourses sc ON s.idnr = sc.student
LEFT JOIN RecommendedCredits rc ON s.idnr = rc.student;