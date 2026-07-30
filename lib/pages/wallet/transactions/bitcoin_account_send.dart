import 'package:big_dart/big_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/entities/transaction_helper.dart';
import 'package:provider/provider.dart';

import '../../../entities/bitcoin_utxo.dart';
import '../../../entities/network_dto.dart';
import '../../../entities/user_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/wallet_service.dart';
import '../../../util/app_theme.dart';
import '../../../util/network.dart';
import '../../../util/secure_screen.dart';
import '../../../util/util.dart';
import 'qr_scanner_page.dart';

class BitcoinAccountSendSend extends StatefulWidget {
  const BitcoinAccountSendSend({super.key, required this.user, required this.selectedNetwork});

  final SimpleUser user;
  final NetworkDto selectedNetwork;

  @override
  _BitcoinAccountSendSend createState() {
    return _BitcoinAccountSendSend();
  }
}

enum SingingCharacter { tip, notip }

class User {
  final String name;
  final int age;
  bool selected = false;

  User({required this.name, required this.age});
}

class _BitcoinAccountSendSend extends State<BitcoinAccountSendSend> {
  _BitcoinAccountSendSend();

  static final _log = Logger('bitcoin_account_send');

  bool processing = false;
  bool full = true;
  String address = '';
  late WalletServiceImpl walletService;
  List<String> splittedMnemonic = List<String>.filled(1, '');
  final valueController = TextEditingController();
  String balance = '0';
  String balanceInUsd = 'USD 0.00';
  String amount = '0';
  String amountInUsd = 'USD 0.00';
  final TextEditingController addressController = TextEditingController();
  bool sendingTransaction = false;
  bool success = false;
  final amountController = TextEditingController();
  final destinationAddressController = TextEditingController();
  String transactionFeeEstimation = "0.00";
  String transactionFeeEstimationUsd = "USD 0.00";
  final FocusNode _myFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  SingingCharacter? _character = SingingCharacter.tip;
  final double tipAmount = 0.000009;
  String tipAmountUsd = "USD 0.00";
  List<Utxo> utxos = [];
  String maxAmountBtc = "0.00000000";
  String maxAmountUsd = "USD 0.00";
  double _currentBtcPrice = 0;

  /// Comfortable reading width for the form when centered on wide (desktop)
  /// screens. Has no effect on narrower screens since it's only an upper bound.
  static const double _maxContentWidth = 640.0;

  /// Screens at least this wide get the maximize/restore toggle in the AppBar.
  static const double _wideScreenBreakpoint = 700.0;

  /// When true, the form stretches to the full available width instead of
  /// staying centered at [_maxContentWidth].
  bool _maximized = false;

  Icon fullIcon = const Icon(
    Icons.account_balance_wallet,
    color: Colors.white,
  );

  Icon sucessIcon = const Icon(
    Icons.check,
    color: Colors.green,
  );

  List<User> users = [
    User(name: 'Alice', age: 24),
    User(name: 'Bob', age: 30),
    User(name: 'Charlie', age: 18),
  ];

  @override
  void initState() {
    super.initState();
    SecureScreen.activate();
    // The shared Provider instance, not a locally-constructed one, so the
    // testnet/mainnet toggle (and its resolved RPC endpoints) applies here too.
    walletService = Provider.of<WalletServiceImpl>(context, listen: false);

    address = Network.generateAddress(widget.selectedNetwork.network, widget.selectedNetwork.wallet);

    _myFocusNode.addListener(_handleFocusChange);
    _amountFocusNode.addListener(_handleAmountFocusChange);
    balance = widget.selectedNetwork.walletDTO.valueInWeiFormatted;
    balanceInUsd = widget.selectedNetwork.walletDTO.valueInUsdFormatted;

    calculateTip();
    listUtxos();
  }

  void _handleFocusChange() {
    if (!_myFocusNode.hasFocus) {
      // Focus is lost (on blur event)
      setState(() {
        if (kDebugMode) {
          _log.info("Focus lost!");
        }
      });
      // You can add your custom logic here, like validation or saving data
      if (kDebugMode) {
        _log.info("TextFormField lost focus. Performing action...");
      }
    } else {
      calculateFee();
    }
  }

  void _handleAmountFocusChange() {
    if (!_amountFocusNode.hasFocus) {
      // Focus is lost (on blur event)
      setState(() {
        calculateAmount();
      });
    } else {
      calculateFee();
    }
  }

