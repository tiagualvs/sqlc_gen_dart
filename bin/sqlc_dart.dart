import 'dart:convert';
import 'dart:io';

import 'package:sqlc_dart/sqlc_dart.dart';

Future<void> main(List<String> args) async {
  final bytes = await stdin.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
  final input = utf8.decode(bytes, allowMalformed: true);
  final output = await generateFromSqlcInput(input);
  stdout.write(output);
}
