import 'package:flutter/material.dart';

import '../../../entities/transaction_helper.dart';
import '../../../entities/user_helper.dart';
import '../../../util/util.dart';

class OutgoingTransactionLine extends TableRow {
  final SimpleUser user;
  const OutgoingTransactionLine(this.user);

  TableRow create(SimpleTransaction tx) {
    return TableRow(children: [
      const Icon(Icons.call_made_rounded, color: Colors.red),
      Text(
        tx.ddateTime,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
      Text(
        tx.valueInWeiFormatted,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
      Text(
        "   ${formatAddressMinimal(tx.transactionId)}",
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
