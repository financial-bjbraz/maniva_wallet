import 'package:flutter/material.dart';
import '../../../entities/simple_user.dart';
import '../../../util/util.dart';

class IncomingTransactionLine extends TableRow {
  final SimpleUser user;
  const IncomingTransactionLine(this.user);

  TableRow create() {
     return  TableRow(children: [
      Icon(Icons.call_made, color: Colors.red),
      Text(
        "12/12/2024",
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
      Text(
        "USD 11.000.00",
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
      Text(
        formatAddressMinimal("0xac77b0b6fc94940c2847582e4fe1d1a720085ea0b00fbb308f35230923c576fd"),
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
      Icon(Icons.open_in_new, color: Colors.red),
      Icon(Icons.copy, color: Colors.red),
    ]);
  }
}
