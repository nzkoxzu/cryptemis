import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

Future<void> main() async {
  Directory directory = Directory('C:\\Users\\pc\\Desktop\\Dart\\a');
  Map<String, dynamic> structure = await exploreDirectory(directory);
  File outputFile = File('output.json');
  await outputFile.writeAsString(jsonEncode(structure));
}

Future<Map<String, dynamic>> exploreDirectory(Directory directory) async {
  Map<String, dynamic> result = {};

  List<FileSystemEntity> entities = await directory.list().toList();

  for (FileSystemEntity entity in entities) {
    String hash = sha256.convert(utf8.encode(entity.path)).toString();
    if (entity is File) {
      result[hash] = {'path': entity.path, 'type': 'file'};
      await entity.rename('${entity.parent.path}/$hash');
    } else if (entity is Directory) {
      result[hash] = {'path': entity.path, 'type': 'directory', 'content': await exploreDirectory(entity)};
      await entity.rename('${entity.parent.path}/$hash');
    }
  }

  return result;
}

