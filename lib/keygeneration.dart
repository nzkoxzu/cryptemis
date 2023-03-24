import 'dart:convert';
import 'package:kyber/kyber.dart';
import 'package:pointycastle/export.dart';

void generateAndExportRSAKeys() {
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        SecureRandom()));

  final keyPair = keyGen.generateKeyPair();

  final privateKey = keyPair.privateKey as RSAPrivateKey;
  final privateKeyData = privateKey.toPEM(true);

  final publicKey = keyPair.publicKey as RSAPublicKey;
  final publicKeyData = publicKey.toPEM();
}

void generateAndExportAESKey() {
  final keyGen = KeyGenerator('AES')..init(256);

  final aesKey = keyGen.generateKey();

  final aesKeyData = base64.encode(aesKey.bytes);
}

void generateAndExportKyberKeys() {
  final keyPair = Kyber().generateKeyPair();

  final publicKeyData = base64.encode(keyPair.publicKey);

  final privateKeyData = base64.encode(keyPair.privateKey);
}