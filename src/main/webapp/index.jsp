<%@ page import="com.ppm.custom.war.config.PpmConfig" %>
<%@ page import="java.sql.*" %>


    <html>
   <body>
        <h2>Welcome to the Sample PPM Custom WAR.</h2>
        <p>This file demonstrates the different ways to access PPM Data from your custom war. Check the source code here: <a href="https://github.com/MicroFocus/ppm-sample-custom-war/blob/main/src/main/webapp/index.jsp">ppm-sample-custom-war/src/main/webapp/index.jsp</a></p>
        <h3> Client side REST Calls </h3>
        <p>The code in a sample Custom WAR runs on the same Tomcat as PPM, and its Client-side code can make REST Calls
        to PPM REST API with the session of the logged in user.</p>
        <p>For example, the following information is retrieved from URL /itg/web/new/user-profile.jsp:</p>
        <p><ul>
                <li>Username: <span id='username-field'></span></li>
                <li>User ID: <span id='user-id-field'></span></li>
                <li>Full Name: <span id='full-name-field'></span></li>
                <li>Locale: <span id='locale-field'></span></li>
        </ul></p>
        <script>
                // Demo basic JS code to make calls to PPM Server from the browser. If user is already in PPM, no authentication is required.
                let xmlhttp = new XMLHttpRequest();

                xmlhttp.onreadystatechange = function() {
                        if (xmlhttp.readyState == XMLHttpRequest.DONE) {   // XMLHttpRequest.DONE == 4
                                if (xmlhttp.status == 200) {
                                        let userInfo = JSON.parse(xmlhttp.responseText);
                                        document.getElementById('username-field').textContent = userInfo.username;
                                        document.getElementById('user-id-field').textContent = userInfo.userId;
                                        document.getElementById('full-name-field').textContent = userInfo.fullName;
                                        document.getElementById('locale-field').textContent = userInfo.locale;
                                }
                        }
                };

                xmlhttp.open("GET", "/itg/web/new/user-profile.jsp", true);
                xmlhttp.send();
        </script>

        <h3>Querying PPM Database</h3>
    <p>The JNDI Datasources for PPM Database and (if configured) Reporting Database are available to your custom WAR. The corresponding JNDI names are provided in customWars.properties, that can be easily accessed through class <a href="https://github.com/MicroFocus/ppm-sample-custom-war/blob/main/src/main/java/com/ppm/custom/war/config/PpmConfig.java">PpmConfig</a>.</p>

        <%
        // We must pass the ServletContext to the constructor of PpmConfig to let it retrieve values from customWars.properties.
        PpmConfig ppmConfig = new PpmConfig(getServletContext());
        %>

        <p>Feel free to build your own version of the PpmConfig class, but you should always leverage the configuration provided in customWars.properties when possible instead of hard-coding configuration values.</p>
        <p>The code below will run a SQL query against PPM to retrieve the number of users (enabled or not).</p>

         <%
            // We intentionally omit the whole JDBC error handling for the sake of clarity - don't do this in production code!
            Connection con = ppmConfig.getPpmDbConnection();
            Statement stmt = con.createStatement();
            stmt.executeQuery("SELECT count(*) FROM knta_users");
            ResultSet rs = stmt.getResultSet();
            rs.next();
            long enabledUsersCount = rs.getLong(1);
            rs.close();
            stmt.close();

            // Always close connections when you get them though PpmConfig.
            con.close();
        %>
        <p>There are <%= enabledUsersCount %> users in PPM.</p>

        <p>Even if the Datasource lets you run any type of query against PPM Database, you should refrain from updating data directly in database. All data-modifying operations should be performed through REST APIs when available.</p>

        <h3>Check if a call to the custom WAR is made with a valid PPM session</h3>
        <p>Any call made by the UI to <BASE_URL>/itg/rest2/customWars/your_war_name/* will be forwarded automatically to <BASE_URL>/your_war_name/* , but with an extra JWT token added that contains info of the PPM user currently logged in. </p>
        <p>You can then verify this JWT signature against the public key included in customWars.properties in property security.oauth2.resource.jwt.key-value.</p>
        <p>This can be a simple way to ensure that all calls made against your custom wars are done from valid PPM users - useful if you want to leverage PPM authentication mechanism instead of building your own.</p>
        <p>You can try this on the custom WAR by making a call to PPM_BASE_URL/itg/rest2/customWars/ppm-sample-custom-war/ppmJWTVerificationServlet/ . Source code of this servlet is <a href="">here</a>.
        <p></p>
        <h3>Server-side REST Calls</h3>
        <p>In order to do a server-side REST API call to PPM, you will need to authenticate. If the custom Web App is access by a user from a browser with an existing PPM session, you can retrieve the PPM internal JWT Token in order to make a server-side call authenticated as the same user.</p>


        <p>You can also use standard authentication - it's advised to use API Keys in order to be able to authenticate even when users use SSO. </p>

   </body>
</html>
