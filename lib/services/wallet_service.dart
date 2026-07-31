import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/entities/wallet_dto.dart';
import 'package:maniva_wallet/util/coingeck_resopnse.dart';
import 'package:maniva_wallet/util/transaction_type.dart';
import 'package:maniva_wallet/util/wei.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../contracts/ERC20.g.dart';
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

  /// Generates a new BIP39 mnemonic phrase.
  @override
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  /// Derives a hex private key from [mnemonic] using BIP39 seed + ED25519 HD master key.
  @override
  Future<String> getPrivateKey(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    final privateKey = HEX.encode(master.key);
    return privateKey;
  }

  /// Returns the RSK/EVM [web3.EthereumAddress] derived from [privateKey].
  @override
  web3.EthereumAddress getPublicKey(String privateKey) {
    final private = web3.EthPrivateKey.fromHex(privateKey);
    final address = private.address;
    return address;
  }

  /// Returns the checksummed hex RSK/EVM address string derived from [privateKey].
  Future<String> getPublicKeyString(String privateKey) async {
    final private = web3.EthPrivateKey.fromHex(privateKey);
    final address = private.address;
    return address.hex;
  }

  /// Sanitizes and validates an owner email.
  /// Returns the sanitized (trimmed & lowercased) email, or `null` if invalid.
  static String? sanitizeOwnerEmail(String ownerEmail) {
    final sanitized = ownerEmail.trim().toLowerCase();
    if (sanitized.isEmpty) {
      return null;
    }

    // Basic email format validation
    final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
    if (!emailRegex.hasMatch(sanitized)) {
      return null;
    }

    return sanitized;
  }

  /// Returns all wallets stored for [ownerEmail].
  ///
  /// [ownerEmail] is sanitized and validated before the database is queried;
  /// an invalid or empty address returns an empty list.
  Future<List<WalletEntity>> getWallets(final String ownerEmail) async {
    // sanitize ownerEmail, add validation for null, empty, special characters or whitespaces
    WidgetsFlutterBinding.ensureInitialized();
    WalletHelper walletHelper = WalletHelper();

    final sanitized = sanitizeOwnerEmail(ownerEmail);

    if (sanitized == null) {
      log.warning('getWallets called with invalid or empty ownerEmail: $ownerEmail');
      return List<WalletEntity>.empty();
    }

    return walletHelper.fetchItems(sanitized);
  }

  /// Persists the latest balance for [wallet] to the local database.
  Future<int> updateBalance(WalletEntity wallet) async {
    WidgetsFlutterBinding.ensureInitialized();
    WalletHelper walletHelper = WalletHelper();
    return walletHelper.updateBalance(wallet);
  }

  /// Inserts [wallet] into the local database. Throws if the insert fails.
  Future<void> persistNewWallet(WalletEntity wallet) async {
    WalletHelper helper = WalletHelper();
    var inserted = await helper.insertItem(wallet);

    if (inserted > 0) {
      log.info("Wallet persisted successfully");
    } else {
      log.warning("Failed to persist wallet");
      throw Exception("Failed to persist wallet");
    }
  }

  /// Deletes [wallet] from the local database, matched by private key.
  void delete(WalletEntity wallet) async {
    final db = await openDataBase();
    await db.delete("wallets", where: 'privateKey = ?', whereArgs: [wallet.privateKey]);
  }

  /// Returns the live RBTC balance for [dto] as a trimmed decimal string.
  ///
  /// Fetches directly from the Rootstock node; returns `"0.00"` on any error.
  Future<String> getBalance(WalletDTO dto) async {
    const returnValue = "0.00";
    try {
      final wei = await getRootstockBalanceFromBlockchainOnly(dto.publicKey!);
      return (wei.toRBTCTrimmedString());
    } catch (e) {
      return returnValue;
    }
  }

  /// Loads the cached BTC balance for [privateKey] from the local database and
  /// converts it to a USD-formatted string using the current price.
  Future<WalletDTO> getBitcoinBalanceOnDataBase(String privateKey) async {
    log.info("Searching BTC Balance");
    WalletHelper helper = WalletHelper();
    final wallet = await helper.getWalletByPrivateKey(privateKey);
    WalletDTO dto = WalletDTO(wallet: wallet, transactions: null, btcTransactions: null);
    try {
      final formatter = NumberFormat.simpleCurrency();
      var balance = wallet.btcAmount;
      log.info('Balance obtained on DataBase: $balance BTC');
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

  /// Refreshes the RBTC balance for [dto] from the Rootstock node, updates the
  /// local database if the value changed, and returns the updated [WalletDTO].
  Future<WalletDTO> getBalanceFromRsk(WalletDTO dto) async {
    try {
      var dataBase = await getBalanceRootstockFromDataBaseOnly(dto.wallet.privateKey);
      var blockchain = await getRootstockWalletRefreshed(dto.wallet);
      if (dataBase.balanceInDouble != blockchain.balanceInDouble) {
        dataBase.balanceInDouble = blockchain.balanceInDouble;
        dataBase.balance = blockchain.balance;
        dataBase.wallet.amount = dataBase.balanceInDouble;
        updateBalance(dataBase.wallet);
      }
      return dataBase;
    } catch (e) {
      log.severe("Error getting balance ${e}");
    }
    return dto;
  }

  /// Refreshes the BTC balance for [dto] from the blockchain, updates the local
  /// database if the value changed, and returns the updated [WalletDTO].
  Future<WalletDTO> getBalanceBitcoin(WalletDTO dto) async {
    try {
      var dataBase = await getBitcoinBalanceOnDataBase(dto.wallet.privateKey);

      var blockchainBalance = await getBitcoinBalanceFromBlockchainOnly(dto.wallet);

      if (blockchainBalance.btcBalanceInDouble != dataBase.btcBalanceInDouble) {
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

  /// Fetches the live RBTC balance for [address] directly from the Rootstock
  /// node, returning the result as a [Wei] value. Returns zero on error.
  Future<Wei> getRootstockBalanceFromBlockchainOnly(String address) async {
    Wei lastBalanceReceivedInWei = Wei(src: BigInt.zero, currency: "wei");
    try {
      final node = rootstockNodeUrl;
      final client = web3.Web3Client(node, http.Client());
      final lastBalanceReceivedInEtherAmount =
          await client.getBalance(web3.EthereumAddress.fromHex(address.toLowerCase()));
      lastBalanceReceivedInWei =
          Wei(src: lastBalanceReceivedInEtherAmount.getInWei, currency: "wei");
    } catch (error) {
      log.severe("Error getting balance", error);
    }
    return lastBalanceReceivedInWei;
  }

  /// Lists UTXOs via the configured Bitcoin Core node's wallet RPC
  /// (`listunspent`). Only works against a self-hosted node with the address
  /// imported into its wallet; public RPC providers reject this method.
  Future<List<Utxo>> listUtxos(String btcFromAddress) async {
    final node = bitcoinNodeUrl;
    if (node.isEmpty) {
      return List<Utxo>.empty();
    }

    try {
      final client = BitcoinNodeClient(rpcUrl: node);
      return await client.listUtxos(btcFromAddress);
    } catch (e) {
      log.severe("Error occurred listing UTXOs ${e}");
    }

    return List<Utxo>.empty();
  }

  /// Fetches the UTXO set for [btcFromAddress]. Prefers a public Esplora-style
  /// REST API (works without a self-hosted wallet node); falls back to the
  /// node's wallet RPC for self-hosted setups where Esplora isn't configured.
  Future<List<Utxo>> scanUtxosForAddress(String btcFromAddress) async {
    final node = bitcoinNodeUrl;
    if (node.isEmpty) {
      return List<Utxo>.empty();
    }

    final client = BitcoinNodeClient(rpcUrl: node);

    try {
      return await client.fetchUtxosFromEsplora(btcFromAddress, baseUrl: bitcoinEsploraUrl);
    } catch (e) {
      log.warning('Esplora UTXO lookup unavailable, falling back to node wallet RPC: $e');
    }

    try {
      return await client.listUtxos(btcFromAddress);
    } catch (e) {
      log.severe("Error occurred scanning UTXOs ${e}");
    }

    return List<Utxo>.empty();
  }

  /// Selects UTXOs from [allUtxos] sufficient to cover [amount] BTC including
  /// estimated fees. Delegates to [BitcoinNodeClient.selectUtxosForAmount].
  Future<List<Utxo>> selectUtxosForAmount(double amount, List<Utxo>? allUtxos) async {
    final node = bitcoinNodeUrl;
    if (node.isEmpty) {
      return List<Utxo>.empty();
    }

    try {
      final client = BitcoinNodeClient(rpcUrl: node);
      return await client.selectUtxosForAmount(amount, availableUtxos: allUtxos);
    } catch (e) {
      log.severe("Error occurred calculating fees ${e}");
    }

    return List<Utxo>.empty();
  }

  /// Estimates the BTC transaction fee for [selectedUtxos] targeting 6-block
  /// confirmation. Returns `0.0` when no node URL is configured or on error.
  Future<double> calculateBtcFee(List<Utxo> selectedUtxos) async {
    final node = bitcoinNodeUrl;
    // If no node URL is configured, use a client whose RPC always throws so
    // calculateFeeForBlocks falls through to its built-in 50 sats/vbyte
    // fallback — giving the UI a sensible non-zero fee estimate.
    final client = node.isEmpty
        ? BitcoinNodeClient(
            rpcUrl: 'http://localhost',
            rpcCallOverride: (_, [__]) async => throw Exception('Bitcoin node not configured'),
          )
        : BitcoinNodeClient(rpcUrl: node);

    try {
      final feeCalculated = await client.calculateFeeForBlocks(
        numInputs: 0,
        confTarget: 6,
        utxos: selectedUtxos,
      );
      return feeCalculated['feeBtc'] as double;
    } catch (e) {
      log.warning('Fee estimation unavailable, using static fallback: $e');
      return 0.0;
    }
  }

  /// Sends a BTC transfer built from [utxos], signed offline with the wallet's
  /// own WIF key, using the wallet's own address as change (no node-hosted
  /// wallet required). Persists the resulting transaction record regardless
  /// of outcome, mirroring [sendRBTC].
  Future<SimpleTransaction> sendTransferUsingUtxos(
      WalletEntity wallet, String destinationAddress, double amount, List<Utxo> utxos) async {
    final transactionToPersist = SimpleTransaction(
        transactionId: '',
        amountInWeis: amount.toString(),
        ddateTime: DateFormat("dd/MM/yyyy").format(DateTime.now()),
        walletId: wallet.walletId,
        valueInUsdFormatted: await calculateInUsd(amount),
        valueInWeiFormatted: amount.toString(),
        type: TransactionType.REGULAR_OUTGOING.type,
        status: "Sent",
        destination: destinationAddress,
        network: currentBitcoinNetwork.name,
        timestampMs: DateTime.now().millisecondsSinceEpoch);

    final node = bitcoinNodeUrl;
    if (node.isEmpty) {
      transactionToPersist.transactionSent = false;
      return transactionToPersist;
    }

    final client = BitcoinNodeClient(rpcUrl: node);

    try {
      // Derived live from the private key for the currently selected network
      // rather than trusting the wallet's stored btcWif/btcAddress columns,
      // which are only ever populated in testnet format at wallet creation
      // time — a stored value would be the wrong format/checksum on mainnet.
      final id = await client.sendTransferUsingUtxos(
        destinationAddress,
        amount,
        utxos,
        privKeysWif: [getBtcWifFromPrivateKey(wallet.privateKey, currentBitcoinNetwork)],
        changeAddress: getBtcAddressFromPrivateKey(wallet.privateKey, currentBitcoinNetwork),
      );

      log.info('BTC transfer sent, txid: $id');
      transactionToPersist.transactionId = id;
      transactionToPersist.transactionSent = true;
    } catch (e) {
      log.severe("Error occurred sending BTC transfer ${e}");
      transactionToPersist.transactionSent = false;
      try {
        await service.createOrUpdateTransaction(transactionToPersist);
      } catch (persistError) {
        log.severe("Error persisting failed BTC transaction $persistError");
      }
      throw StateError("Error occurred sending BTC transfer ${e}");
    }

    try {
      await service.createOrUpdateTransaction(transactionToPersist);
    } catch (e) {
      log.severe("Error persisting BTC transaction $e");
    }

    return transactionToPersist;
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
    Wei fee = Wei(src: BigInt.zero, currency: 'wei');
    try {
      final node = rootstockNodeUrl;
      if (node.isEmpty) {
        return fee;
      }

      final client = web3.Web3Client(node, http.Client());

      final unit = web3.EtherAmount.fromUnitAndValue(
        web3.EtherUnit.wei,
        value ?? BigInt.zero,
      );

      // get current gas price from node
      final gasPrice = await client.getGasPrice();
      log.info("gasPrice is ${gasPrice} ");

      // try to estimate gas; fall back to provided default if it fails
      int gasLimit;
      try {
        final estimated = await client.estimateGas(
          sender: web3.EthereumAddress.fromHex(from.toLowerCase()),
          to: web3.EthereumAddress.fromHex(to.toLowerCase()),
          value: unit,
        );
        gasLimit = estimated.toInt();
        log.info("gaslimit is ${gasLimit} ");
      } catch (e) {
        gasLimit = fallbackGasLimit;
        log.warning("Error estimating gas: ${e}");
      }

      final feeWei = gasPrice.getInWei * BigInt.from(gasLimit);
      fee = Wei(src: feeWei, currency: 'wei');
      log.info("fee calculated is ${fee}");

      await client.dispose();
    } catch (error) {
      log.severe("Error estimating RBTC fee", error);
    }

    log.info("returning the fee of ${fee}");
    return fee;
  }

  /// Sends [amount] wei of RBTC from [dto]'s wallet to [destinationAddress].
  ///
  /// Signs and broadcasts the transaction via the configured Rootstock node.
  /// Persists the resulting [SimpleTransaction] record regardless of outcome.
  // TODO(alexjavabraz): implement persistence of transaction sent
  Future<SimpleTransaction> sendRBTC(
      WalletDTO dto, String destinationAddress, BigInt amount) async {
    var unit = web3.EtherAmount.fromUnitAndValue(web3.EtherUnit.wei, amount);
    var transactionToPersist = await createTransactionInstance(dto, destinationAddress, amount);
    try {
      var node = rootstockNodeUrl;
      var httpClient = http.Client();
      final client = web3.Web3Client(node.toString(), httpClient);
      final credentials = web3.EthPrivateKey.fromHex(dto.wallet.privateKey);
      var chainId = await client.getChainId();
      web3.EtherAmount gasPrice = await client.getGasPrice();

      var transaction = web3.Transaction(
        to: web3.EthereumAddress.fromHex(destinationAddress.toLowerCase()),
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

  /// Decimal-adjusted ERC20 balance for [walletAddress], following the same
  /// decimals() scaling used in tokens_from_network.dart.
  ///
  /// [httpClientOverride] lets tests inject a mock HTTP client instead of
  /// hitting a real node.
  Future<double> getErc20Balance(String tokenAddress, String walletAddress,
      {http.Client? httpClientOverride}) async {
    final node = rootstockNodeUrl;
    if (node.isEmpty) {
      return 0;
    }
    web3.Web3Client? client;
    try {
      client = web3.Web3Client(node, httpClientOverride ?? http.Client());
      final contract =
          ERC20(address: web3.EthereumAddress.fromHex(tokenAddress.toLowerCase()), client: client);
      final balance = await contract
          .balanceOf((account: web3.EthereumAddress.fromHex(walletAddress.toLowerCase())));
      if (balance == BigInt.zero) {
        return 0;
      }
      final decimals = await contract.decimals();
      return balance / BigInt.from(10).pow(decimals.toInt());
    } catch (e) {
      log.severe('Error fetching ERC20 balance', e);
      return 0;
    } finally {
      await client?.dispose();
    }
  }

  /// [httpClientOverride] lets tests inject a mock HTTP client instead of
  /// hitting a real node.
  Future<int> getErc20Decimals(String tokenAddress, {http.Client? httpClientOverride}) async {
    final node = rootstockNodeUrl;
    if (node.isEmpty) {
      return 18;
    }
    web3.Web3Client? client;
    try {
      client = web3.Web3Client(node, httpClientOverride ?? http.Client());
      final contract =
          ERC20(address: web3.EthereumAddress.fromHex(tokenAddress.toLowerCase()), client: client);
      final decimals = await contract.decimals();
      return decimals.toInt();
    } catch (e) {
      log.severe('Error fetching ERC20 decimals', e);
      return 18;
    } finally {
      await client?.dispose();
    }
  }

  /// Checks whether [fromAddress] holds enough RBTC to cover gas for a
  /// transaction estimated at [estimatedGasLimit] units — gas on Rootstock is
  /// always paid in RBTC, even when the transaction being sent is an ERC20
  /// token transfer. On any error checking this (e.g. RPC hiccup), returns
  /// true (fail-open) so a transient network issue doesn't block sending —
  /// the node itself will still reject the transaction if gas genuinely runs
  /// out.
  ///
  /// [httpClientOverride] lets tests inject a mock HTTP client instead of
  /// hitting a real node.
  Future<bool> hasEnoughGasForRootstockTx(String fromAddress,
      {int estimatedGasLimit = 100000, http.Client? httpClientOverride}) async {
    final node = rootstockNodeUrl;
    if (node.isEmpty) {
      return true;
    }
    web3.Web3Client? client;
    try {
      client = web3.Web3Client(node, httpClientOverride ?? http.Client());
      final balance =
          await client.getBalance(web3.EthereumAddress.fromHex(fromAddress.toLowerCase()));
      final gasPrice = await client.getGasPrice();
      final requiredWei = gasPrice.getInWei * BigInt.from(estimatedGasLimit);
      return balance.getInWei >= requiredWei;
    } catch (e) {
      log.warning('Error checking gas sufficiency, allowing send to proceed', e);
      return true;
    } finally {
      await client?.dispose();
    }
  }

  /// Sends an ERC20 token transfer. Gas for this transaction is paid in RBTC
  /// regardless of which token is being transferred — callers should check
  /// [hasEnoughGasForRootstockTx] first so the user gets a clear error
  /// instead of a failed/reverted transaction.
  ///
  /// [httpClientOverride] lets tests inject a mock HTTP client instead of
  /// hitting a real node.
  Future<SimpleTransaction> sendErc20Token(
      WalletEntity wallet, String tokenAddress, String destinationAddress, BigInt amount,
      {String? valueInUsdFormatted,
      String? valueInTokenFormatted,
      http.Client? httpClientOverride}) async {
    final transactionToPersist = SimpleTransaction(
        transactionId: '',
        amountInWeis: amount.toString(),
        ddateTime: DateFormat("dd/MM/yyyy").format(DateTime.now()),
        walletId: wallet.walletId,
        valueInUsdFormatted: valueInUsdFormatted ?? '',
        valueInWeiFormatted: valueInTokenFormatted ?? amount.toString(),
        type: TransactionType.REGULAR_OUTGOING.type,
        status: "Sent",
        destination: destinationAddress,
        network: currentRootstockNetwork.name,
        timestampMs: DateTime.now().millisecondsSinceEpoch);

    final node = rootstockNodeUrl;
    if (node.isEmpty) {
      transactionToPersist.transactionSent = false;
      return transactionToPersist;
    }

    web3.Web3Client? client;
    try {
      client = web3.Web3Client(node, httpClientOverride ?? http.Client());
      final credentials = web3.EthPrivateKey.fromHex(wallet.privateKey);
      final contract =
          ERC20(address: web3.EthereumAddress.fromHex(tokenAddress.toLowerCase()), client: client);
      final txHash = await contract.transfer(
        (to: web3.EthereumAddress.fromHex(destinationAddress.toLowerCase()), value: amount),
        credentials: credentials,
      );
      transactionToPersist.transactionId = txHash;
      transactionToPersist.transactionSent = true;
    } catch (error) {
      log.severe("Error sending ERC20 transfer", error);
      transactionToPersist.transactionSent = false;
    } finally {
      await client?.dispose();
    }
    try {
      await service.createOrUpdateTransaction(transactionToPersist);
    } catch (error) {
      log.severe("Error persisting ERC20 transaction", error);
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
        log.info('Balance obtained on DataBase: $balanceRsk RSK');
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
    if (rootstockAmount == 0) {
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
      final node = bitcoinNodeUrl;
      if (node.isEmpty) {
        log.info("BITCOIN_NODE environment variable not set.");
        dto.amountInUsd = 0.00;
        dto.valueInWeiFormatted = "0.00";
        dto.balanceInUsd = "0";
        dto.balance = "0";
        return dto;
      }
      final client = BitcoinNodeClient(rpcUrl: node);
      final address = getBtcAddressFromPrivateKey(wallet.privateKey, currentBitcoinNetwork);

      double balance;
      try {
        balance = await client.fetchBalanceFromEsplora(address, baseUrl: bitcoinEsploraUrl);
      } catch (e) {
        log.warning('Esplora balance lookup unavailable, falling back to node RPC: $e');
        balance = await client.getBalanceForAddress(address);
      }
      log.info('Balance obtained on Blockchain: $balance BTC');
      final formatter = NumberFormat.simpleCurrency();

      final usdPrice = await _getPrice();
      final value = balance * usdPrice;
      dto.btcBalanceInDouble = balance;
      dto.amountInUsd = value;
      dto.balanceInUsd = formatter.format(value);
      dto.btcBalance = balance.toString();
      dto.wallet.btcAmount = dto.btcBalanceInDouble;

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
      log.info('Balance obtained on Blockchain: ${dto.balance} Rootstock');

      dto.balanceInUsd = dto.valueInUsdFormatted;
      return dto;
    } catch (error) {
      log.severe("Error creating wallet to display $error");
      throw Exception("Error creating wallet to display");
    }
  }

  /// Current BTC/RBTC USD price (they're pegged 1:1), as a plain double
  /// rather than a pre-formatted currency string.
  Future<double> getCurrentUsdPricePerCoin() async {
    return (await _getPrice()).toDouble();
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
          destination: destinationAddress,
          network: currentRootstockNetwork.name,
          timestampMs: DateTime.now().millisecondsSinceEpoch);
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

  String getBtcAddressFromPrivateKey(final String privateKey, [Network? network]) {
    return BitcoinWallet.generateCompressedAddress(
        privateKey, (network ?? Network.BITCOIN_TESTNET).networkByte);
  }

  String getBtcWifFromPrivateKey(String privateKey, [Network? network]) {
    return BitcoinWallet.generateWIF(privateKey, (network ?? Network.BITCOIN_TESTNET).networkByte);
  }

  // --- Network mode (testnet/mainnet) ---
  //
  // A user-facing toggle between testnet and mainnet. Persisted via
  // SharedPreferences and exposed as ChangeNotifier state so any widget
  // watching this WalletServiceImpl instance (it must be the shared Provider
  // instance, not a locally-constructed one) refreshes automatically when the
  // mode flips. Bitcoin addresses/WIFs are derived live from the private key
  // per mode rather than trusting the wallet's stored (testnet-only)
  // btcAddress/btcWif columns; Rootstock addresses are always derived live
  // already (EVM addresses don't change between networks, only the chainId
  // used for checksumming does).
  bool isMainnet = false;
  bool networkModeLoaded = false;

  /// Loads the persisted network mode (mainnet/testnet) from [SharedPreferences]
  /// on first call; subsequent calls are no-ops. Notifies listeners on change.
  Future<void> loadNetworkMode() async {
    if (networkModeLoaded) {
      return;
    }
    final saved = await getIsMainnet();
    isMainnet = saved;
    networkModeLoaded = true;
    notifyListeners();
  }

  /// Switches between mainnet and testnet, persists the choice, and notifies
  /// listeners so dependent widgets rebuild with the correct network context.
  Future<void> setNetworkMode(bool mainnet) async {
    isMainnet = mainnet;
    await setIsMainnet(mainnet);
    notifyListeners();
  }

  // --- Language override ---
  //
  // Null means "follow the system locale" (Flutter's own default behavior
  // when MaterialApp.locale is null). Set explicitly by the user in Settings.
  Locale? selectedLocale;
  bool localeLoaded = false;

  /// Loads the persisted language override from [SharedPreferences] on first
  /// call; subsequent calls are no-ops. A stored `null` means "follow the
  /// system locale". Notifies listeners on change.
  Future<void> loadLocale() async {
    if (localeLoaded) {
      return;
    }
    final code = await getLanguageCode();
    selectedLocale = code == null ? null : Locale(code);
    localeLoaded = true;
    notifyListeners();
  }

  /// Updates the app language to [locale], persists the choice, and notifies
  /// listeners. Pass `null` to revert to the system locale.
  Future<void> setLocale(Locale? locale) async {
    selectedLocale = locale;
    await setLanguageCode(locale?.languageCode);
    notifyListeners();
  }

  Network get currentBitcoinNetwork =>
      isMainnet ? Network.BITCOIN_MAINNET : Network.BITCOIN_TESTNET;

  Network get currentRootstockNetwork =>
      isMainnet ? Network.ROOTSTOCK_MAINNET : Network.ROOTSTOCK_TESTNET;

  // --- Custom node URL overrides (Settings) ---
  //
  // Kept separate per testnet/mainnet (see keys in util.dart) so switching
  // network mode can never silently reuse the other network's custom node.
  // A null entry means "use the .env default" for that slot.
  Map<String, String?> _customNodeUrls = {};
  bool customNodeUrlsLoaded = false;

  /// Loads persisted custom node/API URL overrides on first call; subsequent
  /// calls are no-ops. Notifies listeners on change.
  Future<void> loadCustomNodeUrls() async {
    if (customNodeUrlsLoaded) {
      return;
    }
    _customNodeUrls = {
      customBitcoinNodeUrlTestnetKey: await getCustomNodeUrl(customBitcoinNodeUrlTestnetKey),
      customBitcoinNodeUrlMainnetKey: await getCustomNodeUrl(customBitcoinNodeUrlMainnetKey),
      customBitcoinEsploraUrlTestnetKey: await getCustomNodeUrl(customBitcoinEsploraUrlTestnetKey),
      customBitcoinEsploraUrlMainnetKey: await getCustomNodeUrl(customBitcoinEsploraUrlMainnetKey),
      customRootstockNodeUrlTestnetKey: await getCustomNodeUrl(customRootstockNodeUrlTestnetKey),
      customRootstockNodeUrlMainnetKey: await getCustomNodeUrl(customRootstockNodeUrlMainnetKey),
    };
    customNodeUrlsLoaded = true;
    notifyListeners();
  }

  /// Persists a custom node/API URL override for [key] (one of the constants
  /// in util.dart) and notifies listeners. Pass null/empty to clear the
  /// override and revert to the .env default.
  Future<void> setCustomNodeUrl(String key, String? value) async {
    final trimmed = value?.trim();
    _customNodeUrls[key] = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    await setCustomNodeUrlPref(key, trimmed);
    notifyListeners();
  }

  String? get customBitcoinNodeUrlForCurrentMode =>
      _customNodeUrls[isMainnet ? customBitcoinNodeUrlMainnetKey : customBitcoinNodeUrlTestnetKey];

  String? get customBitcoinEsploraUrlForCurrentMode => _customNodeUrls[
      isMainnet ? customBitcoinEsploraUrlMainnetKey : customBitcoinEsploraUrlTestnetKey];

  String? get customRootstockNodeUrlForCurrentMode => _customNodeUrls[
      isMainnet ? customRootstockNodeUrlMainnetKey : customRootstockNodeUrlTestnetKey];

  String get bitcoinNodeUrl =>
      customBitcoinNodeUrlForCurrentMode ??
      (isMainnet ? dotenv.env['BITCOIN_NODE_MAIN'] : dotenv.env['BITCOIN_NODE']) ??
      '';

  String get bitcoinEsploraUrl {
    final custom = customBitcoinEsploraUrlForCurrentMode;
    if (custom != null) {
      return custom;
    }
    final mainUrl = dotenv.env['BITCOIN_ESPLORA_URL_MAIN'];
    if (isMainnet && mainUrl != null && mainUrl.isNotEmpty) {
      return mainUrl;
    }
    return dotenv.env['BITCOIN_ESPLORA_URL'] ?? '';
  }

  String get rootstockNodeUrl =>
      customRootstockNodeUrlForCurrentMode ??
      (isMainnet ? dotenv.env['ROOTSTOCK_NODE_MAIN'] : dotenv.env['ROOTSTOCK_NODE']) ??
      '';

  String get rskAddressTip {
    final mainTip = dotenv.env['RSK_ADDRESS_TIP_MAIN'];
    if (isMainnet && mainTip != null && mainTip.isNotEmpty) {
      return mainTip;
    }
    return dotenv.env['RSK_ADDRESS_TIP'] ?? '';
  }

  int get rootstockTokenChainId => isMainnet ? 30 : 31;

  /// Blockscout-compatible API base for Rootstock transaction history — the
  /// official explorer.testnet.rootstock.io frontend doesn't expose this
  /// classic/v2 API itself, only its own Next.js app, so this points at the
  /// public Blockscout instances instead.
  String get rootstockExplorerApiUrl {
    final envKey = isMainnet ? 'ROOTSTOCK_EXPLORER_API_URL_MAIN' : 'ROOTSTOCK_EXPLORER_API_URL';
    final override = dotenv.env[envKey];
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return isMainnet
        ? 'https://rootstock.blockscout.com'
        : 'https://rootstock-testnet.blockscout.com';
  }

  Future<double> _getHistoricUsdPrice(DateTime date) async {
    try {
      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/coins/bitcoin/history?date=$dateStr&localization=false'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final marketData = body['market_data'] as Map<String, dynamic>?;
        final currentPrice = marketData?['current_price'] as Map<String, dynamic>?;
        final usd = currentPrice?['usd'];
        if (usd is num) {
          return usd.toDouble();
        }
      }
    } catch (e) {
      log.warning('Error fetching historic USD price for $date', e);
    }
    return (await _getPrice()).toDouble();
  }

  /// Syncs Bitcoin transaction history for [wallet] from Esplora, persisting
  /// any not already stored (matched by txid) and pricing each in USD using
  /// the rate at the time it happened. Returns the newly-discovered
  /// *incoming* transactions only, so callers can notify the user.
  Future<List<SimpleTransaction>> syncBitcoinTransactions(WalletEntity wallet) async {
    final newIncoming = <SimpleTransaction>[];
    final base = bitcoinEsploraUrl;
    if (base.isEmpty) {
      return newIncoming;
    }
    try {
      final address = getBtcAddressFromPrivateKey(wallet.privateKey, currentBitcoinNetwork);
      final response = await http.get(Uri.parse('$base/address/$address/txs'));
      if (response.statusCode != 200) {
        return newIncoming;
      }
      final txs = jsonDecode(response.body) as List<dynamic>;
      final txService = CreateTransactionServiceImpl();
      final formatter = NumberFormat.simpleCurrency();

      for (final txJson in txs) {
        if (txJson is! Map<String, dynamic>) {
          continue;
        }
        final tx = txJson;
        final txid = tx['txid'] as String;
        if (await txService.transactionExists(txid)) {
          continue;
        }

        final vin = (tx['vin'] as List<dynamic>).cast<Map<String, dynamic>>();
        final vout = (tx['vout'] as List<dynamic>).cast<Map<String, dynamic>>();
        final isOutgoing = vin.any((input) {
          final prevout = input['prevout'] as Map<String, dynamic>?;
          return prevout != null && prevout['scriptpubkey_address'] == address;
        });
        final myOutputsTotalSats = vout
            .where((o) => o['scriptpubkey_address'] == address)
            .fold<int>(0, (sum, o) => sum + (o['value'] as int));

        final status = tx['status'] as Map<String, dynamic>?;
        final blockTimeSec = status?['block_time'] as int?;
        final timestamp = blockTimeSec != null
            ? DateTime.fromMillisecondsSinceEpoch(blockTimeSec * 1000)
            : DateTime.now();
        final amountBtc = myOutputsTotalSats / 100000000.0;
        final historicPrice = await _getHistoricUsdPrice(timestamp);
        final otherAddress = vout
            .map((o) => o['scriptpubkey_address'] as String?)
            .firstWhere((a) => a != null && a != address, orElse: () => '');

        final record = SimpleTransaction(
          transactionId: txid,
          amountInWeis: amountBtc.toString(),
          ddateTime: DateFormat("dd/MM/yyyy").format(timestamp),
          walletId: wallet.walletId,
          valueInUsdFormatted: formatter.format(amountBtc * historicPrice),
          valueInWeiFormatted: amountBtc.toStringAsFixed(8),
          type: (isOutgoing ? TransactionType.REGULAR_OUTGOING : TransactionType.REGULAR_INCOMING)
              .type,
          status: (status?['confirmed'] == true) ? 'Confirmed' : 'Pending',
          destination: isOutgoing ? (otherAddress ?? '') : address,
          network: currentBitcoinNetwork.name,
          timestampMs: timestamp.millisecondsSinceEpoch,
        );
        await txService.createOrUpdateTransaction(record);
        if (!isOutgoing) {
          newIncoming.add(record);
        }
      }
    } catch (e) {
      log.severe('Error syncing Bitcoin transactions', e);
    }
    return newIncoming;
  }

  /// Syncs Rootstock native-coin (RBTC) transaction history for [wallet] from
  /// a Blockscout-compatible API, persisting any not already stored (matched
  /// by tx hash) and pricing each in USD using the rate at the time it
  /// happened (RBTC is pegged 1:1 with BTC). Returns the newly-discovered
  /// *incoming* transactions only, so callers can notify the user. Skips
  /// contract calls/ERC20 token transfers — only native RBTC transfers are
  /// covered here, matching the Send/Receive buttons this feeds.
  Future<List<SimpleTransaction>> syncRootstockTransactions(WalletEntity wallet) async {
    final newIncoming = <SimpleTransaction>[];
    final base = rootstockExplorerApiUrl;
    if (base.isEmpty) {
      return newIncoming;
    }
    try {
      final address = wallet.publicKey;
      final response = await http.get(Uri.parse('$base/api/v2/addresses/$address/transactions'));
      if (response.statusCode != 200) {
        return newIncoming;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (body['items'] as List<dynamic>?) ?? [];
      final txService = CreateTransactionServiceImpl();
      final formatter = NumberFormat.simpleCurrency();

      for (final itemJson in items) {
        final item = itemJson as Map<String, dynamic>;
        final hash = item['hash'] as String?;
        if (hash == null || await txService.transactionExists(hash)) {
          continue;
        }

        final types = (item['transaction_types'] as List<dynamic>?)?.cast<String>() ?? [];
        if (!types.contains('coin_transfer')) {
          continue;
        }

        final toHash = (item['to'] as Map<String, dynamic>?)?['hash'] as String?;
        final fromHash = (item['from'] as Map<String, dynamic>?)?['hash'] as String?;
        final isIncoming = toHash != null && toHash.toLowerCase() == address.toLowerCase();
        final valueWei = BigInt.tryParse(item['value'] as String? ?? '0') ?? BigInt.zero;
        final wei = Wei(src: valueWei, currency: 'wei');
        final timestampStr = item['timestamp'] as String?;
        final timestamp = timestampStr != null
            ? (DateTime.tryParse(timestampStr) ?? DateTime.now())
            : DateTime.now();
        final historicPrice = await _getHistoricUsdPrice(timestamp);

        final record = SimpleTransaction(
          transactionId: hash,
          amountInWeis: valueWei.toString(),
          ddateTime: DateFormat("dd/MM/yyyy").format(timestamp),
          walletId: wallet.walletId,
          valueInUsdFormatted: formatter.format(wei.getWei() * historicPrice),
          valueInWeiFormatted: wei.toRBTCTrimmedStringPlaces(10),
          type: (isIncoming ? TransactionType.REGULAR_INCOMING : TransactionType.REGULAR_OUTGOING)
              .type,
          status: (item['status'] as String? ?? '') == 'ok' ? 'Confirmed' : 'Pending',
          destination: isIncoming ? (fromHash ?? '') : (toHash ?? ''),
          network: currentRootstockNetwork.name,
          timestampMs: timestamp.millisecondsSinceEpoch,
        );
        await txService.createOrUpdateTransaction(record);
        if (isIncoming) {
          newIncoming.add(record);
        }
      }
    } catch (e) {
      log.severe('Error syncing Rootstock transactions', e);
    }
    return newIncoming;
  }
}
