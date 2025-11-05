import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/pages/wallet/tokens/tokens_from_network.dart';
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
  late String balance = formatBalance("0");
  late String balanceInUsd = formatUsd("0");
  Timer? _periodicTimer;

  late String currentAddress =
      Network.generateFormattedAddress(Network.BITCOIN_TESTNET, widget.wallet);
  late NetworkDto selectedNetwork;

  late List<NetworkDto> availableNetworks;

  int operation = 0;
  static const int BITCOIN_INDEX = 0;
  static const int ROOTSTOCK_INDEX = 1;
  static const int TRANSACTIONS_INDEX = 2;

  bool loaded = false;
  bool receiveScreenOpened = false;
  bool openListTransactions = false;

  TokenServiceImpl tokenServiceImpl = TokenServiceImpl();

  TextEditingController addressController = TextEditingController();
  TextEditingController amountController = TextEditingController();

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

  loadWalletData() async {
    if (loaded) {
      return;
    }
    _isLoading = false;
    loaded = true;
  }

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
        if (index < TRANSACTIONS_INDEX) {
          await _callData(index);
        }

        setState(() {
          openListTransactions = index == TRANSACTIONS_INDEX;
        });
      },
    );
  }

  void startPeriodicRefresh() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) return;
      try {
        setState(() {
          loaded = false;
          _isLoading = true;
        });

        print("Waiting...");
        if (mounted) {
          for (int safeIndex = 0; safeIndex < availableNetworks.length; safeIndex++) {
            availableNetworks[safeIndex].fetchDateFromBlockchain();
          }
          loaded = true;
          //_isLoading = false;
        }

        setState(() {
          loaded = true;
          _isLoading = false;
        });
      } catch (_) {
        // ignore or handle errors
      }
    });
  }

  _callData(int index) async {
    availableNetworks = [
      NetworkDto(
          network: Network.BITCOIN_TESTNET, tokens: [], wallet: widget.wallet, user: widget.user),
      NetworkDto(
          network: Network.ROOTSTOCK_TESTNET, tokens: [], wallet: widget.wallet, user: widget.user),
    ];
    selectedNetwork = availableNetworks[index];
    selectedNetwork.fetchDataFromDataBase();

    if (!availableNetworks[index].tokensLoaded) {
      availableNetworks[index].tokens =
          await tokenServiceImpl.list(availableNetworks[index].network.networkId);
      availableNetworks[index].tokensLoaded = true;
    }
    selectedNetwork = availableNetworks[index];
    loaded = false;
    _isLoading = false;
    currentAddress = Network.generateFormattedAddress(selectedNetwork.network, widget.wallet);
  }

  Widget _createMainScreen() {
    return ShimmerLoading(
        isLoading: _isLoading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HuxContextMenu(
              menuItems: [
                HuxContextMenuItem(
                  text: AppLocalizations.of(context)!.copiar,
                  icon: FeatherIcons.copy,
                  onTap: () async {
                    String address = selectedNetwork.network == Network.BITCOIN_TESTNET ||
                            selectedNetwork.network == Network.BITCOIN_MAINNET
                        ? widget.wallet.btcAddress
                        : widget.wallet.publicKey;
                    await Clipboard.setData(ClipboardData(text: address));
                    showMessage(
                        "${AppLocalizations.of(context)!.copiedMessage}: $address", context);
                  },
                ),
              ],
              child: Card(
                elevation: 5, // Adds a shadow to the card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                margin: const EdgeInsets.all(16), // Margin around the card
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
                    child: Image.asset(
                      "assets/icons/btc.png",
                      fit: BoxFit.cover,
                    ),
                  ), // Icon on the left
                  title: Text(
                    currentAddress,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // Main text
                  subtitle: _showSaldo
                      ? Text(
                          "${balance} ~ ${balanceInUsd}",
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
                        ), // Secondary text
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
    _callData(BITCOIN_INDEX);
    loadWalletData();
    startPeriodicRefresh();
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
                      isLoading: _isLoading,
                      loaded: loaded,
                      dbTokens2: selectedNetwork.tokens,
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
