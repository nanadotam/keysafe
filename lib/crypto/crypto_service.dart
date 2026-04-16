import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class CryptoService {
  static Uint8List deriveKey({
    required String masterPassword,
    required String salt,
    int iterations = 100000,
    int keyLength = 32,
  }) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(
      Uint8List.fromList(utf8.encode(salt)),
      iterations,
      keyLength,
    ));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(masterPassword)));
  }

  static String encrypt(String plaintext, Uint8List key) {
    final iv = _randomBytes(12);
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
    );
    final input = Uint8List.fromList(utf8.encode(plaintext));
    final ciphertext = cipher.process(input);
    final combined = Uint8List(12 + ciphertext.length);
    combined.setRange(0, 12, iv);
    combined.setRange(12, combined.length, ciphertext);
    return base64Encode(combined);
  }

  static String decrypt(String ciphertextB64, Uint8List key) {
    final combined = base64Decode(ciphertextB64);
    final iv = combined.sublist(0, 12);
    final ciphertext = combined.sublist(12);
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
    );
    final plaintext = cipher.process(ciphertext);
    return utf8.decode(plaintext);
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => rng.nextInt(256)),
    );
  }

  static int calculateStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 15;
    if (password.length >= 16) score += 10;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 15;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 10;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 15;
    return score.clamp(0, 100);
  }
}
