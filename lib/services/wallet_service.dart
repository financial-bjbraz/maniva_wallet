import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/util/coingeck_resopnse.dart';
import 'package:my_rootstock_wallet/util/transaction_type.dart';
import 'package:my_rootstock_wallet/util/wei.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../entities/transaction_helper.dart';
import '../entities/wallet_helper.dart';
import '../util/bitcoin.dart';
import '../util/network.dart';
import '../util/util.dart';
import 'create_transaction_service.dart';

abstract class WalletAddressService {
  String generateMnemonic();

  Future<String> getPrivateKey(String mnemonic);

  web3.EthereumAddress getPublicKey(String privateKey);
}

class WalletServiceImpl extends ChangeNotifier implements WalletAddressService {
  static const privateKey = "flutter_k1";
  static const walletName = "flutter_k2";
  static const publickey = "flutter_k3";
  static const wid = "flutter_k4";
  final log = Logger("WalletServiceImpl");
  CreateTransactionServiceImpl service = CreateTransactionServiceImpl();

  @override
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  @override
  Future<String> getPrivateKey(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    final privateKey = HEX.encode(master.key);
    return privateKey;
  }

  @override
  web3.EthereumAddress getPublicKey(String privateKey) {
    final private = web3.EthPrivateKey.fromHex(privateKey);
    final address = private.address;
    return address;
  }

  Future<String> getPublicKeyString(String privateKey) async {
    final private = web3.EthPrivateKey.fromHex(privateKey);
    final address = private.address;
    return address.hex;
  }

  Future<List<WalletEntity>> getWallets(final String ownerEmail) async {
    WidgetsFlutterBinding.ensureInitialized();
    WalletHelper walletHelper = WalletHelper();
    return walletHelper.fetchItems(ownerEmail);
  }

  void persistNewWallet(WalletEntity wallet) async {
    WalletHelper helper = WalletHelper();
    var inserted = await helper.insertItem(wallet);

    if (inserted > 0) {
      log.info("Wallet persisted successfully");
    } else {
      log.warning("Failed to persist wallet");
      throw Exception("Failed to persist wallet");
    }
  }

  void delete(WalletEntity wallet) async {
    final db = await openDataBase();
    await db.delete("wallets", where: 'privateKey = ?', whereArgs: [wallet.privateKey]);
  }

  Future<String> getBalance(WalletDTO dto) async {
    const returnValue = "0.00";
    try {
      final wei = await getBalanceInWei(dto);
      return (wei.toRBTCTrimmedString());
    } catch (e) {
      return returnValue;
    }
  }

  Future<String> getBalanceBitcoin(WalletDTO dto) async {
    const returnValue = "0.00";
    try {
      final wei = await getBalanceInWei(dto);
      return (wei.toRBTCTrimmedString());
    } catch (e) {
      return returnValue;
    }
  }

  Future<Wei> getBalanceInWei(WalletDTO dto) async {
    try {
      if (!dto.updated) {
        final node = dotenv.env['ROOTSTOCK_NODE'];
        final client = web3.Web3Client(node!, http.Client());
        final credentials = web3.EthPrivateKey.fromHex(dto.wallet.privateKey);
        final address = credentials.address;
        dto.lastBalanceReceivedInEtherAmount = await client.getBalance(address);
        dto.lastBalanceReceivedInWei =
            Wei(src: dto.lastBalanceReceivedInEtherAmount.getInWei, currency: "wei");
        dto.updated = true;
      }
    } catch (error) {
      log.severe("Error getting balance", error);
    }
    return dto.lastBalanceReceivedInWei;
  }

  Future<Wei> getBalanceInSatoshis(WalletDTO dto) async {
    try {
      if (!dto.updated) {
        final node = dotenv.env['ROOTSTOCK_NODE'];
        final client = web3.Web3Client(node!, http.Client());
        final credentials = web3.EthPrivateKey.fromHex(dto.wallet.privateKey);
        final address = credentials.address;
        dto.lastBalanceReceivedInEtherAmount = await client.getBalance(address);
        dto.lastBalanceReceivedInWei =
            Wei(src: dto.lastBalanceReceivedInEtherAmount.getInWei, currency: "wei");
        dto.updated = true;
      }
    } catch (error) {
      log.severe("Error getting balance", error);
    }
    return dto.lastBalanceReceivedInWei;
  }

  // TODO(alexjavabraz): implement persistence of transaction sent
  Future<SimpleTransaction> sendRBTC(
      WalletDTO dto, String destinationAddress, BigInt amount) async {
    var unit = web3.EtherAmount.fromUnitAndValue(web3.EtherUnit.wei, amount);
    var transactionToPersist = await createTransactionInstance(dto, destinationAddress, amount);
    try {
      var node = dotenv.env['ROOTSTOCK_NODE'];
      var httpClient = http.Client();
      final client = web3.Web3Client(node.toString(), httpClient);
      final credentials = web3.EthPrivateKey.fromHex(dto.wallet.privateKey);
      var chainId = await client.getChainId();
      web3.EtherAmount gasPrice = await client.getGasPrice();

      var transaction = web3.Transaction(
        to: web3.EthereumAddress.fromHex(destinationAddress),
        gasPrice: gasPrice,
        maxGas: 54000,
        value: unit,
      );

      transactionToPersist.transactionId =
          await client.sendTransaction(credentials, transaction, chainId: chainId.toInt());
      transactionToPersist.transactionSent = true;
      await client.dispose();
    } catch (error) {
      log.severe("Error sending transaction", error);
      transactionToPersist.transactionSent = false;
    }
    try {
      service.createOrUpdateTransaction(transactionToPersist);
      transactionToPersist.transactionSent = true;
    } catch (error) {
      log.severe("Error persisting transaction", error);
    }
    return transactionToPersist;
  }

