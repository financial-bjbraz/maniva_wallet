import 'package:big_dart/big_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_rootstock_wallet/entities/transaction_helper.dart';
import 'package:my_rootstock_wallet/util/transaction_type.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../entities/bitcoin_utxo.dart';
import '../../../entities/network_dto.dart';
import '../../../entities/user_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/wallet_service.dart';
import '../../../util/network.dart';
import '../../../util/util.dart';

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

  Icon fullIcon = const Icon(
    Icons.account_balance_wallet,
    color: Colors.black,
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
    walletService = WalletServiceImpl();

    address = Network.generateAddress(Network.BITCOIN_TESTNET, widget.selectedNetwork.wallet);

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
        if (kDebugMode){
          _log.info("Focus lost!");
        }
      });
      // You can add your custom logic here, like validation or saving data
      if (kDebugMode){
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
    if (address.isEmpty) {
      address = widget.selectedNetwork.walletDTO.getAddress();
    }
    valueController.dispose();
    _myFocusNode.removeListener(_handleFocusChange);
    _myFocusNode.dispose();

    _amountFocusNode.removeListener(_handleFocusChange);
    _amountFocusNode.dispose();

    super.dispose();
  }

  void displaySnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
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
    // var fee = 0;
    // await walletService.calculateBtcFee();
    //
    // setState(() {
    //   transactionFeeEstimation = fee.toString();
    //   transactionFeeEstimationUsd = feeUsd;
    // });
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
    setState(() {
      utxos = utxoList;
    });
  }

  Big prepareAmountValue() {
    var pointedText = amountController.text;
    pointedText = pointedText.replaceAll(",", ".");
    var bp = Big(pointedText);

    if (!destinationAddressController.text.trim().startsWith("0x")) {
      throw const FormatException("Invalid address");
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
      setState(() {
        amountInUsd = usdAmount;
      });
    } catch (e) {
      displaySnackBar("Error sending transaction, review and try again");
      success = false;
      sucessIcon = const Icon(
        Icons.dangerous_outlined,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String sendTransaction = AppLocalizations.of(context)!.sendTransaction;

    return Scaffold(
      backgroundColor: Colors.white,
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
        backgroundColor: const Color.fromRGBO(158, 118, 255, 1),
      ),
      body: Column(
        spacing: 1.0,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.wallet_rounded,
                  color: lightBlue(),
                  size: 48,
                ),
                Expanded(
                    child: TextField(
                  style: const TextStyle(
                    color: Colors.white,
                    backgroundColor: Color.fromRGBO(7, 255, 208, 1),
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(labelText: "Destination Address"),
                  keyboardType: TextInputType.text,
                  controller: destinationAddressController,
                )),
                ElevatedButton(
                  style: blackWhiteButton,
                  onPressed: () {},
                  child: const Row(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.document_scanner_outlined,
                                color: Colors.black,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                "Scan",
                                style: smallBlackText,
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
          ),
          const Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Paste or Scan",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
              child: Row(
            children: [
              Image.asset(
                "assets/icons/rbtc2.png",
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
                style: blackWhiteButton,
                onPressed: () {
                  setState(() {
                    if (full) {
                      fullIcon = const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.black,
                      );
                    } else {
                      fullIcon = const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.black,
                      );
                    }
                    full = !full;
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
                          style: smallBlackText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  amountInUsd,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
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
                const SizedBox(height: 20,),
                ExpansionTile(
                  title: const Text('ExpansionTile 3'),
                  subtitle: const Text('Leading expansion arrow icon'),
                  controlAffinity: ListTileControlAffinity.leading,
                  children: <Widget>[
                    SingleChildScrollView(
                      // Added for potential horizontal scrolling
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Id')),
                          DataColumn(label: Text('Amount')),
                        ],
                        rows: utxos.map((user) {
                          final isSelected = user.selected;
                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: (bool? value) {
                              setState(() {
                                user.selected = value ?? false;
                              });
                            },
                            cells: [
                              DataCell(Text(user.txid)),
                              DataCell(Text('${user.amount}')),
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
                    subtitle: Text(' ${transactionFeeEstimation} - ${transactionFeeEstimationUsd}'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text('SEND TRANSACTION'),
                        onPressed: () async {
                          setState(() {
                            sendingTransaction = true;
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          var sucesso = false;
                          try {
                            var transactionPersist = await validateAndPerformTransaction();
                            validateAndPerformTipTransaction();
                            sucesso = transactionPersist.transactionSent!;
                          } catch (e) {
                            displaySnackBar("Error sending transaction, review and try again");
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
                        child: const Text('CANCEL'),
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
          Expanded(
              flex: 3,
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
    );
  }

  void validateAndPerformTipTransaction() async {
    if (_character == SingingCharacter.tip) {
      final tipAccount = dotenv.env['RSK_ADDRESS_TIP'];
      if (tipAccount != null || tipAccount!.isNotEmpty) {
        await walletService.sendRBTC(widget.selectedNetwork.walletDTO,
            destinationAddressController.text, BigInt.from(tipAmount));
      }
    }
  }

  Future<SimpleTransaction> validateAndPerformTransaction() async {
    try {
      Big bp = prepareAmountValue();

      await walletService.sendTransferUsingUtxos(
          widget.selectedNetwork.walletDTO,
          destinationAddressController.text,
          BigInt.parse(bp.times(RBTC_DECIMAL_PLACES).toString()).toDouble(),
          utxos);
    }catch(e){
      rethrow;
    }

    return SimpleTransaction(transactionId: "", amountInWeis: "", ddateTime: "", walletId: "", valueInUsdFormatted: "", valueInWeiFormatted: "", type: TransactionType.REGULAR_OUTGOING.type, destination: "");
  }

}
