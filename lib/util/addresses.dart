import "dart:convert";
import "dart:typed_data";

import "package:convert/convert.dart" show hex;
import 'package:pointycastle/digests/keccak.dart';
import "package:pointycastle/ecc/curves/secp256k1.dart";
import 'package:pointycastle/pointycastle.dart';

const HEX_PREFIX = '0x';
const ETHEREUM_NETWORK_ID = 1;
const POLYGON_NETWORK_ID = 137;
const ETHEREUM_TESTNET_ID = 3;
const POLYGON_TESTNET_ID = 80001;
const POLYGON_MUMBAI_TESTNET_ID = 80001;
const POLYGON_ZKEVM_TESTNET_ID = 1442;
const POLYGON_ZKEVM_MAINNET_ID = 1101;

String strip0x(String address) {
  if (address.startsWith("0x") || address.startsWith("0X")) {
    return address.substring(2);
  }
  return address;
}

bool isValidFormat(String address) {
  return RegExp(r"^[0-9a-fA-F]{40}$").hasMatch(strip0x(address));
}

Uint8List decompressPublicKey(Uint8List publicKey) {
  final length = publicKey.length;
  final firstByte = publicKey[0];

  if ((length != 33 && length != 65) || firstByte < 2 || firstByte > 4) {
    throw ArgumentError.value(publicKey, "publicKey", "invalid public key");
  }

  final ECPoint? ecPublicKey = ECCurve_secp256k1().curve.decodePoint(publicKey);
  return ecPublicKey!.getEncoded(false);
}

String stripHexPrefix(String str) {
  return hasHexPrefix(str) ? str.substring(HEX_PREFIX.length) : str;
}

bool hasHexPrefix(String str) {
  return str.startsWith(HEX_PREFIX);
}

bool isHexPrefix(String str) {
  return str.startsWith(HEX_PREFIX);
}

/// Converts an address to a checksummed address (EIP-55).
String toChecksumAddress(String address, int chainId) {
  address = stripHexPrefix(address).toLowerCase();
  final prefix = (chainId != null) ? '${chainId.toString()}0x' : '';
  final hash = hex
      .encode(
        KeccakDigest(256).process(ascii.encode('$prefix$address')),
      )
      .toString();

  return HEX_PREFIX +
      address.split('').asMap().entries.map((entry) {
        final b = entry.value;
        final i = entry.key;
        final hashCar = int.parse(hash[i], radix: 16);
        return hashCar >= 8 ? b.toUpperCase() : b;
      }).join('');
}

bool isAddress(String address) {
  return RegExp(r"^(0x)?[0-9a-fA-F]{40}$").hasMatch(address);
}

bool isValidChecksumAddress(String address, int chainId) {
  return isAddress(address) && toChecksumAddress(address, chainId) == address;
}
