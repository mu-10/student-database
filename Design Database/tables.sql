CREATE TABLE Departments(
	departmentName TEXT NOT NULL,
  departmentAbbreviation TEXT NOT NULL,
  PRIMARY KEY (departmentName),
  UNIQUE (departmentAbbreviation)
);

CREATE TABLE Programs(
  programAbbreviation TEXT NOT NULL,
  programName TEXT NOT NULL,
  PRIMARY KEY (programName)
);

CREATE TABLE ProgramIn(
  programName TEXT NOT NULL,
  departmentName TEXT NOT NULL,
  PRIMARY KEY(programName, departmentName),
  FOREIGN KEY(programName) REFERENCES Programs(programName),
  FOREIGN KEY(departmentName) REFERENCES Departments(departmentName)
);

CREATE TABLE Branches(
    name TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (name, program),
  	FOREIGN KEY(program) REFERENCES Programs(programName)
);


CREATE TABLE Students(
    idnr CHAR(10) NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    login TEXT NOT NULL,
    program TEXT NOT NULL,
  	FOREIGN KEY(program) REFERENCES Programs(programName),
    UNIQUE(login)
);

CREATE TABLE Courses(
    code CHAR(6) NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    credits INT NOT NULL CHECK (credits > 0), 
    department TEXT NOT NULL,
  	FOREIGN KEY(department) REFERENCES Departments(departmentName)
);

CREATE TABLE LimitedCourses(
    code CHAR(6) NOT NULL PRIMARY KEY,
    capacity INT NOT NULL CHECK (capacity >= 0),
    FOREIGN KEY (code) REFERENCES Courses(code)
);

CREATE TABLE StudentBranches(
    student CHAR(10) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    FOREIGN KEY (student) REFERENCES Students(idnr),
  	FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
    PRIMARY KEY (student)
);


CREATE TABLE Classifications(
    name TEXT NOT NULL,
  	PRIMARY KEY(name)
);

CREATE TABLE Classified(
    course CHAR(6) NOT NULL,
    classification TEXT NOT NULL,
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (classification) REFERENCES Classifications(name),
    PRIMARY KEY (course, classification)
);

CREATE TABLE MandatoryProgram( 
    course CHAR(6) NOT NULL,
    program TEXT NOT NULL, 
    PRIMARY KEY(course, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
  	FOREIGN KEY (program) REFERENCES Programs(programName)
);

CREATE TABLE MandatoryBranch(
    course CHAR(6) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE RecommendedBranch(
    course CHAR(6) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE Registered(
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code),
    PRIMARY KEY (student, course)  -- Ensuring a student can register for each course only once
);

CREATE TABLE Taken(
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    grade CHAR(1) NOT NULL CHECK (grade IN ('U', '3', '4', '5')),  -- Valid grades only
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code),
    PRIMARY KEY (student, course)  
);

-- position is the absolute position (an integer) 
CREATE TABLE WaitingList(
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    position INT NOT NULL CHECK (position > 0), 
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES LimitedCourses(code),
    PRIMARY KEY (student, course),
    UNIQUE(course,position)
);

CREATE TABLE Requirements(
  course CHAR(6) NOT NULL,
  requires CHAR(6) NOT NULL,
  PRIMARY KEY (course, requires),
  FOREIGN KEY (course) REFERENCES Courses(code),
  FOREIGN KEY (requires) REFERENCES Courses(code) 
);
