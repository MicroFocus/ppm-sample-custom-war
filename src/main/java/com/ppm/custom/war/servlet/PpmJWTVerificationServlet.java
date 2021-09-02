package com.ppm.custom.war.servlet;

import com.auth0.jwt.JWT;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.ppm.custom.war.config.PpmConfig;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.Writer;
import java.util.Enumeration;

/**
 *
 * This Servlet demonstrate how any call to PPM BASE_URL/itg/rest2/customWars/your_custom_war_name/* will automatically be forwarded to
 * BASE_URL/your_custom_war_name/* , but with a valid PPM Internal JWT included. Your code can then verify the JWT to ensure that the call was made with a valid PPM User authenticated.
 *
 * This is an easy way to leverage PPM Authentication in your custom WAR to ensure that every HTTP request it receives comes from an authenticated PPM User.
 *
 * */
public class PpmJWTVerificationServlet extends HttpServlet {

    private static final String BEARER_AUTH_PREFIX = "Bearer ";

    @Override
    protected void service(final HttpServletRequest req, final HttpServletResponse resp) throws IOException {

        PpmConfig config = new PpmConfig(getServletContext());

        Writer w = resp.getWriter();

        String authorizationHeader = req.getHeader("authorization");

        if (authorizationHeader == null || "".equals(authorizationHeader.trim())) {
            w.write("There is no 'authorization' header in the request, it is not a request from a valid PPM User");
        } else if (!(authorizationHeader.startsWith(BEARER_AUTH_PREFIX))) {
            w.write("There is an authorization Header, but it is not a Bearer Token.");
        } else {
            String token =  authorizationHeader.substring(BEARER_AUTH_PREFIX.length());
            try {
                config.verifyPpmJWTBearerToken(token);
            } catch (JWTVerificationException e) {
                w.write("This request has a JWT Token, but it is invalid. Error: "+e.getMessage());
                return;
            }
            DecodedJWT jwt = JWT.decode(token);

            w.write("This request has a valid PPM Internal JWT Token.\n");
            w.write("Username: "+jwt.getClaim("user_name")+"\n");
            w.write("User ID: "+jwt.getClaim("user_id")+"\n");
            w.write("Language: "+jwt.getClaim("language")+"\n");
        }

    }

}
