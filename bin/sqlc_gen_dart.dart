import 'dart:convert';
import 'dart:io';

import 'package:pluralize/pluralize.dart';
import 'package:strings/strings.dart';

Future<void> main(List<String> args) async {
  final input = await stdin.transform(utf8.decoder).join();
  final output = await _generateFromSqlcInput(input);
  return stdout.write(output);
}

Future<String> _generateFromSqlcInput(String input) async {
  final data = Map<String, dynamic>.from(jsonDecode(input));

  final request = CodeGenRequest.fromJson(data);

  final files = DartCodeGenerator.generate(request);

  final response = CodeGenResponse(files: files);

  return jsonEncode(response.toJson());
}

String _toPascalCase(String input) {
  if (input.isEmpty) return input;
  return input
      .split('_')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join('');
}

class CodeGenRequest {
  final Catalog catalog;
  final List<Query> queries;
  final String engine;

  CodeGenRequest({required this.catalog, required this.queries, required this.engine});

  factory CodeGenRequest.fromJson(Map<String, dynamic> json) {
    return CodeGenRequest(
      catalog: Catalog.fromJson(json['catalog'] ?? {}),
      queries: (json['queries'] as List<dynamic>? ?? []).map((e) => Query.fromJson(e)).toList(),
      engine: json['settings']?['engine'] ?? 'sqlite',
    );
  }
}

class Catalog {
  final String defaultSchema;
  final List<Schema> schemas;

  Catalog({required this.defaultSchema, required this.schemas});

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      defaultSchema: json['default_schema'] ?? 'public',
      schemas: (json['schemas'] as List<dynamic>? ?? []).map((e) => Schema.fromJson(e)).toList(),
    );
  }

  List<Table> getUserTables() {
    final publicSchema = schemas.firstWhere(
      (s) => s.name == defaultSchema,
      orElse: () => Schema(name: '', tables: []),
    );
    return publicSchema.tables;
  }
}

class Schema {
  final String name;
  final List<Table> tables;

  Schema({required this.name, required this.tables});

  factory Schema.fromJson(Map<String, dynamic> json) {
    return Schema(
      name: json['name'] ?? '',
      tables: (json['tables'] as List<dynamic>? ?? []).map((e) => Table.fromJson(e)).toList(),
    );
  }
}

class Table {
  final TableRef rel;
  final List<Column> columns;

  Table({required this.rel, required this.columns});

  factory Table.fromJson(Map<String, dynamic> json) {
    return Table(
      rel: TableRef.fromJson(json['rel'] ?? {}),
      columns: (json['columns'] as List<dynamic>? ?? []).map((e) => Column.fromJson(e)).toList(),
    );
  }

  String get className => _toPascalCase(rel.name);
}

class TableRef {
  final String name;

  TableRef({required this.name});

  factory TableRef.fromJson(Map<String, dynamic> json) {
    return TableRef(name: json['name'] ?? '');
  }
}

class Column {
  final String name;
  final bool notNull;
  final bool namedParam;
  final TypeRef type;

  Column({required this.name, required this.notNull, required this.namedParam, required this.type});

  factory Column.fromJson(Map<String, dynamic> json) {
    return Column(
      name: json['name'] ?? '',
      notNull: json['not_null'] ?? false,
      namedParam: json['is_named_param'] ?? false,
      type: TypeRef.fromJson(json['type'] ?? {}),
    );
  }

  String get dartType {
    final baseType = SqlTypeToDart.convert(type.name);
    return notNull ? baseType : '$baseType?';
  }
}

class TypeRef {
  final String name;

  TypeRef({required this.name});

  factory TypeRef.fromJson(Map<String, dynamic> json) {
    return TypeRef(name: json['name'] ?? '');
  }
}

class Query {
  final String name;
  final String text;
  final String cmd;
  final List<Column> columns;
  final List<QueryParam> params;

  Query({required this.name, required this.text, required this.cmd, required this.columns, required this.params});

