package one.dmj;

import org.apache.commons.text.WordUtils;
import org.apache.commons.text.StringEscapeUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * d1run Gradle Demo
 * 
 * This class demonstrates d1run's ability to:
 * 1. Auto-detect Gradle projects (build.gradle)
 * 2. Automatically download dependencies
 * 3. Build and run the project using Gradle
 * 
 * Run with: d1run App.java
 * Or: gradle run
 */
public class App {
    private static final Logger logger = LoggerFactory.getLogger(App.class);

    public static void main(String[] args) {
        System.out.println("========================================");
        System.out.println("  d1run Gradle Demo");
        System.out.println("========================================");
        System.out.println();

        // Demonstrate Apache Commons Text
        System.out.println("Using Apache Commons Text:");

        String text = "hello world from gradle";
        System.out.println("  Original: '" + text + "'");
        System.out.println("  Capitalized: '" + WordUtils.capitalize(text) + "'");
        System.out.println("  Swapped case: '" + WordUtils.swapCase(text) + "'");
        System.out.println("  Initials: '" + WordUtils.initials(text) + "'");
        System.out.println();

        // Demonstrate HTML escaping
        String html = "<script>alert('XSS')</script>";
        System.out.println("  HTML input: " + html);
        System.out.println("  Escaped: " + StringEscapeUtils.escapeHtml4(html));
        System.out.println();

        // Demonstrate SLF4J logging
        System.out.println("Using SLF4J Logging:");
        logger.info("This is an INFO message from Gradle demo");
        logger.warn("This is a WARN message");
        System.out.println();

        System.out.println("Dependencies were installed automatically by Gradle!");
        System.out.println("========================================");
    }
}
