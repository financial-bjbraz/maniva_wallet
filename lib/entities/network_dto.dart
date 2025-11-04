import 'package:my_rootstock_wallet/entities/token_helper.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/util/network.dart';

class NetworkDto {
  final Network network;
  late List<Token> tokens;
  late bool tokensLoaded = false;
  late WalletDTO walletDTO;

  NetworkDto({required this.network, List<Token>? tokens}) : tokens = tokens ?? [];

  setTokens(List<Token> tokenList) {
    tokens = tokenList;
  }

  setWalletDTO(WalletDTO dto) {
    walletDTO = dto;
  }
}
