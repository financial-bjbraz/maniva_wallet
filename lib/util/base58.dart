import "package:convert/convert.dart" show hex;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import 'bitcoin.dart';
import 'network.dart';

String base58Encode(String hex) {
  const chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  final base = chars.length;

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

String getBtcPrivateKey(String rskAddress) {
  List<int> addressArray = rskAddress.codeUnits;
  List<int> partialResult = [];
  List<int> result = [];

  partialResult.add(0xEF);
  partialResult.addAll(addressArray);
  partialResult.add(0x01);

  List<int> check = sha256.convert(sha256.convert(partialResult).bytes).bytes;

  result.addAll(partialResult);
  result.addAll(check.sublist(0, 8));

  return base58Encode(hex.encode(result));
}

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

String generatePublicKey(String privateKeyHex) {
  final privateKey =
      ECPrivateKey(BigInt.parse(privateKeyHex, radix: 16), ECDomainParameters('secp256k1'));
  final publicKey = privateKey.parameters!.G * privateKey.d!;
  final publicKeyBytes = publicKey?.getEncoded(false);
  return hex.encode(publicKeyBytes!.toList());
}

void main() {
  String privateKey = "bbe55fc1379fed1e783054ef4dd7f666367413087e1eb2ab22cce0f89e386708";
  const String MAINNET = "80";
  const String TESTNET = "ef";
  const String REGTEST = "f0";
  String extended = "$REGTEST${privateKey}01";

  String extendedChecksum = extended + checksum(extended);
  String wif = base58Encode(extendedChecksum);
  print(wif);
  print(generatePublicKey(privateKey));
  // print(generatePublicKey(wif));
  var addressGenerated =
      BitcoinWallet.generateCompressedAddress(privateKey, Network.TESTNET.networkByte);
  print(addressGenerated);
}

/*
https://mempool.space/testnet/address/mfjKbRTeJMMsn9EY1Do9B4yj8qAYnA7P6p

mainnet: 1DNJNNfVKvd12kvHepmM9mQGqZqvEptzB
mainnet: 1DNJNNfVKvd12kvHepmM9mQGqZqvEptzB

*/
