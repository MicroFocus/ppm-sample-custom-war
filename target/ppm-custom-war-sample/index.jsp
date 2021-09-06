<html>
   <body>
        <h2>Welcome to the Sample PPM Custom WAR.</h2>
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
        

   </body>
</html>