  @override
  void dispose() {
    SecureScreen.deactivate();
    if (address.isEmpty) {
      address = widget.selectedNetwork.walletDTO.getAddress();
    }
    valueController.dispose();
    _myFocusNode.removeListener(_handleFocusChange);
    _myFocusNode.dispose();

    _amountFocusNode.removeListener(_handleAmountFocusChange);
    _amountFocusNode.dispose();

    super.dispose();
  }

  void displaySnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () {
          setState(() {
            success = true;
            sendingTransaction = false;
          });
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  calculateFee() async {
    var selectedUtxos = utxos.where((u) => u.selected).toList();
    if (selectedUtxos.isEmpty) selectedUtxos = utxos;
    if (selectedUtxos.isEmpty) return;

    var fee = await walletService.calculateBtcFee(selectedUtxos);
    var feeUsd = await walletService.calculateInUsd(fee);

    if (mounted) {
      setState(() {
        transactionFeeEstimation = fee.toStringAsFixed(8);
        transactionFeeEstimationUsd = feeUsd;
      });
    }
  }

  calculateTip() async {
    var feeUsd = await walletService.calculateInUsd(tipAmount);
    setState(() {
      tipAmountUsd = feeUsd;
    });
  }

  listUtxos() async {
    // Use scantxoutset to scan the UTXO set for this address (works even if address isn't in the wallet)
    var utxoList = await walletService.scanUtxosForAddress(address);
    final price = await walletService.getCurrentUsdPricePerCoin();
    if (mounted) {
      setState(() {
        utxos = utxoList;
        _currentBtcPrice = price;
      });
    }
    calculateMaxAmount();
  }

  /// Surfaces the most trustworthy/spendable UTXOs first — confirmed and
  /// well-confirmed ones ahead of unconfirmed or barely-confirmed ones, then
  /// larger amounts first — to make picking one easier.
  List<Utxo> _sortedUtxos() {
    final sorted = [...utxos];
    sorted.sort((a, b) {
      final confA = a.confirmations ?? 0;
      final confB = b.confirmations ?? 0;
      if (confA != confB) {
        return confB.compareTo(confA);
      }
      return b.amount.compareTo(a.amount);
    });
    return sorted;
  }

  String _utxoUsdEstimate(Utxo u) {
    if (_currentBtcPrice == 0) {
      return '—';
    }
    return NumberFormat.simpleCurrency(name: 'USD').format(u.amount * _currentBtcPrice);
  }

  String _formatUtxoAge(DateTime? confirmedAt) {
    if (confirmedAt == null) {
      return '—';
    }
    final age = DateTime.now().difference(confirmedAt);
    if (age.inDays > 0) {
      return '${age.inDays}d ago';
    }
    if (age.inHours > 0) {
      return '${age.inHours}h ago';
    }
    if (age.inMinutes > 0) {
      return '${age.inMinutes}m ago';
    }
    return 'just now';
  }

  Future<void> _scanAddress() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );
    if (scanned == null || !mounted) {
      return;
    }
    final trimmed = scanned.trim();
    if (!Network.isValidBitcoinAddress(trimmed, isMainnet: walletService.isMainnet)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code does not contain a valid Bitcoin address'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    destinationAddressController.text = trimmed;
    calculateFee();
  }

  calculateMaxAmount() async {
    final total = utxos.fold<double>(0.0, (sum, u) => sum + u.amount);

    double maxSendable = 0.0;
    if (utxos.isNotEmpty) {
      // Spending the full balance still needs to pay the network fee, so the
      // actual max sendable amount is the UTXO total minus the estimated fee
      // for spending all of them.
      final fee = await walletService.calculateBtcFee(utxos);
      maxSendable = total - fee;
      if (maxSendable < 0) {
        maxSendable = 0.0;
      }
    }

    final maxSendableUsd = await walletService.calculateInUsd(maxSendable);
    if (mounted) {
      setState(() {
        maxAmountBtc = maxSendable.toStringAsFixed(8);
        maxAmountUsd = maxSendableUsd;
      });
    }
  }

