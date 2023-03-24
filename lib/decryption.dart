import 'dart:convert';
import 'package:kyber/kyber.dart';
import 'package:pointycastle/pointycastle.dart';

String decryptRSA(String ciphertext, String privateKey) {
  final privateKeyBytes = base64.decode(privateKey);

  final rsaPrivateKey = RSAKeyParser().parse(privateKeyBytes);

  final ciphertextBytes = base64.decode(ciphertext);

  final decryptor = RSAEngine()
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));
  final plaintext = decryptor.process(ciphertextBytes);

  final plaintextData = utf8.decode(plaintext);

  return plaintextData;
}

String decryptAES(String ciphertext, String key) {
  final keyBytes = base64.decode(key);

  final aesKey = KeyParameter(keyBytes);
  final aesCipher = BlockCipher('AES')..init(false, aesKey);

  final ciphertextBytes = base64.decode(ciphertext);

  final paddedPlaintext = aesCipher.process(ciphertextBytes);
  final plaintextBytes = PKCS7Padding().strip(paddedPlaintext);

  final plaintextData = utf8.decode(plaintextBytes);

  return plaintextData;
}

String decryptKyber(String ciphertext, String privateKey) {
  final privateKeyBytes = base64.decode(privateKey);

  final kyber = Kyber(privateKey: privateKeyBytes);

  final ciphertextBytes = base64.decode(ciphertext);

  final plaintext = kyber.decrypt(ciphertextBytes);

  final plaintextData = utf8.decode(plaintext);

  return plaintextData;
}