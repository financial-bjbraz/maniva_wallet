import 'package:flutter/material.dart';
import 'package:maniva_wallet/util/util.dart';

import '../entities/wallet_helper.dart';
import 'addresses.dart';
import 'bitcoin.dart';

enum Network {
  BITCOIN_TESTNET(
    networkByte: 0x6f,
    name: 'Bitcoin Testnet',
    networkId: 0,
  ),
  BITCOIN_MAINNET(
    networkByte: 0x00,
    name: 'Bitcoin',
    networkId: 0,
  ),
  ROOTSTOCK_MAINNET(
    networkByte: 0x00,
    name: 'Rootstock',
    networkId: 30,
  ),
  ROOTSTOCK_TESTNET(
    networkByte: 0x00,
    name: 'Rootstock Testnet',
    networkId: 31,
  );

  const Network({required this.networkByte, required this.name, required this.networkId});

  static String generateFormattedAddress(Network n, WalletEntity wallet) {
    switch (n) {
      case Network.BITCOIN_TESTNET:
        return formatTextWithParameter(wallet.btcAddress, 11);
      case Network.BITCOIN_MAINNET:
        return formatTextWithParameter(wallet.btcAddress, 11);
      case Network.ROOTSTOCK_MAINNET:
        return formatAddressWithParameter(
            toChecksumAddress(wallet.publicKey.toString(), Network.ROOTSTOCK_MAINNET.networkId),
            11);
      case Network.ROOTSTOCK_TESTNET:
        return formatAddressWithParameter(
            toChecksumAddress(wallet.publicKey.toString(), Network.ROOTSTOCK_TESTNET.networkId),
            11);
    }
  }

  static String generateAddress(Network n, WalletEntity wallet) {
    switch (n) {
      case Network.BITCOIN_TESTNET:
        return BitcoinWallet.generateCompressedAddress(
            wallet.privateKey, Network.BITCOIN_TESTNET.networkByte);
      case Network.BITCOIN_MAINNET:
        return BitcoinWallet.generateCompressedAddress(
            wallet.privateKey, Network.BITCOIN_MAINNET.networkByte);
      case Network.ROOTSTOCK_MAINNET:
        return toChecksumAddress(wallet.publicKey.toString(), Network.ROOTSTOCK_MAINNET.networkId);
      case Network.ROOTSTOCK_TESTNET:
        return toChecksumAddress(wallet.publicKey.toString(), Network.ROOTSTOCK_TESTNET.networkId);
    }
  }

  static Image getIcon(Network n) {
    switch (n) {
      case Network.BITCOIN_TESTNET:
        return Image.asset(
          'assets/icons/btc.png',
          width: 48,
        );
      case Network.BITCOIN_MAINNET:
        return Image.asset(
          'assets/icons/btc.png',
          width: 48,
        );
      case Network.ROOTSTOCK_MAINNET:
        return Image.asset(
          'assets/icons/rbtc.png',
          width: 48,
          cacheWidth: 96,
          cacheHeight: 96,
        );
      case Network.ROOTSTOCK_TESTNET:
        return Image.asset(
          'assets/icons/rbtc.png',
          width: 48,
          cacheWidth: 96,
          cacheHeight: 96,
        );
    }
  }

  static Image getIconGrey(Network n) {
    switch (n) {
      case Network.BITCOIN_TESTNET:
        return Image.asset(
          'assets/icons/btc.png',
          color: Colors.grey,
          width: 48,
        );
      case Network.BITCOIN_MAINNET:
        return Image.asset(
          'assets/icons/btc.png',
          color: Colors.grey,
          width: 48,
        );
      case Network.ROOTSTOCK_MAINNET:
        return Image.asset(
          'assets/icons/rbtc.png',
          color: Colors.grey,
          width: 48,
          cacheWidth: 96,
          cacheHeight: 96,
        );
      case Network.ROOTSTOCK_TESTNET:
        return Image.asset(
          'assets/icons/rbtc.png',
          color: Colors.grey,
          width: 48,
          cacheWidth: 96,
          cacheHeight: 96,
        );
    }
  }

  /// Validates a Bitcoin address's format AND that its prefix matches
  /// [isMainnet]. Mainnet and testnet addresses look superficially similar
  /// (base58/bech32 strings), so a purely-format-only check would happily
  /// accept a mainnet address while the wallet is in testnet mode or vice
  /// versa — sending there is not what the user intended and can result in
  /// funds effectively going to the wrong network/recipient.
  static bool isValidBitcoinAddress(String address, {required bool isMainnet}) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (isMainnet) {
      final bech32 = RegExp(r'^bc1[0-9a-zA-Z]{11,71}$');
      final base58 = RegExp(r'^[13][1-9A-HJ-NP-Za-km-z]{25,39}$');
      return bech32.hasMatch(trimmed) || base58.hasMatch(trimmed);
    }
    final bech32Testnet = RegExp(r'^tb1[0-9a-zA-Z]{11,71}$');
    final base58Testnet = RegExp(r'^[mn2][1-9A-HJ-NP-Za-km-z]{25,39}$');
    return bech32Testnet.hasMatch(trimmed) || base58Testnet.hasMatch(trimmed);
  }

  /// EVM addresses (Rootstock/Ethereum) don't differ in format between
  /// mainnet/testnet — only the chainId used when signing differs — so this
  /// only needs to validate the hex format itself.
  static bool isValidEvmAddress(String address) {
    return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address.trim());
  }

  final int networkByte;
  final String name;
  final int networkId;
}
