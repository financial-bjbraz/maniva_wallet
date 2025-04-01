import 'dart:collection';

import 'package:my_rootstock_wallet/entities/simple_transaction.dart';
import 'package:my_rootstock_wallet/entities/transaction_type.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/incoming_line.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/outgoing_line.dart';
import '../../../services/create_transaction_service.dart';
import '../../../services/wallet_service.dart';
import '../../../entities/wallet_entity.dart';
import '../../../entities/simple_user.dart';
import '../../../util/shimmer_loading.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'blank_line.dart';

class TableTransactions extends StatefulWidget {
  const TableTransactions(
      {super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _TableTransactions createState() => _TableTransactions();
}

class _TableTransactions extends State<TableTransactions> {
  late WalletServiceImpl walletService =
      Provider.of<WalletServiceImpl>(context, listen: false);
  late CreateTransactionServiceImpl createTransactionServiceImpl = CreateTransactionServiceImpl();
  var transactions = <TableRow>{};
  final Map<String, int> txHashMap = HashMap();
  bool _isLoading = true;
  _TableTransactions();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  loadWalletData() async {
    if(this.mounted) {
      await Future.delayed(const Duration(seconds: 5), () {
        createTransactionServiceImpl
            .listTransactions(widget.wallet.walletId)
            .then((listTransactions) =>
        {
          setState(() {
            if (listTransactions.isNotEmpty) {
              for (final item in listTransactions) {
                if(!txHashMap.containsKey(item.walletId)){
                  transactions.add(generateItem(item));
                  txHashMap.addAll({item.walletId: item.type});
                }
              }
            }
            _isLoading = false;
          })
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isLoading = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    loadWalletData();
    return ShimmerLoading(
      isLoading: _isLoading,
      child: SingleChildScrollView(
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(4),
            2: FlexColumnWidth(4),
            3: FlexColumnWidth(4),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
          },
          children: [
            ...transactions,
            const BlankTransactionLine().create(),
          ],
        ),
      ),
    );
  }

  TableRow generateItem(SimpleTransaction item) {
    TableRow transactionItem = const TableRow();
    if(item.type == TransactionType.REGULAR_OUTGOING.type) {
      transactionItem = OutgoingTransactionLine(widget.user).create(item.date, item.valueInUsdFormatted);
    }else{
      transactionItem = IncomingTransactionLine(widget.user).create(item.date, item.valueInUsdFormatted);
    }
    return transactionItem;
  }
}
