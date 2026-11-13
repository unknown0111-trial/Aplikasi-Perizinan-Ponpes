import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  static String generateSalt([int length = 16]) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  static bool verify(String password, String salt, String expectedHash) =>
      hash(password, salt) == expectedHash;
}
