import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/pages/wallet/tokens/tokens_from_network.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_receive.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_send.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/table_transactions.dart';

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

  _loadBalanceFromDatabaseAndTokens() async {
    final WalletDTO dto = await walletService.getBalanceFromDataBase(widget.wallet.privateKey);

    setState(() {
      selectedNetwork.walletDTO.btcBalance = dto.btcBalance;
      selectedNetwork.walletDTO.btcBalanceInUsd = dto.btcBalanceInUsd;
      selectedNetwork.walletDTO.balance = dto.balance;
      selectedNetwork.walletDTO.balanceInUsd = dto.balanceInUsd;

      availableNetworks[0].walletDTO.btcBalance = dto.btcBalance;
      availableNetworks[0].walletDTO.btcBalanceInUsd = dto.btcBalanceInUsd;
      availableNetworks[0].walletDTO.balance = dto.balance;
      availableNetworks[0].walletDTO.balanceInUsd = dto.balanceInUsd;

      availableNetworks[1].walletDTO.btcBalance = dto.btcBalance;
      availableNetworks[1].walletDTO.btcBalanceInUsd = dto.btcBalanceInUsd;
      availableNetworks[1].walletDTO.balance = dto.balance;
      availableNetworks[1].walletDTO.balanceInUsd = dto.balanceInUsd;

      loaded = false;
      _isLoading = false;
    });
  }

  Widget _createMainScreen() {
    return ShimmerLoading(
        isLoading: _isLoading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HuxContextMenu(
              menuItems: [],
              child: Card(
                elevation: 5, // Adds a shadow to the card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                margin: const EdgeInsets.all(16), // Margin around the card
                child: ListTile(
                  leading: selectedNetwork.network == Network.BITCOIN_TESTNET
                      ? Image.asset(
                          "assets/icons/btc.png",
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                        )
                      : Image.asset(
                          "assets/icons/rbtc2.png",
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                        ),
                  trailing: PopupMenuButton<int>(
                    onSelected: (int value) {
                      switch (value) {
                        case SEND:
                          print("Send");
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  Send(user: widget.user, walletDto: selectedNetwork.walletDTO),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                var begin = const Offset(0.0, 1.0);
                                var end = Offset.zero;
                                var curve = Curves.ease;

                                var tween =
                                    Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                          break;
                        case RECEIVE:
                          String completeAddress =
                              selectedNetwork.network == Network.BITCOIN_TESTNET ||
                                      selectedNetwork.network == Network.BITCOIN_MAINNET
                                  ? widget.wallet.btcAddress
                                  : widget.wallet.publicKey;

                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => Receive(
                                  user: widget.user,
                                  walletDto: selectedNetwork.walletDTO,
                                  network: selectedNetwork.network,
                                  address: completeAddress),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                var begin = const Offset(0.0, 1.0);
                                var end = Offset.zero;
                                var curve = Curves.ease;

                                var tween =
                                    Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                          break;
                        case VIEW:
                          String address = selectedNetwork.network == Network.BITCOIN_TESTNET ||
                                  selectedNetwork.network == Network.BITCOIN_MAINNET
                              ? widget.wallet.btcAddress
                              : widget.wallet.publicKey;
                          walletService.openBlockExplorerForAddress(
                              address, selectedNetwork.network);
                          break;
                        case COPY:
                          print("Copy");
                          String address = selectedNetwork.network == Network.BITCOIN_TESTNET ||
                                  selectedNetwork.network == Network.BITCOIN_MAINNET
                              ? widget.wallet.btcAddress
                              : widget.wallet.publicKey;
                          Clipboard.setData(ClipboardData(text: address)).then((value) {
                            showMessage("${AppLocalizations.of(context)!.copiedMessage}: $address",
                                context);
                          });
                          break;
                        case REFRESH:
                          print("Send");
                      }
                      setState(() {});
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                      const PopupMenuItem<int>(
                        value: SEND,
                        child: ListTile(
                          leading: Icon(Icons.call_made),
                          title: Text('Send'),
                        ),
                      ),
                      const PopupMenuItem<int>(
                        value: RECEIVE,
                        child: ListTile(
                          leading: Icon(Icons.call_received),
                          title: Text('Receive'),
                        ),
                      ),
                      const PopupMenuItem<int>(
                        value: VIEW,
                        child: ListTile(
                          leading: Icon(Icons.open_in_new),
                          title: Text('View on explorer'),
                        ),
                      ),
                      const PopupMenuItem<int>(
                        value: COPY,
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Copy'),
                        ),
                      ),
                      const PopupMenuItem<int>(
                        value: REFRESH,
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Refresh'),
                        ),
                      ),
                    ],
                  ),
                  titleAlignment: titleAlignment,
                  title: Text(
                    currentAddress,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Main text
                  subtitle: _showSaldo
                      ? Text(
                          selectedNetwork.network == Network.BITCOIN_TESTNET
                              ? "${selectedNetwork.walletDTO.btcBalance} ~ ${selectedNetwork.walletDTO.btcBalanceInUsd}"
                              : "${selectedNetwork.walletDTO.balance} ~ ${selectedNetwork.walletDTO.balanceInUsd}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        )
                      : const Text(
                          "- ~ -",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                  // Secondary text
                  onTap: () {
                    // Handle tap event on the card
                    print('Card tapped!');
                  },
                ),
              ),
            ),
          ],
        ));
  }

  Widget _lastTransactions() {
    return TableTransactions(wallet: widget.wallet, user: widget.user);
  }

  @override
  void initState() {
    super.initState();

    var bitCoin = NetworkDto(
      network: Network.BITCOIN_TESTNET,
      tokens: [],
      wallet: widget.wallet,
      user: widget.user,
    );
    var rootstock = NetworkDto(
      network: Network.ROOTSTOCK_TESTNET,
      tokens: [],
      wallet: widget.wallet,
      user: widget.user,
    );
    availableNetworks = [bitCoin, rootstock];
    selectedNetwork = availableNetworks[BITCOIN_INDEX];

    if (!mounted) return;
    _loadBalanceFromDatabaseAndTokens().then((_) {
      print("loaded from database");
    });
    startPeriodicRefresh();
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Shimmer(
        linearGradient: shimmerGradient,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(color: Colors.white)),
          child: ListView(
            physics: _isLoading ? const NeverScrollableScrollPhysics() : null,
            children: [
              _buildSegmentButton(),
              !openListTransactions ? _createMainScreen() : Container(),
              !openListTransactions
                  ? TokensFromNetwork(
                      wallet: widget.wallet,
                      user: widget.user,
                      selectedNetwork: selectedNetwork.network,
                      currentAddress: currentAddress,
                    )
                  : const SizedBox(height: 0),
              openListTransactions ? _lastTransactions() : const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }
}
