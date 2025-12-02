import 'package:example/db/sqlc_dart.dart';

void main(List<String> arguments) async {
  final sqlc = SqlcDart(SqliteMemory());

  await sqlc.queries.insertOneUser(name: 'Tiago', username: 'tiagualvs', email: 'tiago@gmail.com', password: 'Abc@123');

  await sqlc.queries.findManyUsers();

  await sqlc.queries.findOneUserByEmail(email: 'tiago@gmail.com');

  await sqlc.queries.findOneUserById(id: 1);

  await sqlc.queries.updateOneUser(
    id: 1,
    name: 'Tiago',
    username: 'tiagualvs',
    email: 'tiago@gmail.com',
    password: 'Abc@123',
  );

  await sqlc.queries.deleteOneUser(id: 1);
}
