import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/pages/details/detail_list.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_receive.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_send.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/table_transactions.dart';
import 'package:provider/provider.dart';

import '../../../entities/simple_user.dart';
import '../../../services/wallet_service.dart';
import '../../entities/wallet_entity.dart';
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
  late WalletServiceImpl walletService = Provider.of<WalletServiceImpl>(context, listen: false);
  bool _showSaldo = true;
  bool _isLoading = true;
  final double iconSize = 48;
  late String balance = "0";
  late String balanceInUsd = "0";
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadWalletData();
  }

  loadWalletData() async {
    if (mounted) {
      int seconds = loaded ? 30 : 3;
      await Future.delayed(Duration(seconds: seconds), () {
        walletService
            .convert(widget.wallet)
            .then((value) => walletService.createWalletToDisplay(value).then((dto) => {
                  setState(() {
                    if (dto.valueInWeiFormatted != balance) {
                      walletDto = dto;
                      balance = dto.valueInWeiFormatted;
                      balanceInUsd = dto.valueInUsdFormatted;
                      _isLoading = false;
                    }
                  })
                }));
        loaded = true;
      });
    }
  }

  Widget _buildFirstLine() {
    return ShimmerLoading(
      isLoading: _isLoading,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, top: 1, bottom: 20, right: 10),
        child: Row(
          children: <Widget>[
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
                        fontSize: 20,
                      ),
                    ),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(
                          text: Network.generateAddress(selectedNetwork, widget.wallet)));
                      showMessage(AppLocalizations.of(context)!.copiedMessage, context);
                    },
                  )
                : Container(height: 32, width: 230, color: Colors.grey[200]),
            const SizedBox(
              width: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton() {
    return SegmentedButton<Network>(
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.grey;
          },
        ),
      ),
      segments: <ButtonSegment<Network>>[
        ButtonSegment<Network>(
          value: Network.ROOTSTOCK_TESTNET,
          label: const Text('Rootstock'),
          icon: rootstockSelected,
        ),
        ButtonSegment<Network>(
          value: Network.BITCOIN_TESTNET,
          label: const Text('Bitcoin'),
          icon: bitcoinSelected,
        ),
      ],
      selected: <Network>{selectedNetwork},
      onSelectionChanged: (Set<Network> newSelection) {
        setState(() {
          selectedNetwork = newSelection.first;

          if (selectedNetwork == Network.ROOTSTOCK_TESTNET) {
            rootstockSelected = Network.getIcon(Network.ROOTSTOCK_TESTNET);
            bitcoinSelected = Network.getIconGrey(Network.BITCOIN_TESTNET);
          } else {
            rootstockSelected = Network.getIconGrey(Network.ROOTSTOCK_TESTNET);
            bitcoinSelected = Network.getIcon(Network.BITCOIN_TESTNET);
          }

          currentAddress = Network.generateFormattedAddress(selectedNetwork, widget.wallet);
        });
      },
    );
  }

  Widget _createMainScreen() {
    return Column(
      children: [
        ShimmerLoading(
          isLoading: _isLoading,
          child: const Padding(
            padding: EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 10),
            child: Row(
              children: [],
            ),
          ),
        ),
        ShimmerLoading(
            isLoading: _isLoading,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/rbtc2.png",
                    width: iconSize,
                  ),
                  _showSaldo
                      ? Text.rich(
                          TextSpan(
                              text: balance,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                backgroundColor: orange(),
                              )),
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        )
                      : Container(height: 32, width: 230, color: Colors.grey[200]),
                  const SizedBox(
                    width: 5,
                  ),
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
            )),
        ShimmerLoading(
            isLoading: _isLoading,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/btc.png",
                    width: iconSize,
                  ),
                  _showSaldo
                      ? Text.rich(
                          TextSpan(
                              text: balance,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                backgroundColor: orange(),
                              )),
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        )
                      : Container(height: 32, width: 230, color: Colors.grey[200]),
                  const SizedBox(
                    width: 5,
                  ),
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
            )),
        ShimmerLoading(
          isLoading: _isLoading,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: const Color.fromRGBO(121, 198, 0, 1),
                  size: iconSize,
                ),
                _showSaldo
                    ? Text.rich(
                        TextSpan(
                            text: balanceInUsd,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                backgroundColor: Color.fromRGBO(121, 198, 0, 1))),
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      )
                    : Container(height: 32, width: 230, color: Colors.grey[200]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _lastTransactions() {
    return TableTransactions(wallet: widget.wallet, user: widget.user);
  }

  Widget _buttonsLine() {
    final String send = AppLocalizations.of(context)!.send;
    final String receive = AppLocalizations.of(context)!.receive;

    return ShimmerLoading(
      isLoading: _isLoading,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: blackWhiteButton,
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
              child: Row(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.call_made,
                        color: Colors.black,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        send,
                        style: blackText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: blackWhiteButton,
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
              child: Row(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(receive, style: blackText),
                      const SizedBox(
                        width: 10,
                      ),
                      const Icon(
                        Icons.call_received,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isLoading = false;
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
              const SizedBox(height: 16),
              _buildFirstLine(),
              const SizedBox(height: 16),
              _createMainScreen(),
              const SizedBox(height: 16),
              _buttonsLine(),
              const SizedBox(height: 16),
              _lastTransactions(),
            ],
          ),
        ),
      ),
    );
  }
}
