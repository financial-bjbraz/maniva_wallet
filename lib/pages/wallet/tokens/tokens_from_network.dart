import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:maniva_wallet/pages/wallet/tokens/token_item.dart';
import 'package:web3dart/web3dart.dart' as i1;
import 'package:logging/logging.dart';

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
      required this.currentAddress});

  final WalletEntity wallet;
  final SimpleUser user;
  final Network selectedNetwork;

  final String currentAddress;

  @override
  _TokensFromNetwork createState() => _TokensFromNetwork();
}

class _TokensFromNetwork extends State<TokensFromNetwork> {
  static final _log = Logger('tokens_from_network');
  String accountBalance = "0";
  String tokenSymbol = "";
  final List<Token> dbTokens = [];
  final TokenHelper service = TokenHelper();
  List<Widget> tokens = [];
  Timer? _periodicTimer;
  bool isLoading = true;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    searchTokensForCurrentChainId();
  }

  searchTokensForCurrentChainId() async {
    if(!mounted) {
      return;
    }

    _periodicTimer?.cancel();
    int secs = (tokens.isNotEmpty ? 250 : 5);
    _periodicTimer = Timer.periodic(Duration(seconds: secs), (timer) async {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = true;
        loaded = false;
      });

      var dbTokens = await service.fetchItems(widget.selectedNetwork.networkId); //;
      final futures = dbTokens.map<Future<Widget>>((dbToken) async {
        final String contractAddress = dbToken.address;
        final String myAddress = widget.wallet.publicKey;
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
      listTokens.sort((a, b) {
        final double aBal = double.tryParse((a as TokenItem).tokenBalance) ?? 0.0;
        final double bBal = double.tryParse((b as TokenItem).tokenBalance) ?? 0.0;
        return bBal.compareTo(aBal);
      });

      if (mounted) {
        setState(() {
          tokens = listTokens;
          isLoading = false;
          loaded = true;
        });
      }
    });
  }

  Future<String> callSmartContract(String tokenAddress, String myAddress) async {
    var accountBalance = "0.000";
    i1.Web3Client? client;
    try {
      final node = dotenv.env['ROOTSTOCK_NODE'];
      if (node == null || node.isEmpty) {
        if (kDebugMode) {
          _log.info("ROOTSTOCK_NODE environment variable not set.");
        }
        return "0.00";
      }
      client = i1.Web3Client(node, http.Client());
      // final credentials = i1.EthPrivateKey.fromHex(widget.wallet.privateKey);

      final i1.EthereumAddress contractAddr = i1.EthereumAddress.fromHex(tokenAddress);
      final i1.EthereumAddress myAccount = i1.EthereumAddress.fromHex(myAddress);
      ERC20 token = ERC20(address: contractAddr, client: client);
      final BigInt balanceObtained = await token.balanceOf((account: myAccount));
      if (kDebugMode) {
        _log.info(
            "Raw balance obtained from $contractAddr, and the balance is $balanceObtained from account $myAccount");
      } // final BigInt decimalsObtained = await token.decimals();
      // final int decimals = decimalsObtained.toInt();

      if (balanceObtained == BigInt.zero) {
        return "0.000";
      }

      // Decimal balanceDecimal = Decimal.parse(balanceObtained.toString());
      // Decimal divisor = Decimal.parse(pow(10, decimals).toString());
      // final Decimal formattedBalance = balanceDecimal == Decimal.zero
      //     ? Decimal.zero
      //     : Decimal.parse((balanceDecimal / divisor).toString());
      accountBalance = balanceObtained.toString();
    } catch (e) {
      accountBalance = "0.000";
    } finally {
      client?.dispose();
    }
    return accountBalance;
  }

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: isLoading,
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
