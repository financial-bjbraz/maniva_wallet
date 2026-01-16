import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/pages/wallet/tokens/tokens_from_network.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_receive.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/account_send.dart';

import '../../entities/network_dto.dart';
import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/wallet_service.dart';
import '../../util/network.dart';
import '../../util/shimmer_loading.dart';
import '../../util/util.dart';
import '../../util/widget_shimmer.dart';

class ViewRootstockAccount extends StatefulWidget {
  const ViewRootstockAccount({super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _ViewRootstockAccount createState() => _ViewRootstockAccount();
}

class _ViewRootstockAccount extends State<ViewRootstockAccount> {
  bool _isLoading = true;
  static const int SEND = 1;
  static const int RECEIVE = 2;
  static const int VIEW = 3;
  static const int COPY = 4;
  static const int REFRESH = 5;
  late NetworkDto selectedNetwork;
  late WalletServiceImpl walletService = WalletServiceImpl();
  ListTileTitleAlignment? titleAlignment;
  late String formattedAddress =
      Network.generateFormattedAddress(Network.ROOTSTOCK_TESTNET, widget.wallet);
  late String completeAddress = Network.generateAddress(Network.ROOTSTOCK_TESTNET, widget.wallet);
  bool _showSaldo = true;

  @override
  void initState() {
    selectedNetwork =
        NetworkDto(network: Network.ROOTSTOCK_TESTNET, wallet: widget.wallet, user: widget.user);
    fetchDataBaseData();
    super.initState();
  }

  fetchDataBaseData() async {
    var walletDto = await walletService.getBalanceFromRsk(selectedNetwork.walletDTO);
    if (mounted) {
      setState(() {
        selectedNetwork.walletDTO = walletDto;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _isLoading = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Shimmer(
        linearGradient: shimmerGradient,
        child: ListView(
          physics: _isLoading ? const NeverScrollableScrollPhysics() : null,
          children: [
            ShimmerLoading(
                isLoading: _isLoading,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Card(
                        elevation: 5, // Adds a shadow to the card
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                        margin: const EdgeInsets.all(16), // Margin around the card
                        child: ListTile(
                          leading: Image.asset(
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
                                          Send(user: widget.user, selectedNetwork: selectedNetwork),
                                      transitionsBuilder:
                                          (context, animation, secondaryAnimation, child) {
                                        var begin = const Offset(0.0, 1.0);
                                        var end = Offset.zero;
                                        var curve = Curves.ease;

                                        var tween = Tween(begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));

                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                  break;
                                case RECEIVE:
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          Receive(
                                              user: widget.user,
                                              walletDto: selectedNetwork.walletDTO,
                                              network: selectedNetwork.network,
                                              address: completeAddress),
                                      transitionsBuilder:
                                          (context, animation, secondaryAnimation, child) {
                                        var begin = const Offset(0.0, 1.0);
                                        var end = Offset.zero;
                                        var curve = Curves.ease;

                                        var tween = Tween(begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));

                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                  break;
                                case VIEW:
                                  walletService.openBlockExplorerForAddress(
                                      completeAddress, selectedNetwork.network);
                                  break;
                                case COPY:
                                  print("Copy");
                                  String address = widget.wallet.publicKey;
                                  Clipboard.setData(ClipboardData(text: address)).then((value) {
                                    showMessage(
                                        "${AppLocalizations.of(context)!.copiedMessage}: $address",
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
                            formattedAddress,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Main text
                          subtitle: _showSaldo
                              ? Text(
                                  "${selectedNetwork.walletDTO.balance} ~ ${selectedNetwork.walletDTO.balanceInUsd}",
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

                  ],
                )
            ),
            TokensFromNetwork(wallet: widget.wallet, user: widget.user, selectedNetwork: selectedNetwork.network, currentAddress: completeAddress)

          ],
        ),
      ),
    );
  }
}
