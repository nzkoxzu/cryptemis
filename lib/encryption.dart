import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

Cipher callAlg(String algchoice){
  if (algchoice == "Xchacha20") {
    final alg = Xchacha20(macAlgorithm: Hmac.sha256());
    return alg;
  } else {
    final alg = Xchacha20(macAlgorithm: Hmac.sha256());
    return alg;
  }
}

Future<List<int>> nonceGen(Cipher alg) async {
  // generate a nonce
  var nonce = alg.newNonce();
  return nonce;
}

Future<List<int>> getHash(String password, List<int> salt) async {
  final algorithm = Sha256();
  List<int> values = [];
  for (int i = 0; i < password.length; i++) {
    values.add(password.codeUnitAt(i));
  }
  final hash = await algorithm.hash(values+salt);
  return hash.bytes;
}

Future<SecretKey> keyGen(Cipher alg, List<int> password) async {
  var key = await alg.newSecretKeyFromBytes(password);
  return key;
}

String bytesToHex(List<int> bytes) {
  final hexDigits = '0123456789ABCDEF';
  final chars = List<String>.from(
    bytes.map((byte) => hexDigits[(byte >> 4) & 0x0f] + hexDigits[byte & 0x0f]),
  );
  return chars.join('');
}

List<int> hexToBytes(String hex) {
  final bytes = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return bytes;
}

void exportConfig(String nonce, String salt, String directory){
  var config = {"nonce": nonce, "salt": salt};
  if (directory == ""){
    File file = File('.cryptemis');
    file.writeAsString(jsonEncode(config));
  } else {
    File file = File(directory+'/.cryptemis');
    file.writeAsString(jsonEncode(config));
  }
  return null;
}

Future<List<int>> importData(String data_to_import, String directory) async {
  if (directory == ""){
    File file = File('.cryptemis');
    var content = await file.readAsString();
    var data = json.decode(content);
    return hexToBytes(data[data_to_import]);
  } else {
    File file = File(directory+'/.cryptemis');
    var content = await file.readAsString();
    var data = json.decode(content);
    return hexToBytes(data[data_to_import]);
  }
}

Future<String> fileHierarchy(String directory) async {
  final dir = Directory(directory);
  final List<FileSystemEntity> entities = await dir.list().toList();
  print(entities);
  return directory;
}

//void decipherDirectory(String algorithm, String password, String directory) async {
//  final alg = callAlg(algorithm);
//  final nonce = await importData("nonce", directory);
//  final salt = await importData("salt", directory);
//  final map = await importData("hierarchy", directory);
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//}
//
//void cipherDirectory(String algorithm, String password, String directory) async {
//  final alg = callAlg(algorithm);
//  final nonce = await importData("nonce", directory);
//  final salt = await importData("salt", directory);
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//  final map = await importData("hierarchy", directory);
//  final map_to_compare = await fileHierarchy(directory);
//  if (map =! map_to_compare) {
//    updateConfig(algorithm, password, directory);
//  }
//  final key = await keyGen(alg, password);
//}
//
//void updateConfig(String algorithm, String password, String directory) async {
//  final alg = callAlg(algorithm);
//  final nonce = await importData("nonce", directory);
//  final salt = await importData("salt", directory);
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//  final map = await fileHierarchy(directory);
//  exportConfig(bytesToHex(nonce), bytesToHex(salt), directory);
//}
//
//void createConfig(String algorithm, String password, String directory) async {
//  final alg = callAlg(algorithm);
//  final nonce = await nonceGen(alg);
//  final salt = await nonceGen(alg);
//  final hash = await getHash(password, salt);
//  final key = await keyGen(alg, hash);
//  final map = await fileHierarchy(directory);
//  exportConfig(bytesToHex(nonce), bytesToHex(salt), map, directory);
//}

void main(List<String> arguments) async {
  final alg = callAlg("Xchacha20");
  final nonce = await nonceGen(alg);
  final salt = await nonceGen(alg);
  exportConfig(bytesToHex(nonce), bytesToHex(salt), "");
  final password = await getHash("LaMèreMichel", salt);
  final key = await keyGen(alg, password);
  final map = await fileHierarchy("../../cryptemis");
}

