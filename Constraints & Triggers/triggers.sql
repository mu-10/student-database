CREATE OR REPLACE FUNCTION handle_student_reg()
RETURNS TRIGGER AS $$
DECLARE
    reg_students INT;
    course_capacity INT;
    current_position INT;
    unmet_pre INT;
BEGIN
    -- If the student already passed the given course, RAISE EXCEPTION
    IF EXISTS(
        SELECT 1 FROM taken WHERE student = NEW.student AND course = NEW.course AND grade IN ('3', '4', '5')
    ) THEN
        RAISE EXCEPTION 'Student % has already passed course %', NEW.student, NEW.course;
    END IF;

    -- If the student already is registered on the given course, RAISE EXCEPTION
    IF EXISTS(
        SELECT 1 FROM registered WHERE student = NEW.student AND course = NEW.course
    ) OR EXISTS(
        SELECT 1 FROM waitingList WHERE student = NEW.student AND course = NEW.course
    ) THEN
        RAISE EXCEPTION 'Student % is already registered or in the waiting-list for course %!', NEW.student, NEW.course;
    END IF;

    -- Check unmet prerequisites
    SELECT COUNT(*) INTO unmet_pre
    FROM requirements p
    LEFT JOIN taken t
    ON p.requires = t.course AND t.student = NEW.student
    WHERE p.course = NEW.course AND (t.grade IS NULL OR t.grade = 'U');
    IF unmet_pre > 0 THEN
        RAISE EXCEPTION 'Student % does not meet all the prerequisites for course %!', NEW.student, NEW.course;
    END IF;

    -- Lock course capacity row for update
    SELECT capacity INTO course_capacity FROM limitedCourses WHERE code = NEW.course FOR UPDATE;

    -- Number of students registered on the given course
    SELECT COUNT(*) INTO reg_students FROM registered WHERE course = NEW.course;

    -- Check if the course is full
    IF reg_students >= course_capacity THEN
        -- Get current position of the last in queue
        SELECT COALESCE(MAX(position), 0) INTO current_position FROM waitingList WHERE course = NEW.course;
        INSERT INTO waitingList (student, course, position) VALUES (NEW.student, NEW.course, current_position + 1);
    ELSE
        -- If not full, register the student
        INSERT INTO registered (student, course) VALUES (NEW.student, NEW.course);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_register_trigger
INSTEAD OF INSERT ON Registrations
FOR EACH ROW EXECUTE FUNCTION handle_student_reg();


CREATE OR REPLACE FUNCTION handle_student_unreg()
RETURNS TRIGGER AS $$
DECLARE
    reg_students INT;
    course_capacity INT;
    next_student CHAR(10); -- To store the student ID from the waiting list
    old_position INT; -- To store the position of the student in the waiting list
BEGIN
    -- If the student is in the Registered table, delete the record
    IF EXISTS(
        SELECT 1 FROM Registered
        WHERE student = OLD.student AND course = OLD.course
    ) THEN
        DELETE FROM Registered
        WHERE student = OLD.student AND course = OLD.course;

        -- Check the current capacity and registered count
        SELECT capacity INTO course_capacity FROM limitedCourses WHERE code = OLD.course FOR UPDATE;
        SELECT COUNT(*) INTO reg_students FROM Registered WHERE course = OLD.course;

        -- If space is available, move the first student in the waiting list to Registered
        IF reg_students < course_capacity THEN
            SELECT student INTO next_student
            FROM WaitingList
            WHERE course = OLD.course
            ORDER BY position ASC
            LIMIT 1;

            IF next_student IS NOT NULL THEN
                -- Remove the student from the waiting list
                DELETE FROM WaitingList
                WHERE student = next_student AND course = OLD.course;

                -- Register the student
                INSERT INTO Registered (student, course) VALUES (next_student, OLD.course);

                -- Adjust positions in the waiting list
                UPDATE WaitingList
                SET position = position - 1
                WHERE course = OLD.course
                AND position > 1;
            END IF;
        END IF;

    -- If the student is in the WaitingList table, delete the record
    ELSIF EXISTS(
        SELECT 1 FROM WaitingList
        WHERE student = OLD.student AND course = OLD.course
    ) THEN
        -- Retrieve the position of the student being removed
        SELECT position INTO old_position
        FROM WaitingList
        WHERE student = OLD.student AND course = OLD.course;

        DELETE FROM WaitingList
        WHERE student = OLD.student AND course = OLD.course;

        -- Update positions for rows in the same course after the deleted position
        UPDATE WaitingList
        SET position = position - 1
        WHERE course = OLD.course
        AND position > old_position;

    ELSE
        RAISE EXCEPTION 'Student is neither registered nor in the waitingList for the given course';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_unregistration_trigger
INSTEAD OF DELETE ON Registrations
FOR EACH ROW
EXECUTE FUNCTION handle_student_unreg();