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
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../entities/bitcoin_address_details.dart';
import '../entities/bitcoin_utxo.dart';
import '../entities/transaction_helper.dart';
import '../entities/wallet_helper.dart';
import '../util/bitcoin.dart';
import '../util/network.dart';
import '../util/util.dart';
import 'bitcoin_service.dart';
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

  Future<int> updateBalance(WalletEntity wallet) async {
    WidgetsFlutterBinding.ensureInitialized();
    WalletHelper walletHelper = WalletHelper();
    return walletHelper.updateBalance(wallet);
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
      final wei = await getRootstockBalanceFromBlockchainOnly(dto.publicKey!);
      return (wei.toRBTCTrimmedString());
    } catch (e) {
      return returnValue;
    }
  }


  Future<WalletDTO> getBitcoinBalanceOnDataBase(String privateKey) async {
    log.info("Searching BTC Balance");
    WalletHelper helper = WalletHelper();
    final wallet = await helper.getWalletByPrivateKey(privateKey);
    WalletDTO dto = WalletDTO(wallet: wallet, transactions: null, btcTransactions: null);
    try {
      final formatter = NumberFormat.simpleCurrency();
      var balance = wallet.btcAmount;
      print('Balance obtained on DataBase: $balance BTC');
      if (balance > 0) {

        final usdPrice = await _getPrice();
        final value = balance * usdPrice;
        dto.btcBalanceInUsd = formatter.format(value);
        dto.btcBalance = balance.toString();
      }

    } catch (error) {
      log.severe("Error creating wallet to display $error");
      throw Exception("Error creating wallet to display");
    }
    return dto;
  }


  Future<WalletDTO> getBalanceFromRsk(WalletDTO dto) async {
    try{
      var dataBase = await getBalanceRootstockFromDataBaseOnly(dto.wallet.privateKey);
      var blockchain = await getRootstockWalletRefreshed(dto.wallet);
      if(dataBase.balanceInDouble != blockchain.balanceInDouble){
        dataBase.balanceInDouble = blockchain.balanceInDouble;
        dataBase.balance = blockchain.balance;
        dataBase.wallet.amount = dataBase.balanceInDouble;
        updateBalance(dataBase.wallet);
      }
      return dataBase;
    }catch(e){
      log.severe("Error getting balance ${e}");
    }
    return dto;
  }

  Future<WalletDTO> getBalanceBitcoin(WalletDTO dto) async {
    try {
      var dataBase = await getBitcoinBalanceOnDataBase(dto.wallet.privateKey);

      var blockchainBalance = await getBitcoinBalanceFromBlockchainOnly(dto.wallet);

      if(blockchainBalance.btcBalanceInDouble != dataBase.btcBalanceInDouble){
        dataBase.btcBalanceInDouble = blockchainBalance.btcBalanceInDouble;
        dataBase.btcBalance = blockchainBalance.btcBalance;
        dataBase.wallet.btcAmount = blockchainBalance.btcBalanceInDouble;
        await updateBalance(dataBase.wallet);
        dataBase.updated = true;
        return dataBase;
      }

    } catch (e) {
      log.severe("Error obtaining database balance ${e}");
    }
    return dto;
  }

  Future<Wei> getRootstockBalanceFromBlockchainOnly(String address) async {
    Wei lastBalanceReceivedInWei = Wei(src: BigInt.zero, currency: "wei");
    try {
      final node = dotenv.env['ROOTSTOCK_NODE'];
      final client = web3.Web3Client(node!, http.Client());
      final lastBalanceReceivedInEtherAmount =
          await client.getBalance(web3.EthereumAddress.fromHex(address));
      lastBalanceReceivedInWei =
          Wei(src: lastBalanceReceivedInEtherAmount.getInWei, currency: "wei");
    } catch (error) {
      log.severe("Error getting balance", error);
    }
    return lastBalanceReceivedInWei;
  }

  Future<List<Utxo>> listUtxos(String btcFromAddress ) async {
    final node = dotenv.env['BITCOIN_NODE'];
    if (node == null || node.isEmpty) {
      return List<Utxo>.empty();
    }

    try {

      final client = BitcoinNodeClient(
        rpcUrl: node,
        rpcUser: 'bitcoin',
        rpcPassword: 'aTVQ5b0mS4y27qG',
      );

      var utxos = await client.listUtxos(btcFromAddress);
      return utxos;

    }catch(e){
      log.severe("Error occurred listing UTXOs ${e}");
    }

    return List<Utxo>.empty();
  }

  /// Scan the UTXO set for an address using Bitcoin Core `scantxoutset`.
  /// Returns a typed list of `Utxo` objects.
  Future<List<Utxo>> scanUtxosForAddress(String btcFromAddress) async {
    final node = dotenv.env['BITCOIN_NODE'];
    if (node == null || node.isEmpty) {
      return List<Utxo>.empty();
    }

    try {
      final client = BitcoinNodeClient(
        rpcUrl: node,
        rpcUser: 'bitcoin',
        rpcPassword: 'aTVQ5b0mS4y27qG',
      );

      BitcoinAddressDetails details = await client.fetchAddressInfoFromBlockbook(btcFromAddress);
      List<Utxo> utxos = [];

      for(var id in details.txids){
        var txUtxos = await client.fetchUtxosFromTransaction(id);
        utxos.addAll(txUtxos);
      }

      return utxos;

    }catch(e){
      log.severe("Error occurred scanning UTXOs ${e}");
    }

    return List<Utxo>.empty();
  }

  Future<List<Utxo>> selectUtxosForAmount(double amount, List<Utxo>? allUtxos)async{
    final node = dotenv.env['BITCOIN_NODE'];
    if (node == null || node.isEmpty) {
      return List<Utxo>.empty();
    }

    try {

      final client = BitcoinNodeClient(
        rpcUrl: node,
        rpcUser: 'bitcoin',
        rpcPassword: 'aTVQ5b0mS4y27qG',
      );

      var selectedUtxos = client.selectUtxosForAmount(amount, availableUtxos: allUtxos);
      return selectedUtxos;

    }catch(e){
      log.severe("Error occurred calculating fees ${e}");
    }

    return List<Utxo>.empty();
  }

  Future <double> calculateBtcFee(List<Utxo> selectedUtxos) async {
    final node = dotenv.env['BITCOIN_NODE'];
    if (node == null || node.isEmpty) {
      return 0.00;
    }

    try {

      final client = BitcoinNodeClient(
        rpcUrl: node,
        rpcUser: 'bitcoin',
        rpcPassword: 'aTVQ5b0mS4y27qG',
      );

    Map<String, dynamic> feeCalculated = await client.calculateFeeForBlocks(
          numInputs: 0,
          confTarget: 6,
          utxos: selectedUtxos);

      return feeCalculated['feeInBtc'] as double;

    }catch(e){
      log.severe("Error occurred calculating fees ${e}");
    }

    return 0.00;
  }

  Future<String> sendTransferUsingUtxos(WalletDTO wallet,String destinationAddress, double amount, List<Utxo> utxos) async {
    final node = dotenv.env['BITCOIN_NODE'];
    if (node == null || node.isEmpty) {
      return "";
    }

    try {

      final client = BitcoinNodeClient(
        rpcUrl: node,
        rpcUser: 'bitcoin',
        rpcPassword: 'aTVQ5b0mS4y27qG',
      );

      String id = await client.sendTransferUsingUtxos(destinationAddress, amount, utxos);

      print(id);
    }catch(e){
      log.severe("Error occurred sending BTC transfer ${e}");
    }

    return "";
  }

