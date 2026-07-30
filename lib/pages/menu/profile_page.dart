import 'package:flutter/material.dart';

import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../util/app_theme.dart';
import '../../util/clipboard_guard.dart';
import '../../util/util.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.wallets});

  final SimpleUser user;
  final List<WalletEntity> wallets;

  void _copy(BuildContext context, String value) {
    copyWithTimeout(value);
    showMessage(AppLocalizations.of(context)!.copiedMessage, context);
  }

  Widget _addressRow(BuildContext context, String label, String address) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: mutedCaptionText),
          ),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(color: rootstockCream, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: rootstockCream, size: 16),
            onPressed: () => _copy(context, address),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: rootstockBlack,
      appBar: AppBar(
        backgroundColor: rootstockBlack,
        iconTheme: const IconThemeData(color: rootstockCream),
        title: Text(t.profile, style: const TextStyle(color: rootstockCream)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.accountLabel,
              style: const TextStyle(
                  color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(user.name, style: const TextStyle(color: rootstockCream, fontSize: 15)),
          const SizedBox(height: 4),
          Text(user.email, style: mutedCaptionText),
          const SizedBox(height: 24),
          Text(t.walletsLabel,
              style: const TextStyle(
                  color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final wallet in wallets)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: rootstockCream.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.walletName,
                    style: const TextStyle(color: rootstockCream, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _addressRow(context, t.bitcoinLabel, wallet.btcAddress),
                  _addressRow(context, t.rootstockLabel, wallet.publicKey),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
