# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-02

### Added

- Initial release of sqlc_gen_dart plugin
- Support for generating Dart code from SQL queries
- SQLite database support with in-memory and file-based configurations
- PostgreSQL database support with URI-based and connection object configurations
- Automatic schema generation from SQL DDL statements
- Type-safe query methods generation
- CRUD operations support (Create, Read, Update, Delete)
- Custom `SqlcException` for unified error handling
- Automatic database connection management
- Support for multiple query types (`:one`, `:many`, `:exec`)
- Pluralization support for table names
- MIT License

### Features

- **Database Support**: SQLite and PostgreSQL
- **Query Generation**: Generates type-safe Dart methods from SQL queries
- **Schema Generation**: Automatically generates Dart classes from SQL tables
- **Error Handling**: Custom exception handling with `SqlcException`
- **Connection Management**: Automatic database connection and disposal

[1.0.0]: https://github.com/tiagualvs/sqlc_gen_dart/releases/tag/v1.0.0
