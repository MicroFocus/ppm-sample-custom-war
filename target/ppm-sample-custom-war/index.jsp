<%@ page import="com.ppm.custom.war.config.PpmConfig" %>
<%@ page import="java.sql.*" %>

<html>
   <body>
      <h2>Welcome to the Sample PPM Custom WAR.</h2>
      <p>This file demonstrates the different ways to access PPM Data from your custom war. Check the source code here: <a href="https://github.com/MicroFocus/ppm-sample-custom-war/blob/main/src/main/webapp/index.jsp">ppm-sample-custom-war/src/main/webapp/index.jsp</a></p>
      <h3> Client side REST Calls </h3>
      <p>The code in a sample Custom WAR runs on the same Tomcat as PPM, and its Client-side code can make REST Calls
         to PPM REST API with the session of the logged in user.
      </p>
      <p>For example, the following information is retrieved from URL /itg/web/new/user-profile.jsp:</p>
      <p>
      <ul>
         <li>Username: <span id='username-field'></span></li>
         <li>User ID: <span id='user-id-field'></span></li>
         <li>Full Name: <span id='full-name-field'></span></li>
         <li>Locale: <span id='locale-field'></span></li>
      </ul>
      </p>
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
      <p>The code below will run a SQL query against PPM database to retrieve the number of users (enabled or not).</p>
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
      <p>Any call made by the UI to PPM_BASE_URL/itg/rest2/customWars/your_war_name/* will be forwarded automatically to PPM_BASE_URL/your_war_name/* , but with an extra JWT token added that contains info of the PPM user currently logged in. </p>
      <p>You can then verify this JWT signature against the public key included in customWars.properties in property security.oauth2.resource.jwt.key-value.</p>
      <p>This can be a simple way to ensure that all calls made against your custom wars are done from valid PPM users - useful if you want to leverage PPM authentication mechanism instead of building your own.</p>
      <p>You can try this on this custom WAR by making a call to PPM_BASE_URL/itg/rest2/customWars/ppm-sample-custom-war/ppmJWTVerificationServlet/ . Source code of this servlet is <a href="https://github.com/MicroFocus/ppm-sample-custom-war/blob/main/src/main/java/com/ppm/custom/war/servlet/PpmJWTVerificationServlet.java">here</a>.</p>
      <p>If you make the call from a Web Browser with a valid PPM Session, you will see some information on the logged in PPM User contained in the JWT (User ID and Username). However, if you make directly the call to PPM_BASE_URL/ppm-sample-custom-war/ppmJWTVerificationServlet/ from a browser without session, you will see an error message. If you try passing a JWT that is not coming from PPM, that will fail too as the JWT is verified using the PPM Server public key. </p>
      <p></p>
      <h3>Server-side REST Calls</h3>
      <p>You can get the address of the PPM Local URL of the instance your custom WAR is running on (including the right web port) through PpmConfig.getPPMLocalUrl(): <%= ppmConfig.getPPMLocalUrl() %></p>
      <p>Since you directly access the PPM Tomcat server with this URL, calls will bypass SSO when using Generic Web SSO. Then it's up to you to pick the right authentication method for your server calls.</p>
      <h4>Using PPM Authentication and Basic authorization header</h4>
      <p>You can authenticate with Basic authentication using the PPM account Username and password - only for users using PPM Authentication.</p>
      <p><b>Pros:</b>
      <ul>
         <li>Easy to implement</li>
         <li>Can use ephemeral calls (set the HTTP Header ephemeral:true)</li>
      </ul>
      <b>Cons:</b>
      <ul>
         <li>Passwords may need to be changed regularly for security reasons, forcing you to maintain them in your custom War</li>
         <li>Doesn't work when users don't use PPM Authentication</li>
      </ul>
      </p>
      <h4>Using API Key</h4>
      <p>You can create an API Key for any PPM user in PPM (<i>"Manage API Keys" page, make sure the "API Keys" Feature Toggle is turned on</i>). And then use it on LOCAL_BASE_URL/itg/api-auth?username=my_username&key=my_api_key to get a PPM Session for the PPM User.</p>
      <p><b>Pros:</b>
      <ul>
         <li>API Keys are not subject to password changes policy and can be easily managed by PPM Administrations</li>
         <li>Works even for users using SSO authentication</li>
      </ul>
      <b>Cons:</b>
      <ul>
         <li>Cannot use ephemeral calls as you always need a call to /itg/api-auth first to get the session.</li>
         <li>Need to store API Key information in the custom WAR - It's stored nowhere in PPM Database and thus cannot be dynamically retrieved after its creation.</li>
      </ul>
      </p>
      <h4>Using JWK</h4>
      <p>Since PPM 9.66, JWK Authentication is supported. If you have ways to retrieve JWT for the target PPM user that will be successfully verified by the JWK provider configured in PPM, then just pass these JWT as bearer tokens to authenticate in PPM. </p>
      <p><b>Pros:</b>
      <ul>
         <li>No need to hard code any credentials in the custom WAR (only end points to get valid JWT) </li>
         <li>Works for users using SSO authentication</li>
      </ul>
      <b>Cons:</b>
      <ul>
         <li>Requires JWK Provider - as of PPM 10, we do not support RS JWT with Key Signature for external JWT Authentication.</li>
      </ul>
      </p>
      <h4>Using PPM User session from Web Browser (PPM Custom War JWT)</h4>
      <p>In order to do a server-side REST API call to PPM, you will need to authenticate. If the custom Web App is access by a user from a browser with an existing PPM session, you can retrieve the PPM internal JWT Token in order to make a server-side call authenticated as the same user.</p>
      <p>Unlike the "PPM-Internal" JWT that is added by PPM server when accessing /itg/rest2/customWars/your_war_name , these "PPM-Custom-War" JWT Tokens will not force ephemeral sessions and will allow you to create a long-lasting PPM Session, which can be the best option if you're planning to run many REST API calls over a long period of time. You can still decide to make ephemeral calls to server by setting HTTP header "ephemeral" with value "true" in your REST calls.</p>
      <p>An example of server-side REST Call with Custom WAR JWT is given in servlet <a href="https://github.com/MicroFocus/ppm-sample-custom-war/blob/main/src/main/java/com/ppm/custom/war/servlet/CustomWarToPpmCallServlet.java">CustomWarToPpmCallServlet</a>. Calling this servlet on /itg/rest2/customWarsJWTProvider/ppm-sample-custom-war/serverCallToPpmServer/ will pass a valid JWT to the servlet which will then use it to authenticate as currently logged in user and make multiple REST calls to PPM within the same user session.</p>
      <p>One of these calls will retrieve the PPM Version from /itg/rest2/version, which is displayed here: <span id="ppm-version-span"></span></p>
      <script>
         // Following code retrieve data from a custom WAR servlet, which will make the REST calls on the backend - but with a new PPM Session.
         xmlhttp = new XMLHttpRequest();

         xmlhttp.onreadystatechange = function() {
             if (xmlhttp.readyState == XMLHttpRequest.DONE) {   // XMLHttpRequest.DONE == 4
                 if (xmlhttp.status == 200) {
                     let ppmVersion = JSON.parse(xmlhttp.responseText);
                     document.getElementById('ppm-version-span').textContent = ppmVersion.majorVersion+"."+ppmVersion.minorVersion+"."+ppmVersion.minorMinorVersion;
                 }
             }
         };

         xmlhttp.open("GET", "/itg/rest2/customWarsJWTProvider/ppm-sample-custom-war/serverCallToPpmServer/", true);
         xmlhttp.send();
      </script>
      <p>Both "PPM-Internal" and "PPM-Custom-War" JWTs will expire 5 minutes after they're issued (<i>plus a 30 seconds leeway for validation</i>) and as such should not be stored for future usage. So we only provide a supported way to authenticate for a PPM User through JWT on server-side if that user is already authenticated in PPM.</p>
   </body>
</html>