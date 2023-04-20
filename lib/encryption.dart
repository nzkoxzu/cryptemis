import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
// required imports
import 'dart:ffi';
import 'package:sodium/sodium.dart';
 
// load the dynamic library into dart
final libsodium = DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsodium.so');
 
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
  } catch (e) {
    throw Exception("whoops");
  }
}

Future<SecureKey> keygen() async {
  // initialize the sodium APIs
  final sodium = await SodiumInit.init(libsodium);
 
  // generate a key
  var key = sodium.crypto.secretBox.keygen();
  return key;
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

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i')
    ..addOption('output', abbr: 'o');
 
  ArgResults args = parser.parse(arguments);
  var isInput = await Directory(args['input']).exists();
  if (!isInput) {
    throw Exception('input not found');
  }
 
  var input = args['input'];
  var output = args['output'];
  //FIXME absolute path vs relative
  print(input + " " + output);
 
  var key = await keygen();
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