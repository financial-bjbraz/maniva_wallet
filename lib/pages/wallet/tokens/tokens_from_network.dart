import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      required this.currentAddress,
      required this.rootstockNodeUrl,
      this.onBalancesLoaded});

  final WalletEntity wallet;
  final SimpleUser user;
  final Network selectedNetwork;

  final String currentAddress;

  /// Resolved per the app's current testnet/mainnet toggle
  /// (WalletServiceImpl.rootstockNodeUrl) — passed in rather than read from
  /// dotenv directly here, so this widget doesn't need its own network-mode
  /// awareness.
  final String rootstockNodeUrl;

  /// Reports each token's symbol and decimal-adjusted balance after every
  /// refresh, so callers (e.g. the account overview's grand total) can price
  /// tokens that have a real market quote without re-fetching balances.
  final void Function(Map<String, double> balancesBySymbol)? onBalancesLoaded;

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
  i1.Web3Client? _web3Client;
  bool isLoading = true;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    searchTokensForCurrentChainId();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _web3Client?.dispose();
    super.dispose();
  }

  searchTokensForCurrentChainId() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      loaded = false;
    });

    var dbTokens = await service.fetchItems(widget.selectedNetwork.networkId); //;
    final balancesBySymbol = <String, double>{};
    final futures = dbTokens.map<Future<Widget>>((dbToken) async {
      final String contractAddress = dbToken.address;
      final String myAddress = widget.wallet.publicKey;
      final balance = await callSmartContract(contractAddress, myAddress);
      balancesBySymbol[dbToken.symbol] = balance;

      return TokenItem(
        tokenName: dbToken.symbol2,
        tokenSymbol: dbToken.symbol,
        tokenAddress: dbToken.address,
        tokenBalance: balance.toStringAsFixed(4),
        networkId: dbToken.network,
      );
    });

    final listTokens = await Future.wait(futures);
    listTokens.sort((a, b) {
      final double aBal = double.tryParse((a as TokenItem).tokenBalance) ?? 0.0;
      final double bBal = double.tryParse((b as TokenItem).tokenBalance) ?? 0.0;
      return bBal.compareTo(aBal);
    });

    widget.onBalancesLoaded?.call(balancesBySymbol);

    if (mounted) {
      setState(() {
        tokens = listTokens;
        isLoading = false;
        loaded = true;
      });
    }

    // Poll every 5s until the first successful load, then back off to every
    // 250s — a fixed-interval Timer.periodic can't change its own period, so
    // this reschedules itself as a one-shot timer each time instead.
    final secs = tokens.isNotEmpty ? 250 : 5;
    _periodicTimer?.cancel();
    _periodicTimer = Timer(Duration(seconds: secs), searchTokensForCurrentChainId);
  }

  Future<double> callSmartContract(String tokenAddress, String myAddress) async {
    try {
      final node = widget.rootstockNodeUrl;
      if (node.isEmpty) {
        if (kDebugMode) {
          _log.info("ROOTSTOCK_NODE environment variable not set.");
        }
        return 0;
      }
      // Reuse one client across calls/ticks instead of allocating a new
      // Web3Client+http.Client per token every time this runs.
      final client = _web3Client ??= i1.Web3Client(node, http.Client());

      final i1.EthereumAddress contractAddr = i1.EthereumAddress.fromHex(tokenAddress);
      final i1.EthereumAddress myAccount = i1.EthereumAddress.fromHex(myAddress);
      ERC20 token = ERC20(address: contractAddr, client: client);
      final BigInt balanceObtained = await token.balanceOf((account: myAccount));
      if (balanceObtained == BigInt.zero) {
        return 0;
      }

      final BigInt decimals = await token.decimals();
      final double scaled = balanceObtained / BigInt.from(10).pow(decimals.toInt());
      if (kDebugMode) {
        _log.info(
            "Raw balance obtained from $contractAddr: $balanceObtained ($decimals decimals) => $scaled from account $myAccount");
      }
      return scaled;
    } catch (e) {
      return 0;
    }
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
