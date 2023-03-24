import 'dart:convert';
import 'package:kyber/kyber.dart';
import 'package:pointycastle/pointycastle.dart';

String encryptRSA(String plaintext, String publicKey) {
  final publicKeyBytes = base64.decode(publicKey);

  final rsaPublicKey = RSAPublicKeyParser().parse(publicKeyBytes);

  final plaintextBytes = utf8.encode(plaintext);

  final encryptor = RSAEngine()
    ..init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
  final ciphertext = encryptor.process(plaintextBytes);

  final ciphertextData = base64.encode(ciphertext);

  return ciphertextData;
}

String encryptAES(String plaintext, String key) {
  final keyBytes = base64.decode(key);

  final aesKey = KeyParameter(keyBytes);
  final aesCipher = BlockCipher('AES')..init(true, aesKey);

  final plaintextBytes = utf8.encode(plaintext);

  final paddedPlaintext =
      PKCS7Padding().pad(plaintextBytes, aesCipher.blockSize);
  final ciphertext = aesCipher.process(paddedPlaintext);

  final ciphertextData = base64.encode(ciphertext);

  return ciphertextData;
}

String encryptKyber(String plaintext, String publicKey) {
  final publicKeyBytes = base64.decode(publicKey);

  final kyber = Kyber(publicKey: publicKeyBytes);

  final plaintextBytes = utf8.encode(plaintext);

  final ciphertext = kyber.encrypt(plaintextBytes);

  final ciphertextData = base64.encode(ciphertext);

  return ciphertextData;
}