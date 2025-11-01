import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_rootstock_wallet/pages/wallet/create_import/import_wallet_seed_detail.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

import '../../../entities/user_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/wallet_service.dart';
import '../../../util/util.dart';
import '../../details/detail_list.dart';

// seeed generation page, this component doesnt create a new wallet, just creates seed to be imported
class CreateNewWalletDetail extends StatefulWidget {
  final SimpleUser user;

  const CreateNewWalletDetail({super.key, required this.user});

  @override
  _CreateNewWalletDetail createState() {
    return _CreateNewWalletDetail();
  }
}

class _CreateNewWalletDetail extends State<CreateNewWalletDetail> {
  bool processing = false;
  bool _created = false;
  late WalletServiceImpl walletService;
  List<String> splittedMnemonic = List<String>.filled(1, "");
  late EthereumAddress address;

  _CreateNewWalletDetail();

  @override
  void initState() {
    super.initState();
  }

  void createNewAccount() async {
    if (!_created) {
      walletService = Provider.of<WalletServiceImpl>(context);
      final mnemonic = walletService.generateMnemonic();
      final privateKey = await walletService.getPrivateKey(mnemonic);
      address = walletService.getPublicKey(privateKey);
      splittedMnemonic = mnemonic.split(' ');
      setState(() {
        splittedMnemonic = mnemonic.split(' ');
      });
      _created = !_created;
    }
  }

  @override
  Widget build(BuildContext context) {
    int contador = 0;
    createNewAccount();
    final String copy = AppLocalizations.of(context)!.copiar;

    Widget createTextFieldWithSeed(String word) {
      contador++;
      return Expanded(
        child: TextFormField(
          enabled: false,
          style: const TextStyle(fontSize: 6),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(2, 2, 2, 1),
            labelText: "$contador. $word",
          ),
        ),
      );
    }

    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(88, 36),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );

    sentToDetail() {
      processing = false;
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DetailList(
            child: ImportNewWalletBySeedDetail(
          user: widget.user,
        )),
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
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Icon(Icons.add_circle, color: Colors.white),
                SizedBox(
                  width: 5,
                ),
                Text(
                  "Criando uma nova wallet",
                  style: TextStyle(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Padding(
                                  padding: createPaddingBetweenRows(),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Padding(
                                  padding: createPaddingBetweenRows(),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Padding(
                                  padding: createPaddingBetweenRows(),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Padding(
                                  padding: createPaddingBetweenRows(),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                      const SizedBox(width: 5),
                                      createTextFieldWithSeed(splittedMnemonic.length > contador
                                          ? splittedMnemonic.elementAt(contador)
                                          : ""),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: createPaddingBetweenDifferentRows(),
                                  child: !processing
                                      ? ElevatedButton(
                                          onPressed: () async {
                                            await Clipboard.setData(ClipboardData(
                                                text: splittedMnemonic
                                                    .toString()
                                                    .replaceAll("[", "")
                                                    .replaceAll("]", "")));
                                            showMessage("Copied to the clipboard", context);

                                            setState(() {
                                              processing = true;
                                              delay(context, 5).whenComplete(() {
                                                processing = false;
                                                sentToDetail();
                                              });
                                            });
                                          },
                                          style: raisedButtonStyle,
                                          child: Row(
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  const Icon(Icons.copy),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    copy,
                                                    style: const TextStyle(fontSize: 20),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      : const Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [CircularProgressIndicator()]),
                                ),
                              ],
                            ),

                            // SizedBox(

                            //   width: double.infinity,
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: <Widget>[
                            //       GestureDetector(
                            //           onTap: () async {
                            //             _dialogBuilder(context);
                            //           },
                            //           child:const Text.rich(
                            //             TextSpan(
                            //                 text: "Clique aqui para \n gerar o seed",
                            //                 style: TextStyle(
                            //                   fontWeight: FontWeight.bold,
                            //                 )),
                            //             textAlign: TextAlign.start,
                            //             style: TextStyle(
                            //               color: Colors.teal,
                            //               fontSize: 28,
                            //             ),
                            //           ),
                            //       ),
                            //
                            //
                            //
                            //     ],
                            //   ),
                            //
                            // ),
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
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
                          child: Column(
                            children: <Widget>[
                              Expanded(flex: 1, child: Container(color: Colors.orange)),
                              Expanded(flex: 2, child: Container(color: Colors.blue)),
                              Expanded(flex: 3, child: Container(color: Colors.green)),
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
