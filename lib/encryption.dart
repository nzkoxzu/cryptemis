import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

Cipher callAlg(String algchoice){
  /*
  Allows user to select a prefered algorithm
  */
  if (algchoice == "Xchacha20") {
    final alg = Xchacha20(macAlgorithm: Hmac.sha256());
    return alg;
  } else if (algchoice == "AES-CTR-256bits") {
    final alg = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
    return alg;
  } else {
    final alg = Xchacha20(macAlgorithm: Hmac.sha256());
    return alg;
  }
}

Future<List<int>> getHash(String password, List<int> salt) async {
  /*
  generate a salted hash of the user's password
  */
  final algorithm = Sha256();
  List<int> values = [];
  for (int i = 0; i < password.length; i++) {
    values.add(password.codeUnitAt(i));
  }
  final hash = await algorithm.hash(values+salt);
  return hash.bytes;
}

Future<SecretKey> keyGen(Cipher alg, List<int> password) async {
  /*
  generate a key from user's salted hash
  */
  var key = await alg.newSecretKeyFromBytes(password);
  return key;
}

String bytesToHex(List<int> bytes) {
  /*
  Makes a string for the conf file
  */
  final hexDigits = '0123456789ABCDEF';
  final chars = List<String>.from(
    bytes.map((byte) => hexDigits[(byte >> 4) & 0x0f] + hexDigits[byte & 0x0f]),
  );
  return chars.join('');
}

List<int> hexToBytes(String hex) {
  /*
  Makes a string from the conf file into usable data
  */
  final bytes = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return bytes;
}

void exportConfig(String alg, String salt, String map, String directory){
  /*
  Exports the config
  */
  var config = {"algorithm": alg, "salt": salt, "hierarchy": map};
  if (directory == ""){
    File file = File('.cryptemis');
    file.writeAsString(jsonEncode(config));
  } else {
    File file = File(directory+'/.cryptemis');
    file.writeAsString(jsonEncode(config));
  }
  return null;
}

Future<String> importData(String data_to_import, String directory) async {
  /*
  Import selected data from the config
  */
  if (directory == ""){
    File file = File('.cryptemis');
    var content = await file.readAsString();
    var data = json.decode(content);
    return data[data_to_import];
  } else {
    File file = File(directory+'/.cryptemis');
    var content = await file.readAsString();
    var data = json.decode(content);
    return data[data_to_import];
  }
}

Future<Map<String, Map<String, String>>> fileHierarchy(String directoryPath) async {
  /*
  Gets the file hierarchy recursively
  */
  final Map<String, Map<String, String>> files = {};

  final Directory directory = Directory(directoryPath);
  final List<FileSystemEntity> entities = directory.listSync();

  final algorithm = Sha256();

  for (final FileSystemEntity entity in entities) {
    if (entity is File) {
      List<int> values = [];
      for (int i = 0; i < entity.path.length; i++) {
        values.add(entity.path.codeUnitAt(i));
      }
      final data = await algorithm.hash(values);
      final fileName = entity.uri.pathSegments.last;
      if (fileName != '.cryptemis') {
        files[fileName] = {entity.path: bytesToHex(data.bytes)};
      }
    } else if (entity is Directory) {
      final subdirectoryFiles = await fileHierarchy(entity.path);
      files.addAll(subdirectoryFiles);
    }
  }
  return files;
}

void deleteDirectories(String directoryPath){
  final Directory directory = Directory(directoryPath);
  final List<FileSystemEntity> entities = directory.listSync();

  for (final FileSystemEntity entity in entities) {
    if (entity is Directory) {
      new Directory(entity.path).delete(recursive: true);
    }
  }
}

Future<void> cipherFile(Cipher alg, SecretKey key, String file_to_read, String file_to_write) async {
  final file = await File(file_to_read);
  final encrypted_file = await File(file_to_write).create(recursive: true);

  final data_file = await file.readAsString();
  file.delete();
  final cipherdata_file = await cipherData(alg, key, data_file);

  encrypted_file.writeAsString(new String.fromCharCodes(cipherdata_file.concatenation()));
}

Future<void> decipherFile(Cipher alg, SecretKey key, String file_to_read, String file_to_write) async {
  final file = await File(file_to_read);
  final decrypted_file = await File(file_to_write).create(recursive: true);

  final data_file = await file.readAsString();
  file.delete();
  final cleardata_file = await decipherData(alg, key, data_file);

  decrypted_file.writeAsString(cleardata_file);
}

Future<SecretBox> cipherData(Cipher alg, SecretKey key, String data) async {
  /*
  Cipher selected data for the config file
  */
  final ciphertext = await alg.encryptString(data, secretKey: key);
  return ciphertext;
}

Future<String> decipherData(Cipher alg, SecretKey key, String msg) async {
  /*
  Deipher selected data from the config file
  */
  List<int> secretbox = [];
  for (int i = 0; i < msg.length; i++) {
    secretbox.add(msg.codeUnitAt(i));
  }
  final data = await SecretBox.fromConcatenation(secretbox, nonceLength: alg.nonceLength, macLength: alg.macAlgorithm.macLength);
  final cleartext = await alg.decryptString(data, secretKey: key);
  return cleartext;
}

Future<int> decipherDirectory(String password, String directory) async {
  final alg = callAlg(await importData("algorithm", directory));
  final salt = hexToBytes(await importData("salt", directory));
  final hash = await getHash(password, salt);
  final key = await keyGen(alg, hash);
  final ciphermap = await importData("hierarchy", directory);
  try {
    final map = jsonDecode(await decipherData(alg, key, ciphermap));
    for (var i in map.keys){
      for (var k in map[i].keys){
        await decipherFile(alg, key, directory+"/"+map[i][k], k);
      }
    }
    return 0;
  } catch (e) {
    return 1;
  }
}

Future<int> cipherDirectory(String password, String directory) async {
  final algorithm = await importData("algorithm", directory);
  final alg = callAlg(algorithm);
  final salt = hexToBytes(await importData("salt", directory));
  final hash = await getHash(password, salt);
  final key = await keyGen(alg, hash);
  final ciphermap = await importData("hierarchy", directory);
  try {
    var map = jsonDecode(await decipherData(alg, key, ciphermap));
    var map_to_compare = await fileHierarchy(directory);
    if (map!(map_to_compare)) {
      final ciphermap = await cipherData(alg, key, json.encode(map_to_compare));
      updateConfig(await bytesToHex(salt), password, new String.fromCharCodes(ciphermap.concatenation()), directory);
    }
    for (var i in map.keys){
      for (var k in map[i].keys){
        await cipherFile(alg, key, k, directory+"/"+map[i][k]);
      }
    }
    return 0;
  }catch (e) {
    return 1;
  }
}

void updateConfig(String salt, String password, String map, String directory) async {
  exportConfig(await importData("algorithm", directory), salt, map, directory);
}

void createConfig(String algorithm, String password, String directory) async {
  final alg = callAlg(algorithm);
  final salt = alg.newNonce();
  final hash = await getHash(password, salt);
  final key = await keyGen(alg, hash);
  final map = await fileHierarchy(directory);
  final ciphermap = await cipherData(alg, key, json.encode(map));
  exportConfig(algorithm, bytesToHex(salt), new String.fromCharCodes(ciphermap.concatenation()), directory);
}

