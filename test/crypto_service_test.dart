import 'package:flutter_test/flutter_test.dart';
import 'package:keysafe/crypto/crypto_service.dart';

void main() {
  group('CryptoService', () {
    test('encrypt/decrypt round-trip', () {
      final key = CryptoService.deriveKey(
        masterPassword: 'test-master-password',
        salt: 'test-user-id-12345',
      );

      const plaintext = 'my-super-secret-password-123!';
      final ciphertext = CryptoService.encrypt(plaintext, key);
      final decrypted = CryptoService.decrypt(ciphertext, key);

      expect(decrypted, equals(plaintext));
    });

    test('two encryptions of same text produce different ciphertexts (IV randomness)', () {
      final key = CryptoService.deriveKey(
        masterPassword: 'test-master-password',
        salt: 'test-user-id-12345',
      );

      const plaintext = 'same-password';
      final c1 = CryptoService.encrypt(plaintext, key);
      final c2 = CryptoService.encrypt(plaintext, key);

      expect(c1, isNot(equals(c2)));
    });

    test('wrong key fails to decrypt', () {
      final key1 = CryptoService.deriveKey(
        masterPassword: 'correct-password',
        salt: 'user-id',
      );
      final key2 = CryptoService.deriveKey(
        masterPassword: 'wrong-password',
        salt: 'user-id',
      );

      const plaintext = 'secret';
      final ciphertext = CryptoService.encrypt(plaintext, key1);

      expect(
        () => CryptoService.decrypt(ciphertext, key2),
        throwsA(anything),
      );
    });

    test('calculateStrength returns 0 for empty', () {
      expect(CryptoService.calculateStrength(''), equals(0));
    });

    test('calculateStrength strong for complex password', () {
      final score = CryptoService.calculateStrength('Tr0ub4dor&3!xKq9');
      expect(score, greaterThanOrEqualTo(70));
    });

    test('calculateStrength weak for short lowercase', () {
      final score = CryptoService.calculateStrength('abc');
      expect(score, lessThan(40));
    });
  });
}
