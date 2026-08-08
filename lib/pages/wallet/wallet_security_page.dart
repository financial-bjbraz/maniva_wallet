import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/wallet_service.dart';
import '../../util/app_theme.dart';
import '../../util/clipboard_guard.dart';
import '../../util/util.dart';
import '../home_page.dart';

/// Per-wallet export (private key / Bitcoin WIF) and delete screen, reached
/// from [ViewWalletDetailPage]. Deletion is only reachable after the user has
/// revealed at least one key and explicitly confirmed they saved it — there
/// is no other way to recover a wallet's key once it's deleted, since the
/// original BIP39 mnemonic is never persisted (see WalletEntity).
class WalletSecurityPage extends StatefulWidget {
  const WalletSecurityPage({super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _WalletSecurityPageState createState() => _WalletSecurityPageState();
}

class _WalletSecurityPageState extends State<WalletSecurityPage> {
  late final WalletServiceImpl walletService =
      Provider.of<WalletServiceImpl>(context, listen: false);

  bool _privateKeyRevealed = false;
  bool _wifRevealed = false;
  bool _savedConfirmed = false;
  bool _deleting = false;

  bool get _hasRevealedKey => _privateKeyRevealed || _wifRevealed;

  void _copy(String value) {
    copyWithTimeout(value);
    showMessage(AppLocalizations.of(context)!.copiedMessage, context);
  }

  Widget _revealableKeyRow({
    required String label,
    required String value,
    required bool revealed,
    required VoidCallback onToggle,
  }) {
    final t = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: rootstockCream.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: mutedCaptionText),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  revealed ? value : '•' * 32,
                  style: const TextStyle(
                    color: rootstockCream,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (revealed)
                IconButton(
                  icon: const Icon(Icons.copy, color: rootstockCream, size: 18),
                  onPressed: () => _copy(value),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onToggle,
              icon: Icon(revealed ? Icons.visibility_off : Icons.visibility,
                  color: rootstockCream, size: 16),
              label: Text(
                revealed ? t.hideLabel : t.revealLabel,
                style: const TextStyle(color: rootstockCream, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: rootstockBlack,
        title: Text(t.deleteWalletConfirmTitle, style: const TextStyle(color: rootstockCream)),
        content: Text(t.deleteWalletConfirmBody, style: const TextStyle(color: rootstockCream)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancelLabel, style: const TextStyle(color: rootstockCream)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.deleteWalletConfirmButton, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _deleting = true;
    });
    try {
      await walletService.delete(widget.wallet);
      final wallets = await walletService.getWallets(widget.user.email);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePage(user: widget.user, wallets: wallets),
        ),
        (route) => false,
      );
      showMessage(t.walletDeletedMessage, context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deleting = false;
      });
      showMessage(t.walletDeleteFailedMessage, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: rootstockBlack,
      appBar: AppBar(
        backgroundColor: rootstockBlack,
        iconTheme: const IconThemeData(color: rootstockCream),
        title: Text(t.walletSecurityTitle, style: const TextStyle(color: rootstockCream)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                      t.walletSecurityWarning,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _revealableKeyRow(
              label: t.privateKeyLabel,
              value: widget.wallet.privateKey,
              revealed: _privateKeyRevealed,
              onToggle: () => setState(() {
                _privateKeyRevealed = !_privateKeyRevealed;
              }),
            ),
            _revealableKeyRow(
              label: t.bitcoinWifLabel,
              value: widget.wallet.btcWif,
              revealed: _wifRevealed,
              onToggle: () => setState(() {
                _wifRevealed = !_wifRevealed;
              }),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _savedConfirmed,
              onChanged: _hasRevealedKey
                  ? (value) => setState(() {
                        _savedConfirmed = value ?? false;
                      })
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: rootstockCream,
              checkColor: rootstockBlack,
              title: Text(t.confirmSavedKeyLabel, style: const TextStyle(color: rootstockCream)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                icon: _deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_forever, color: Colors.white),
                label: Text(t.deleteWalletButton, style: smallWhiteBoldText),
                onPressed: _savedConfirmed && !_deleting ? _confirmAndDelete : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
