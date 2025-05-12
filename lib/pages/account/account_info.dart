// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountInfo extends StatefulWidget {
  const AccountInfo({super.key});

  @override
  _AccountInfoState createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> with AutomaticKeepAliveClientMixin {
  bool _showSaldo = false;

  @override
  bool get wantKeepAlive => true;

  String currentBalance = "R\$ 0,00";

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // final FirebaseAuth auth = FirebaseAuth.instance;

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: <Widget>[
                          Icon(Icons.attach_money, color: Colors.grey),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Conta",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
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
                  padding:
                      const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "Saldo disponível",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
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
                            : Container(
                                height: 32,
                                width: 140,
                                color: Colors.grey[200]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Icon(Icons.credit_card, color: Colors.grey),
                    const SizedBox(
                      width: 10,
                    ),
                    const Flexible(
                      child: Text(
                        "Compra mais recente em Super Mercado no valor de R\$ 150,99",
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
