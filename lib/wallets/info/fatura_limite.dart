import 'package:flutter/material.dart';

class FaturaLimitePage extends StatelessWidget {
  const FaturaLimitePage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Icon(Icons.credit_card, color: Colors.grey),
                SizedBox(
                  width: 5,
                ),
                Text(
                  "Cartão de Crédito",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.purple[800],
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
                          const Padding(
                            padding: EdgeInsets.only(
                                left: 20, top: 20, bottom: 20),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "FATURA ATUAL",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        color: Colors.teal,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text.rich(
                                    TextSpan(text: "R\$ ", children: [
                                      TextSpan(
                                          text: "600",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          )),
                                      TextSpan(text: ",50")
                                    ]),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontSize: 28,
                                    ),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                        text: "Limite disponível ",
                                        children: [
                                          TextSpan(
                                              text: " R\$ 2.200.95",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              )),
                                        ]),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.05),
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
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListView(
                      scrollDirection: Axis.vertical,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                            const Icon(Icons.shopping_cart, color: Colors.grey),
                            const SizedBox(
                              width: 10,
                            ),
                            const Flexible(
                              child: Text(
                                "Compra mais recente em Super Mercado no valor de R\$ 250,99",
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
                      ],
                    ),
                  ),
                ),
              ),
              // Center(
              //   child: ElevatedButton(
              //     onPressed: () {
              //       Navigator.pop(context);
              //     },
              //     child: Text("Go Back"),
              //   ),
              // ),
            ],
          ),
        ));
  }
}
