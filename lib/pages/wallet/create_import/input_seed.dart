
import 'package:flutter/material.dart';

class AccountStatementsDetail extends StatelessWidget {
  final String currentBalance = "R\$ 0,00";

  const AccountStatementsDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: TextFormField(
      decoration: InputDecoration(
          labelText: "aaaaaa",
          prefixIcon: const Icon(Icons.person),
          border: const OutlineInputBorder(
              borderSide:
              BorderSide(width: 5, color: Colors.white)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.done),
            splashColor: Colors.white,
            tooltip: "Submit",
            onPressed: () {

            },
          )),
    ),
    );
  }
}
