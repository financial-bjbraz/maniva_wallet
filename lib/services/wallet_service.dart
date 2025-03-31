import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_rootstock_wallet/entities/transaction_type.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/util/coingeck_resopnse.dart';
import 'package:my_rootstock_wallet/util/wei.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:web3dart/web3dart.dart' as web3;
import '../entities/simple_transaction.dart';
import '../entities/wallet_entity.dart';
import '../util/util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
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
    // Open the database and store the reference.
    final database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), databaseName),
    );
    // Get a reference to the database.
    final db = await database;

    // Query the table for all the wallets.
    final List<Map<String, Object?>> walletMaps = await db.query(
        'wallets', where: 'ownerEmail = ?', whereArgs: [ownerEmail]);

    // Convert the list of each fields into a list of `Wallet` objects.
    return [
      for (final {
      'privateKey': privateKey as String,
      'walletName': walletName as String,
      'walletId': walletId as String,
      'publicKey': publicKey as String,
      'ownerEmail': ownerEmail as String,
      'amount': amountValue as double,
      } in walletMaps)
        WalletEntity(amountValue, privateKey: privateKey,
            publicKey: publicKey,
            walletId: walletId,
            walletName: walletName,
            ownerEmail: ownerEmail,),
    ];
  }

  void persistNewWallet(WalletEntity wallet) async {
    final database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), databaseName),
    );
    // Get a reference to the database.
    final db = await database;

    await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    db.close();
  }

  void delete(WalletEntity wallet) async {
    final db = await openDataBase();
    await db.delete(
        "wallets", where: 'privateKey = ?', whereArgs: [wallet.privateKey]);
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

  Future<Wei> getBalanceInWei(WalletDTO dto) async {
    try {
      if(!dto.updated) {
        final node = dotenv.env['ROOTSTOCK_NODE'];
        final client = web3.Web3Client(node!, http.Client());
        final credentials = web3.EthPrivateKey.fromHex(dto.wallet.privateKey);
        final address = credentials.address;
        dto.lastBalanceReceivedInEtherAmount = await client.getBalance(address);
        dto.lastBalanceReceivedInWei = Wei(src: dto.lastBalanceReceivedInEtherAmount.getInWei, currency: "wei");
        dto.updated = true;
      }
    } catch (error) {
      log.severe("Error getting balance", error);
    }
    return dto.lastBalanceReceivedInWei;
  }

  // TODO implement persistence of transaction sent
  Future<SimpleTransaction> sendRBTC(WalletEntity wallet, String destinationAddress, BigInt amount) async {

    var transactionToPersist = SimpleTransaction(transactionId: '', amountInWeis: amount.toInt(), date: DateFormat("dd/MM/yyyy").format(DateTime.now()), walletId: wallet.walletId,
        valueInUsdFormatted: '',
        valueInWeiFormatted: '',
        type: TransactionType.REGULAR_OUTGOING.type,
    );
    try {
      var node = dotenv.env['ROOTSTOCK_NODE'];
      var httpClient = http.Client();
      final client = web3.Web3Client(node.toString(), httpClient);
      final credentials = web3.EthPrivateKey.fromHex(wallet.privateKey);
      var chainId = await client.getChainId();
      web3.EtherAmount gasPrice = await client.getGasPrice();

      var unit = web3.EtherAmount.fromUnitAndValue(web3.EtherUnit.wei, amount);

      var transaction = web3.Transaction(
        to: web3.EthereumAddress.fromHex(destinationAddress),
        gasPrice: gasPrice,
        maxGas: 54000,
        value: unit,
      );

      transactionToPersist.transactionId = await client.sendTransaction(
        credentials,
        transaction,
        chainId: chainId.toInt()
      );
      transactionToPersist.transactionSent = false;
      await client.dispose();
    } catch (error) {
      log.severe("Error sending transaction", error);
      transactionToPersist.transactionSent = false;
    }
    try{
      service.createOrUpdateTransaction(transactionToPersist);
      transactionToPersist.transactionSent = true;
    }catch(error){
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
    return WalletDTO(wallet: entity, transactions: null);
  }

  Future<WalletDTO> createWalletToDisplay(WalletDTO dto) async {
    final wei = await getBalanceInWei(dto);
    final usdPrice = await _getPrice();
    final value = wei.getWei() * usdPrice;
    final formatter = NumberFormat.simpleCurrency();
    dto.amountInWeis = wei.getWei();
    dto.amountInUsd = value;
    dto.valueInWeiFormatted = (wei.toRBTCTrimmedStringPlaces(10));
    dto.valueInUsdFormatted = formatter.format(value);

    if (wei.src.compareTo(BigInt.from(dto.wallet.amount)) != 0) {
      dto.wallet.amount = wei.src.toDouble();
      persistNewWallet(dto.wallet);
    }

    return dto;
  }

  Future<int> _getPrice() async {
    final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin&order=market_cap_desc&per_page=100&page=1&sparkline=false'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body) as List<dynamic>;

      List<CoinGeckoResponse> prices = body
          .map(
            (dynamic item) =>
            CoinGeckoResponse.fromJson2(item as Map<String, dynamic>),
      ).toList();
      var price = (prices
          .elementAt(0)
          .currentPrice);

      setLastUsdPrice(price);

      return price;
    } else {
      return getLastUsdPrice();
    }
  }

}
