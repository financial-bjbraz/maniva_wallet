import 'package:flutter_test/flutter_test.dart';
import 'package:maniva_wallet/services/wallet_service.dart';

void main() {
  group('WalletServiceImpl.sanitizeOwnerEmail', () {
    test('normalizes and accepts a valid email', () {
      final input = '  Alice.Example+tag@Example.COM  ';
      final out = WalletServiceImpl.sanitizeOwnerEmail(input);
      expect(out, 'alice.example+tag@example.com');
    });

    test('returns null for empty or whitespace-only', () {
      expect(WalletServiceImpl.sanitizeOwnerEmail(''), isNull);
      expect(WalletServiceImpl.sanitizeOwnerEmail('   '), isNull);
    });

    test('returns null for invalid formats', () {
      expect(WalletServiceImpl.sanitizeOwnerEmail('not-an-email'), isNull);
      expect(WalletServiceImpl.sanitizeOwnerEmail('abc@'), isNull);
      expect(WalletServiceImpl.sanitizeOwnerEmail('a b@c.com'), isNull);
    });

    test('accepts common valid emails', () {
      expect(WalletServiceImpl.sanitizeOwnerEmail('user.name@example.co.uk'),
          'user.name@example.co.uk');
      expect(WalletServiceImpl.sanitizeOwnerEmail('user_name-123@example.io'),
          'user_name-123@example.io');
    });
  });
}
