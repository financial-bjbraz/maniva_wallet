import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_rootstock_wallet/util/util.dart';
import 'package:provider/provider.dart';

import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../services/wallet_service.dart';

class CreateSendTransaction extends StatefulWidget {
  const CreateSendTransaction({super.key, required this.user});

  final SimpleUser user;

  @override
  _CreateSendTransaction createState() => _CreateSendTransaction();
}

class _CreateSendTransaction extends State<CreateSendTransaction>
    with AutomaticKeepAliveClientMixin {
  bool _showSaldo = false;
  String currentBalance = " 0,00";
  final TextEditingController _controller = TextEditingController();
  late WalletServiceImpl walletService = Provider.of<WalletServiceImpl>(context, listen: false);
  late List<WalletEntity> wallets;

  _CreateSendTransaction() {
    walletService.getWallets(widget.user.email).then((value) => wallets = value);
  }

  @override
  Widget build(BuildContext context) {
    currentBalance = "widget.user";
    super.build(context);

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Image.asset('assets/icons/rbtc.png', height: 30),
                const SizedBox(
                  width: 5,
                ),
                const Text(
                  "SEND",
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
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: <Widget>[
                              const Icon(Icons.attach_money, color: Colors.black),
                              _showSaldo
                                  ? Text.rich(
                                      TextSpan(
                                        text: currentBalance,
                                      ),
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 28,
                                      ),
                                    )
                                  : Container(height: 32, width: 140, color: Colors.grey[200]),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showSaldo = !_showSaldo;
                              });
                            },
                            child: SvgPicture.asset(
                              _showSaldo
                                  ? "assets/icons/eye-outline.svg"
                                  : "assets/icons/eye-off-outline.svg",
                              semanticsLabel: "visualizar",
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            TextFormField(
                                controller: _controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) => newValue.copyWith(
                                      text: newValue.text.replaceAll('.', ','),
                                    ),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                    labelText: "Amount to Send",
                                    hintText: "Amount to Send",
                                    icon: Icon(Icons.attach_money))),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListView(
                      scrollDirection: Axis.vertical,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Icon(Icons.credit_card, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "1 - account_statements_detail.dart de R\$ 150,99",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Icon(Icons.credit_card, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "2 - Compra mais recente em Super Mercado no valor de R\$ 150,99",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Icon(Icons.credit_card, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "3 - Compra mais recente em Super Mercado no valor de R\$ 150,99",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Icon(Icons.credit_card, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "4 - Compra mais recente em Super Mercado no valor de R\$ 150,99",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Icon(Icons.credit_card, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "5 - Compra mais recente em Super Mercado no valor de R\$ 150,99",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
