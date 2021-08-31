package com.ppm.custom.war.config;

import javax.naming.InitialContext;
import javax.servlet.ServletContext;
import javax.sql.DataSource;
import java.io.*;
import java.sql.Connection;
import java.util.Properties;

/**
 * This class reads the content of file ${catalina.base}/conf/customWars.properties which contains some configuration information about the PPM Server,
 * and exposes them in a way convenient for Java usage.
 * <p>
 * You'll want to cache this file in case of repeated usage, or even better,
 * set up a ServletContextListener and initialize a single instance on event contextInitialized(...) that will be used by your whole Custom WebApp.
 */
public class PpmConfig {

    private static final String PPM_JNDI_DS = "ppm.datasource.jndi-name";
    private static final String PPM_REPORTING_DS = "ppm.datasource.jndi-name";
    private static final String PPM_LOCAL_URL = "ppm.base-url";


    private Properties props;

    /**
     * The path to file customWars.properties is passed in a Context initialization parameter - it will be read from ServletContext.
     */
    public PpmConfig(ServletContext sc) {
        String propertiesLocation = sc.getInitParameter("custom.wars.config.location");

        if (propertiesLocation == null) {
            throw new RuntimeException("The custom war should have an initialization parameter custom.wars.config.location passed in server.xml, but it's missing. Please declare your custom WAR in server.conf param CUSTOM_WARS and run kRunUpdateHtml.sh");
        }

        this.props = new Properties();
        try {
            InputStream is = new FileInputStream(propertiesLocation);
            props.load(is);
            is.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public Properties getProperties() {
        return (Properties) props.clone();
    }

    public String getProperty(String propName) {
        return (String) props.get(propName);
    }

    /**
     * Don't forget to .close() the Connection after usage.
     */
    public Connection getPpmDbConnection() {
        return getConnection(getProperty(PPM_JNDI_DS));
    }

    /**
     * Return a connection to PPM Reporting DB if it's defined, or a connection to PPM DB if it's not.
     * Don't forget to .close() the Connection after usage.
     * <p>
     * If you only want a connection to Reporting DB (without the fallback to PPM DB in case it's not defined), then check {@link #isReportingDbAvailable()} first.
     *
     * @see #isReportingDbAvailable()
     */
    public Connection getReportingDbConnection() {
        if (isReportingDbAvailable()) {
            return getConnection(getProperty(PPM_REPORTING_DS));
        } else {
            return getConnection(getProperty(PPM_JNDI_DS));
        }
    }

    /**
     * @return The local HTTP URL of this PPM Server at which Server-side REST calls should be made. Typically, http://127.0.0.1:port/itg .
     */
    public String getPPMLocalUrl() {
        return getProperty(PPM_LOCAL_URL);
    }

    /**
     * @return true if the reporting DB is set up on PPM, false otherwise.
     * @see #getPpmDbConnection()
     */
    public boolean isReportingDbAvailable() {
        String reportingDbJndiName = getProperty(PPM_REPORTING_DS);
        return (reportingDbJndiName != null || !"".equals(reportingDbJndiName.trim()));
    }


    private Connection getConnection(String jndiName) {
        try {
            InitialContext ctx = new InitialContext();
            DataSource ds = (DataSource) ctx.lookup(getProperty(jndiName));
            return ds.getConnection();
        } catch (Exception e) {
            throw new RuntimeException("Error while retrieving DB connection from JNDI name " + jndiName, e);
        }
    }

}
