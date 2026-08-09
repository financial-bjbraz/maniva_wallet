// Regression tests for two bugs found while manually testing v1.1.0:
//
// 1. WalletServiceImpl.delete routed through util.dart's openDataBase(),
//    which called EntityHelper.setUp() - a method that fires the async
//    `database` getter without awaiting it and returns nothing, so
//    openDataBase() always resolved to null. db.delete(...) on that null
//    threw inside an unhandled async gap, leaving the Wallet Security
//    delete button spinning forever with no error surfaced. Fixed by
//    routing through WalletHelper.deleteItem instead (see wallet_service.dart).
//
// 2. WalletServiceImpl.setCustomNodeUrl persists the override and calls
//    notifyListeners(), but nothing previously consumed that outside of a
//    mainnet/testnet toggle - saving a custom node URL had no visible
//    effect until an unrelated rebuild. Fixed in ViewWalletDetailPage by
//    also tracking the effective node URLs (see view_wallet_detail.dart).
//    This test exercises the service layer directly: persistence, the
//    getters ViewWalletDetailPage reads, and that notifyListeners actually
//    fires - the underlying contract that fix depends on.
//
// Uses the real (non-mocked) database via sqflite_common_ffi, the same
// pattern as app_navigation_test.dart: forces the Linux/FFI code path in
// EntityHelper (no native macOS/iOS/Android plugin needed under `flutter
// test`) so these tests exercise the real SQL, not a stand-in for it.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maniva_wallet/entities/wallet_helper.dart';
import 'package:maniva_wallet/services/wallet_service.dart';
import 'package:maniva_wallet/util/util.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String _tempPath = Directory.systemTemp.createTempSync('maniva_test_').path;

  @override
  Future<String?> getApplicationSupportPath() async => _tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'ROOTSTOCK_NODE=http://localhost:9999\n');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('WalletServiceImpl.delete actually removes the wallet from the database', () async {
    final walletService = WalletServiceImpl();
    final wallet = WalletEntity(
      amount: 0,
      btcAmount: 0,
      privateKey: '0xdeadbeef00000000000000000000000000000000000000000000000000cafe',
      walletName: 'Test wallet',
      walletId: '1',
      publicKey: '0x0000000000000000000000000000000000dEaD',
      ownerEmail: 'delete-test@example.com',
      btcAddress: 'mzBc4XEFSdzCDcTxAgf6EZXgsZWpztRhef',
      btcWif: 'cVtestwiftestwiftestwiftestwiftestwiftestwifX',
    );

    await WalletHelper().insertItem(wallet);
    final beforeDelete = await WalletHelper().fetchItems(wallet.ownerEmail);
    expect(beforeDelete.any((w) => w.privateKey == wallet.privateKey), isTrue,
        reason: 'setup: the wallet should exist right after insertItem');

    // This used to throw (openDataBase() resolved to null) and never
    // complete the Future - the exact hang seen in the running app.
    await walletService.delete(wallet);

    final afterDelete = await WalletHelper().fetchItems(wallet.ownerEmail);
    expect(afterDelete.any((w) => w.privateKey == wallet.privateKey), isFalse,
        reason: 'the wallet should be gone from the database after delete()');
  });

  test(
      'WalletServiceImpl.setCustomNodeUrl persists the override, updates the effective '
      'node getters, and notifies listeners', () async {
    final walletService = WalletServiceImpl();
    await walletService.loadCustomNodeUrls();

    var notifyCount = 0;
    walletService.addListener(() => notifyCount++);

    expect(walletService.isMainnet, isFalse, reason: 'default mode is testnet');

    await walletService.setCustomNodeUrl(
        customBitcoinNodeUrlTestnetKey, 'https://custom-btc-node.example.com');
    await walletService.setCustomNodeUrl(
        customBitcoinEsploraUrlTestnetKey, 'https://custom-esplora.example.com');
    await walletService.setCustomNodeUrl(
        customRootstockNodeUrlTestnetKey, 'https://custom-rsk-node.example.com');

    expect(notifyCount, 3,
        reason: 'ViewWalletDetailPage relies on notifyListeners firing on every save to '
            'know it needs to refetch balances');

    // These are exactly the getters ViewWalletDetailPage._onWalletServiceChanged
    // compares against its last-seen values to decide whether to reload.
    expect(walletService.bitcoinNodeUrl, 'https://custom-btc-node.example.com');
    expect(walletService.bitcoinEsploraUrl, 'https://custom-esplora.example.com');
    expect(walletService.rootstockNodeUrl, 'https://custom-rsk-node.example.com');

    // Clearing (empty string, as the Settings "Reset to default" action does)
    // should revert to the .env default and still notify.
    await walletService.setCustomNodeUrl(customRootstockNodeUrlTestnetKey, '');
    expect(notifyCount, 4);
    expect(walletService.rootstockNodeUrl, 'http://localhost:9999');
  });
}
