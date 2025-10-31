import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/pages/wallet/tokens/tokens_from_network.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/table_transactions.dart';

import '../../../services/wallet_service.dart';
import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
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

  late String currentAddress =
      Network.generateFormattedAddress(Network.ROOTSTOCK_TESTNET, widget.wallet);
  late Network selectedNetwork = Network.ROOTSTOCK_TESTNET;

  int operation = 0;
  bool loaded = false;
  bool receiveScreenOpened = false;

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

    int seconds = loaded ? 30 : 1;
    await Future.delayed(Duration(seconds: seconds), () {
      walletService
          .convert(widget.wallet)
          .then((value) => walletService.createGenericWalletToDisplay(selectedNetwork, value).then(
                  (dto) => {
                        if (mounted)
                          {
                            setState(() {
                              if (dto.balance != balance || dto.balanceInUsd != balanceInUsd) {
                                walletDto = dto;
                                balance = formatBalance(dto.balance);
                                balanceInUsd = formatUsd(dto.balanceInUsd);
                              }
                              _isLoading = false;
                            })
                          }
                      }, onError: (err) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    balance = formatBalance("0");
                    balanceInUsd = formatUsd("0");
                    loaded = false;
                  });
                }
              }))
          .whenComplete(() => loaded = true);
    });
  }

  Widget _buildFirstLine() {
    loadWalletData();

    return ShimmerLoading(
        isLoading: _isLoading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HuxContextMenu(
              menuItems: [
                HuxContextMenuItem(
                  text: 'Copy',
                  icon: FeatherIcons.copy,
                  onTap: () => print('Copy action'),
                ),
                HuxContextMenuItem(
                  text: 'Share',
                  icon: FeatherIcons.clipboard,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(
                        text: Network.generateAddress(selectedNetwork, widget.wallet)));
                    showMessage(AppLocalizations.of(context)!.copiedMessage, context);
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
                    child: Icon(
                      Icons.wallet_rounded,
                      color: lightBlue(),
                      size: iconSize,
                    ),
                  ), // Icon on the left
                  title: Text(
                    currentAddress,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // Main text
                  subtitle: Text(
                    "${balance} ~ ${balanceInUsd}",
                    style: const TextStyle(
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

  Widget _buildSegmentButton() {
    return HuxTabs(
      size: HuxTabSize.large,
      variant: HuxTabVariant.minimal,
      tabs: const [
        HuxTabItem(label: 'Bitcoin', content: Text(''), icon: Icons.currency_bitcoin),
        HuxTabItem(label: 'Rootstock', content: Text(''), icon: Icons.account_balance),
      ],
      onTabChanged: (index) {
        setState(() {
          selectedNetwork = index == 0 ? Network.BITCOIN_TESTNET : Network.ROOTSTOCK_TESTNET;
          loaded = false;
          _isLoading = false;
          currentAddress = Network.generateFormattedAddress(selectedNetwork, widget.wallet);
          loadWalletData();
        });
      },
    );
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
                  text: 'Copy',
                  icon: FeatherIcons.copy,
                  onTap: () => print('Copy action'),
                ),
                HuxContextMenuItem(
                  text: 'Paste',
                  icon: FeatherIcons.clipboard,
                  onTap: () => print('Paste action'),
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
                    selectedNetwork.name,
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
  }

  @override
  void dispose() {
    _isLoading = false;
    loadWalletData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    loadWalletData();
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
              _buildFirstLine(),
              _createMainScreen(),
              TokensFromNetwork(
                  wallet: widget.wallet,
                  user: widget.user,
                  selectedNetwork: selectedNetwork,
                  isLoading: _isLoading,
                  loaded: loaded,
                  currentAddress: currentAddress),
              const SizedBox(height: 16),
              _lastTransactions(),
            ],
          ),
        ),
      ),
    );
  }
}