  factory Query.fromJson(Map<String, dynamic> json) {
    return Query(
      name: json['name'] ?? '',
      text: json['text'] ?? '',
      cmd: json['cmd'] ?? '',
      columns: (json['columns'] as List<dynamic>? ?? []).map((e) => Column.fromJson(e)).toList(),
      params: (json['params'] as List<dynamic>? ?? []).map((e) => QueryParam.fromJson(e)).toList(),
    );
  }

  String get methodName => name.toSnakeCase().toCamelCase(lower: true);

  bool get returnsOne => cmd == ':one';
  bool get returnsMany => cmd == ':many';
  bool get isExec => cmd == ':exec';
}

class QueryParam {
  final int number;
  final Column column;

  QueryParam({required this.number, required this.column});

  factory QueryParam.fromJson(Map<String, dynamic> json) {
    return QueryParam(number: json['number'] ?? 0, column: Column.fromJson(json['column'] ?? {}));
  }
}

class GeneratedFile {
  final String name;
  final String contents;

  GeneratedFile({required this.name, required this.contents});

  Map<String, dynamic> toJson() => {'name': name, 'contents': base64Encode(utf8.encode(contents))};
}

class CodeGenResponse {
  final List<GeneratedFile> files;

  CodeGenResponse({required this.files});

  Map<String, dynamic> toJson() => {'files': files.map((e) => e.toJson()).toList()};
}

// ============================================================================
// Type Mapping
// ============================================================================

class SqlTypeToDart {
  static const _typeMap = {
    'bigserial': 'int',
    'bigint': 'int',
    'int8': 'int',
    'serial': 'int',
    'int': 'int',
    'int4': 'int',
    'integer': 'int',
    'smallint': 'int',
    'int2': 'int',
    'smallserial': 'int',

    'text': 'String',
    'varchar': 'String',
    'char': 'String',
    'bpchar': 'String',
    'name': 'String',

    'bool': 'bool',
    'boolean': 'bool',

    'real': 'double',
    'float4': 'double',
    'float8': 'double',
    'double': 'double',
    'numeric': 'double',
    'decimal': 'double',

    'timestamp': 'DateTime',
    'timestamptz': 'DateTime',
    'date': 'DateTime',
    'time': 'DateTime',
    'timetz': 'DateTime',

    'uuid': 'Uuid',

    'json': 'Map<String, dynamic>',
    'jsonb': 'Map<String, dynamic>',

    'bytea': 'List<int>',
  };

  static String convert(String postgresType) {
    final normalized = postgresType.replaceFirst('pg_catalog.', '').replaceAll(RegExp(r'\(.+\)'), '').toLowerCase();
    return _typeMap[normalized] ?? 'dynamic';
  }
}

abstract class DartCodeGenerator {
  static List<GeneratedFile> generate(CodeGenRequest request) {
    final mainFile = _generateMainFile(request.catalog, request.queries, request.engine);
    return [mainFile];
  }

  static GeneratedFile _generateMainFile(Catalog catalog, List<Query> queries, String engine) {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by sqlc_dart');
    buffer.writeln();
    if (engine == 'postgresql') {
      buffer.writeln('import \'package:postgres/postgres.dart\';');
    }
    if (engine == 'sqlite') {
      buffer.writeln('import \'package:sqlite3/sqlite3.dart\';');
    }
    buffer.writeln();

    buffer.writeln('/// Custom exception for SQLC generated code');
    buffer.writeln('class SqlcException implements Exception {');
    buffer.writeln('  final String message;');
    buffer.writeln('  final Object? originalError;');
    buffer.writeln('  SqlcException(this.message, [this.originalError]);');
    buffer.writeln('  @override');
    buffer.writeln(
      "  String toString() => 'SqlcException: \$message \${originalError != null ? \"(\$originalError)\" : \"\"}';",
    );
    buffer.writeln('}');
    buffer.writeln();

    if (catalog.schemas.any((s) => s.tables.any((t) => t.columns.any((c) => c.type.name == 'uuid')))) {
      buffer.writeln('class Uuid implements Comparable<Uuid> {');
      buffer.writeln('  final String _value;');
      buffer.writeln();
      buffer.writeln('  Uuid(this._value) {');
      buffer.writeln(
        '    if (!RegExp(r\'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$\').hasMatch(_value)) {',
      );
      buffer.writeln('      throw FormatException(\'Invalid UUID: \$_value\');');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  String toString() => _value;');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  int compareTo(covariant Uuid other) {');
      buffer.writeln('    return _value.compareTo(other._value);');
      buffer.writeln('  }');
      buffer.writeln('}');
    }

