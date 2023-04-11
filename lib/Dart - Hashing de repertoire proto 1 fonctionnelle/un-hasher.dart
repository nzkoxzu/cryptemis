import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  String basePath = 'C:\\Users\\pc\\Desktop\\Dart\\a';
  File inputFile = File('output.json');
  String jsonString = await inputFile.readAsString();
  Map<String, dynamic> structure = jsonDecode(jsonString);
  await restoreOriginalNames(basePath, structure);
}

Future<void> restoreOriginalNames(String basePath, Map<String, dynamic> structure) async {
  for (String hash in structure.keys) {
    Map<String, dynamic> item = structure[hash];
    String originalPath = item['path'];
    String itemType = item['type'];
    String currentPath = basePath + '/' + hash;

    if (itemType == 'file') {
      await File(currentPath).rename(originalPath);
    } else if (itemType == 'directory') {
      await Directory(currentPath).rename(originalPath);
      await restoreOriginalNames(originalPath, item['content']);
    }
  }
}