  // Tentar reutilizar isso em alguma classe para nao buscar toda hora do .env
  String getExplorerUrl(String transactionId) {
    final blockExplorer = dotenv.env['BLOCK_EXPLORER_URL'];
    return blockExplorer! + transactionId;
  }

  Future<WalletDTO> convert(WalletEntity entity) async {
    return WalletDTO(wallet: entity, transactions: null, btcTransactions: null);
  }

  Future<WalletDTO> createGenericWalletToDisplay(Network network, WalletDTO dto) async {
    switch (network) {
      case Network.BITCOIN_TESTNET:
        dto = await setBitcoinWallet(dto);
        break;
      case Network.ROOTSTOCK_TESTNET:
        dto = await setRootstockWallet(dto);
        break;
      case Network.BITCOIN_MAINNET:
        throw UnimplementedError();
      case Network.ROOTSTOCK_MAINNET:
        throw UnimplementedError();
    }
    return dto;
  }

  Future<WalletDTO> setBitcoinWallet(WalletDTO dto) async {
    try {
      final usdPrice = await _getPrice();
      final formatter = NumberFormat.simpleCurrency();
      dto.amountInUsd = 0.00;
      dto.valueInWeiFormatted = "0.00";
      dto.balanceInUsd = "0";
      dto.balance = "0";

      return dto;
    } catch (error) {
      log.severe("Error creating wallet to display $error");
      throw Exception("Error creating wallet to display");
    }
  }

  Future<WalletDTO> setRootstockWallet(WalletDTO dto) async {
    try {
      final wei = await getBalanceInWei(dto);
      final usdPrice = await _getPrice();
      final value = wei.getWei() * usdPrice;
      final formatter = NumberFormat.simpleCurrency();
      dto.amountInWeis = wei.getWei();
      dto.amountInUsd = value;
      dto.valueInWeiFormatted = (wei.toRBTCTrimmedStringPlaces(10));
      dto.valueInUsdFormatted = formatter.format(value);

      // If last received value is != than stored value, udpate stored value
      if (wei.src.compareTo(BigInt.from(dto.wallet.amount)) != 0) {
        dto.wallet.amount = wei.src.toDouble();
        persistNewWallet(dto.wallet);
      }

      dto.balance = dto.valueInWeiFormatted;
      dto.balanceInUsd = dto.valueInUsdFormatted;

      return dto;
    } catch (error) {
      log.severe("Error creating wallet to display $error");
      throw Exception("Error creating wallet to display");
    }
  }

  Future<int> _getPrice() async {
    if (!await isTimeToQuery()) {
      // setted to 4 hours
      return getLastUsdPrice();
    }

    final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin&order=market_cap_desc&per_page=100&page=1&sparkline=false'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body) as List<dynamic>;

      List<CoinGeckoResponse> prices = body
          .map(
            (dynamic item) => CoinGeckoResponse.fromJson2(item as Map<String, dynamic>),
          )
          .toList();
      var price = (prices.elementAt(0).currentPrice);
      setLastUsdPrice(price);
      return price;
    } else {
      return getLastUsdPrice();
    }
  }

  Future<bool> isTimeToQuery() async {
    final now = DateTime.now();
    final lastQuery = await getLastUsdPriceTime();
    final difference = now.difference(lastQuery);
    return difference.inHours > 4; // 4 hours
  }

  Future<SimpleTransaction> createTransactionInstance(
      WalletDTO dto, String destinationAddress, BigInt amount) async {
    var wei = Wei(src: BigInt.zero, currency: 'wei');
    var usdPrice = 0;
    final formatter = NumberFormat.simpleCurrency();

    try {
      wei = Wei(src: amount, currency: 'wei');
      usdPrice = await _getPrice();
      final value = wei.getWei() * usdPrice;

      final transactionToPersist = SimpleTransaction(
          transactionId: '',
          amountInWeis: amount.toString(),
          ddateTime: DateFormat("dd/MM/yyyy").format(DateTime.now()),
          walletId: dto.wallet.walletId,
          valueInUsdFormatted: (formatter.format(value)),
          valueInWeiFormatted: (wei.toRBTCTrimmedStringPlaces(10)),
          type: TransactionType.REGULAR_OUTGOING.type,
          destination: destinationAddress);
      return transactionToPersist;
    } catch (error) {
      log.severe("error creating transaction to be persisted", error);
    }
    return SimpleTransaction(
        transactionId: '',
        amountInWeis: "0",
        ddateTime: '',
        walletId: '',
        valueInUsdFormatted: '',
        valueInWeiFormatted: '',
        type: TransactionType.NONE.type,
        destination: destinationAddress);
  }

  String getBtcAddressFromPrivateKey(final String privateKey) {
    return BitcoinWallet.generateCompressedAddress(privateKey, Network.BITCOIN_TESTNET.networkByte);
  }
}