    if (engine == 'postgresql') {
      _generatePostgresCode(buffer, catalog, queries);
    } else {
      _generateSqliteCode(buffer, catalog, queries);
    }

    return GeneratedFile(name: 'sqlc_dart.dart', contents: buffer.toString());
  }

  static void _generateSqliteCode(StringBuffer buffer, Catalog catalog, List<Query> queries) {
    buffer.writeln('/// Configuration for SQLite database');
    buffer.writeln('sealed class SqliteConfig {}');
    buffer.writeln();
    buffer.writeln('/// In-memory SQLite database');
    buffer.writeln('class SqliteMemory extends SqliteConfig {}');
    buffer.writeln();
    buffer.writeln('/// File-based SQLite database');
    buffer.writeln('class SqliteLocal extends SqliteConfig {');
    buffer.writeln('  final String path;');
    buffer.writeln('  SqliteLocal(this.path);');
    buffer.writeln('}');
    buffer.writeln();

    buffer.writeln('/// Main class for managing database connection and queries');
    buffer.writeln('class SqlcDart {');
    buffer.writeln('  late final Queries queries;');
    buffer.writeln();
    buffer.writeln('  SqlcDart(SqliteConfig config) {');
    buffer.writeln('    final db = switch (config) {');
    buffer.writeln('      SqliteMemory() => sqlite3.openInMemory(),');
    buffer.writeln('      SqliteLocal(:final path) => sqlite3.open(path),');
    buffer.writeln('    };');
    buffer.writeln('    queries = Queries(db);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    _generateSchemaClasses(buffer, catalog);

    _generateQueriesClass(buffer, queries, catalog, 'sqlite');
  }

  static void _generatePostgresCode(StringBuffer buffer, Catalog catalog, List<Query> queries) {
    buffer.writeln('/// Main class for managing database connection and queries');
    buffer.writeln('class SqlcDart {');
    buffer.writeln('  late final Queries queries;');
    buffer.writeln();
    buffer.writeln('  SqlcDart(String connectionUrl) {');
    buffer.writeln('    Uri uri = Uri.parse(connectionUrl);');
    buffer.writeln('    if (!uri.queryParameters.containsKey(\'max_connection_count\')) {');
    buffer.writeln('      uri = uri.replace(queryParameters: {...uri.queryParameters, \'max_connection_count\': 10});');
    buffer.writeln('    }');
    buffer.writeln('    if (!uri.queryParameters.containsKey(\'max_connection_age\')) {');
    buffer.writeln('      uri = uri.replace(queryParameters: {...uri.queryParameters, \'max_connection_age\': 3600});');
    buffer.writeln('    }');
    buffer.writeln('    queries = Queries(Pool.withUrl(uri.toString()));');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    _generateSchemaClasses(buffer, catalog);

    _generateQueriesClass(buffer, queries, catalog, 'postgresql');
  }

  static void _generateSchemaClasses(StringBuffer buffer, Catalog catalog) {
    final tables = catalog.getUserTables();

    for (final table in tables) {
      SchemaGenerator.generateTableClass(buffer, table);
      buffer.writeln();
    }
  }

  static void _generateQueriesClass(StringBuffer buffer, List<Query> queries, Catalog catalog, String engine) {
    final dbType = engine == 'postgresql' ? 'Pool' : 'Database';

    buffer.writeln('class Queries {');
    buffer.writeln('  final $dbType _db;');
    buffer.writeln();
    buffer.writeln('  Queries(this._db);');
    buffer.writeln();

    for (final query in queries) {
      QueriesGenerator.generateQueryMethod(buffer, query, catalog, engine);
      buffer.writeln();
    }

    buffer.writeln('}');
  }
}

