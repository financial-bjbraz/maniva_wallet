import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/incoming_line.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/outgoing_line.dart';
import 'package:my_rootstock_wallet/util/transaction_type.dart';
import 'package:my_rootstock_wallet/util/util.dart';
import 'package:provider/provider.dart';

import '../../../entities/transaction_helper.dart';
import '../../../entities/user_helper.dart';
import '../../../entities/wallet_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/create_transaction_service.dart';
import '../../../services/wallet_service.dart';
import '../../../util/shimmer_loading.dart';
import 'blank_line.dart';

class TableTransactions extends StatefulWidget {
  const TableTransactions({super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _TableTransactions createState() => _TableTransactions();
}

class _TableTransactions extends State<TableTransactions> {
  late WalletServiceImpl walletService = Provider.of<WalletServiceImpl>(context, listen: false);
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
    if (mounted) {
      createTransactionServiceImpl
          .listTransactionsOnDataBase(widget.wallet.walletId)
          .then((listTransactions) => {
                setState(() {
                  if (null != listTransactions || listTransactions.isNotEmpty) {
                    for (final item in listTransactions) {
                      if (!txHashMap.containsKey(item.transactionId)) {
                        transactions.add(generateItem(item));
                        txHashMap.addAll({item.transactionId: item.type});
                        //displaySnackBar(item.type);
                      }
                    }
                  }
                })
              })
          .then((_) => {
                setState(() {
                  _isLoading = false;
                })
              });
    }
  }

  void displaySnackBar(int type) {
    var message = "";
    if (type == TransactionType.REGULAR_OUTGOING.type) {
      message = AppLocalizations.of(context)!.txSent;
    } else {
      message = AppLocalizations.of(context)!.txReceived;
    }
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () {
          setState(() {});
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
    final String transactionsTitle = AppLocalizations.of(context)!.transactions;

    return ShimmerLoading(
        isLoading: _isLoading,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(15),
              width: double.infinity,
              child: Text.rich(
                TextSpan(
                    text: transactionsTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, backgroundColor: pink())),
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              height: 90,
              color: Colors.white,
              padding: const EdgeInsets.all(8),
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
            )
          ],
        ));
  }

  TableRow generateItem(SimpleTransaction item) {
    TableRow transactionItem = const TableRow();
    if (item.type == TransactionType.REGULAR_OUTGOING.type) {
      transactionItem = OutgoingTransactionLine(widget.user).create(item);
    } else {
      transactionItem = IncomingTransactionLine(widget.user).create(item);
    }
    return transactionItem;
  }
}
