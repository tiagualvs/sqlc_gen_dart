import 'package:example/db/sqlc_dart.dart';

void main(List<String> arguments) async {
  final sqlc = SqlcDart(SqliteMemory());

  await sqlc.queries.insertUser(name: 'Tiago', username: 'tiagualvs', email: 'tiago@gmail.com', password: 'Abc@123');

  await sqlc.queries.listUsers();

  await sqlc.queries.getUserByEmail(email: 'tiago@gmail.com');

  await sqlc.queries.getUserById(id: 1);

  await sqlc.queries.updateUser(
    id: 1,
    name: 'Tiago',
    username: 'tiagualvs',
    email: 'tiago@gmail.com',
    password: 'Abc@123',
  );

  await sqlc.queries.deleteUser(id: 1);
}
