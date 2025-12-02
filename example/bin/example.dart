import 'package:example/db/sqlc_dart.dart';

void main(List<String> arguments) async {
  // final sqlc = SqlcDart(SqliteMemory());
  final sqlc = SqlcDart('postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable');

  final user = await sqlc.queries.insertUser(
    name: 'Tiago',
    username: 'tiagualvs',
    email: 'tiago@gmail.com',
    password: 'Abc@123',
  );

  print([user.id, user.name, user.username, user.email, user.password, user.createdAt, user.updatedAt]);
}
