import 'package:flutter/material.dart';

import '../../../entities/transaction_helper.dart';
import '../../../entities/user_helper.dart';
import '../../../util/util.dart';

class IncomingTransactionLine extends TableRow {
  final SimpleUser user;
  const IncomingTransactionLine(this.user);

  TableRow create(SimpleTransaction tx) {
    return TableRow(children: [
      const Icon(Icons.call_received_rounded, color: Colors.blue),
      Text(
        tx.date,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
        ),
      ),
      Text(
        tx.valueInWeiFormatted,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
        ),
      ),
      Text(
        "   ${formatAddressMinimal(tx.transactionId)}",
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
        ),
      ),
      const Icon(Icons.open_in_new, color: Colors.blue),
      const Icon(Icons.copy, color: Colors.blue),
    ]);
  }
}