abstract class SchemaGenerator {
  static void generateTableClass(StringBuffer buffer, Table table) {
    final className = Pluralize().singular(table.className);

    buffer.writeln('class $className {');

    for (final column in table.columns) {
      buffer.writeln('  final ${column.dartType} ${column.name.toCamelCase(lower: true)};');
    }

    buffer.writeln();

    buffer.write('  const $className({');
    for (var i = 0; i < table.columns.length; i++) {
      final column = table.columns[i];
      if (column.notNull) {
        buffer.write('required this.${column.name.toCamelCase(lower: true)}');
      } else {
        buffer.write('this.${column.name.toCamelCase(lower: true)}');
      }
      if (i < table.columns.length - 1) buffer.write(', ');
    }
    buffer.writeln('});');

    buffer.writeln();

    buffer.writeln('  factory $className.fromMap(Map<String, dynamic> map) {');
    buffer.writeln('    return $className(');
    for (final column in table.columns) {
      final dartType = SqlTypeToDart.convert(column.type.name);
      if (dartType == 'DateTime') {
        if (column.notNull) {
          buffer.writeln(
            "      ${column.name.toCamelCase(lower: true)}: DateTime.parse(map['${column.name}'] as String),",
          );
        } else {
          buffer.writeln(
            "      ${column.name.toCamelCase(lower: true)}: map['${column.name}'] != null ? DateTime.parse(map['${column.name}'] as String) : null,",
          );
        }
      } else if (dartType == 'Uuid') {
        if (column.notNull) {
          buffer.writeln("      ${column.name.toCamelCase(lower: true)}: Uuid(map['${column.name}'] as String),");
        } else {
          buffer.writeln(
            "      ${column.name.toCamelCase(lower: true)}: map['${column.name}'] != null ? Uuid(map['${column.name}'] as String) : null,",
          );
        }
      } else {
        buffer.writeln("      ${column.name.toCamelCase(lower: true)}: map['${column.name}'] as ${column.dartType},");
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln();

    buffer.writeln('  Map<String, dynamic> toMap() {');
    buffer.writeln('    return {');
    for (final column in table.columns) {
      final dartType = SqlTypeToDart.convert(column.type.name);
      if (dartType == 'DateTime') {
        if (column.notNull) {
          buffer.writeln("      '${column.name}': ${column.name.toCamelCase(lower: true)}.toIso8601String(),");
        } else {
          buffer.writeln("      '${column.name}': ${column.name.toCamelCase(lower: true)}?.toIso8601String(),");
        }
      } else if (dartType == 'Uuid') {
        if (column.notNull) {
          buffer.writeln("      '${column.name}': ${column.name.toCamelCase(lower: true)}.toString(),");
        } else {
          buffer.writeln("      '${column.name}': ${column.name.toCamelCase(lower: true)}?.toString(),");
        }
      } else {
        buffer.writeln("      '${column.name}': ${column.name.toCamelCase(lower: true)},");
      }
    }
    buffer.writeln('    };');
    buffer.writeln('  }');

    buffer.writeln('}');
  }
}

abstract class QueriesGenerator {
  static void generateQueryMethod(StringBuffer buffer, Query query, Catalog catalog, String engine) {
    final methodName = query.methodName;
    final isPostgres = engine == 'postgresql';

    String returnType;
    String returnTypeName = '';
    if (query.isExec) {
      returnType = 'Future<void>';
    } else if (query.returnsOne) {
      returnTypeName = _getReturnTypeName(query, catalog);
      returnType = 'Future<$returnTypeName>';
    } else if (query.returnsMany) {
      returnTypeName = _getReturnTypeName(query, catalog);
      returnType = 'Future<List<$returnTypeName>>';
    } else {
      returnType = 'Future<dynamic>';
    }

    buffer.write('  $returnType $methodName(');

    final paramNames = <String>[];
    if (query.params.isNotEmpty) {
      paramNames.addAll(
        query.params.indexed.map((e) {
          final name = switch (e.$2.column.name.isEmpty) {
            true => 'param${e.$1}',
            false => e.$2.column.name,
          };
          return name;
        }),
      );

      final namedParams = query.params.indexed.map((e) {
        final name = switch (e.$2.column.name.isEmpty) {
          true => 'param${e.$1}',
          false => e.$2.column.name,
        };
        return '${e.$2.column.notNull ? 'required ' : ''}${e.$2.column.dartType} $name';
      });

      buffer.write('{${namedParams.join(', ')}}');
    }

    buffer.writeln(') async {');

    var sqlText = query.text;
    if (isPostgres) {
      sqlText = _convertSqlToPostgres(sqlText);
    }
    buffer.writeln("    const sql = r'''$sqlText''';");

    if (isPostgres) {
      _generatePostgresMethodBody(buffer, query, methodName, returnTypeName, paramNames, catalog);
    } else {
      _generateSqliteMethodBody(buffer, query, methodName, returnTypeName, paramNames, catalog);
    }

    buffer.writeln('  }');
  }

  static String _convertSqlToPostgres(String sql) {
    var index = 1;
    return sql.replaceAllMapped('?', (match) => '\$${index++}');
  }

  static void _generatePostgresMethodBody(
    StringBuffer buffer,
    Query query,
    String methodName,
    String returnTypeName,
    List<String> paramNames,
    Catalog catalog,
  ) {
    if (query.isExec) {
      buffer.writeln('    try {');
      if (paramNames.isEmpty) {
        buffer.writeln('      await _db.execute(sql);');
      } else {
        buffer.write('      await _db.execute(Sql.indexed(sql), parameters: [');
        buffer.write(paramNames.join(', '));
        buffer.writeln(']);');
      }
      buffer.writeln('    } on PgException catch (e) {');
      buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
      buffer.writeln('    } on Exception catch (e) {');
      buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
      buffer.writeln('    }');
    } else {
      buffer.writeln('    try {');
      if (paramNames.isEmpty) {
        buffer.writeln('      final result = await _db.execute(sql);');
      } else {
        buffer.write('      final result = await _db.execute(Sql.indexed(sql), parameters: [');
        buffer.write(paramNames.join(', '));
        buffer.writeln(']);');
      }

      if (query.returnsOne) {
        buffer.writeln('      if (result.isEmpty) {');
        buffer.writeln("        throw SqlcException('No results found for query $methodName');");
        buffer.writeln('      }');
        buffer.writeln('      final row = result.first.toColumnMap();');
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln('      return $returnTypeName.fromMap(row);');
        } else {
          buffer.writeln('      return row;');
        }
      } else if (query.returnsMany) {
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln('      return result.map((row) => $returnTypeName.fromMap(row.toColumnMap())).toList();');
        } else {
          buffer.writeln('      return result.map((row) => row.toColumnMap()).toList();');
        }
      }
      buffer.writeln('    } on SqlcException {');
      buffer.writeln('      rethrow;');
      buffer.writeln('    } on PgException catch (e) {');
      buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
      buffer.writeln('    } on Exception catch (e) {');
      buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
      buffer.writeln('    }');
    }
  }