// dart
  Future<Wei> calculateRbtcFee({
    required String from,
    required String to,
    BigInt? value,
    int fallbackGasLimit = 54000,
  }) async {
    from = from.trim();
    to = to.trim();
    print("calculating ${from} and ${to}");
    Wei fee = Wei(src: BigInt.zero, currency: 'wei');
    try {
      final node = dotenv.env['ROOTSTOCK_NODE'];
      print("node is");
      print(node);
      if (node == null || node.isEmpty) return fee;

      final client = web3.Web3Client(node, http.Client());

      final unit = web3.EtherAmount.fromUnitAndValue(
        web3.EtherUnit.wei,
        value ?? BigInt.zero,
      );
      print("here 1");

      // get current gas price from node
      final gasPrice = await client.getGasPrice();
      print("gasPrice is ${gasPrice} ");

      // try to estimate gas; fall back to provided default if it fails
      int gasLimit;
      try {
        final estimated = await client.estimateGas(
          sender: web3.EthereumAddress.fromHex(from),
          to: web3.EthereumAddress.fromHex(to),
          value: unit,
        );
        print("estimated is ${estimated}");
        print(estimated);
        gasLimit = estimated is BigInt ? estimated.toInt() : (estimated as int);
        print("gaslimit is ${gasLimit} ");
      } catch (e) {
        gasLimit = fallbackGasLimit;
        print("errorrrrrr ${e}");
      }

      final feeWei = gasPrice.getInWei * BigInt.from(gasLimit);
      fee = Wei(src: feeWei, currency: 'wei');
      print("fee calculated is ${fee}");

      await client.dispose();
    } catch (error) {
      log.severe("Error estimating RBTC fee", error);
      print("error ${error} ");
    }

    print("returning the fee of ${fee}");
    return fee;
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

  String getExplorerUrl(Network network) {
    if (network == Network.ROOTSTOCK_MAINNET) {
      return dotenv.env['BLOCK_EXPLORER_URL_MAIN'] ?? "";
    }
    if (network == Network.ROOTSTOCK_TESTNET) {
      return dotenv.env['BLOCK_EXPLORER_URL'] ?? "";
    }
    if (network == Network.BITCOIN_TESTNET) {
      return dotenv.env['BTC_BLOCK_EXPLORER_URL'] ?? "";
    }
    if (network == Network.BITCOIN_MAINNET) {
      return dotenv.env['BTC_BLOCK_EXPLORER_URL_MAIN'] ?? "";
    }
    return "";
  }

  openBlockExplorerForTransaction(String transactionId, Network network) async {
    final Uri url =
        Uri.parse("${getExplorerUrl(network)}/tx/${transactionId}"); // Replace with your URL

    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  openBlockExplorerForAddress(String address, Network network) async {
    final Uri url =
        Uri.parse("${getExplorerUrl(network)}/address/${address}"); // Replace with your URL

    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<WalletDTO> getBalanceRootstockFromDataBaseOnly(String privateKey) async {
    WalletHelper helper = WalletHelper();
    final wallet = await helper.getWalletByPrivateKey(privateKey);
    WalletDTO dto = WalletDTO(wallet: wallet, transactions: null, btcTransactions: null);
    try {
      final formatter = NumberFormat.simpleCurrency();

      final balanceRsk = wallet.amount;
      if (balanceRsk > 0) {
        print('Balance obtained on DataBase: $balanceRsk RSK');
        final usdPrice = await _getPrice();
        final value = balanceRsk * usdPrice;
        dto.balanceInUsd = formatter.format(value);
        dto.balance = balanceRsk.toString();
      }
    } catch (error) {
      log.severe("Error creating wallet to display $error");
      throw Exception("Error creating wallet to display");
    }
    return dto;
  }

  String formatString(double amount) {
    final formatter = NumberFormat.simpleCurrency();
    return formatter.format(amount);
  }

    Future<String> calculateInUsd(double rootstockAmount) async {
    if(rootstockAmount == 0) {
      return "USD 0.00";
    }

    final formatter = NumberFormat.simpleCurrency();
    final usdPrice = await _getPrice();
    final value = rootstockAmount * usdPrice;
    return "USD ${formatter.format(value)}";
  }

  Future<void> getDataFromBlockchain(WalletEntity wallet) async {
    //var dto = await _callEachBlockchain(wallet);
    // wallet.btcAmount = dto.btcBalanceInDouble;
    // wallet.amount = dto.balanceInDouble;
    // await updateBalance(wallet);
  }

  Future<WalletDTO> getBitcoinBalanceFromBlockchainOnly(WalletEntity wallet) async {
    WalletDTO dto = WalletDTO(wallet: wallet, transactions: null, btcTransactions: null);
    try {
      final node = dotenv.env['BITCOIN_NODE'];
      if (node == null || node.isEmpty) {
        print("BITCOIN_NODE environment variable not set.");
        dto.amountInUsd = 0.00;
        dto.valueInWeiFormatted = "0.00";
        dto.balanceInUsd = "0";
        dto.balance = "0";
        return dto;
      }
      final client = BitcoinNodeClient(
        rpcUrl: node,
        rpcUser: 'bitcoin',
        rpcPassword: 'aTVQ5b0mS4y27qG',
      );

      final balance = await client.getBalanceForAddress(dto.wallet.btcAddress);
      print('Balance obtained on Blockchain: $balance BTC');
      final formatter = NumberFormat.simpleCurrency();

      final usdPrice = await _getPrice();
      final value = balance * usdPrice;
      dto.btcBalanceInDouble = balance;
      dto.amountInUsd = value;
      dto.balanceInUsd = formatter.format(value);
      dto.btcBalance = balance.toString();
      dto.wallet.btcAmount = dto.balanceInDouble;

      return dto;
    } catch (error) {
      log.severe("Error creating wallet to display $error");
      throw Exception("Error creating wallet to display $error");
    }
  }

  Future<WalletDTO> getRootstockWalletRefreshed(WalletEntity wallet) async {
    WalletDTO dto = WalletDTO(wallet: wallet, transactions: null, btcTransactions: null);
    try {
      final wei = await getRootstockBalanceFromBlockchainOnly(dto.wallet.publicKey);
      final usdPrice = await _getPrice();
      final value = wei.getWei() * usdPrice;
      final formatter = NumberFormat.simpleCurrency();
      dto.amountInWeis = wei.getWei();
      dto.amountInUsd = value;
      dto.valueInWeiFormatted = (wei.toRBTCTrimmedStringPlaces(10));
      dto.valueInUsdFormatted = formatter.format(value);
      dto.wallet.amount = wei.src.toDouble();
      dto.balanceInDouble = wei.getWei();
      dto.balance = dto.valueInWeiFormatted;
      print('Balance obtained on Blockchain: ${dto.balance} Rootstock');

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
          status: "Sent",
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
