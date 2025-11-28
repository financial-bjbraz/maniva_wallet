import 'package:my_rootstock_wallet/entities/transaction_helper.dart';
import 'package:my_rootstock_wallet/entities/wallet_helper.dart';
import 'package:my_rootstock_wallet/util/wei.dart';
import 'package:web3dart/web3dart.dart';

import '../util/util.dart';

class WalletDTO {
  late String? publicKey;
  final WalletEntity wallet;
  late double amountInUsd = 0.00;
  late double amountInWeis;
  late String valueInUsdFormatted = "0.00";
  late String valueInWeiFormatted = "0.00";
  Set<SimpleTransaction>? transactions;
  Set<SimpleTransaction>? btcTransactions;
  bool updated = false;
  late Wei lastBalanceReceivedInWei;
  late EtherAmount lastBalanceReceivedInEtherAmount;
  late String balance = "0.000";
  double balanceInDouble = 0.000;
  late String balanceInUsd = "0.000";

  late String btcBalance = "0.000";
  double btcBalanceInDouble = 0.000;
  late String btcBalanceInUsd = "0.000";

  WalletDTO({required this.wallet, required this.transactions, required this.btcTransactions});

  String getName() {
    return "Wallet #${wallet.walletId}";
  }

  String getPrivateKeyToDisplay() {
    return "";
  }

  String getAddress() {
    return formatAddress(wallet.publicKey);
  }

  String getCompleteAddress() {
    return wallet.publicKey;
  }

  String getValueInUsd() {
    return valueInUsdFormatted;
  }
}