  static void _generateSqliteMethodBody(
    StringBuffer buffer,
    Query query,
    String methodName,
    String returnTypeName,
    List<String> paramNames,
    Catalog catalog,
  ) {
    if (query.isExec) {
      if (paramNames.isEmpty) {
        buffer.writeln('    try {');
        buffer.writeln('      _db.execute(sql);');
        buffer.writeln('    } catch (e) {');
        buffer.writeln("      throw SqlcException('Error executing query $methodName', e);");
        buffer.writeln('    }');
      } else {
        buffer.writeln('    final stmt = _db.prepare(sql);');
        buffer.writeln('    try {');
        buffer.write('      stmt.execute([');
        buffer.write(paramNames.join(', '));
        buffer.writeln(']);');
        buffer.writeln('    } on SqlcException {');
        buffer.writeln('      rethrow;');
        buffer.writeln('    } on SqliteException catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } on Exception catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } finally {');
        buffer.writeln('      stmt.close();');
        buffer.writeln('    }');
      }
    } else if (query.returnsOne) {
      if (paramNames.isEmpty) {
        buffer.writeln('    try {');
        buffer.writeln('      final result = _db.select(sql);');
        buffer.writeln('      if (result.isEmpty) {');
        buffer.writeln("        throw SqlcException('No results found for query $methodName');");
        buffer.writeln('      }');
        buffer.writeln('      final row = result.first;');
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln('      return $returnTypeName.fromMap(row);');
        } else {
          buffer.writeln('      return row;');
        }
        buffer.writeln('    } on SqlcException {');
        buffer.writeln('      rethrow;');
        buffer.writeln('    } on SqliteException catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } on Exception catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    }');
      } else {
        buffer.writeln('    final stmt = _db.prepare(sql);');
        buffer.writeln('    try {');
        buffer.write('      final result = stmt.select([');
        buffer.write(paramNames.join(', '));
        buffer.writeln(']);');
        buffer.writeln('      if (result.isEmpty) {');
        buffer.writeln("        throw SqlcException('No results found for query $methodName');");
        buffer.writeln('      }');
        buffer.writeln('      final row = result.first;');
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln('      return $returnTypeName.fromMap(row);');
        } else {
          buffer.writeln('      return row;');
        }
        buffer.writeln('    } on SqlcException {');
        buffer.writeln('      rethrow;');
        buffer.writeln('    } on SqliteException catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } on Exception catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } finally {');
        buffer.writeln('      stmt.close();');
        buffer.writeln('    }');
      }
    } else if (query.returnsMany) {
      if (paramNames.isEmpty) {
        buffer.writeln('    try {');
        buffer.writeln('      final result = _db.select(sql);');
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln('      return result.map((row) => $returnTypeName.fromMap(row)).toList();');
        } else {
          buffer.writeln('      return result.toList();');
        }
        buffer.writeln('    } on SqlcException {');
        buffer.writeln('      rethrow;');
        buffer.writeln('    } on SqliteException catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } on Exception catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    }');
      } else {
        buffer.writeln('    final stmt = _db.prepare(sql);');
        buffer.writeln('    try {');
        buffer.write('      final result = stmt.select([');
        buffer.write(paramNames.join(', '));
        buffer.writeln(']);');
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln('      return result.map((row) => $returnTypeName.fromMap(row)).toList();');
        } else {
          buffer.writeln('      return result.toList();');
        }
        buffer.writeln('    } on SqlcException {');
        buffer.writeln('      rethrow;');
        buffer.writeln('    } on SqliteException catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } on Exception catch (e) {');
        buffer.writeln('      throw SqlcException(e.runtimeType.toString(), e);');
        buffer.writeln('    } finally {');
        buffer.writeln('      stmt.close();');
        buffer.writeln('    }');
      }
    }
  }

  static bool _isTableType(String typeName, Catalog catalog) {
    final tables = catalog.getUserTables();
    return tables.any((table) => Pluralize().singular(table.className) == typeName);
  }

  static String _getReturnTypeName(Query query, Catalog catalog) {
    if (query.columns.isEmpty) {
      return 'Map<String, dynamic>';
    }

    final tables = catalog.getUserTables();
    for (final table in tables) {
      if (_columnsMatchTable(query.columns, table.columns)) {
        return Pluralize().singular(table.className);
      }
    }

    return 'Map<String, dynamic>';
  }

  static bool _columnsMatchTable(List<Column> queryColumns, List<Column> tableColumns) {
    if (queryColumns.length != tableColumns.length) return false;

    for (var i = 0; i < queryColumns.length; i++) {
      if (queryColumns[i].name != tableColumns[i].name) return false;
    }

    return true;
  }
}
