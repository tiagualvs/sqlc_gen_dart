sealed class SqlcDartConfig {
  const SqlcDartConfig();
}

final class SqliteMemoryConfig extends SqlcDartConfig {
  const SqliteMemoryConfig();
}

final class SqliteFileConfig extends SqlcDartConfig {
  const SqliteFileConfig(this.path);

  final String path;
}

final class PostgresConfig extends SqlcDartConfig {
  const PostgresConfig(this.uri);

  final String uri;
}
