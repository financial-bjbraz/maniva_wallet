import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/pages/wallet/transactions/account_receive.dart';
import 'package:maniva_wallet/pages/wallet/transactions/bitcoin_account_send.dart';

import '../../entities/network_dto.dart';
import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/wallet_service.dart';
import '../../util/network.dart';
import '../../util/shimmer_loading.dart';
import '../../util/util.dart';
import '../../util/widget_shimmer.dart';

class ViewBitcoinAccount extends StatefulWidget {
  const ViewBitcoinAccount({super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _ViewBitcoinAccount createState() => _ViewBitcoinAccount();
}

class _ViewBitcoinAccount extends State<ViewBitcoinAccount> {
  static final _log = Logger('view_wallet_detail_btc');
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
  Network.generateFormattedAddress(Network.BITCOIN_TESTNET, widget.wallet);
  late String completeAddress =
  Network.generateAddress(Network.BITCOIN_TESTNET, widget.wallet);
  final bool _showSaldo = true;

  @override
  void initState() {
    _isLoading = true;
    selectedNetwork = NetworkDto(network: Network.BITCOIN_TESTNET, wallet: widget.wallet, user: widget.user);
    selectedNetwork.walletDTO.btcBalanceInDouble = widget.wallet.btcAmount;
    selectedNetwork.walletDTO.btcBalance = widget.wallet.btcAmount.toString();
    fetchDataBaseData();
    super.initState();
  }



  fetchDataBaseData() async {
    selectedNetwork.walletDTO.btcBalanceInUsd = await walletService.calculateInUsd(selectedNetwork.walletDTO.btcBalanceInDouble);

    if(mounted){
      walletService.getBalanceBitcoin(selectedNetwork.walletDTO).then((walletDtoReceived){

        if(selectedNetwork.walletDTO.updated){
          selectedNetwork.walletDTO.updated = false;
          setState(() async {
            _isLoading = true;
            await Future.delayed(const Duration(seconds: 2));
            selectedNetwork.walletDTO = walletDtoReceived;
            if (kDebugMode) {
              _log.info("walletDto refresehd ${walletDtoReceived
                  .btcBalanceInDouble}");
            }
            _isLoading = false;
          });
        }
      });

      setState(() {
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
                                "assets/icons/btc.png",
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              ),
                              trailing: PopupMenuButton<int>(
                                onSelected: (int value) {
                                  switch (value) {
                                    case SEND:
                                      if (kDebugMode) {
                                        _log.info("Send");
                                      }

                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              BitcoinAccountSendSend(user: widget.user, selectedNetwork: selectedNetwork),
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
                                    case RECEIVE:


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
                                    case VIEW:

                                      walletService.openBlockExplorerForAddress(
                                          completeAddress, selectedNetwork.network);
                                    case COPY:
                                      if (kDebugMode) {
                                        _log.info("Copy");
                                      }

                                      Clipboard.setData(ClipboardData(text: completeAddress)).then((value) {
                                        showMessage("${AppLocalizations.of(context)!.copiedMessage}: $completeAddress",
                                            context);
                                      });
                                    case REFRESH:
                                      if (kDebugMode){
                                        _log.info("Send");
                                      }
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
                                "${selectedNetwork.walletDTO.btcBalance} ~ ${selectedNetwork.walletDTO.btcBalanceInUsd}",

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
                                if (kDebugMode) {
                                  _log.info('Card tapped!');
                                }
                              },
                            ),
                          ),




                    ],
                  ))
            ],
          ),
        ),);

  }

}