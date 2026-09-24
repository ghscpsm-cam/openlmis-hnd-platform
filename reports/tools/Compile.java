import java.io.*;
import net.sf.jasperreports.engine.*;

// Compila .jrxml igual que los servicios de OpenLMIS:
// JasperCompileManager.compileReport + ObjectOutputStream.writeObject.
public class Compile {
  public static void main(String[] args) throws Exception {
    for (int i = 0; i < args.length; i += 2) {
      JasperReport report;
      try (InputStream in = new FileInputStream(args[i])) {
        report = JasperCompileManager.compileReport(in);
      }
      try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream(args[i + 1]))) {
        out.writeObject(report);
      }
      System.out.println("OK " + args[i] + " -> " + args[i + 1]);
    }
  }
}
