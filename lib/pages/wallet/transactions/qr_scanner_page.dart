import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../util/app_theme.dart';

/// mobile_scanner has no Linux platform implementation (Android, iOS,
/// macOS, and Web are all supported) — callers should hide/disable the
/// scan entry point on Linux rather than navigating to [QrScannerPage],
/// which would otherwise throw a MissingPluginException there.
bool get isQrScannerSupported => kIsWeb || !Platform.isLinux;

/// Full-screen QR scanner. Pops with the scanned string as soon as a code is
/// detected, or with null if the user backs out.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value != null && value.isNotEmpty) {
      _handled = true;
      Navigator.of(context).pop(value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rootstockBlack,
      appBar: AppBar(
        backgroundColor: rootstockBlack,
        iconTheme: const IconThemeData(color: rootstockCream),
        title: const Text('Scan QR code', style: TextStyle(color: rootstockCream)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: rootstockCream),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}
