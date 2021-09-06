package com.ppm.custom.war.servlet;

import com.ppm.custom.war.config.PpmConfig;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.CookieManager;
import java.net.HttpCookie;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * This Servlet demonstrate how to make Server-side HTTP calls to the PPM itself in order to perform server-side REST Calls while leveraging the session of the logged in user.
 * The "PPM-Custom-Wars" JWT authentication is used.
 * <p>
 * In order to use this servlet, have a user with a valid PPM Session make a call from the UI to PPM_HOME/itg/rest2/customWarsJWTProvider/ppm-sample-customer-war/serverCallToPpmServer/ ,
 * which will then reach this servlet with a valid PPM-Custom-Wars JWT that is retrieved here and used to make server-side REST calls to PPM Server with a long-lasting sessions.
 * <p>
 * Note that the same operation can be done by retrieving the PPM-Internal JWT from a call to rest2/customWars/ppm-sample-customer-war/serverCallToPpmServer/ ,
 * but this JWT will only allow ephemeral calls, so if the server side processing will take more than 5 minutes (the validity period of Internal JWT), future calls will fail authentication.
 * <p>
 * This Servlet uses Java built-in libraries to make HTTP calls, but we expect your custom WAR to use your favorite libraries - just make sure to keep Cookies between calls in order to keep the PPM session.
 * Also, unless you make ephemeral calls, always make a call to /rest2/logout to end the session once your server-side processing is done.
 */
public class CustomWarToPpmCallServlet extends HttpServlet {

    private static final String BEARER_AUTH_PREFIX = "Bearer ";

    private static final String COOKIES_HEADER = "Set-Cookie";

    @Override
    protected void service(final HttpServletRequest req, final HttpServletResponse resp) throws IOException {

        PpmConfig config = new PpmConfig(getServletContext());


        String authorizationHeader = req.getHeader("authorization");


        String token = authorizationHeader.substring(BEARER_AUTH_PREFIX.length());

        // If we verify the JWT against PPM Public key, it will check.
        // However, in this servlet we don't care about validating the JWT, we want to use it to make REST calls to PPM Server.
        config.verifyPpmJWTBearerToken(token);

        // First, let's just make a ping to PPM REST API - this will ensure that everything works and will set the session token.
        String pingUrl = config.getPPMRest2Url("ping");
        URL url = new URL(pingUrl);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        con.setRequestMethod("GET");

        // We use the same Bearer authorization header as received from PPM to make our call - it includes the JWT.
        con.setRequestProperty("authorization", authorizationHeader);

        // We make the REST GET call to /ping/ . It does nothing but allows us to easily test if authentication is successful.
        con.connect();

        if (con.getResponseCode() != 200) {
            throw new RuntimeException("Making a Ping call on PPM should return HTTP 200, but got " + con.getResponseCode() + " instead.");
        }

        // Let's now read all the cookies returned by PPM - they will include the session cookie, and we'll pass them with every future REST call we'll do in order to reuse the session.
        CookieManager cookies = new CookieManager();
        List<String> cookiesHeader = con.getHeaderFields().get(COOKIES_HEADER);
        for (String cookie : cookiesHeader) {
            cookies.getCookieStore().add(null, HttpCookie.parse(cookie).get(0));
        }

        con.disconnect();



        // Now that we have cookies with the PPM Session, let's make another REST Call without the authentication header - it's not needed anymore as we have the session cookie for a valid PPM Session.
        // Let's get the PPM Version info and return it as the result of the call of this Servlet.
        String versionUrl = config.getPPMRest2Url("version");
        con = (HttpURLConnection) (new URL(versionUrl)).openConnection();
        con.setRequestMethod("GET");
        // Let's get the data in JSon format, as default will be XML.
        con.setRequestProperty("Accept", "application/json");
        setCookiesToConnection(con, cookies);

        BufferedReader restResponse = new BufferedReader(new InputStreamReader(con.getInputStream()));
        String jsonVersionResponse = restResponse.lines().collect(Collectors.joining());

        // We now write the JSon Response of REST call as the response of the call to this servlet.
        resp.setHeader("Content-Type", "application/json");
        resp.getWriter().write(jsonVersionResponse);

        con.disconnect();


        // Now that we've finished to use our session, we must always log out - because we're not using ephemeral sessions here.
        String logoutUrl = config.getPPMRest2Url("logout");
        con = (HttpURLConnection) (new URL(logoutUrl)).openConnection();
        con.setRequestMethod("GET");
        // We must make sure to log out of the session with initially opened, so cookies are always a must.
        setCookiesToConnection(con, cookies);

        // Just sending the request is enough to end the session. You can check that the session was effectively ended in table PPM_LOGON_SESSIONS, with AUTHENTICATION_TYPE = 'PPM_CUSTOM_WAR_JWT_TOKEN'.
        con.connect();
        con.getResponseCode(); // We must call this for the HTTP call to actually happen.
        con.disconnect();

    }

    private void setCookiesToConnection(HttpURLConnection con, CookieManager cookies) {
        if (cookies.getCookieStore().getCookies().size() > 0) {
            // While joining the Cookies, use ',' or ';' as needed. Most of the servers are using ';'
            List<String> cookiesStr = new ArrayList<String>();
            for (HttpCookie cookie: cookies.getCookieStore().getCookies()) {
                cookiesStr.add(cookie.toString());
            }
            con.setRequestProperty("Cookie", String.join(";", cookiesStr));
        }
    }

}
