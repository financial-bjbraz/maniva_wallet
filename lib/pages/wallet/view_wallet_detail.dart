import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../entities/network_dto.dart';
import '../../entities/user_helper.dart';
import '../../entities/wallet_dto.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/wallet_service.dart';
import '../../util/app_theme.dart';
import '../../util/clipboard_guard.dart';
import '../../util/network.dart';
import '../../util/util.dart';
import '../../util/widget_shimmer.dart';
import 'tokens/tokens_from_network.dart';
import 'transactions/account_receive.dart';
import 'transactions/account_send.dart' as rsk_send;
import 'transactions/bitcoin_account_send.dart';
import 'transactions/transactions_history_page.dart';
import 'wallet_security_page.dart';

/// Single-page account overview: shows the Bitcoin address/balance, the
/// Rootstock address/balance and its tokens, and a grand total — replacing
/// the previous BTC/RSK/List tab navigation so everything is visible without
/// switching tabs.
class ViewWalletDetailPage extends StatefulWidget {
  const ViewWalletDetailPage({super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _ViewWalletDetailPageState createState() => _ViewWalletDetailPageState();
}

class _ViewWalletDetailPageState extends State<ViewWalletDetailPage>
    with SingleTickerProviderStateMixin {
  static final _log = Logger('view_wallet_detail');

  // Tokens that have a real, exchange-listed USD price, mapped to their
  // CoinGecko id. Everything else in TokensFromNetwork (DOC, RIFPRO, tBRZ,
  // ...) is shown in native units only, since there's no reliable quote for
  // testnet-only assets.
  static const Map<String, String> _pricedTokenCoingeckoIds = {
    'rif': 'rif-token',
    'usdrif': 'rif-us-dollar',
  };

  // The shared Provider instance (not a locally-constructed one) — required
  // so this page reacts when the testnet/mainnet toggle in Settings calls
  // notifyListeners() on it. listen: false because reactivity here comes
  // from the explicit walletService.addListener() in initState below, not
  // from Provider's InheritedWidget mechanism — the listening variant can't
  // be used from a field initializer accessed during initState().
  late final WalletServiceImpl walletService =
      Provider.of<WalletServiceImpl>(context, listen: false);
  final NumberFormat _usdFormat = NumberFormat.simpleCurrency(name: 'USD');

  bool _btcLoading = true;
  bool _rskLoading = true;
  String _btcAddress = '';
  String _rskAddress = '';
  double _btcBalance = 0;
  double _btcUsd = 0;
  String _rbtcBalanceFormatted = '0';
  double _rskUsd = 0;

  final Map<String, double> _pricedTokenBalances = {};
  final Map<String, double> _pricedTokenUsdPrices = {};

  final ScrollController _scrollController = ScrollController();
  late final AnimationController _bounceController;
  bool _hasMoreBelow = true;

  Timer? _transactionSyncTimer;
  bool _syncingTransactions = false;

  @override
  void initState() {
    super.initState();
    walletService.loadNetworkMode().then((_) => _onWalletServiceChanged());
    walletService.addListener(_onWalletServiceChanged);
    _refreshAddresses();
    _loadBtc();
    _loadRsk();
    _loadTokenPrices();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scrollController.addListener(_updateScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());

    _syncTransactions();
    _transactionSyncTimer = Timer.periodic(const Duration(seconds: 25), (_) => _syncTransactions());
  }

  Future<void> _syncTransactions() async {
    if (_syncingTransactions || !mounted) {
      return;
    }
    _syncingTransactions = true;
    try {
      final newBtc = await walletService.syncBitcoinTransactions(widget.wallet);
      final newRsk = await walletService.syncRootstockTransactions(widget.wallet);
      final newIncoming = [...newBtc, ...newRsk];
      if (newIncoming.isNotEmpty && mounted) {
        // A fresh balance load reflects the newly-arrived funds right away
        // instead of waiting for the next periodic refresh.
        _loadBtc();
        _loadRsk();
        for (final tx in newIncoming) {
          final symbol = newBtc.contains(tx) ? 'BTC' : 'RBTC';
          showMessage(
            'Incoming: ${tx.valueInWeiFormatted} $symbol received (${tx.valueInUsdFormatted})',
            context,
          );
        }
      }
    } finally {
      _syncingTransactions = false;
    }
  }

  void _refreshAddresses() {
    _btcAddress = walletService.getBtcAddressFromPrivateKey(
        widget.wallet.privateKey, walletService.currentBitcoinNetwork);
    _rskAddress = Network.generateAddress(walletService.currentRootstockNetwork, widget.wallet);
  }

  bool _wasMainnet = false;
  late String _lastBitcoinNodeUrl = walletService.bitcoinNodeUrl;
  late String _lastBitcoinEsploraUrl = walletService.bitcoinEsploraUrl;
  late String _lastRootstockNodeUrl = walletService.rootstockNodeUrl;

  /// Reacts to any change walletService broadcasts that could affect what
  /// this page shows: the mainnet/testnet toggle, or a custom node/Esplora
  /// URL saved in Settings. Without tracking the node URLs too, saving a
  /// custom node in Settings silently had no effect here until the next
  /// unrelated rebuild, since only the network-mode flip was checked.
  void _onWalletServiceChanged() {
    if (!mounted) {
      return;
    }
    final mainnetChanged = walletService.isMainnet != _wasMainnet;
    final nodeUrlsChanged = walletService.bitcoinNodeUrl != _lastBitcoinNodeUrl ||
        walletService.bitcoinEsploraUrl != _lastBitcoinEsploraUrl ||
        walletService.rootstockNodeUrl != _lastRootstockNodeUrl;
    if (!mainnetChanged && !nodeUrlsChanged) {
      return;
    }
    _wasMainnet = walletService.isMainnet;
    _lastBitcoinNodeUrl = walletService.bitcoinNodeUrl;
    _lastBitcoinEsploraUrl = walletService.bitcoinEsploraUrl;
    _lastRootstockNodeUrl = walletService.rootstockNodeUrl;
    setState(() {
      _refreshAddresses();
      _btcLoading = true;
      _rskLoading = true;
    });
    _loadBtc();
    _loadRsk();
  }

  void _updateScrollHint() {
    if (!_scrollController.hasClients) {
      return;
    }
    final hasMore =
        _scrollController.position.maxScrollExtent - _scrollController.position.pixels > 4;
    if (hasMore != _hasMoreBelow && mounted) {
      setState(() {
        _hasMoreBelow = hasMore;
      });
    }
  }

  @override
  void dispose() {
    walletService.removeListener(_onWalletServiceChanged);
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    _bounceController.dispose();
    _transactionSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBtc() async {
    try {
      final btcDto = await walletService.getBitcoinBalanceFromBlockchainOnly(widget.wallet);
      if (mounted) {
        setState(() {
          _btcBalance = btcDto.btcBalanceInDouble;
          _btcUsd = btcDto.amountInUsd;
          _btcLoading = false;
        });
      }
    } catch (e) {
      _log.severe('Error loading Bitcoin balance', e);
      if (mounted) {
        setState(() {
          _btcLoading = false;
        });
      }
    }
  }

  Future<void> _loadRsk() async {
    try {
      final rskDto = await walletService.getRootstockWalletRefreshed(widget.wallet);
      if (mounted) {
        setState(() {
          _rbtcBalanceFormatted = rskDto.valueInWeiFormatted;
          _rskUsd = rskDto.amountInUsd;
          _rskLoading = false;
        });
      }
    } catch (e) {
      _log.severe('Error loading Rootstock balance', e);
      if (mounted) {
        setState(() {
          _rskLoading = false;
        });
      }
    }
  }

  Future<void> _loadTokenPrices() async {
    try {
      final ids = _pricedTokenCoingeckoIds.values.join(',');
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$ids&vs_currencies=usd'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final prices = <String, double>{};
        _pricedTokenCoingeckoIds.forEach((symbol, coingeckoId) {
          final entry = body[coingeckoId] as Map<String, dynamic>?;
          final usd = entry?['usd'];
          if (usd is num) {
            prices[symbol] = usd.toDouble();
          }
        });
        if (mounted) {
          setState(() {
            _pricedTokenUsdPrices
              ..clear()
              ..addAll(prices);
          });
        }
      }
    } catch (e) {
      _log.severe('Error loading token USD prices', e);
    }
  }

  void _onTokenBalancesLoaded(Map<String, double> balancesBySymbol) {
    final priced = <String, double>{};
    balancesBySymbol.forEach((symbol, balance) {
      final key = symbol.toLowerCase().replaceFirst(RegExp('^t'), '');
      if (_pricedTokenCoingeckoIds.containsKey(key)) {
        priced[key] = balance;
      }
    });
    if (mounted) {
      setState(() {
        _pricedTokenBalances
          ..clear()
          ..addAll(priced);
      });
    }
  }

  double get _pricedTokensUsd {
    double total = 0;
    _pricedTokenBalances.forEach((symbol, balance) {
      total += balance * (_pricedTokenUsdPrices[symbol] ?? 0);
    });
    return total;
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _addressTile(String iconAsset, String address) {
    return Row(
      children: [
        Image.asset(iconAsset, width: 28, height: 28, cacheWidth: 56, cacheHeight: 56),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            formatTextWithParameter(address, 10),
            style: const TextStyle(color: rootstockCream, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: rootstockCream, size: 18),
          onPressed: () {
            copyWithTimeout(address);
            showMessage(AppLocalizations.of(context)!.copiedMessage, context);
          },
        ),
      ],
    );
  }

  Widget _balanceRow(String symbol, String amount, double usdValue, bool loading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$amount $symbol', style: const TextStyle(color: rootstockCream, fontSize: 15)),
          if (loading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: rootstockCream),
            )
          else
            Text(_usdFormat.format(usdValue), style: mutedCaptionText),
        ],
      ),
    );
  }

  Widget _subtotalRow(double usdValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLocalizations.of(context)!.subtotalLabel,
              style: const TextStyle(color: rootstockCream, fontWeight: FontWeight.bold)),
          Text(
            _usdFormat.format(usdValue),
            style: const TextStyle(color: rootstockCream, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons({
    required VoidCallback onSend,
    required VoidCallback onTransactions,
    required VoidCallback onReceive,
  }) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: greenButton,
              icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
              label: Text(t.send, style: smallWhiteBoldText),
              onPressed: onSend,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: purpleButton,
              icon: const Icon(Icons.receipt_long, color: Colors.white, size: 16),
              label: Text(t.transactions, style: smallWhiteBoldText),
              onPressed: onTransactions,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: lightBlueButton,
              icon: const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
              label: Text(t.receive, style: smallWhiteBoldText),
              onPressed: onReceive,
            ),
          ),
        ],
      ),
    );
  }

  void _openBitcoinSend() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BitcoinAccountSendSend(
          user: widget.user,
          selectedNetwork: NetworkDto(
              network: walletService.currentBitcoinNetwork,
              wallet: widget.wallet,
              user: widget.user),
        ),
      ),
    );
  }

  void _openBitcoinReceive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Receive(
          user: widget.user,
          walletDto: WalletDTO(wallet: widget.wallet, transactions: null, btcTransactions: null),
          network: walletService.currentBitcoinNetwork,
          address: _btcAddress,
        ),
      ),
    );
  }

  void _openRootstockSend() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => rsk_send.Send(
          user: widget.user,
          selectedNetwork: NetworkDto(
              network: walletService.currentRootstockNetwork,
              wallet: widget.wallet,
              user: widget.user),
        ),
      ),
    );
  }

  void _openRootstockReceive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Receive(
          user: widget.user,
          walletDto: WalletDTO(wallet: widget.wallet, transactions: null, btcTransactions: null),
          network: walletService.currentRootstockNetwork,
          address: _rskAddress,
        ),
      ),
    );
  }

  void _openBitcoinTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionsHistoryPage(
          wallet: widget.wallet,
          network: walletService.currentBitcoinNetwork,
        ),
      ),
    );
  }

  void _openRootstockTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionsHistoryPage(
          wallet: widget.wallet,
          network: walletService.currentRootstockNetwork,
        ),
      ),
    );
  }

  void _openWalletSecurity() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WalletSecurityPage(wallet: widget.wallet, user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final double rskSectionUsd = _rskUsd + _pricedTokensUsd;
    final double grandTotal = _btcUsd + rskSectionUsd;
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: rootstockBlack,
        border: Border.all(color: rootstockCream),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 48,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(AppLocalizations.of(context)!.accountOverviewTitle,
                style: const TextStyle(color: rootstockCream, fontSize: 14)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: IconButton(
                tooltip: t.walletSecurityTitle,
                icon: const Icon(Icons.key, color: rootstockCream),
                onPressed: _openWalletSecurity,
              ),
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        body: Stack(
          children: [
            Shimmer(
              linearGradient: shimmerGradient,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (walletService.isMainnet) _mainnetBanner(),
                    _sectionHeader(t.bitcoinLabel),
                    _addressTile('assets/icons/btc.png', _btcAddress),
                    const SizedBox(height: 8),
                    _balanceRow('BTC', _btcBalance.toStringAsFixed(8), _btcUsd, _btcLoading),
                    _actionButtons(
                        onSend: _openBitcoinSend,
                        onTransactions: _openBitcoinTransactions,
                        onReceive: _openBitcoinReceive),
                    _subtotalRow(_btcUsd),
                    const Divider(color: rootstockCream),
                    const SizedBox(height: 8),
                    _sectionHeader(t.rootstockLabel),
                    _addressTile('assets/icons/rbtc2.png', _rskAddress),
                    const SizedBox(height: 8),
                    _balanceRow('RBTC', _rbtcBalanceFormatted, _rskUsd, _rskLoading),
                    _actionButtons(
                        onSend: _openRootstockSend,
                        onTransactions: _openRootstockTransactions,
                        onReceive: _openRootstockReceive),
                    const SizedBox(height: 8),
                    // Tokens with a real market quote (RIF, USDRIF) are folded into
                    // the subtotal/grand total below via onBalancesLoaded; the
                    // rest (DOC, RIFPRO, tBRZ, ...) are shown in native units only
                    // since there's no reliable USD quote for those testnet assets.
                    TokensFromNetwork(
                      // Includes the node URL (not just isMainnet) so a
                      // custom Rootstock node saved in Settings forces this
                      // widget to remount and refetch, instead of silently
                      // keeping the balances it fetched with the old node.
                      key: ValueKey('${walletService.isMainnet}-${walletService.rootstockNodeUrl}'),
                      wallet: widget.wallet,
                      user: widget.user,
                      selectedNetwork: walletService.currentRootstockNetwork,
                      currentAddress: _rskAddress,
                      rootstockNodeUrl: walletService.rootstockNodeUrl,
                      onBalancesLoaded: _onTokenBalancesLoaded,
                    ),
                    const SizedBox(height: 8),
                    _subtotalRow(rskSectionUsd),
                    const Divider(color: rootstockCream),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.grandTotalLabel,
                              style: const TextStyle(
                                  color: rootstockCream,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            _usdFormat.format(grandTotal),
                            style: const TextStyle(
                                color: rootstockCream, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_hasMoreBelow) _scrollHint(),
          ],
        ),
      ),
    );
  }

  Widget _mainnetBanner() {
    final configured = walletService.rootstockNodeUrl.isNotEmpty;
    final t = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              configured ? t.mainnetBannerConfigured : t.mainnetBannerNotConfigured,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollHint() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [rootstockBlack.withValues(alpha: 0), rootstockBlack],
            ),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -4 * _bounceController.value),
                child: child,
              );
            },
            child: Icon(
              Icons.keyboard_arrow_down,
              color: rootstockCream.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
