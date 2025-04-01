import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../entities/simple_user.dart';
import '../../services/wallet_service.dart';
import '../../util/util.dart';

/// Essa classe pode ser adaptada para mostrar em uma tela completa todas as transacoes de uma wallet, ou podemos colocar filtros
 class AccountTransactions extends StatefulWidget {
  final SimpleUser user;
  final WalletDTO walletDto;
  const AccountTransactions({super.key, required this.user, required this.walletDto});

  @override
  _AccountTransactions createState() {
    return _AccountTransactions();
  }
}

class _AccountTransactions extends State<AccountTransactions> {
  bool processing = false;
  bool _showSaldo = false;
  String address = "";
  late WalletServiceImpl walletService;
  List<String> splittedMnemonic = List<String>.filled(1, "");
  final valueController = TextEditingController();
  late String balance = "0";
  late String balanceInUsd = "0";

  _AccountTransactions();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (address.isEmpty) {
      address = widget.walletDto.getAddress();
    }
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (address.isEmpty) {
      address = widget.walletDto.getAddress();
    }
    final String sendTransaction =
        AppLocalizations.of(context)!.sendTransaction;

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                const Icon(Icons.add_circle, color: Colors.white),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  sendTransaction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color.fromRGBO(158, 118, 255, 1),
        ),
        body: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, top: 10, bottom: 10, right: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wallet_rounded,
                                  color: lightBlue(),
                                  size: 48,
                                ),
                                _showSaldo
                                    ? Text.rich(
                                  addressText(address),
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    backgroundColor:
                                    Color.fromRGBO(7, 255, 208, 1),
                                    fontSize: 20,
                                  ),
                                )
                                    : Container(
                                    height: 32,
                                    width: 230,
                                    color: Colors.grey[200]),
                                const SizedBox(
                                  width: 5,
                                ),
                                GestureDetector(
                                  child: Icon(Icons.copy, color: lightBlue()),
                                  onTap: () async {
                                    await Clipboard.setData(
                                        ClipboardData(text: address));
                                    showMessage(
                                        "Copied to the clipboard", context);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, top: 10, bottom: 10, right: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  "assets/icons/rbtc2.png",
                                  width: 48,
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
                                    : Container(
                                    height: 32,
                                    width: 230,
                                    color: Colors.grey[200]),
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
                                      width: 40,
                                      color: orange()),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, top: 10, bottom: 10, right: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  color: Color.fromRGBO(121, 198, 0, 1),
                                  size: 48,
                                ),
                                _showSaldo
                                    ? Text.rich(
                                  TextSpan(
                                      text: balanceInUsd,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          backgroundColor: Color.fromRGBO(
                                              121, 198, 0, 1))),
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                  ),
                                )
                                    : Container(
                                    height: 32,
                                    width: 230,
                                    color: Colors.grey[200]),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 20,
                            thickness: 5,
                            indent: 20,
                            endIndent: 0,
                            color: Colors.black,
                          ),
                          ExpansionTile(
                            title: const Text('Transaction Sent 0.001'),
                            subtitle: const Text('USD 150.99'),
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(child:
                                  ElevatedButton(
                                    style: blackWhiteButton,
                                    onPressed: () async {
                                      final Uri url = Uri.parse('https://flutter.dev');
                                      if (!await launchUrl(url)) {
                                        throw Exception('Could not launch $url');
                                      }
                                    },
                                    child: const Row(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Icon(Icons.remove_circle, color: Colors.red),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              "0xe6e495a493d67ae081cc473ca7db387f7adacb376ac8fb74f1fdb6501205fc3d",
                                              style: smallBlackText,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Icon(
                                              Icons.open_in_new,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(
                            width: 10,
                          ),

                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                        bottom: 12,
                        left: 10,
                        right: 15,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          width: 7,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5)),
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                  flex: 1,
                                  child: Container(color: Colors.orange)),
                              Expanded(
                                  flex: 2,
                                  child: Container(color: Colors.blue)),
                              Expanded(
                                  flex: 3,
                                  child: Container(color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
