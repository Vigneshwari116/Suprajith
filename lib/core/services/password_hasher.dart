import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 of [saltBytes] concatenated with UTF-8 [password], base64-encoded.
String hashPasswordBase64(List<int> saltBytes, String password) {
  final combined = [...saltBytes, ...utf8.encode(password)];
  return base64Encode(sha256.convert(combined).bytes);
}

bool verifyPasswordHash({
  required String password,
  required String saltBase64,
  required String expectedHashBase64,
}) {
  final salt = base64Decode(saltBase64);
  final actual = hashPasswordBase64(salt, password);
  return actual == expectedHashBase64;
}
