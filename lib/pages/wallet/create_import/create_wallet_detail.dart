import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/pages/wallet/create_import/import_wallet_seed_detail.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

import '../../../entities/user_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/wallet_service.dart';
import '../../../util/app_theme.dart';
import '../../../util/clipboard_guard.dart';
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
  static final _log = Logger('create_wallet_detail');

  bool processing = false;
  bool _created = false;
  bool _creationFailed = false;
  late WalletServiceImpl walletService;
  List<String> splittedMnemonic = List<String>.filled(1, "");
  late EthereumAddress address;

  _CreateNewWalletDetail();

  @override
  void initState() {
    super.initState();
  }

  void createNewAccount() async {
    if (_created || _creationFailed) {
      return;
    }
    try {
      walletService = Provider.of<WalletServiceImpl>(context, listen: false);
      final mnemonic = walletService.generateMnemonic();
      final privateKey = await walletService.getPrivateKey(mnemonic);
      address = walletService.getPublicKey(privateKey);
      if (mounted) {
        setState(() {
          splittedMnemonic = mnemonic.split(' ');
          _created = true;
        });
      }
    } catch (e, stack) {
      _log.severe('Error generating new wallet seed', e, stack);
      if (mounted) {
        setState(() {
          _creationFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int contador = 0;
    createNewAccount();
    final String copy = AppLocalizations.of(context)?.copiar ?? 'Copy to clipboard';

    Widget createTextFieldWithSeed(String word) {
      contador++;
      return Expanded(
        child: TextFormField(
          enabled: false,
          style: const TextStyle(fontSize: 6, color: rootstockCream),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(2, 2, 2, 1),
            labelText: "$contador. $word",
            labelStyle: const TextStyle(color: rootstockCream),
            disabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: rootstockCream),
            ),
          ),
        ),
      );
    }

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
        backgroundColor: rootstockBlack,
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
          backgroundColor: purple(),
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
                                  child: _creationFailed
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Could not generate a new wallet seed. Please try again.',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                            const SizedBox(height: 10),
                                            Center(
                                              child: SizedBox(
                                                width: 200,
                                                child: ElevatedButton(
                                                  style: greenButton,
                                                  onPressed: () {
                                                    setState(() {
                                                      _creationFailed = false;
                                                    });
                                                  },
                                                  child: const Text('Retry', style: smallWhiteBoldText),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : !processing
                                      ? Center(
                                          child: SizedBox(
                                            width: 240,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                copyWithTimeout(
                                                    splittedMnemonic
                                                        .toString()
                                                        .replaceAll("[", "")
                                                        .replaceAll("]", ""),
                                                    timeout: const Duration(seconds: 30));
                                                showMessage(
                                                    AppLocalizations.of(context)!.copiedMessage,
                                                    context);

                                                setState(() {
                                                  processing = true;
                                                  delay(context, 5).whenComplete(() {
                                                    processing = false;
                                                    sentToDetail();
                                                  });
                                                });
                                              },
                                              style: greenButton,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: <Widget>[
                                                  const Icon(Icons.copy, color: Colors.white),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    copy,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
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
