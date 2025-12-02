# sqlc_gen_dart

A plugin for [SQLC](https://sqlc.dev/) that generates type-safe Dart code from SQL queries.

**[🇧🇷 Versão em Português](./README.md)**

## 🚀 Features

- ✅ **Type-safe**: Generates strongly-typed Dart code from your SQL queries
- ✅ **PostgreSQL and SQLite support**: Works with both databases
- ✅ **Automatic model generation**: Creates Dart classes for your tables automatically
- ✅ **Ready-to-use queries**: Async methods with built-in error handling
- ✅ **Connection management**: Configurable connection pool for PostgreSQL
- ✅ **Custom exceptions**: `SqlcException` for consistent error handling
- ✅ **Complex type support**: UUID, DateTime, nullable types and more

## 📦 Installation

### Prerequisites

1. **Dart SDK 3.10.0 or higher** - [Install Dart](https://dart.dev/get-dart)
2. **SQLC** - [Install SQLC](https://docs.sqlc.dev/en/latest/overview/install.html)

### Installing the Plugin

```bash
dart install sqlc_gen_dart
```

> **Note**: Starting with Dart 3.10.0, use `dart install` instead of `dart pub global activate`.

## 🔧 Configuration

Create a `sqlc.yaml` file in your project root:

### PostgreSQL

```yaml
version: "2"

plugins:
  - name: dart
    process:
      cmd: sqlc-gen-dart
      format: json

sql:
  - schema: "schema.sql"
    queries: "query.sql"
    engine: "postgresql"
    codegen:
      - plugin: dart
        out: lib/db
```

### SQLite

```yaml
version: "2"

plugins:
  - name: dart
    process:
      cmd: sqlc-gen-dart
      format: json

sql:
  - schema: "schema.sql"
    queries: "query.sql"
    engine: "sqlite"
    codegen:
      - plugin: dart
        out: lib/db
```

## 📝 Usage

### 1. Define your SQL schema

**schema.sql:**

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Write your queries

**query.sql:**

```sql
-- name: GetUserById :one
SELECT * FROM users WHERE id = $1 LIMIT 1;

-- name: ListUsers :many
SELECT * FROM users ORDER BY name;

-- name: InsertUser :one
INSERT INTO users (name, username, email, password)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: UpdateUser :exec
UPDATE users
SET name = COALESCE($2, name),
    username = COALESCE($3, username),
    email = COALESCE($4, email),
    password = COALESCE($5, password)
WHERE id = $1;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = $1;
```

### 3. Generate the code

```bash
sqlc generate
```

### 4. Use the generated code

**PostgreSQL:**

```dart
import 'package:your_app/db/sqlc_dart.dart';

void main() async {
  // Connect to database
  final db = SqlcDart('postgresql://user:password@localhost:5432/mydb');

  // Insert a user
  final user = await db.queries.insertUser(
    name: 'John Doe',
    username: 'johndoe',
    email: 'john@example.com',
    password: 'hashed_password',
  );

  print('User created: ${user.name}');

  // Get a user
  final foundUser = await db.queries.getUserById(id: user.id);
  print('User found: ${foundUser.email}');

  // List all users
  final users = await db.queries.listUsers();
  for (final u in users) {
    print('- ${u.name} (${u.username})');
  }

  // Update a user
  await db.queries.updateUser(
    id: user.id,
    name: 'John Smith',
    username: 'johndoe',
    email: 'john@example.com',
    password: 'new_hashed_password',
  );

  // Delete a user
  await db.queries.deleteUser(id: user.id);
}
```

**SQLite:**

```dart
import 'package:your_app/db/sqlc_dart.dart';

void main() async {
  // Connect to database
  final db = SqlcDart('myapp.db');

  // Use the same queries...
  final user = await db.queries.insertUser(
    name: 'Jane Smith',
    username: 'janesmith',
    email: 'jane@example.com',
    password: 'hashed_password',
  );
}
```

## 🎯 Generated Code

The plugin generates a single `sqlc_dart.dart` file containing:

- **Model classes**: Represent your tables with appropriate Dart types
- **`SqlcDart` class**: Manages database connection
- **`Queries` class**: Contains all methods to execute your queries
- **`SqlcException` class**: For consistent error handling
- **Custom types**: Like `Uuid` with validation

### Example of generated class:

```dart
class User {
  final Uuid id;
  final String name;
  final String username;
  final String email;
  final String password;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) { /* ... */ }
  Map<String, dynamic> toMap() { /* ... */ }
}
```

## ⚙️ Advanced Configuration

### Connection Pool (PostgreSQL)

The plugin automatically configures a connection pool with default values:

- `max_connection_count`: 10
- `max_connection_age`: 3600 seconds

You can customize via connection URL:

```dart
final db = SqlcDart(
  'postgresql://user:password@localhost:5432/mydb?max_connection_count=20&max_connection_age=7200'
);
```

## 🛠️ Dependencies

The generated code requires the following dependencies in your `pubspec.yaml`:

**For PostgreSQL:**

```yaml
dependencies:
  postgres: ^3.0.0
```

**For SQLite:**

```yaml
dependencies:
  sqlite3: ^2.0.0
```

## 📚 Additional Resources

- [SQLC Documentation](https://docs.sqlc.dev/)
- [Examples](./example)
- [Changelog](./CHANGELOG.md)

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or pull requests.

## 📄 License

This project is licensed under the MIT License.
