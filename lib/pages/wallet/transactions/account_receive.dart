import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hux/hux.dart';
import 'package:maniva_wallet/entities/wallet_dto.dart';
import 'package:maniva_wallet/util/network.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../entities/user_helper.dart';
import '../../../services/wallet_service.dart';
import '../../../util/util.dart';

class Receive extends StatefulWidget {
  final SimpleUser user;
  final WalletDTO walletDto;
  final Network network;
  final String address;

  const Receive(
      {super.key,
      required this.user,
      required this.walletDto,
      required this.network,
      required this.address});

  @override
  _Receive createState() {
    return _Receive();
  }
}

class _Receive extends State<Receive> {
  ListTileTitleAlignment? titleAlignment;

  bool processing = false;
  late WalletServiceImpl walletService;
  List<String> splittedMnemonic = List<String>.filled(1, "");
  final valueController = TextEditingController();
  late String balance = "0";
  late String balanceInUsd = "0";

  _Receive();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Icon(Icons.add_circle, color: Colors.white),
              SizedBox(
                width: 5,
              ),
              Text(
                "Receive",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromRGBO(158, 118, 255, 1),
      ),
      body: Center(
          child:
              HuxCard(child: ShowQrCode(completeAddress: widget.address, network: widget.network))),
    );
  }
}

class ShareAndCopy extends StatelessWidget {
  final String completeAddress;
  final ethereum = "ethereum:";

  const ShareAndCopy({super.key, required this.completeAddress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            QrImageView(
              data: ethereum + completeAddress,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              embeddedImage: Image.asset("assets/icons/rbtc2.png").image,
              size: 50.0,
            ),
          ],
        ),
      ],
    );
  }
}

class ShowQrCode extends StatelessWidget {
  final String completeAddress;
  final ethereum = "ethereum:";
  final Network network;

  const ShowQrCode({super.key, required this.completeAddress, required this.network});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: ethereum + completeAddress,
      version: QrVersions.auto,
      backgroundColor: Colors.white,
      embeddedImage: (network == Network.ROOTSTOCK_TESTNET || network == Network.ROOTSTOCK_MAINNET)
          ? Image.asset("assets/icons/rbtc2.png").image
          : Image.asset("assets/icons/btc.png").image,
      size: 200.0,
    );
  }
}

class ShareButton extends StatefulWidget {
  final String completeAddress;

  const ShareButton({super.key, required this.completeAddress});

  @override
  _ShareButton createState() => _ShareButton();
}

class _ShareButton extends State<ShareButton> {
  bool checkingFlight = false;
  bool success = false;

  @override
  Widget build(BuildContext context) {
    return !checkingFlight
        ? ElevatedButton(
            style: blackWhiteButton,
            onPressed: () async {
              final box = context.findRenderObject() as RenderBox?;
              final data = utf8.encode(widget.completeAddress);
              await Share.shareXFiles(
                [
                  XFile.fromData(
                    data,
                    // name: fileName, // Notice, how setting the name here does not work.
                    mimeType: 'text/plain',
                  ),
                ],
                sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                fileNameOverrides: [widget.completeAddress],
              );

              setState(() {
                checkingFlight = true;
              });
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                success = true;
              });
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.pop(context);
            },
            child: const Row(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text("Share Your Address", style: smallBlackText),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(
                      Icons.share,
                      color: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          )
        : !success
            ? const CircularProgressIndicator()
            : const Icon(
                Icons.check,
                color: Colors.green,
              );
  }
}

class CopyButton extends StatefulWidget {
  final String completeAddress;

  const CopyButton({super.key, required this.completeAddress});

  @override
  _CopyButton createState() => _CopyButton();
}

class _CopyButton extends State<CopyButton> {
  bool checkingFlight = false;
  bool success = false;

  @override
  Widget build(BuildContext context) {
    return !checkingFlight
        ? ElevatedButton(
            style: blackWhiteButton,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.completeAddress));

              setState(() {
                checkingFlight = true;
              });
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                success = true;
              });
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.pop(context);
            },
            child: const Row(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text("Copy Your Address", style: smallBlackText),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(
                      Icons.copy,
                      color: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          )
        : !success
            ? const CircularProgressIndicator()
            : const Icon(
                Icons.check,
                color: Colors.green,
              );
  }
}
