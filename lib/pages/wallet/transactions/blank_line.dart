import 'package:flutter/material.dart';

class BlankTransactionLine extends TableRow {
  const BlankTransactionLine();

  TableRow create() {
    return  const TableRow(children: [
      SizedBox(),
      Text(""),
      SizedBox(),
      SizedBox(),
      SizedBox(),
      SizedBox(),
    ]);
  }
}
