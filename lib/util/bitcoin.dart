import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

class BitcoinWallet {
  static String generateAddress(String privateKey, int network) {
    final publicKey = _privateToPublic(privateKey);
    final address = _publicToAddress(publicKey, network);
    return address;
  }

  static String generateCompressedAddress(String privateKey, int network) {
    final publicKey = _privateToCompressedPublic(privateKey);
    final address = _publicToAddress(publicKey, network);
    return address;
  }

  static Uint8List _privateToPublic(String privateKey) {
    final privateKeyBytes = hexToBytes(privateKey);
    final curve = ECCurve_secp256k1();
    final privateKeyNum = decodeBigInt(privateKeyBytes);
    final publicPoint = curve.G * privateKeyNum;
    final x = encodeBigInt(publicPoint!.x!.toBigInteger()!);
    final y = encodeBigInt(publicPoint.y!.toBigInteger()!);
    return Uint8List.fromList([0x04, ...x, ...y]);
  }

  static Uint8List _privateToCompressedPublic(String privateKey) {
    final privateKeyBytes = hexToBytes(privateKey);
    final curve = ECCurve_secp256k1();
    final privateKeyNum = decodeBigInt(privateKeyBytes);
    final publicPoint = curve.G * privateKeyNum;
    final x = encodeBigInt(publicPoint!.x!.toBigInteger()!);
    final isEven = publicPoint.y!.toBigInteger()!.isEven;
    final prefix = isEven ? 0x02 : 0x03;
    return Uint8List.fromList([prefix, ...x]);
  }

  static String _publicToAddress(Uint8List publicKey, int networkByteInt) {
    final sha256Hash = sha256.convert(publicKey).bytes;
    final ripemd160Hash = RIPEMD160Digest().process(Uint8List.fromList(sha256Hash));
    final networkByte = Uint8List.fromList([networkByteInt, ...ripemd160Hash]);
    final checksum = sha256.convert(sha256.convert(networkByte).bytes).bytes.sublist(0, 4);
    final addressBytes = Uint8List.fromList([...networkByte, ...checksum]);
    return base58Encode(addressBytes);
  }

  static String base58Encode(Uint8List input) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    BigInt intData = decodeBigInt(input);
    String result = '';
    while (intData > BigInt.zero) {
      final mod = intData % BigInt.from(58);
      result = alphabet[mod.toInt()] + result;
      intData ~/= BigInt.from(58);
    }
    for (final byte in input) {
      if (byte == 0) {
        result = '1' + result;
      } else {
        break;
      }
    }
    return result;
  }
}

// Helper functions
Uint8List hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return result;
}

BigInt decodeBigInt(Uint8List bytes) {
  return BigInt.parse(bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16);
}

Uint8List encodeBigInt(BigInt number) {
  final hexString = number.toRadixString(16).padLeft((number.bitLength + 7) >> 3 << 1, '0');
  return hexToBytes(hexString);
}
