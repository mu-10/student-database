# 📚 **University Database Management System**

Welcome to the **University Database Management System**! This project is designed to manage a university's departments, programs, branches, courses, students, and much more. It ensures data integrity and scalability with robust constraints and relationships.

---

## **🚀 Features**

- 📁 Manage departments, programs, and branches.
- 🎓 Enroll students in programs and assign them to branches.
- 📜 Track student registrations, completed courses, and grades.
- 🛑 Handle limited-capacity courses with a waiting list system.
- 📘 Define mandatory and recommended courses for specific programs and branches.
- 🔗 Enforce course prerequisites and validate data with constraints.

---

## **🔍 Schema Overview**

| **Table**            | **Description**                                                                 |
|-----------------------|---------------------------------------------------------------------------------|
| `Departments`         | Represents university departments.                                             |
| `Programs`            | Contains academic program information.                                         |
| `Branches`            | Links programs to their respective branches.                                   |
| `Students`            | Manages student data and their enrolled programs.                              |
| `Courses`             | Defines courses offered by the university.                                     |
| `StudentBranches`     | Ensures students can only select branches within their enrolled program.        |
| `MandatoryProgram`    | Tracks courses mandatory for specific programs.                                |
| `MandatoryBranch`     | Tracks courses mandatory for specific branches.                                |
| `WaitingList`         | Manages students waiting for limited-capacity courses.                         |
| `Requirements`        | Enforces course prerequisites.                                                 |

---

## **👩‍💻 Authors**

This project was created by:
- **[Amir Shojay](https://github.com/amirshojay)**  
- **[Muhammad Usman](https://github.com/mu-10)**  
