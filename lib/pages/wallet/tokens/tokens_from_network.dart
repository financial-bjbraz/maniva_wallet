import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:my_rootstock_wallet/pages/wallet/tokens/token_item.dart';
import 'package:web3dart/web3dart.dart' as _i1;

import '../../../contracts/ERC20.g.dart';
import '../../../entities/token_helper.dart';
import '../../../entities/user_helper.dart';
import '../../../entities/wallet_helper.dart';
import '../../../util/network.dart';
import '../../../util/shimmer_loading.dart';

class TokensFromNetwork extends StatefulWidget {
  const TokensFromNetwork(
      {super.key,
      required this.wallet,
      required this.user,
      required this.selectedNetwork,
      required this.isLoading,
      required this.loaded,
      required this.currentAddress,
      required this.dbTokens2});

  final WalletEntity wallet;
  final SimpleUser user;
  final Network selectedNetwork;
  final bool isLoading;
  final bool loaded;
  final String currentAddress;
  final List<Token> dbTokens2;

  @override
  _TokensFromNetwork createState() => _TokensFromNetwork();
}

class _TokensFromNetwork extends State<TokensFromNetwork> {
  String accountBalance = "0";
  String tokenSymbol = "";
  List<Widget> tokens = [];

  @override
  void initState() {
    super.initState();
    searchTokensForCurrentChainId();
  }

  searchTokensForCurrentChainId() async {
    if (widget.loaded) {
      return;
    }
    var dbTokens =
        widget.dbTokens2; //await tokenServiceImpl.list(widget.selectedNetwork.networkId);
    print(
        "searchTokensForCurrentChainId: obtained ${dbTokens.length} tokens, using ${widget.selectedNetwork.networkId} network");
    final futures = dbTokens.map<Future<Widget>>((dbToken) async {
      final String contractAddress = dbToken.address;
      final String myAddress = widget.currentAddress;
      final balance = await callSmartContract(contractAddress, myAddress);
      return TokenItem(
        tokenName: dbToken.symbol2,
        tokenSymbol: dbToken.symbol,
        tokenAddress: dbToken.address,
        tokenBalance: balance,
        networkId: dbToken.network,
      );
    });

    final listTokens = await Future.wait(futures);

    if (mounted) {
      setState(() {
        tokens = listTokens;
      });
    }
  }

  Future<String> callSmartContract(String tokenAddress, String myAddress) async {
    var accountBalance = "0.000";
    _i1.Web3Client? client;
    try {
      final node = dotenv.env['ROOTSTOCK_NODE'];
      if (node == null || node.isEmpty) {
        print("ROOTSTOCK_NODE environment variable not set.");
        return "0.00";
      }
      client = _i1.Web3Client(node!, http.Client());
      final credentials = _i1.EthPrivateKey.fromHex(widget.wallet.privateKey);

      final _i1.EthereumAddress contractAddr = _i1.EthereumAddress.fromHex(tokenAddress);
      final _i1.EthereumAddress myAccount = _i1.EthereumAddress.fromHex(myAddress);
      ERC20 token = ERC20(address: contractAddr, client: client);
      print("Fetching data from $contractAddr");
      final BigInt balanceObtained = await token.balanceOf((account: myAccount));
      final BigInt decimalsObtained = await token.decimals();
      final int decimals = decimalsObtained.toInt();

      Decimal balanceDecimal = Decimal.parse(balanceObtained.toString());
      Decimal divisor = Decimal.parse(pow(10, decimals).toString());
      final Decimal formattedBalance = Decimal.parse((balanceDecimal / divisor).toString());
      accountBalance = formattedBalance.toString();
    } catch (e) {
      accountBalance = "0.000";
    } finally {
      client?.dispose();
    }
    return accountBalance;
  }

  @override
  Widget build(BuildContext context) {
    print("Shimming? ${!widget.loaded}");
    searchTokensForCurrentChainId();
    return ShimmerLoading(
      isLoading: !widget.loaded,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...tokens,
        ],
      ),
    );
  }
}
