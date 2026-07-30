import 'package:big_dart/big_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/entities/network_dto.dart';
import 'package:maniva_wallet/entities/transaction_helper.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../entities/token_helper.dart';
import '../../../entities/user_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/wallet_service.dart';
import '../../../util/app_theme.dart';
import '../../../util/network.dart';
import '../../../util/secure_screen.dart';
import '../../../util/util.dart';
import 'qr_scanner_page.dart';

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

  static final _log = Logger('account_send');

  bool processing = false;
  bool full = true;
  // double _currentSliderValue = 5;
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

  // Token being sent — null means the native coin (RBTC). Populated with
  // whatever ERC20 tokens exist for the current network (RIF, USDRIF, DOC,
  // RIFPRO, tBRZ, ...), so the user can pick one instead of only ever
  // sending RBTC.
  List<Token> _tokens = [];
  Token? _selectedToken;
  int _selectedTokenDecimals = 18;
  double _selectedTokenBalance = 0;
  bool _loadingTokenBalance = false;

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
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final tokens = await TokenHelper().fetchItems(walletService.rootstockTokenChainId);
    if (mounted) {
      setState(() {
        _tokens = tokens;
      });
    }
  }

  Future<void> _onTokenChanged(Token? token) async {
    setState(() {
      _selectedToken = token;
      _loadingTokenBalance = token != null;
    });
    if (token == null) {
      return;
    }
    final decimals = await walletService.getErc20Decimals(token.address);
    final tokenBalance = await walletService.getErc20Balance(token.address, address);
    if (mounted) {
      setState(() {
        _selectedTokenDecimals = decimals;
        _selectedTokenBalance = tokenBalance;
        _loadingTokenBalance = false;
      });
    }
  }

  Future<void> _scanAddress() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );
    if (scanned == null || !mounted) {
      return;
    }
    final trimmed = scanned.trim();
    if (!Network.isValidEvmAddress(trimmed)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code does not contain a valid Rootstock/EVM address'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    destinationAddressController.text = trimmed;
    calculateFee();
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

    if (!Network.isValidEvmAddress(destinationAddressController.text)) {
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
      // Tokens other than RBTC don't have a reliable USD quote here, so show
      // nothing rather than a misleading number computed with RBTC's price.
      var usdAmount =
          _selectedToken == null ? await walletService.calculateInUsd(bp.toNumber()) : '';
      setState(() {
        amountInUsd = usdAmount;
      });
    } catch (e) {
      // Send the same message shown to user (line 185) to Sentry for telemetry
      displaySnackBar("Error sending transaction, review and try again");
      try {
        await Sentry.captureMessage("Error sending transaction, review and try again");
      } catch (_) {
        // ignore Sentry failures to avoid breaking the app flow
      }
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
                      ),
                    ),
                    ElevatedButton(
                      style: lightBlueButton,
                      onPressed: isQrScannerSupported ? _scanAddress : null,
                      child: const Row(
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
                if (_tokens.isNotEmpty)
                  DropdownButtonFormField<Token?>(
                    initialValue: _selectedToken,
                    decoration: const InputDecoration(labelText: "Token"),
                    dropdownColor: rootstockBlack,
                    style: const TextStyle(color: rootstockCream),
                    items: [
                      const DropdownMenuItem<Token?>(
                        value: null,
                        child: Text('RBTC (native)'),
                      ),
                      for (final token in _tokens)
                        DropdownMenuItem<Token?>(
                          value: token,
                          child: Text(token.symbol),
                        ),
                    ],
                    onChanged: _onTokenChanged,
                  ),
                if (_selectedToken != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _loadingTokenBalance
                          ? 'Loading balance…'
                          : 'Balance: ${_selectedTokenBalance.toStringAsFixed(4)} ${_selectedToken!.symbol}',
                      style: mutedCaptionText,
                    ),
                  ),
                Row(
                  children: [
                    Image.asset(
                      _selectedToken == null
                          ? "assets/icons/rbtc2.png"
                          : "assets/contracts/${_selectedToken!.symbol}.png",
                      width: 48,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        "assets/icons/rbtc2.png",
                        width: 48,
                      ),
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
                        ),
                      ),
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
                                : sucessIcon,
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                ),
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
        final Big tipBp = Big(tipAmount.toString());
        final BigInt tipAmountWei = BigInt.parse(tipBp.times(RBTC_DECIMAL_PLACES).toString());
        await walletService.sendRBTC(
          widget.selectedNetwork.walletDTO,
          tipAccount,
          tipAmountWei,
        );
      }
    }
  }

  Future<SimpleTransaction> validateAndPerformTransaction() async {
    Big bp = prepareAmountValue();
    final token = _selectedToken;

    // Gas on Rootstock is always paid in RBTC, even when sending an ERC20
    // token — check this explicitly so the user gets a clear error instead
    // of a failed/reverted transaction with an unhelpful message.
    final hasGas = await walletService.hasEnoughGasForRootstockTx(
      address,
      estimatedGasLimit: token == null ? 54000 : 100000,
    );
    if (!hasGas) {
      throw Exception('Insufficient RBTC balance to pay for network gas fees');
    }

    if (token == null) {
      return walletService.sendRBTC(
        widget.selectedNetwork.walletDTO,
        destinationAddressController.text,
        BigInt.parse(bp.times(RBTC_DECIMAL_PLACES).toString()),
      );
    }

    final rawAmount =
        BigInt.parse(bp.times(BigInt.from(10).pow(_selectedTokenDecimals).toDouble()).toString());
    return walletService.sendErc20Token(
      widget.selectedNetwork.wallet,
      token.address,
      destinationAddressController.text,
      rawAmount,
      valueInTokenFormatted: '${bp.toString()} ${token.symbol}',
    );
  }
}
