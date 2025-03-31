import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_rootstock_wallet/entities/transaction_type.dart';
import 'package:provider/provider.dart';

import '../../entities/simple_user.dart';
import '../../entities/wallet_entity.dart';
import '../../pages/home_page.dart';
import '../../services/wallet_service.dart';
import '../../util/util.dart';

class ImportNewWalletByPrivateKeyDetail extends StatefulWidget {
  final SimpleUser user;

  const ImportNewWalletByPrivateKeyDetail({super.key, required this.user});

  @override
  _ImportNewWalletByPKDetail createState() => _ImportNewWalletByPKDetail();
}

class _ImportNewWalletByPKDetail
    extends State<ImportNewWalletByPrivateKeyDetail> {
  late WalletServiceImpl walletService =
      Provider.of<WalletServiceImpl>(context, listen: false);
  bool inputSeedEnabled = true;

  _ImportNewWalletByPKDetail();

  @override
  Widget build(BuildContext context) {
    final TextEditingController mailController = TextEditingController();

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
                  "Importar uma nova wallet",
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
                            padding: const EdgeInsets.only(
                                left: 20, top: 20, bottom: 20),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text.rich(
                                    TextSpan(
                                        text: "Insert your private key",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontSize: 28,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextField(
                                    controller: mailController,
                                    enabled: inputSeedEnabled,
                                    decoration: InputDecoration(
                                        labelText:
                                            "Type or Paste your PrivateKey",
                                        border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                width: 5,
                                                color: Colors.white)),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.done),
                                          splashColor: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context)
                                                .requestFocus(FocusNode());
                                          },
                                        )),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      var privateKey = mailController.text;

                                      if (privateKey.isEmpty) {
                                        showMessage(
                                            "Invalid privateKey", context);
                                      } else {
                                        var publicKey = await walletService
                                            .getPublicKeyString(privateKey);
                                        var walletId = await getIndex();
                                        WalletEntity wallet = WalletEntity(
                                            BigInt.zero.toDouble(),
                                            privateKey: privateKey,
                                            publicKey: publicKey,
                                            walletId: walletId,
                                            walletName: "Wallet #",
                                            ownerEmail: widget.user.email,
                                        );

                                        walletService
                                            .persistNewWallet(wallet);
                                        showMessage(
                                            "Account ${wallet.walletName} Created",
                                            context);
                                        final user = SimpleUser(
                                            name: AppLocalizations.of(
                                                context)!
                                                .anonimus,
                                            email:
                                            "${AppLocalizations.of(context)!.passwordField}@${AppLocalizations.of(context)!.passwordField}.com",
                                            password: "");
                                        final List<WalletEntity> wallets = await walletService.getWallets(user.email);

                                        Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                                builder:
                                                    (context) => HomePage(
                                                          wallets: wallets,
                                                          user: user,
                                                        )));
                                      }
                                    },
                                    style: raisedButtonStyle,
                                    child: const Row(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Icon(Icons.key),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              "Validate and Import",
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
