import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../entities/user_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/wallet_service.dart';
import '../../util/app_theme.dart';
import '../../util/util.dart';
import '../login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.user});

  final SimpleUser user;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';

  // Set at build time via --dart-define=RELEASE_NAME=... by the CI workflows
  // (only when triggered by an actual published GitHub Release, from
  // github.event.release.name) - empty for regular push/PR/dispatch builds,
  // in which case it's simply not shown.
  static const String _releaseName = String.fromEnvironment('RELEASE_NAME', defaultValue: '');

  final _bitcoinNodeController = TextEditingController();
  final _bitcoinEsploraController = TextEditingController();
  final _rootstockNodeController = TextEditingController();
  bool? _fieldsLoadedForMainnet;

  // Native names on purpose — a language's own name is conventionally shown
  // in that language regardless of the UI's current language.
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'pt': 'Português',
    'es': 'Español',
  };

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          final suffix = _releaseName.isNotEmpty ? ' ($_releaseName)' : '';
          _appVersion = 'v${info.version}$suffix';
        });
      }
    });
    final walletService = Provider.of<WalletServiceImpl>(context, listen: false);
    walletService.loadNetworkMode();
    walletService.loadLocale();
    walletService.loadCustomNodeUrls();
  }

  @override
  void dispose() {
    _bitcoinNodeController.dispose();
    _bitcoinEsploraController.dispose();
    _rootstockNodeController.dispose();
    super.dispose();
  }

  /// Re-fills the text fields from the override for the currently-selected
  /// network whenever that network changes (or on first load), so switching
  /// testnet/mainnet never shows the other network's custom URL by mistake.
  void _syncFieldsWithCurrentMode(WalletServiceImpl walletService) {
    if (_fieldsLoadedForMainnet == walletService.isMainnet) {
      return;
    }
    _fieldsLoadedForMainnet = walletService.isMainnet;
    _bitcoinNodeController.text = walletService.customBitcoinNodeUrlForCurrentMode ?? '';
    _bitcoinEsploraController.text = walletService.customBitcoinEsploraUrlForCurrentMode ?? '';
    _rootstockNodeController.text = walletService.customRootstockNodeUrlForCurrentMode ?? '';
  }

  bool _isValidUrlOrEmpty(String value) {
    if (value.trim().isEmpty) {
      return true;
    }
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  Future<void> _saveNodeUrl(String key, String value, WalletServiceImpl walletService) async {
    if (!_isValidUrlOrEmpty(value)) {
      showMessage(AppLocalizations.of(context)!.invalidUrlMessage, context);
      return;
    }
    await walletService.setCustomNodeUrl(key, value);
    if (!mounted) return;
    showMessage(
        value.trim().isEmpty
            ? AppLocalizations.of(context)!.nodeUrlResetMessage
            : AppLocalizations.of(context)!.nodeUrlSavedMessage,
        context);
  }

  Future<void> _onMainnetToggled(bool mainnet, WalletServiceImpl walletService) async {
    if (!mainnet) {
      await walletService.setNetworkMode(false);
      return;
    }
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: rootstockBlack,
        title: Text(t.switchToMainnetTitle, style: const TextStyle(color: rootstockCream)),
        content: Text(
          t.switchToMainnetBody,
          style: const TextStyle(color: rootstockCream),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancelLabel, style: const TextStyle(color: rootstockCream)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.switchToMainnetButton, style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await walletService.setNetworkMode(true);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: mutedCaptionText),
          Text(value, style: const TextStyle(color: rootstockCream)),
        ],
      ),
    );
  }

  Widget _nodeUrlField(
    String label,
    TextEditingController controller,
    String prefKey,
    WalletServiceImpl walletService,
  ) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: rootstockCream, fontSize: 13),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: mutedCaptionText,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: rootstockCream.withValues(alpha: 0.3)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: rootstockCream),
                ),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (value) => _saveNodeUrl(prefKey, value, walletService),
            ),
          ),
          IconButton(
            tooltip: t.saveLabel,
            icon: const Icon(Icons.check, color: rootstockCream),
            onPressed: () => _saveNodeUrl(prefKey, controller.text, walletService),
          ),
          IconButton(
            tooltip: t.resetToDefaultLabel,
            icon: Icon(Icons.restore, color: rootstockCream.withValues(alpha: 0.6)),
            onPressed: () {
              controller.text = '';
              _saveNodeUrl(prefKey, '', walletService);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletServiceImpl>();
    final t = AppLocalizations.of(context)!;
    _syncFieldsWithCurrentMode(walletService);
    return Scaffold(
      backgroundColor: rootstockBlack,
      appBar: AppBar(
        backgroundColor: rootstockBlack,
        iconTheme: const IconThemeData(color: rootstockCream),
        title: Text(t.configureAccount, style: const TextStyle(color: rootstockCream)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.accountLabel,
                style: const TextStyle(
                    color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold)),
            _infoRow(t.emailLabel, widget.user.email),
            const SizedBox(height: 16),
            Text(t.networkLabel,
                style: const TextStyle(
                    color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    walletService.isMainnet ? t.mainnetLabel : t.testnetLabel,
                    style: TextStyle(
                      color: walletService.isMainnet ? Colors.orange : rootstockCream,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: walletService.isMainnet,
                    activeColor: Colors.orange,
                    onChanged: (value) => _onMainnetToggled(value, walletService),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(t.customNodeUrlsLabel(walletService.isMainnet ? t.mainnetLabel : t.testnetLabel),
                style: const TextStyle(
                    color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t.customNodeUrlsHint, style: mutedCaptionText),
            _nodeUrlField(
              t.bitcoinNodeUrlLabel,
              _bitcoinNodeController,
              walletService.isMainnet
                  ? customBitcoinNodeUrlMainnetKey
                  : customBitcoinNodeUrlTestnetKey,
              walletService,
            ),
            _nodeUrlField(
              t.bitcoinEsploraUrlLabel,
              _bitcoinEsploraController,
              walletService.isMainnet
                  ? customBitcoinEsploraUrlMainnetKey
                  : customBitcoinEsploraUrlTestnetKey,
              walletService,
            ),
            _nodeUrlField(
              t.rootstockNodeUrlLabel,
              _rootstockNodeController,
              walletService.isMainnet
                  ? customRootstockNodeUrlMainnetKey
                  : customRootstockNodeUrlTestnetKey,
              walletService,
            ),
            const SizedBox(height: 16),
            Text(t.languageLabel,
                style: const TextStyle(
                    color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DropdownButton<String?>(
                value: walletService.selectedLocale?.languageCode,
                dropdownColor: rootstockBlack,
                isExpanded: true,
                style: const TextStyle(color: rootstockCream),
                underline: Container(height: 1, color: rootstockCream.withValues(alpha: 0.3)),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(t.systemDefaultLabel),
                  ),
                  for (final locale in AppLocalizations.supportedLocales)
                    DropdownMenuItem<String?>(
                      value: locale.languageCode,
                      child: Text(_languageNames[locale.languageCode] ?? locale.languageCode),
                    ),
                ],
                onChanged: (value) {
                  walletService.setLocale(value == null ? null : Locale(value));
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(t.aboutLabel,
                style: const TextStyle(
                    color: rootstockCream, fontSize: 18, fontWeight: FontWeight.bold)),
            _infoRow(t.appVersionLabel, _appVersion),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  style: pinkButton,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(t.logOut, style: smallWhiteBoldText),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
