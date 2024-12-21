
import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

  // Set this to e.g. "portal" if you have created a database named portal
  // Leave it blank to use the default database of your database user
  static final String DBNAME = "postgres";
  // For connecting to the portal database on your local machine
  static final String DATABASE = "jdbc:postgresql://localhost/" + DBNAME;
  static final String USERNAME = "postgres";
  static final String PASSWORD = "Aalborg2020!";

  // This is the JDBC connection object you will be using in your methods.
  private Connection conn;

  public PortalConnection() throws SQLException, ClassNotFoundException {
    this(DATABASE, USERNAME, PASSWORD);
  }

  // Initializes the connection, no need to change anything here
  public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
    Class.forName("org.postgresql.Driver");
    Properties props = new Properties();
    props.setProperty("user", user);
    props.setProperty("password", pwd);
    conn = DriverManager.getConnection(db, props);
  }

  // Register a student on a course, returns a tiny JSON document (as a String)
  public String register(String student, String courseCode) {
    // SQL to insert a new record
    String insertSQL = "INSERT INTO Registrations (student, course) VALUES (?, ?)";

    try (PreparedStatement preparedStatement = conn.prepareStatement(insertSQL)) {
      // Bind parameters
      preparedStatement.setString(1, student);
      preparedStatement.setString(2, courseCode);

      // Execute the insert
      preparedStatement.executeUpdate();
      return "{\"success\":true}";
    } catch (SQLException e) {
      // Handle SQL exceptions gracefully
      return "{\"success\":false, \"error\":\"" + getError(e) + "\"}";
    }
  }

  // Unregister a student from a course, returns a tiny JSON document (as a
  // String)
  public String unregister(String student, String courseCode) {
    // Deliberately vulnerable SQL with string concatenation
    String deleteSQL = "DELETE FROM Registrations WHERE student = '" + student + "' AND course = '" + courseCode + "'";

    try (Statement statement = conn.createStatement()) {
      // Execute the delete operation
      int affectedRows = statement.executeUpdate(deleteSQL);
      if (affectedRows == 0) {
        // No rows were deleted, meaning the registration was not found
        return "{\"success\":false, \"message\":\"Student is not registered for this course.\"}";
      } else {
        // Successful deletion
        return "{\"success\":true}";
      }
    } catch (SQLException e) {
      // Handle SQL exceptions gracefully
      return "{\"success\":false, \"error\":\"" + getError(e) + "\"}";
    }
  }

  // Return a JSON document containing lots of information about a student, it
  // should validate against the schema found in information_schema.json
  public String getCourseInfo(String course) throws SQLException {
    try (PreparedStatement st = conn.prepareStatement(
        "SELECT json_build_object(\n" + //
            "    'course', r.course,\n" + //
            "    'registered', json_agg(\n" + //
            "        CASE\n" + //
            "            WHEN r.status = 'registered' THEN json_build_object('student', r.student)\n" + //
            "            ELSE NULL\n" + //
            "        END\n" + //
            "    ) FILTER (WHERE r.status = 'registered'),\n" + //
            "    'waitingList', json_agg(\n" + //
            "        CASE\n" + //
            "            WHEN r.status = 'waiting' THEN json_build_object('student', r.student)\n" + //
            "            ELSE NULL\n" + //
            "        END\n" + //
            "    ) FILTER (WHERE r.status = 'waiting')\n" + //
            ")\n" + //
            "FROM registrations r\n" + //
            "WHERE r.course = ?\n" + //
            "GROUP BY r.course;"
    );) {

      st.setString(1, course);

      ResultSet rs = st.executeQuery();

      if (rs.next())
        return rs.getString(1);
      else
        return "{\"course\":\"does not exist :(\"}";

    }
  }

  // Return a JSON document containing lots of information about a student, it
  // should validate against the schema found in information_schema.json
  public String getInfo(String student) throws SQLException {

    try (PreparedStatement st = conn.prepareStatement(

        "SELECT json_build_object(\n" + //
            "    'student', s.idnr,\n" + //
            "    'name', s.name,\n" + //
            "    'login', s.login,\n" + //
            "    'program', p.programName,\n" + //
            "    'branch', coalesce(sb.branch, null),\n" + //
            "    'finished', (\n" + //
            "        SELECT json_agg(json_build_object(\n" + //
            "            'course', c.name,\n" + //
            "            'code', c.code,\n" + //
            "            'credits', c.credits,\n" + //
            "            'grade', fc.grade\n" + //
            "        ))\n" + //
            "        FROM finishedCourses fc\n" + //
            "        JOIN courses c ON fc.course = c.code\n" + //
            "        WHERE fc.student = s.idnr AND fc.grade IS NOT NULL\n" + //
            "    ),\n" + //
            "    'registered', (\n" + //
            "        SELECT json_agg(json_build_object(\n" + //
            "            'course', rc.name,\n" + //
            "            'code', rc.code,\n" + //
            "            'status', r.status,\n" + //
            "            'position',\n" + //
            "                CASE\n" + //
            "                    WHEN r.status = 'registered' THEN NULL  -- No position for registered students\n" + //
            "                    ELSE w.position  -- Position from waitingList for waiting students\n" + //
            "                END\n" + //
            "        ))\n" + //
            "        FROM registrations r\n" + //
            "        JOIN courses rc ON r.course = rc.code\n" + //
            "        LEFT JOIN waitingList w ON r.student = w.student\n" + //
            "        WHERE r.student = s.idnr\n" + //
            "    ),\n" + //
            "    'seminarCourses', coalesce(sc.seminarCourses, 0),\n" + //
            "    'mathCredits', coalesce(mc.mathCredits, 0),\n" + //
            "    'totalCredits', coalesce(tc.totalCredits, 0),\n" + //
            "    'canGraduate', pg.qualified\n" + //
            ")\n" + //
            "FROM students s\n" + //
            "JOIN programs p ON s.program = p.programName\n" + //
            "LEFT JOIN seminarCourses sc ON s.idnr = sc.student\n" + //
            "LEFT JOIN mathCredits mc ON s.idnr = mc.student\n" + //
            "LEFT JOIN totalCredits tc ON s.idnr = tc.student\n" + //
            "LEFT JOIN pathtograduation pg ON s.idnr = pg.student\n" + //
            "LEFT JOIN studentBranches sb ON s.idnr = sb.student\n" + //
            "WHERE s.idnr = ?;");) {

      st.setString(1, student);

      ResultSet rs = st.executeQuery();

      if (rs.next())
        return rs.getString(1);
      else
        return "{\"student\":\"does not exist :(\"}";

    }
  }

  // This is a hack to turn an SQLException into a JSON string error message. No
  // need to change.
  public static String getError(SQLException e) {
    String message = e.getMessage();
    int ix = message.indexOf('\n');
    if (ix > 0)
      message = message.substring(0, ix);
    message = message.replace("\"", "\\\"");
    return message;
  }
}