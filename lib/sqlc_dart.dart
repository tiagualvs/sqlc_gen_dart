library;

import 'dart:convert';

Future<String> generateFromSqlcInput(String jsonInput) async {
  final data = Map<String, dynamic>.from(jsonDecode(jsonInput));

  final request = CodeGenRequest.fromJson(data);

  final files = DartCodeGenerator().generate(request);

  final response = CodeGenResponse(files: files);

  return jsonEncode(response.toJson());
}

// ============================================================================
// Model Classes
// ============================================================================

class CodeGenRequest {
  final Catalog catalog;
  final List<Query> queries;

  CodeGenRequest({required this.catalog, required this.queries});

  factory CodeGenRequest.fromJson(Map<String, dynamic> json) {
    return CodeGenRequest(
      catalog: Catalog.fromJson(json['catalog'] ?? {}),
      queries: (json['queries'] as List<dynamic>? ?? []).map((e) => Query.fromJson(e)).toList(),
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
  final TypeRef type;

  Column({required this.name, required this.notNull, required this.type});

  factory Column.fromJson(Map<String, dynamic> json) {
    return Column(
      name: json['name'] ?? '',
      notNull: json['not_null'] ?? false,
      type: TypeRef.fromJson(json['type'] ?? {}),
    );
  }

  String get dartType {
    final baseType = PostgresTypeToDart.convert(type.name);
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

  String get methodName => _toCamelCase(name);

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

class PostgresTypeToDart {
  static const _typeMap = {
    // Integer types
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

    // Text types
    'text': 'String',
    'varchar': 'String',
    'char': 'String',
    'bpchar': 'String',
    'name': 'String',

    // Boolean
    'bool': 'bool',
    'boolean': 'bool',

    // Floating point
    'real': 'double',
    'float4': 'double',
    'float8': 'double',
    'double': 'double',
    'numeric': 'double',
    'decimal': 'double',

    // Date/Time
    'timestamp': 'DateTime',
    'timestamptz': 'DateTime',
    'date': 'DateTime',
    'time': 'DateTime',
    'timetz': 'DateTime',

    // UUID
    'uuid': 'String',

    // JSON
    'json': 'Map<String, dynamic>',
    'jsonb': 'Map<String, dynamic>',

    // Binary
    'bytea': 'List<int>',
  };

  static String convert(String postgresType) {
    return _typeMap[postgresType.toLowerCase()] ?? 'dynamic';
  }
}

// ============================================================================
// Code Generators
// ============================================================================

class DartCodeGenerator {
  List<GeneratedFile> generate(CodeGenRequest request) {
    final schemaFile = SchemaGenerator().generate(request.catalog);
    final queriesFile = QueriesGenerator().generate(request.queries, request.catalog);
    final mainFile = _generateMainFile();

    return [mainFile, schemaFile, queriesFile];
  }

  GeneratedFile _generateMainFile() {
    final buffer = StringBuffer();

    buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
    buffer.writeln("// Generated by sqlc_dart");
    buffer.writeln();
    buffer.writeln("import 'package:sqlite3/sqlite3.dart';");
    buffer.writeln();
    buffer.writeln("part 'schema.dart';");
    buffer.writeln("part 'queries.dart';");
    buffer.writeln();

    // Generate sealed class for SQLite configuration
    buffer.writeln("/// Configuration for SQLite database");
    buffer.writeln("sealed class SqliteConfig {}");
    buffer.writeln();
    buffer.writeln("/// In-memory SQLite database");
    buffer.writeln("class SqliteMemory extends SqliteConfig {}");
    buffer.writeln();
    buffer.writeln("/// File-based SQLite database");
    buffer.writeln("class SqliteLocal extends SqliteConfig {");
    buffer.writeln("  final String path;");
    buffer.writeln("  SqliteLocal(this.path);");
    buffer.writeln("}");
    buffer.writeln();

    // Generate SqlcException
    buffer.writeln("/// Custom exception for SQLC generated code");
    buffer.writeln("class SqlcException implements Exception {");
    buffer.writeln("  final String message;");
    buffer.writeln("  final Object? originalError;");
    buffer.writeln("  SqlcException(this.message, [this.originalError]);");
    buffer.writeln("  @override");
    buffer.writeln(
      "  String toString() => 'SqlcException: \$message \${originalError != null ? \"(\$originalError)\" : \"\"}';",
    );
    buffer.writeln("}");
    buffer.writeln();

    // Generate Sqlc class
    buffer.writeln("/// Main class for managing database connection and queries");
    buffer.writeln("class Sqlc {");
    buffer.writeln("  final Database _db;");
    buffer.writeln("  late final Queries queries;");
    buffer.writeln();
    buffer.writeln("  Sqlc._(this._db) {");
    buffer.writeln("    queries = Queries(_db);");
    buffer.writeln("  }");
    buffer.writeln();
    buffer.writeln("  /// Create a new Sqlc instance with the given configuration");
    buffer.writeln("  factory Sqlc(SqliteConfig config) {");
    buffer.writeln("    final db = switch (config) {");
    buffer.writeln("      SqliteMemory() => sqlite3.openInMemory(),");
    buffer.writeln("      SqliteLocal(:final path) => sqlite3.open(path),");
    buffer.writeln("    };");
    buffer.writeln("    return Sqlc._(db);");
    buffer.writeln("  }");
    buffer.writeln();
    buffer.writeln("  /// Close the database connection");
    buffer.writeln("  void close() => _db.close();");
    buffer.writeln();
    buffer.writeln("  /// Get the underlying database instance");
    buffer.writeln("  Database get database => _db;");
    buffer.writeln("}");
    buffer.writeln();

    return GeneratedFile(name: "sqlc.dart", contents: buffer.toString());
  }
}

class SchemaGenerator {
  GeneratedFile generate(Catalog catalog) {
    final buffer = StringBuffer();

    buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
    buffer.writeln("// Generated by sqlc_dart");
    buffer.writeln();
    buffer.writeln("part of 'sqlc.dart';");
    buffer.writeln();

    final tables = catalog.getUserTables();

    for (final table in tables) {
      _generateTableClass(buffer, table);
      buffer.writeln();
    }

    return GeneratedFile(name: "schema.dart", contents: buffer.toString());
  }

  void _generateTableClass(StringBuffer buffer, Table table) {
    final className = table.className;

    buffer.writeln("class $className {");

    // Fields
    for (final column in table.columns) {
      buffer.writeln("  final ${column.dartType} ${column.name};");
    }

    buffer.writeln();

    // Constructor
    buffer.write("  $className({");
    for (var i = 0; i < table.columns.length; i++) {
      final column = table.columns[i];
      if (column.notNull) {
        buffer.write("required this.${column.name}");
      } else {
        buffer.write("this.${column.name}");
      }
      if (i < table.columns.length - 1) buffer.write(", ");
    }
    buffer.writeln("});");

    buffer.writeln();

    // fromMap factory
    buffer.writeln("  factory $className.fromMap(Map<String, dynamic> map) {");
    buffer.writeln("    return $className(");
    for (final column in table.columns) {
      final dartType = PostgresTypeToDart.convert(column.type.name);
      if (dartType == 'DateTime') {
        if (column.notNull) {
          buffer.writeln("      ${column.name}: DateTime.parse(map['${column.name}'] as String),");
        } else {
          buffer.writeln(
            "      ${column.name}: map['${column.name}'] != null ? DateTime.parse(map['${column.name}'] as String) : null,",
          );
        }
      } else {
        buffer.writeln("      ${column.name}: map['${column.name}'] as ${column.dartType},");
      }
    }
    buffer.writeln("    );");
    buffer.writeln("  }");

    buffer.writeln();

    // toMap method
    buffer.writeln("  Map<String, dynamic> toMap() {");
    buffer.writeln("    return {");
    for (final column in table.columns) {
      final dartType = PostgresTypeToDart.convert(column.type.name);
      if (dartType == 'DateTime') {
        if (column.notNull) {
          buffer.writeln("      '${column.name}': ${column.name}.toIso8601String(),");
        } else {
          buffer.writeln("      '${column.name}': ${column.name}?.toIso8601String(),");
        }
      } else {
        buffer.writeln("      '${column.name}': ${column.name},");
      }
    }
    buffer.writeln("    };");
    buffer.writeln("  }");

    buffer.writeln("}");
  }
}

class QueriesGenerator {
  GeneratedFile generate(List<Query> queries, Catalog catalog) {
    final buffer = StringBuffer();

    buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
    buffer.writeln("// Generated by sqlc_dart");
    buffer.writeln();
    buffer.writeln("part of 'sqlc.dart';");
    buffer.writeln();

    // Generate query class
    buffer.writeln("class Queries {");
    buffer.writeln("  final Database _db;");
    buffer.writeln();
    buffer.writeln("  Queries(this._db);");
    buffer.writeln();

    for (final query in queries) {
      _generateQueryMethod(buffer, query, catalog);
      buffer.writeln();
    }

    buffer.writeln("}");

    return GeneratedFile(name: "queries.dart", contents: buffer.toString());
  }

  void _generateQueryMethod(StringBuffer buffer, Query query, Catalog catalog) {
    final methodName = query.methodName;

    // Generate SQL constant
    buffer.writeln("  // ${query.name}");
    buffer.writeln("  static const String ${methodName}Sql = r'''${query.text}''';");
    buffer.writeln();

    // Determine return type
    String returnType;
    String returnTypeName = '';
    if (query.isExec) {
      returnType = 'void';
    } else if (query.returnsOne) {
      returnTypeName = _getReturnTypeName(query, catalog);
      returnType = '$returnTypeName?';
    } else if (query.returnsMany) {
      returnTypeName = _getReturnTypeName(query, catalog);
      returnType = 'List<$returnTypeName>';
    } else {
      returnType = 'dynamic';
    }

    // Generate method signature
    buffer.write("  $returnType $methodName(");

    // Add parameters
    final paramNames = <String>[];
    if (query.params.isNotEmpty) {
      for (var i = 0; i < query.params.length; i++) {
        final param = query.params[i];
        final paramName = param.column.name.isEmpty ? 'param${param.number}' : param.column.name;
        paramNames.add(paramName);
        buffer.write("${param.column.dartType} $paramName");
        if (i < query.params.length - 1) buffer.write(", ");
      }
    }

    buffer.writeln(") {");

    // Generate method body
    if (query.isExec) {
      // Execute query without returning results
      if (paramNames.isEmpty) {
        buffer.writeln("    try {");
        buffer.writeln("      _db.execute(${methodName}Sql);");
        buffer.writeln("    } catch (e) {");
        buffer.writeln("      throw SqlcException('Error executing query $methodName', e);");
        buffer.writeln("    }");
      } else {
        buffer.writeln("    final stmt = _db.prepare(${methodName}Sql);");
        buffer.writeln("    try {");
        buffer.write("      stmt.execute([");
        buffer.write(paramNames.join(", "));
        buffer.writeln("]);");
        buffer.writeln("    } catch (e) {");
        buffer.writeln("      throw SqlcException('Error executing query $methodName', e);");
        buffer.writeln("    } finally {");
        buffer.writeln("      stmt.close();");
        buffer.writeln("    }");
      }
    } else if (query.returnsOne) {
      // Execute query and return single result
      if (paramNames.isEmpty) {
        buffer.writeln("    try {");
        buffer.writeln("      final result = _db.select(${methodName}Sql);");
        buffer.writeln("      if (result.isEmpty) return null;");
        buffer.writeln("      final row = result.first;");
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln("      return $returnTypeName.fromMap(row);");
        } else {
          buffer.writeln("      return row;");
        }
        buffer.writeln("    } catch (e) {");
        buffer.writeln("      throw SqlcException('Error executing query $methodName', e);");
        buffer.writeln("    }");
      } else {
        buffer.writeln("    final stmt = _db.prepare(${methodName}Sql);");
        buffer.writeln("    try {");
        buffer.write("      final result = stmt.select([");
        buffer.write(paramNames.join(", "));
        buffer.writeln("]);");
        buffer.writeln("      if (result.isEmpty) return null;");
        buffer.writeln("      final row = result.first;");
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln("      return $returnTypeName.fromMap(row);");
        } else {
          buffer.writeln("      return row;");
        }
        buffer.writeln("    } catch (e) {");
        buffer.writeln("      throw SqlcException('Error executing query $methodName', e);");
        buffer.writeln("    } finally {");
        buffer.writeln("      stmt.close();");
        buffer.writeln("    }");
      }
    } else if (query.returnsMany) {
      // Execute query and return multiple results
      if (paramNames.isEmpty) {
        buffer.writeln("    try {");
        buffer.writeln("      final result = _db.select(${methodName}Sql);");
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln("      return result.map((row) => $returnTypeName.fromMap(row)).toList();");
        } else {
          buffer.writeln("      return result.toList();");
        }
        buffer.writeln("    } catch (e) {");
        buffer.writeln("      throw SqlcException('Error executing query $methodName', e);");
        buffer.writeln("    }");
      } else {
        buffer.writeln("    final stmt = _db.prepare(${methodName}Sql);");
        buffer.writeln("    try {");
        buffer.write("      final result = stmt.select([");
        buffer.write(paramNames.join(", "));
        buffer.writeln("]);");
        if (_isTableType(returnTypeName, catalog)) {
          buffer.writeln("      return result.map((row) => $returnTypeName.fromMap(row)).toList();");
        } else {
          buffer.writeln("      return result.toList();");
        }
        buffer.writeln("    } catch (e) {");
        buffer.writeln("      throw SqlcException('Error executing query $methodName', e);");
        buffer.writeln("    } finally {");
        buffer.writeln("      stmt.close();");
        buffer.writeln("    }");
      }
    }

    buffer.writeln("  }");
  }

  bool _isTableType(String typeName, Catalog catalog) {
    final tables = catalog.getUserTables();
    return tables.any((table) => table.className == typeName);
  }

  String _getReturnTypeName(Query query, Catalog catalog) {
    if (query.columns.isEmpty) {
      return 'Map<String, dynamic>';
    }

    // Try to find matching table
    final tables = catalog.getUserTables();
    for (final table in tables) {
      if (_columnsMatchTable(query.columns, table.columns)) {
        return table.className;
      }
    }

    return 'Map<String, dynamic>';
  }

  bool _columnsMatchTable(List<Column> queryColumns, List<Column> tableColumns) {
    if (queryColumns.length != tableColumns.length) return false;

    for (var i = 0; i < queryColumns.length; i++) {
      if (queryColumns[i].name != tableColumns[i].name) return false;
    }

    return true;
  }
}

// ============================================================================
// Utility Functions
// ============================================================================

String _toPascalCase(String input) {
  if (input.isEmpty) return input;
  return input
      .split('_')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join('');
}

String _toCamelCase(String input) {
  if (input.isEmpty) return input;
  final pascal = _toPascalCase(input);
  return pascal[0].toLowerCase() + pascal.substring(1);
}
