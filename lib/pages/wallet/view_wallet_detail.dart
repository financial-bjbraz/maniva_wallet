import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/pages/wallet/tokens/tokens_from_network.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_receive.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_send.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/table_transactions.dart';
import 'package:my_rootstock_wallet/pages/wallet/view_wallet_detail_btc.dart';
import 'package:my_rootstock_wallet/pages/wallet/view_wallet_detail_rootstock.dart';

import '../../../services/wallet_service.dart';
import '../../entities/network_dto.dart';
import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/tokken_service.dart';
import '../../util/network.dart';
import '../../util/shimmer_loading.dart';
import '../../util/util.dart';
import '../../util/widget_shimmer.dart';

class ViewWalletDetailPage extends StatefulWidget {
  const ViewWalletDetailPage({super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _ViewWalletApp createState() => _ViewWalletApp();
}

class _ViewWalletApp extends State<ViewWalletDetailPage> {
  late WalletDTO walletDto;
  late WalletServiceImpl walletService = WalletServiceImpl();
  bool _showSaldo = true;
  bool _isLoading = true;
  final double iconSize = 48;
  final double fontSize = 20;
  Timer? _periodicTimer;
  ListTileTitleAlignment? titleAlignment;

  late String currentAddress =
      Network.generateFormattedAddress(Network.BITCOIN_TESTNET, widget.wallet);
  late NetworkDto selectedNetwork;
  late List<NetworkDto> availableNetworks;

  int operation = 0;
  static const int BITCOIN_INDEX = 0;
  static const int ROOTSTOCK_INDEX = 1;
  static const int TRANSACTIONS_INDEX = 2;
  static const int SEND = 1;
  static const int RECEIVE = 2;
  static const int VIEW = 3;
  static const int COPY = 4;
  static const int REFRESH = 5;

  bool loaded = false;
  bool receiveScreenOpened = false;
  bool openListTransactions = false;
  bool searchedFirstTime = false;

  TokenServiceImpl tokenServiceImpl = TokenServiceImpl();

  TextEditingController addressController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  WalletServiceImpl walletServiceImpl = WalletServiceImpl();

  Image rootstockSelected = Image.asset(
    "assets/icons/rbtc2.png",
    width: 48,
  );

  Image bitcoinSelected = Image.asset(
    "assets/icons/btc.png",
    width: 48,
    color: Colors.grey,
  );

  _ViewWalletApp();

  Widget _buildSegmentButton() {
    return HuxTabs(
      size: HuxTabSize.large,
      variant: HuxTabVariant.minimal,
      tabs: const [
        HuxTabItem(label: 'Bitcoin', content: Text(''), icon: Icons.currency_bitcoin),
        HuxTabItem(label: 'Rootstock', content: Text(''), icon: Icons.account_balance),
        HuxTabItem(label: 'Transactions', content: Text(''), icon: Icons.list),
      ],
      onTabChanged: (index) async {
        setState(() {
          openListTransactions = index == TRANSACTIONS_INDEX;

          if (!openListTransactions) {
            selectedNetwork = availableNetworks[index];
            currentAddress =
                Network.generateFormattedAddress(selectedNetwork.network, widget.wallet);
          }
        });
      },
    );
  }

  _loadBalanceFromBlockchain() {
    try {
      setState(() {
        loaded = false;
        _isLoading = true;
      });
      print("Refreshing data from blockchain...");
      walletServiceImpl.getDataFromBlockchain(widget.wallet).then((_) {
        print("Updating...");
      });
    } catch (_) {
      print("Error refreshing data: $_");
    } finally {
      setState(() {
        loaded = true;
        _isLoading = false;
      });
    }
  }

  void startPeriodicRefresh() async {
    _periodicTimer?.cancel();
    _periodicTimer =
        Timer.periodic(Duration(seconds: !searchedFirstTime ? 180 : 360), (timer) async {
      if (!mounted) return;
      await _loadBalanceFromBlockchain();
      searchedFirstTime = true;
    });
  }

  @override
  void initState() {
    super.initState();
    if (!mounted) return;
    loaded = true;
    _isLoading = false;
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _isLoading = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                border: Border.all(color: Colors.white)),
      child: DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          toolbarHeight: 20,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(icon: Image.asset(
                "assets/icons/btc.png",
                fit: BoxFit.cover,
                width: 40,
                height: 40,
              )),
              Tab(icon: Image.asset(
                "assets/icons/rbtc2.png",
                fit: BoxFit.cover,
                width: 30,
                height: 30,
              )),
              const Tab(icon: Icon(Icons.list)),
            ],
          ),
          title: const Text('Account #1'),
        ),
        body: TabBarView(
          children: [
            ViewBitcoinAccount(wallet: widget.wallet, user:widget.user),
            ViewRootstockAccount(wallet: widget.wallet, user:widget.user),
            const Icon(Icons.directions_bike),
          ],
        ),
      ),
    ),);
    //
    // return Scaffold(
    //     backgroundColor: Colors.black,
    //     body: Shimmer(
    //       linearGradient: shimmerGradient,
    //       child: Container(
    //         decoration: BoxDecoration(
    //             borderRadius: BorderRadius.circular(20),
    //             color: Colors.white,
    //             border: Border.all(color: Colors.white)),
    //         child: ListView(
    //           physics: _isLoading ? const NeverScrollableScrollPhysics() : null,
    //           children: [
    //             _buildSegmentButton(),
    //             !openListTransactions ? _createMainScreen() : Container(),
    //             !openListTransactions
    //                 ? TokensFromNetwork(
    //                     wallet: widget.wallet,
    //                     user: widget.user,
    //                     selectedNetwork: selectedNetwork.network,
    //                     currentAddress: currentAddress,
    //                   )
    //                 : const SizedBox(height: 0),
    //             openListTransactions ? _lastTransactions() : const SizedBox(height: 0),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );

  }
}
