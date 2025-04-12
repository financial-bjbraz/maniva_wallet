import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/util/util.dart';

import '../entities/wallet_helper.dart';
import 'addresses.dart';
import 'bitcoin.dart';

enum Network {
  BITCOIN_TESTNET(
    networkByte: 0x6f,
    name: 'Testnet',
    networkId: 0,
  ),
  BITCOIN_MAINNET(networkByte: 0x00, name: 'Mainnet', networkId: 0),
  ROOTSTOCK_MAINNET(networkByte: 0x00, name: 'Mainnet', networkId: 30),
  ROOTSTOCK_TESTNET(networkByte: 0x00, name: 'Testnet', networkId: 31);

  const Network({required this.networkByte, required this.name, required this.networkId});

  static String generateFormattedAddress(Network n, WalletEntity wallet) {
    switch (n) {
      case Network.BITCOIN_TESTNET:
        return formatTextWithParameter(
            BitcoinWallet.generateCompressedAddress(
                wallet.privateKey, Network.BITCOIN_TESTNET.networkByte),
            11);
      case Network.BITCOIN_MAINNET:
        return formatTextWithParameter(
            BitcoinWallet.generateCompressedAddress(
                wallet.privateKey, Network.BITCOIN_MAINNET.networkByte),
            11);
      case Network.ROOTSTOCK_MAINNET:
        return formatAddressWithParameter(
            toChecksumAddress(wallet.publicKey.toString(), Network.ROOTSTOCK_TESTNET.networkId),
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
        return toChecksumAddress(wallet.publicKey.toString(), Network.ROOTSTOCK_TESTNET.networkId);
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
        );
      case Network.ROOTSTOCK_TESTNET:
        return Image.asset(
          'assets/icons/rbtc.png',
          width: 48,
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
        );
      case Network.ROOTSTOCK_TESTNET:
        return Image.asset(
          'assets/icons/rbtc.png',
          color: Colors.grey,
          width: 48,
        );
    }
  }

  final int networkByte;
  final String name;
  final int networkId;
}
