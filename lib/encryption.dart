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

Future<List<int>> nonceGen(Cipher alg) async {
  /*
  generate a nonce
  */
  var nonce = alg.newNonce();
  return nonce;
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

void exportConfig(String nonce, String salt, String map, String directory){
  /*
  Exports the config
  */
  var config = {"nonce": nonce, "salt": salt, "hierarchy": map};
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

//void cipherFile(Cipher alg, SecretKey key, List<int> nonce, String file_to_treat, String file_to_write) async {
//}
//
//void decipherFile(Cipher alg, SecretKey key, List<int> nonce, String file_to_treat, String file_to_write) async {
//}

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

//void decipherDirectory(String algorithm, String password, String directory) async {
//  final alg = callAlg(algorithm);
//  final nonce = hexToBytes(await importData("nonce", directory));
//  final salt = hexToBytes(await importData("salt", directory));
//  final ciphermap = await importData("hierarchy", directory);
//  final map = await decipherData(alg, key, ciphermap);
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//}
//
//void cipherDirectory(String algorithm, String password, String directory) async {
//  final alg = callAlg(algorithm);
//  final nonce = hexToBytes(await importData("nonce", directory));
//  final salt = hexToBytes(await importData("salt", directory));
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//  final ciphermap = await importData("hierarchy", directory);
//  final map = await decipherData(alg, key, ciphermap);
//  final map_to_compare = await fileHierarchy(directory);
//  if (map =! map_to_compare) {
//    final ciphermap = await cipherData(alg, key, json.encode(map_to_compare));
//    updateConfig(algorithm, password, new String.fromCharCodes(ciphermap.concatenation()), directory);
//  }
//}
//
//void updateConfig(String algorithm, String nonce, String salt, String password, String map, String directory) async {
//  final alg = callAlg(algorithm);
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//  exportConfig(bytesToHex(nonce), bytesToHex(salt), map, directory);
//}
//
//void createConfig(String algorithm, String password, String directory) async {
//  final alg = callAlg(algorithm);
//  final nonce = await nonceGen(alg);
//  final salt = await nonceGen(alg);
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//  final map = await fileHierarchy(directory);
//  final ciphermap = await cipherData(alg, key, json.encode(map));
//  exportConfig(bytesToHex(nonce), bytesToHex(salt), new String.fromCharCodes(ciphermap.concatenation()), directory);
//}

void main() async {
  final alg = callAlg("AES-CTR-256bits");
  final nonce = await nonceGen(alg);
  final salt = await nonceGen(alg);
  final password = await getHash("LaMèreMichel", salt);
  final key = await keyGen(alg, password);
  final map = await fileHierarchy("intro/");
  final ciphermap = await cipherData(alg, key, json.encode(map));
  exportConfig(bytesToHex(nonce), bytesToHex(salt), new String.fromCharCodes(ciphermap.concatenation()), "intro");
  final map_from_file = await importData("hierarchy", "intro");
  final clearmap = await decipherData(alg, key, map_from_file);
  print(clearmap);
}

