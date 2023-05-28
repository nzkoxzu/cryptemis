import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:cryptography/cryptography.dart';

String getPath(String path, String name) {
  var index = path.indexOf(name);
  if (index == -1) {
    throw 'getpath failed';
  }
  return path.substring(index + name.length);
}

Future<void> directories(Directory input, Directory output) async {
  var structure = input.list(recursive: true, followLinks: false);
  await for (var entity in structure) {
    var isDirectory = await FileSystemEntity.isDirectory(entity.path);
    if (isDirectory) {
      var folderName = getPath(entity.path, input.path);
      await Directory(output.path + folderName).create(recursive: true);
    }
  }
}

Future<List<int>> tacos(
  List<int> key,
  List<int> data,
  List<int> nonce,
  int version,
  bool cipher,
) async {
  if (version == 0) {
  }
  throw Exception("no tacos");
}

Future<void> files(
  Directory input,
  Directory output,
  List<int> key,
  List<int> nonce,
  int version,
  bool cipher,
) async {
  try {
  } catch (e) {
    print('Error: $e');
    throw Exception("whoops");
  }
}

Future<void> cipher(
  Directory input,
  Directory output,
  List<int> key,
  List<int> nonce,
  int version,
  bool cipher,
) async {
  try {
    await directories(input, output);
    await files(input, output, key, nonce, version, cipher);
  } catch (e) {
    print('Error: $e');
    throw Exception("whoops");
  }
}

Future<SecretKey> keyGen(Cipher alg, List<int> password) async {
  var key = await alg.newSecretKeyFromBytes(password);
  return key;
}

Future<List<int>> nonceGen(Cipher alg) async {
  // generate a nonce
  var nonce = alg.newNonce();
  return nonce;
}

Cipher callAlg(String algchoice){
  if (algchoice == "Xchacha20") {
    final alg = Xchacha20(macAlgorithm: Hmac.sha256());
    return alg;
  } else {
    final alg = Xchacha20(macAlgorithm: Hmac.sha256());
    return alg;
  }
}

Future<List<int>> getHash(String password, List<int> salt) async {
  final algorithm = Sha256();
  List<int> values = [];
  for (int i = 0; i < password.length; i++) {
    values.add(password.codeUnitAt(i));
  }
  final hash = await algorithm.hash(values+salt);
  print(hash.bytes);
  return hash.bytes;
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

Map exportConfig(String nonce, String salt){
  var config = {"nonce": nonce, "salt": salt};
  File outputFile = File('.cryptemis');
  outputFile.writeAsString(jsonEncode(config));
  return config;
}

Future<List<int>> importData(String data_to_import) async {
  File inputFile = File('.cryptemis');
  var content = await inputFile.readAsString();
  var data = json.decode(content);
  return hexToBytes(data[data_to_import]);
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('password', abbr: 'p');

  ArgResults args = parser.parse(arguments);

  final alg = callAlg("Xchacha20");
  final nonce = await nonceGen(alg);
  final salt = await nonceGen(alg);
  exportConfig(bytesToHex(nonce), bytesToHex(salt));
  final password = await getHash(args['password'], salt);
  final key = await keyGen(alg, password);
  final password2 = await getHash(args['password'], await importData("salt"));
  final key2 = await keyGen(alg, password);
}

