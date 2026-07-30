import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

String base58Encode(String hex) {
  const chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  const base = chars.length;

  BigInt i = BigInt.parse(hex, radix: 16);
  String buffer = '';

  while (i > BigInt.zero) {
    final remainder = i % BigInt.from(base);
    i = i ~/ BigInt.from(base);
    buffer = chars[remainder.toInt()] + buffer;
  }

  final leadingZeroBytes = RegExp(r'^([0]+)').firstMatch(hex)?.group(1)?.length ?? 0;
  final leadingZeros = '1' * (leadingZeroBytes ~/ 2);

  return leadingZeros + buffer;
}

// String getBtcPrivateKey(String rskAddress) {
//   List<int> addressArray = rskAddress.codeUnits;
//   List<int> partialResult = [];
//   List<int> result = [];
//
//   partialResult.add(0xEF);
//   partialResult.addAll(addressArray);
//   partialResult.add(0x01);
//
//   List<int> check = sha256.convert(sha256.convert(partialResult).bytes).bytes;
//
//   result.addAll(partialResult);
//   result.addAll(check.sublist(0, 8));
//
//   return base58Encode(hex.encode(result));
// }

String checksum(String str) {
  String hash = hash256(str);
  var checkSumValue = hash.substring(0, 8); // Return the first 4 bytes (8 characters)
  return checkSumValue;
}

String hash256(String hex) {
  var binary = List<int>.generate(hex.length ~/ 2, (i) {
    return int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  });
  var hash1 = sha256.convert(binary).bytes;
  var hash2 = sha256.convert(hash1).bytes;
  var result = hash2.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return result;
}

// String generatePublicKey(String privateKeyHex) {
//   final privateKey =
//       ECPrivateKey(BigInt.parse(privateKeyHex, radix: 16), ECDomainParameters('secp256k1'));
//   final publicKey = privateKey.parameters!.G * privateKey.d!;
//   final publicKeyBytes = publicKey?.getEncoded(false);
//   return hex.encode(publicKeyBytes!.toList());
// }

String hexToWif(String hexKey, {bool testnet = true, bool compressed = true}) {
  final keyBytes = _hexToBytes(hexKey);
  final prefix = testnet ? 0xEF : 0x80;
  final payload = <int>[prefix, ...keyBytes, if (compressed) 0x01];
  final h1 = sha256.convert(payload).bytes;
  final h2 = sha256.convert(h1).bytes;
  final checksum = h2.sublist(0, 4);
  return _base58Encode(Uint8List.fromList([...payload, ...checksum]));
}

Uint8List _hexToBytes(String hex) {
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    out[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return out;
}

String _base58Encode(Uint8List data) {
  const alpha = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  var n = BigInt.parse(data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
  var result = '';
  while (n > BigInt.zero) {
    final mod = n % BigInt.from(58);
    result = alpha[mod.toInt()] + result;
    n ~/= BigInt.from(58);
  }
  for (final b in data) {
    if (b == 0) {
      result = '1$result';
    } else {
      break;
    }
  }
  return result;
}

/*
https://mempool.space/testnet/address/mfjKbRTeJMMsn9EY1Do9B4yj8qAYnA7P6p

mainnet: 1DNJNNfVKvd12kvHepmM9mQGqZqvEptzB
mainnet: 1DNJNNfVKvd12kvHepmM9mQGqZqvEptzB

*/
