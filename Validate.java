import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.fge.jsonschema.core.report.ProcessingMessage;
import com.github.fge.jsonschema.main.JsonSchemaFactory;

import java.io.File;

public final class Validate
{
  private Validate()
  {

  }

  public static void main(
    final String[] args)
    throws Exception
  {
    if (args.length != 1) {
      throw new IllegalArgumentException("usage: file.json");
    }

    final var objectMapper =
      new ObjectMapper();
    final var fileText =
      objectMapper.readTree(new File(args[0]));
    final var schemaText =
      objectMapper.readTree(new File("locatorSchema.json"));

    final var factory =
      JsonSchemaFactory.byDefault();
    final var schema =
      factory.getJsonSchema(schemaText);

    final var report = schema.validate(fileText);
    report.forEach(Validate::logMessage);
    System.exit(report.isSuccess() ? 0 : 1);
  }

  private static void logMessage(
    final ProcessingMessage message)
  {
    System.err.println(message.toString());
  }
}