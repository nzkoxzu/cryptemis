import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:crypto/crypto.dart';

// required imports
import 'dart:ffi';
import 'package:sodium/sodium.dart';

// load the dynamic library into dart
final libsodium = DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsodium.so.23');
//final libsodium = DynamicLibrary.open('libsodium.dll');

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

Future<List<int>> sodiumCipher(
  List<int> key,
  List<int> data,
  List<int> nonce,
  bool cipher,
) async {
  // initialize the sodium APIs
  final sodium = await SodiumInit.init(libsodium);
  var secureKey = SecureKey.fromList(sodium, Uint8List.fromList(key));

  Uint8List bytes;
  if (cipher) {
    // ciphers the data
    bytes = sodium.crypto.secretBox.easy(
      message: Uint8List.fromList(data),
      nonce: Uint8List.fromList(nonce),
      key: secureKey,
    );
  } else {
    // deciphers the data
    bytes = sodium.crypto.secretBox.openEasy(
      cipherText: Uint8List.fromList(data),
      nonce: Uint8List.fromList(nonce),
      key: secureKey,
    );
  }
  // Since these keys wrap native memory, it is mandatory that you dispose of them after you are done with a key, as otherwise they will leak memory.
  secureKey.dispose();
  return bytes;
}

Future<List<int>> tacos(
  List<int> key,
  List<int> data,
  List<int> nonce,
  int version,
  bool cipher,
) async {
  if (version == 0) {
    return await sodiumCipher(key, data, nonce, cipher);
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
  var fileStructure = input.list(recursive: true, followLinks: false);
  await for (var entity in fileStructure) {
    var isFile = await FileSystemEntity.isFile(entity.path);
    if (isFile) {
      var filename = getPath(entity.path, input.path);
      var file = File(entity.path);
      var newFile = File(output.path + filename);

      if (await newFile.exists()) {
        await newFile.delete();
      }
      await newFile.create(recursive: true);
      var readStream = file.openRead();
      var writeStream = newFile.openWrite();
      var cipherStream = StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) async {
        List<int> transformed = await tacos(
          key,
          data,
          nonce,
          version,
          cipher,
        );
        sink.add(transformed);
      });
      await readStream.transform(cipherStream).pipe(writeStream);
      await writeStream.close();
    }
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
    if (cipher) {
      Directory directory = output;
      Map<String, dynamic> structure =
          await exploreDirectory(directory, directory.path, isRoot: true);
      File outputFile = File('output.json');
      await outputFile.writeAsString(jsonEncode(structure));
    } else {
      File inputFile = File('output.json');
      String jsonString = await inputFile.readAsString();
      Map<String, dynamic> structure = jsonDecode(jsonString);
      await restoreOriginalNames(output.path, structure);
    }
  } catch (e) {
    print('Error: $e');
    throw Exception("whoops");
  }
}

Future<SecureKey> keygen(Int8List password, Uint8List salt) async {
  // initialize the sodium APIs
  final sodium = await SodiumInit.init(libsodium);

  // generate a key from the password
  var key = sodium.crypto.pwhash(
    outLen: sodium.crypto.secretBox.keyBytes,
    password: password,
    salt: salt,
    opsLimit: sodium.crypto.pwhash.opsLimitInteractive,
    memLimit: sodium.crypto.pwhash.memLimitInteractive,
  );

  return key;
}

Future<Uint8List> saltGen() async {
  // initialize the sodium APIs
  final sodium = await SodiumInit.init(libsodium);
  // generate a nonce
  var salt = sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes);
  return salt;
}

Future<List<int>> nonceGen() async {
  // initialize the sodium APIs
  final sodium = await SodiumInit.init(libsodium);
  // generate a nonce
  var nonce = sodium.randombytes.buf(
    sodium.crypto.secretBox.nonceBytes,
  );
  return nonce;
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

Uint8List hexToBytesForSalt(String hex) {
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return bytes;
}

Future<Map<String, dynamic>> exploreDirectory(
    Directory directory, String basePath,
    {bool isRoot = true}) async {
  Map<String, dynamic> result = {};

  List<FileSystemEntity> entities = await directory.list().toList();

  for (FileSystemEntity entity in entities) {
    String hash = sha256.convert(utf8.encode(entity.path)).toString();
    String relativePath = path.relative(entity.path, from: basePath);

    if (entity is File) {
      // Remove any unnecessary directory parts from the path
      relativePath = path.basename(relativePath);
      result[hash] = {'path': relativePath, 'type': 'file'};
      await entity.rename(path.join(entity.parent.path, hash));
    } else if (entity is Directory) {
      // If the current directory is not the root directory, remove the parent directory part from the path
      if (!isRoot) {
        relativePath = path.basename(relativePath);
      }
      result[hash] = {
        'path': relativePath,
        'type': 'directory',
        'content': await exploreDirectory(entity, basePath, isRoot: false)
      };
      await entity.rename(path.join(entity.parent.path, hash));
    }
  }

  return result;
}

Future<void> restoreOriginalNames(
    String currentBasePath, Map<String, dynamic> structure) async {
  for (String hash in structure.keys) {
    Map<String, dynamic> item = structure[hash];
    String originalPath = item['path'];
    String itemType = item['type'];
    String currentPath = path.join(currentBasePath, hash);
    String newOriginalPath = path.join(currentBasePath, originalPath);

    if (itemType == 'file') {
      await File(currentPath).rename(newOriginalPath);
    } else if (itemType == 'directory') {
      await Directory(currentPath).rename(newOriginalPath);

      await restoreOriginalNames(newOriginalPath, item['content']);
    }
  }
}

Map exportConfig(String nonce, String salt){
  var config = {"nonce": nonce, "salt": salt};
  File outputFile = File('config.json');
  outputFile.writeAsString(jsonEncode(config));
  return config;
}

Future<List<int>> importNonce() async {
  File inputFile = File('config.json');
  var content = await inputFile.readAsString();
  var data = json.decode(content);
  return hexToBytes(data["nonce"]);
}

Future<Uint8List> importSalt() async {
  File inputFile = File('config.json');
  var content = await inputFile.readAsString();
  var data = json.decode(content);
  return hexToBytesForSalt(data["salt"]);
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i')
    ..addOption('output', abbr: 'o')
    ..addOption('password', abbr: 'p');

  ArgResults args = parser.parse(arguments);
  var isInput = await Directory(args['input']).exists();
  if (!isInput) {
    throw Exception('input not found');
  }

  var input = args['input'];
  var output = args['output'];
  var password = Int8List.fromList(args['password'].codeUnits);
  //FIXME absolute path vs relative
  print(input + " " + output);

  var salt = await saltGen();
  var key = await keygen(password, salt);
  var nonce = await nonceGen();

  await cipher(
    Directory(input),
    Directory(output),
    key.extractBytes(),
    nonce,
    0,
    true,
  );

  await cipher(
    Directory(output),
    Directory("output"),
    key.extractBytes(),
    nonce,
    0,
    false,
  );

  key.dispose();
}

