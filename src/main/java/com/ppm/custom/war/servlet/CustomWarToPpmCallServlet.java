package com.ppm.custom.war.servlet;

import com.ppm.custom.war.config.PpmConfig;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 *
 * This Servlet demonstrate how to make Server-side HTTP calls to the PPM itself in order to perform server-side REST Calls while leveraging the session of the logged in user.
 * The PPM JWT Internal authentication is used.
 *
 * */
public class CustomWarToPpmCallServlet extends HttpServlet {

    @Override
    protected void service(final HttpServletRequest req, final HttpServletResponse resp) throws IOException {

        PpmConfig config = new PpmConfig(getServletContext());

        resp.getWriter().write("customWars.properties: "+ config.getProperties().toString());
    }

}
