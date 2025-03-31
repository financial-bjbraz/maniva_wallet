import 'package:my_rootstock_wallet/pages/wallet/transactions/incoming_line.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/outgoing_line.dart';
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
  bool _isLoading = true;
  _TableTransactions();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadWalletData();
  }

  loadWalletData() async {
    await Future.delayed(const Duration(seconds: 3), () {
      walletService.createWalletToDisplay(widget.wallet).then((dto) => {
            setState(() {
              _isLoading = false;
            })
          });
    });
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
            IncomingTransactionLine(widget.user).create("12/12/2024", "USD 10,00"),
            OutgoingTransactionLine(widget.user).create("11/12/2024", "USD 10,00"),
            IncomingTransactionLine(widget.user).create("10/12/2024", "USD 100,00"),
            OutgoingTransactionLine(widget.user).create("09/12/2024", "USD 10,00"),
            OutgoingTransactionLine(widget.user).create("06/12/2024", "USD 11.000,00"),
            IncomingTransactionLine(widget.user).create("05/12/2024", "USD 1.000,00"),
            const BlankTransactionLine().create(),
          ],
        ),
      ),
    );
  }
}
