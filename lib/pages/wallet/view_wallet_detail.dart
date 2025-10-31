import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/pages/wallet/tokens/tokens_from_network.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_receive.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_send.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/table_transactions.dart';

import '../../../services/wallet_service.dart';
import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../util/network.dart';
import '../../util/shimmer_loading.dart';
import '../../util/util.dart';
import '../../util/widget_shimmer.dart';
import '../details/detail_list.dart';

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

    return Padding(
      padding: const EdgeInsets.all(32),
      child: ShimmerLoading(
        isLoading: _isLoading,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.wallet_rounded,
              color: lightBlue(),
              size: iconSize,
            ),
            _showSaldo
                ? GestureDetector(
                    child: Text.rich(
                      addressText(currentAddress),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: lightBlue(),
                        fontSize: fontSize,
                      ),
                    ),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(
                          text: Network.generateAddress(selectedNetwork, widget.wallet)));
                      showMessage(AppLocalizations.of(context)!.copiedMessage, context);
                    },
                  )
                : Container(height: 32, width: 230, color: Colors.grey[200]),
            HuxButton(
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: Network.generateAddress(selectedNetwork, widget.wallet)));
                showMessage(AppLocalizations.of(context)!.copiedMessage, context);
              },
              isLoading: _isLoading,
              primaryColor: Colors.white, // Text color auto-calculated for readability
              child: const Icon(Icons.copy),
            ),
            HuxButton(
              onPressed: () {
                final Send sendScreenChild = Send(user: widget.user, walletDto: walletDto);

                Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      DetailList(child: sendScreenChild),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var begin = const Offset(0.0, 1.0);
                    var end = Offset.zero;
                    var curve = Curves.ease;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ));
              },
              isLoading: _isLoading,
              primaryColor: Colors.white, // Text color auto-calculated for readability
              child: const Icon(Icons.call_made),
            ),
            HuxButton(
              onPressed: () {
                if (!receiveScreenOpened) {
                  final Receive receiveScreenChild =
                      Receive(user: widget.user, walletDto: walletDto);
                  showBottomSheet(
                    context: context,
                    backgroundColor: Colors.black,
                    builder: (context) => receiveScreenChild,
                  );
                } else {
                  Navigator.pop(context);
                }
                receiveScreenOpened = !receiveScreenOpened;
              },
              isLoading: _isLoading,
              primaryColor: Colors.white, // Text color auto-calculated for readability
              child: const Icon(Icons.call_received),
            ),
          ],
        ),
      ),
    );
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
    final String send = AppLocalizations.of(context)!.send;
    final String receive = AppLocalizations.of(context)!.receive;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: ShimmerLoading(
        isLoading: _isLoading,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Network.getIcon(selectedNetwork),
            _showSaldo
                ? Text.rich(
                    TextSpan(
                        text: balance,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          backgroundColor: orange(),
                        )),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                    ),
                  )
                : Container(height: 32, width: 230, color: Colors.grey[200]),
            _showSaldo
                ? Text.rich(
                    TextSpan(
                        text: balanceInUsd,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          backgroundColor: orange(),
                        )),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                    ),
                  )
                : Container(height: 32, width: 230, color: Colors.grey[200]),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showSaldo = !_showSaldo;
                });
              },
              child: SvgPicture.asset(
                  _showSaldo
                      ? "assets/icons/eye-off-svgrepo-com.svg"
                      : "assets/icons/eye-svgrepo-com.svg",
                  semanticsLabel: "view",
                  width: iconSize,
                  color: orange()),
            ),
          ],
        ),
      ),
    );
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
