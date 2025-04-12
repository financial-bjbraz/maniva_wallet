import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../pages/home_page.dart';
import '../../services/wallet_service.dart';
import '../../util/util.dart';

// validate seed and generate new wallet
class ImportNewWalletBySeedDetail extends StatefulWidget {
  final SimpleUser user;

  const ImportNewWalletBySeedDetail({super.key, required this.user});

  @override
  _ImportNewWalletBySeedDetail createState() => _ImportNewWalletBySeedDetail();
}

class _ImportNewWalletBySeedDetail extends State<ImportNewWalletBySeedDetail> {
  late WalletServiceImpl walletService = Provider.of<WalletServiceImpl>(context, listen: false);
  bool inputSeedEnabled = true;

  _ImportNewWalletBySeedDetail();

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
          backgroundColor: green(),
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
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text.rich(
                                    TextSpan(
                                        text: "Insert your seed",
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
                                        labelText: "Type or Paste your Seed",
                                        border: const OutlineInputBorder(
                                            borderSide: BorderSide(width: 5, color: Colors.white)),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.done),
                                          splashColor: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).requestFocus(FocusNode());
                                          },
                                        )),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      var seed = mailController.text;

                                      if (seed.isEmpty) {
                                        showMessage("Invalid Seed", context);
                                      } else {
                                        var privateKey = await walletService.getPrivateKey(seed);
                                        var publicKey =
                                            await walletService.getPublicKeyString(privateKey);
                                        var walletId = await getIndex();
                                        WalletEntity wallet = WalletEntity(BigInt.zero.toDouble(),
                                            privateKey: privateKey,
                                            publicKey: publicKey,
                                            walletId: walletId,
                                            walletName: "Wallet #",
                                            ownerEmail: widget.user.email);
                                        try {
                                          walletService.persistNewWallet(wallet);
                                          showMessage("Account Created", context);
                                          final List<WalletEntity> wallets =
                                              await walletService.getWallets(widget.user.email);
                                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                                              builder: (context) =>
                                                  HomePage(user: widget.user, wallets: wallets)));
                                        } catch (error) {
                                          showMessage("Failed to create account", context);
                                        }
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
