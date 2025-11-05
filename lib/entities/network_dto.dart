import 'package:my_rootstock_wallet/entities/token_helper.dart';
import 'package:my_rootstock_wallet/entities/user_helper.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/entities/wallet_helper.dart';
import 'package:my_rootstock_wallet/util/network.dart';

import '../services/wallet_service.dart';

class NetworkDto {
  final Network network;
  final WalletEntity wallet;
  final SimpleUser user;
  late List<Token> tokens;
  late bool tokensLoaded = false;
  late WalletDTO walletDTO;
  late WalletServiceImpl walletService = WalletServiceImpl();

  NetworkDto({required this.network, required this.wallet, required this.user, List<Token>? tokens})
      : tokens = tokens ?? [];

  setTokens(List<Token> tokenList) {
    tokens = tokenList;
  }

  void fetchDataFromDataBase() async {
    walletDTO = await walletService.getBalanceFromDataBase(network, wallet.privateKey);
  }

  void fetchDateFromBlockchain() async {
    walletDTO = await walletService.getBalanceFromBlockchain(network, walletDTO);
    wallet.btcAmount = walletDTO.btcBalanceInDouble;
    wallet.amount = walletDTO.balanceInDouble;
    await walletService.updateBalance(wallet);
  }
}
