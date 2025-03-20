import 'package:flutter/material.dart';
import '../../../entities/simple_user.dart';
import '../../../util/util.dart';

class OutgoingTransactionLine extends TableRow {
  final SimpleUser user;
  const OutgoingTransactionLine(this.user);

  TableRow create(String data, String value) {
    return  TableRow(children: [
      const Icon(Icons.call_made_rounded, color: Colors.red),
      Text(
        data,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
      Text(
        "   ${formatAddressMinimal("0xac77b0b6fc94940c2847582e4fe1d1a720085ea0b00fbb308f35230923c576fd")}",
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
      const Icon(Icons.open_in_new, color: Colors.red),
      const Icon(Icons.copy, color: Colors.red),
    ]);
  }
}
