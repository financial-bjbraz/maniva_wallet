import 'package:my_rootstock_wallet/entities/simple_transaction.dart';
import 'package:my_rootstock_wallet/entities/wallet_entity.dart';
import 'package:my_rootstock_wallet/util/wei.dart';
import 'package:web3dart/web3dart.dart';

import '../util/util.dart';

class WalletDTO {

  late String? publicKey;
  final WalletEntity wallet;
  late double amountInUsd;
  late double amountInWeis;
  late String valueInUsdFormatted;
  late String valueInWeiFormatted;
  Set<SimpleTransaction>? transactions;
  bool updated = false;
  late Wei lastBalanceReceivedInWei;
  late EtherAmount lastBalanceReceivedInEtherAmount;

  WalletDTO({required this.wallet, required this.transactions});

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

  String getValueInUsd(){
    return valueInUsdFormatted;
  }

}
