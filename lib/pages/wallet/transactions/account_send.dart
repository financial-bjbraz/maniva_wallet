import 'package:big_dart/big_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hux/hux.dart';
import 'package:my_rootstock_wallet/entities/network_dto.dart';
import 'package:my_rootstock_wallet/entities/transaction_helper.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/util/wei.dart';

import '../../../entities/user_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/wallet_service.dart';
import '../../../util/network.dart';
import '../../../util/util.dart';

class Send extends StatefulWidget {
  const Send({super.key, required this.user, required this.selectedNetwork});

  final SimpleUser user;
  final NetworkDto selectedNetwork;

  @override
  _Send createState() {
    return _Send();
  }
}

enum SingingCharacter { tip, notip }

class _Send extends State<Send> {
  _Send();

  bool processing = false;
  bool full = true;
  double _currentSliderValue = 5;
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

  Icon fullIcon = const Icon(
    Icons.account_balance_wallet,
    color: Colors.black,
  );

  Icon sucessIcon = const Icon(
    Icons.check,
    color: Colors.green,
  );

  @override
  void initState() {
    super.initState();
    walletService = WalletServiceImpl();

    address = widget.selectedNetwork.network == Network.BITCOIN_TESTNET ||
            widget.selectedNetwork.network == Network.BITCOIN_MAINNET
        ? widget.selectedNetwork.walletDTO.wallet.btcAddress
        : widget.selectedNetwork.walletDTO.wallet.publicKey;

    _myFocusNode.addListener(_handleFocusChange);
    _amountFocusNode.addListener(_handleAmountFocusChange);
    balance = widget.selectedNetwork.walletDTO.valueInWeiFormatted;
    balanceInUsd = widget.selectedNetwork.walletDTO.valueInUsdFormatted;

    calculateTip();
  }

  void _handleFocusChange() {
    if (!_myFocusNode.hasFocus) {
      // Focus is lost (on blur event)
      setState(() {
        print("Focus lost!");
      });
      // You can add your custom logic here, like validation or saving data
      print("TextFormField lost focus. Performing action...");
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
    }else{
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
    var fee =
        await walletService.calculateRbtcFee(from: address, to: destinationAddressController.text);
    var feeUsd = await walletService.calculateInUsd(fee.getWei());
    setState(() {
      transactionFeeEstimation = fee.toRBTCString();
      transactionFeeEstimationUsd = feeUsd;
    });
  }

  calculateTip() async {
    var feeUsd = await walletService.calculateInUsd(tipAmount);
    setState(() {
      tipAmountUsd = feeUsd;
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
        await walletService.sendRBTC(
            widget.selectedNetwork.walletDTO,
            destinationAddressController.text,
            BigInt.from(tipAmount)
        );
      }
    }
  }

  Future<SimpleTransaction> validateAndPerformTransaction() async {
    Big bp = prepareAmountValue();

    var transactionPersist = await walletService.sendRBTC(
        widget.selectedNetwork.walletDTO,
        destinationAddressController.text,
        BigInt.parse(bp.times(RBTC_DECIMAL_PLACES).toString()));
    return transactionPersist;
  }

}
