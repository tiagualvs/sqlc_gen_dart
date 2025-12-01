import 'dart:convert';
import 'dart:io';

import 'package:sqlc_dart/sqlc_dart.dart';

Future<void> main(List<String> args) async {
  final input = await stdin.transform(utf8.decoder).join();
  final output = await generateFromSqlcInput(input);
  return stdout.write(output);
}