  Big prepareAmountValue() {
    var pointedText = amountController.text;
    pointedText = pointedText.replaceAll(",", ".");
    var bp = Big(pointedText);

    final destination = destinationAddressController.text;
    if (!Network.isValidBitcoinAddress(destination, isMainnet: walletService.isMainnet)) {
      // Network-aware on purpose: a mainnet-formatted address is a
      // syntactically valid Bitcoin address, but sending to it while this
      // wallet is set to testnet (or vice versa) is very likely a mistake —
      // scanning/pasting the wrong network's address is exactly the kind of
      // error that can send funds somewhere the user didn't intend.
      throw FormatException(walletService.isMainnet
          ? "Invalid address — expected a mainnet address (starts with 1, 3 or bc1)"
          : "Invalid address — expected a testnet address (starts with m, n, 2 or tb1)");
    }

    if (bp.toNumber() == 0) {
      throw const FormatException("Invalid value");
    }
    return bp;
  }

  calculateAmount() async {
    try {
      var bp = prepareAmountValue();
      var usdAmount = await walletService.calculateInUsd(bp.toNumber());
      if (mounted) {
        setState(() {
          amountInUsd = usdAmount;
        });
      }
    } on FormatException {
      // The destination address/amount aren't filled in (yet) — this is normal
      // while the form is incomplete, not a send failure, so just clear the
      // USD preview instead of alarming the user.
      if (mounted) {
        setState(() {
          amountInUsd = "USD 0.00";
        });
      }
    } catch (e) {
      displaySnackBar("Error calculating amount, review and try again");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String sendTransaction = AppLocalizations.of(context)!.sendTransaction;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isWideScreen = screenWidth >= _wideScreenBreakpoint;

    return Scaffold(
      backgroundColor: rootstockBlack,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              const Icon(Icons.add_circle, color: Colors.white),
              const SizedBox(
                width: 5,
              ),
              Text(
                sendTransaction,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: purple(),
        actions: [
          if (isWideScreen)
            IconButton(
              tooltip: _maximized ? 'Restore' : 'Maximize',
              icon: Icon(
                _maximized ? Icons.close_fullscreen : Icons.open_in_full,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _maximized = !_maximized;
                });
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _maximized ? double.infinity : _maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16.0,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.wallet_rounded,
                      color: lightBlue(),
                      size: 48,
                    ),
                    Expanded(
                        child: TextField(
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: lightBlue(),
                        fontSize: 20,
                      ),
                      decoration: const InputDecoration(labelText: "Destination Address"),
                      keyboardType: TextInputType.text,
                      controller: destinationAddressController,
                    )),
                    ElevatedButton(
                      style: lightBlueButton,
                      onPressed: _scanAddress,
                      child: const Row(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.document_scanner_outlined,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  const Text(
                                    "Scan",
                                    style: smallWhiteBoldText,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        "Paste or Scan",
                        style: mutedCaptionText,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Image.asset(
                      "assets/icons/btc.png",
                      width: 48,
                    ),
                    Expanded(
                      child: TextFormField(
                          focusNode: _amountFocusNode,
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.replaceAll(',', '.'),
                              ),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: "Amount to Send",
                          )),
                    ),
                    ElevatedButton(
                      style: lightBlueButton,
                      onPressed: () {
                        setState(() {
                          if (full) {
                            fullIcon = const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                            );
                          } else {
                            fullIcon = const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                            );
                          }
                          full = !full;
                          amountController.text = maxAmountBtc;
                          amountInUsd = maxAmountUsd;
                        });
                      },
                      child: Row(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              fullIcon,
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                "Max",
                                style: smallWhiteBoldText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        'Max (after fee): $maxAmountBtc BTC ($maxAmountUsd)',
                        style: mutedCaptionText,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        amountInUsd,
                        style: mutedCaptionText,
                      ),
                    ),
                  ],
                ),
                RadioGroup<SingingCharacter>(
                  groupValue: _character,
                  onChanged: (SingingCharacter? value) {
                    setState(() {
                      _character = value;
                    });
                  },
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        title: Text('Buy me a coffe ${tipAmountUsd}'),
                        leading: const Radio<SingingCharacter>(value: SingingCharacter.tip),
                      ),
                      const ListTile(
                        title: Text('My tip is: ‘Do your best'),
                        leading: Radio<SingingCharacter>(value: SingingCharacter.notip),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ExpansionTile(
                        title: const Text('Available UTXOs'),
                        subtitle: Text(
                            '${utxos.length} UTXO(s) found — tap a row to select which to spend'),
                        controlAffinity: ListTileControlAffinity.leading,
                        children: <Widget>[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Txid')),
                                DataColumn(label: Text('Vout')),
                                DataColumn(label: Text('Amount (BTC)')),
                                DataColumn(label: Text('Amount (USD)')),
                                DataColumn(label: Text('Confirmations')),
                                DataColumn(label: Text('Age')),
                              ],
                              rows: _sortedUtxos().map((u) {
                                final isSelected = u.selected;
                                final confirmations = u.confirmations ?? 0;
                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (bool? value) {
                                    setState(() {
                                      u.selected = value ?? false;
                                    });
                                  },
                                  cells: [
                                    DataCell(
                                      Tooltip(
                                        message: u.txid,
                                        child: Text(formatTextWithParameter(u.txid, 8)),
                                      ),
                                    ),
                                    DataCell(Text('${u.vout}')),
                                    DataCell(Text(u.amount.toStringAsFixed(8))),
                                    DataCell(Text(_utxoUsdEstimate(u))),
                                    DataCell(
                                      Text(
                                        confirmations == 0 ? 'Unconfirmed' : '$confirmations',
                                        style: TextStyle(
                                          color: confirmations == 0
                                              ? Colors.orangeAccent
                                              : confirmations < 6
                                                  ? Colors.yellowAccent
                                                  : Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(_formatUtxoAge(u.confirmedAt))),
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.monetization_on),
                          title: const Text('Transaction fees to complete your transaction'),
                          subtitle:
                              Text(' ${transactionFeeEstimation} - ${transactionFeeEstimationUsd}'),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              style: greenButton,
                              child: const Text('SEND TRANSACTION', style: smallWhiteBoldText),
                              onPressed: () async {
                                setState(() {
                                  sendingTransaction = true;
                                });
                                await Future.delayed(const Duration(seconds: 1));
                                var sucesso = false;
                                try {
                                  var transactionPersist = await validateAndPerformTransaction();
                                  validateAndPerformTipTransaction();
                                  sucesso = transactionPersist.transactionSent ?? false;
                                } catch (e) {
                                  displaySnackBar(
                                      "Error sending transaction, review and try again");
                                  sucesso = false;
                                  sucessIcon = const Icon(
                                    Icons.dangerous_outlined,
                                    color: Colors.red,
                                  );
                                }

                                setState(() {
                                  success = sucesso;
                                  if (!success) {
                                    sucessIcon = const Icon(
                                      Icons.dangerous_outlined,
                                      color: Colors.red,
                                    );
                                  } else {
                                    sucessIcon = const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    );
                                  }
                                });
                                await Future.delayed(const Duration(milliseconds: 500));
                                if (success) {
                                  Navigator.pop(context);
                                }

                                setState(() {
                                  sendingTransaction = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: pinkButton,
                              child: const Text('CANCEL', style: smallWhiteBoldText),
                              onPressed: () {
                                /* ... */
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                    height: 24,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 15,
                        ),
                        Expanded(
                            child: !sendingTransaction
                                ? const SizedBox(
                                    width: 10,
                                  )
                                : sendingTransaction
                                    ? const LinearProgressIndicator()
                                    : sucessIcon),
                        const SizedBox(
                          width: 15,
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void validateAndPerformTipTransaction() async {
    if (_character == SingingCharacter.tip) {
      final String tipAccount = walletService.rskAddressTip.trim();
      if (tipAccount.isNotEmpty) {
        // Convert the human-readable tip amount to the smallest unit
        final Big tipAmountBig = Big(tipAmount.toString());
        final Big tipInSmallestUnitBig = tipAmountBig.times(RBTC_DECIMAL_PLACES);
        final BigInt tipInSmallestUnit = BigInt.parse(tipInSmallestUnitBig.toString());

        await walletService.sendRBTC(
          widget.selectedNetwork.walletDTO,
          tipAccount,
          tipInSmallestUnit,
        );
      }
    }
  }

  Future<SimpleTransaction> validateAndPerformTransaction() async {
    final Big bp = prepareAmountValue();
    final selectedUtxos = utxos.where((u) => u.selected).toList();
    final utxosToSpend = selectedUtxos.isNotEmpty ? selectedUtxos : utxos;

    return walletService.sendTransferUsingUtxos(widget.selectedNetwork.wallet,
        destinationAddressController.text, bp.toNumber(), utxosToSpend);
  }
}
