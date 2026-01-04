package one.dmj;

import org.apache.commons.lang3.StringUtils;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import java.util.HashMap;
import java.util.Map;

/**
 * d1run Maven Demo
 * 
 * This class demonstrates d1run's ability to:
 * 1. Auto-detect Maven projects (pom.xml)
 * 2. Automatically download dependencies
 * 3. Compile and run the project
 * 
 * Run with: d1run App.java
 */
public class App {
    public static void main(String[] args) {
        System.out.println("========================================");
        System.out.println("  d1run Maven Demo");
        System.out.println("========================================");
        System.out.println();

        // Demonstrate Apache Commons Lang3
        String text = "  hello world  ";
        System.out.println("Using Apache Commons Lang3:");
        System.out.println("  Original: '" + text + "'");
        System.out.println("  Trimmed: '" + StringUtils.trim(text) + "'");
        System.out.println("  Capitalized: '" + StringUtils.capitalize(text.trim()) + "'");
        System.out.println("  Reversed: '" + StringUtils.reverse(text.trim()) + "'");
        System.out.println();

        // Demonstrate Gson
        System.out.println("Using Gson for JSON:");
        Map<String, Object> data = new HashMap<>();
        data.put("name", "d1run");
        data.put("version", "3.1.0");
        data.put("features", new String[] { "Python venv", "Java Maven/Gradle", "C++ vcpkg" });
        data.put("autoInstall", true);

        Gson gson = new GsonBuilder().setPrettyPrinting().create();
        String json = gson.toJson(data);
        System.out.println("  " + json.replace("\n", "\n  "));
        System.out.println();

        System.out.println("Dependencies were installed automatically by Maven!");
        System.out.println("========================================");
    }
}
